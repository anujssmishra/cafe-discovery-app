"""Classify food payments with stable aliases in an additive identity table."""

import json
import re
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from zoneinfo import ZoneInfo

from sqlalchemy import false, func, or_, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import UpiTransaction, FoodPurchase, PaymentIdentity, OrderDetails
from app.models.restaurant import Restaurant
from app.schemas.transaction import TransactionIn, IngestResponse, IngestOutcome
from app.ingestion.mcc_classifier import AGGREGATOR_MCC_CODES, is_food_mcc
from app.ingestion.merchant_resolver import (
    normalize_merchant_name, detect_cuisine, determine_meal_type, determine_price_band,
)


def _name_key(value: str) -> str:
    return re.sub(r"[^\w]+", " ", value.casefold()).strip()


def _contains_phrase(text: str, phrase: str) -> bool:
    return bool(phrase) and f" {phrase} " in f" {text} "


async def match_restaurant_by_name(session: AsyncSession, normalized_name: str) -> str | None:
    """Resolve only an unambiguous active restaurant, preserving branch evidence."""
    rows = (await session.execute(
        select(Restaurant.id, Restaurant.name, Restaurant.area)
        .where(Restaurant.is_active.is_(True))
    )).all()
    merchant = _name_key(normalized_name)
    exact = [r.id for r in rows if _name_key(r.name) == merchant]
    if exact:
        return exact[0] if len(exact) == 1 else None

    candidates = []
    branch_candidates = []
    for row in rows:
        base = _name_key(row.name.split("(")[0])
        if len(base) <= 4 or not (
            _contains_phrase(merchant, base) or _contains_phrase(base, merchant)
        ):
            continue
        candidates.append(row.id)
        qualifiers = re.findall(r"\(([^)]+)\)", row.name)
        qualifiers.append(row.area)
        if any(_contains_phrase(merchant, _name_key(q)) for q in qualifiers if q):
            branch_candidates.append(row.id)

    matches = branch_candidates or candidates
    return matches[0] if len(matches) == 1 else None


def transaction_local_time(tx: TransactionIn) -> datetime:
    zone = ZoneInfo(tx.timezone)
    dt = tx.transaction_time
    return dt.replace(tzinfo=zone) if dt.tzinfo is None else dt.astimezone(zone)


def _identity_ids(tx: TransactionIn, merchant: str, utc_time: datetime) -> list[str]:
    """UPI reference wins across sources; source IDs and exact fingerprints cover retries."""
    keys = []
    if tx.upi_ref:
        keys.append([tx.user_id, "upi", tx.upi_ref.strip().upper()])
    if tx.source_id:
        keys.append([tx.user_id, "source", tx.source_id])
    if not keys and tx.time_precision == "exact":
        keys.append([
            tx.user_id, "payment", utc_time.isoformat(timespec="microseconds"),
            str(Decimal(str(tx.amount)).quantize(Decimal("0.01"))), _name_key(merchant),
        ])
    # Without any trustworthy identity/time, two otherwise identical payments may be distinct.
    if not keys:
        return [str(uuid.uuid4())]
    return [str(uuid.uuid5(uuid.NAMESPACE_URL, json.dumps(key, separators=(",", ":")))) for key in keys]


class ImportRejected(ValueError):
    """A terminal row-level rejection with a safe, machine-readable reason."""


def order_details_id(tx: TransactionIn) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_URL, json.dumps(
        [tx.user_id, "order", tx.order_platform, tx.order_id], separators=(",", ":"),
    )))


def same_amount(left: float, right: float) -> bool:
    return Decimal(str(left)).quantize(Decimal("0.01")) == Decimal(str(right)).quantize(Decimal("0.01"))


async def _existing_transaction(session: AsyncSession, tx: TransactionIn, ids: list[str]) -> str | None:
    matches = set((await session.execute(
        select(PaymentIdentity.transaction_id).where(
            PaymentIdentity.user_id == tx.user_id, PaymentIdentity.id.in_(ids),
        )
    )).scalars())
    conditions = [UpiTransaction.id.in_(ids)]
    if tx.upi_ref:
        conditions.append(func.upper(UpiTransaction.upi_ref) == tx.upi_ref.strip().upper())
    matches.update((await session.execute(select(UpiTransaction.id).where(
        UpiTransaction.user_id == tx.user_id, or_(*conditions),
    ))).scalars())
    if tx.order_id:
        details = await session.get(OrderDetails, order_details_id(tx))
        if details is not None and details.user_id == tx.user_id:
            matches.add(details.transaction_id)
    if len(matches) > 1:
        raise ImportRejected("identity_conflict")
    if tx.linked_transaction_id:
        linked = await session.scalar(select(UpiTransaction).where(
            UpiTransaction.id == tx.linked_transaction_id, UpiTransaction.user_id == tx.user_id,
        ))
        if linked is None:
            raise ImportRejected("linked_payment_not_found")
        if not same_amount(linked.amount, tx.amount):
            raise ImportRejected("amount_mismatch")
        if matches and linked.id not in matches:
            raise ImportRejected("linked_payment_conflicts_with_identity")
        return linked.id
    return next(iter(matches), None)


async def _register_missing_aliases(session: AsyncSession, user_id: str, transaction_id: str, ids: list[str]) -> None:
    for identity_id in ids:
        existing = await session.get(PaymentIdentity, identity_id)
        if existing is not None:
            if existing.user_id != user_id or existing.transaction_id != transaction_id:
                raise ImportRejected("identity_conflict")
            continue
        session.add(PaymentIdentity(id=identity_id, user_id=user_id, transaction_id=transaction_id))
    await session.flush()


def _known_merchant(name: str) -> bool:
    key = _name_key(name)
    return bool(key) and key not in {
        "swiggy", "zomato", "food app", "unknown food outlet", "unknown outlet",
        "bundl technologies", "bundl technologies pvt ltd", "zomato limited", "eternal limited",
    }


async def _classification(session, tx, merchant):
    restaurant_id = await match_restaurant_by_name(session, merchant)
    dish_cuisine = detect_cuisine("", " ".join(tx.dish_names)) if tx.dish_names else "unspecified"
    cuisine = tx.cuisine if tx.cuisine and tx.cuisine != "unspecified" else dish_cuisine
    if cuisine == "unspecified":
        cuisine = detect_cuisine(merchant, tx.raw_description)
    if cuisine == "unspecified" and restaurant_id:
        cuisines = await session.scalar(select(Restaurant.cuisines).where(Restaurant.id == restaurant_id))
        if cuisines:
            cuisine = cuisines[0]
    return restaurant_id, cuisine


def _purchase(tx, transaction_id, restaurant_id, cuisine):
    local_time = transaction_local_time(tx)
    utc_time = local_time.astimezone(timezone.utc).replace(tzinfo=None)
    weekday = local_time.weekday() if tx.time_precision != "unknown" else -1
    return FoodPurchase(
        id=str(uuid.uuid5(uuid.NAMESPACE_URL, f"food-purchase:{transaction_id}")),
        transaction_id=transaction_id, user_id=tx.user_id, restaurant_id=restaurant_id,
        cuisine_detected=cuisine,
        meal_type=determine_meal_type(local_time) if tx.time_precision == "exact" else "unknown",
        price_band=determine_price_band(tx.amount), day_of_week=weekday,
        hour_of_day=local_time.hour if tx.time_precision == "exact" else -1,
        is_weekend=weekday >= 5, purchased_at=utc_time,
    )


async def _attach_order_details(session, tx, stored: UpiTransaction) -> bool:
    """Upgrade safe receipt evidence on one existing payment without adding another purchase."""
    if not tx.order_id:
        return False
    details = await session.get(OrderDetails, order_details_id(tx))
    if details is not None and (details.user_id != tx.user_id or details.transaction_id != stored.id):
        raise ImportRejected("order_identity_conflict")
    merchant = normalize_merchant_name(tx.merchant_name)
    restaurant_id, cuisine = await _classification(session, tx, merchant)
    purchase = await session.scalar(select(FoodPurchase).where(
        FoodPurchase.transaction_id == stored.id, FoodPurchase.user_id == tx.user_id,
    ))
    # A later partial receipt must not replace explicit dishes/cuisine with a merchant guess.
    stronger_food_evidence = (tx.cuisine is not None and tx.cuisine != "unspecified") or bool(tx.dish_names)
    if details is not None and not stronger_food_evidence and details.cuisine:
        cuisine = details.cuisine
    elif purchase is not None and not stronger_food_evidence and purchase.cuisine_detected != "unspecified":
        cuisine = purchase.cuisine_detected
    changed = False
    if purchase is None:
        purchase = _purchase(tx, stored.id, restaurant_id, cuisine)
        session.add(purchase)
        changed = True

    def assign(obj, field, value):
        nonlocal changed
        if getattr(obj, field) != value:
            setattr(obj, field, value)
            changed = True

    if _known_merchant(merchant):
        if purchase.restaurant_id is None or restaurant_id is not None:
            assign(stored, "merchant_name", merchant)
        if restaurant_id is not None:
            assign(purchase, "restaurant_id", restaurant_id)
    if cuisine != "unspecified":
        assign(purchase, "cuisine_detected", cuisine)
    old_precision = "exact" if purchase.hour_of_day >= 0 else "date" if purchase.day_of_week >= 0 else "unknown"
    rank = {"unknown": 0, "date": 1, "exact": 2}
    if rank[tx.time_precision] > rank[old_precision]:
        replacement = _purchase(tx, stored.id, purchase.restaurant_id, purchase.cuisine_detected)
        for field in ("meal_type", "day_of_week", "hour_of_day", "is_weekend", "purchased_at"):
            assign(purchase, field, getattr(replacement, field))
        assign(stored, "transaction_time", replacement.purchased_at)
    if tx.upi_ref and stored.upi_ref is None:
        assign(stored, "upi_ref", tx.upi_ref.strip().upper())

    incoming_time = transaction_local_time(tx).astimezone(timezone.utc).replace(tzinfo=None) if tx.time_precision != "unknown" else None
    if details is None:
        details = OrderDetails(
            id=order_details_id(tx), user_id=tx.user_id, transaction_id=stored.id,
            platform=tx.order_platform, order_id=tx.order_id, merchant_name=merchant,
            dish_names=list(tx.dish_names), cuisine=cuisine if cuisine != "unspecified" else None,
            order_time=incoming_time, timezone=tx.timezone, time_precision=tx.time_precision,
            order_status=tx.order_status, currency=tx.currency,
        )
        session.add(details)
        return True
    if _known_merchant(merchant):
        assign(details, "merchant_name", merchant)
    dishes = list(dict.fromkeys([*details.dish_names, *tx.dish_names]))
    if len(dishes) > 20:
        raise ImportRejected("too_many_distinct_order_dishes")
    assign(details, "dish_names", dishes)
    if cuisine != "unspecified":
        assign(details, "cuisine", cuisine)
    if rank[tx.time_precision] > rank[details.time_precision]:
        assign(details, "order_time", incoming_time)
        assign(details, "timezone", tx.timezone)
        assign(details, "time_precision", tx.time_precision)
    status_rank = {None: 0, "paid": 1, "completed": 2, "delivered": 3}
    if status_rank[tx.order_status] > status_rank[details.order_status]:
        assign(details, "order_status", tx.order_status)
    return changed


async def conflicting_order(session, tx, transaction_id):
    if not tx.order_id:
        return None
    return await session.scalar(select(OrderDetails).where(
        OrderDetails.user_id == tx.user_id, OrderDetails.transaction_id == transaction_id,
        or_(OrderDetails.platform != tx.order_platform, OrderDetails.order_id != tx.order_id),
    ).limit(1))


def order_conflict_reason(details, tx):
    return "payment_already_has_platform_order" if details.platform == tx.order_platform else "payment_already_has_order"


async def _accept_existing(session, tx, identity_ids, transaction_id):
    stored = await session.scalar(select(UpiTransaction).where(
        UpiTransaction.id == transaction_id, UpiTransaction.user_id == tx.user_id,
    ).with_for_update().execution_options(populate_existing=True))
    if stored is None:
        raise ImportRejected("linked_payment_not_found")
    if not same_amount(stored.amount, tx.amount):
        raise ImportRejected("amount_mismatch")
    if tx.order_id and tx.upi_ref and stored.upi_ref and tx.upi_ref.upper() != stored.upi_ref.upper():
        raise ImportRejected("reference_conflict")
    different_order = await conflicting_order(session, tx, stored.id)
    if different_order is not None:
        raise ImportRejected(order_conflict_reason(different_order, tx))
    await _register_missing_aliases(session, tx.user_id, stored.id, identity_ids)
    changed = await _attach_order_details(session, tx, stored)
    await session.flush()
    return "duplicate", changed, False


async def _ingest_one(session, tx):
    merchant = normalize_merchant_name(tx.merchant_name)
    utc_time = transaction_local_time(tx).astimezone(timezone.utc).replace(tzinfo=None)
    ids = _identity_ids(tx, merchant, utc_time)
    existing_id = await _existing_transaction(session, tx, ids)
    if existing_id is not None:
        return await _accept_existing(session, tx, ids, existing_id)
    restaurant_id, cuisine = await _classification(session, tx, merchant)
    stored = UpiTransaction(
        id=ids[0], user_id=tx.user_id, transaction_time=utc_time, amount=tx.amount,
        merchant_name=merchant, merchant_id=tx.merchant_id, mcc_code=tx.mcc_code,
        upi_ref=tx.upi_ref.strip().upper() if tx.upi_ref else None,
        payment_app=tx.payment_app or tx.order_platform, raw_description=tx.raw_description,
    )
    session.add(stored)
    await session.flush()
    session.add(_purchase(tx, stored.id, restaurant_id, cuisine))
    await _register_missing_aliases(session, tx.user_id, stored.id, ids)
    await _attach_order_details(session, tx, stored)
    await session.flush()
    return "inserted", True, restaurant_id is None


async def ingest_transactions(session: AsyncSession, transactions: list[TransactionIn]) -> IngestResponse:
    ingested = rejected = duplicates = unresolved = 0
    affected_users: set[str] = set()
    outcomes: list[IngestOutcome] = []
    if transactions and session.get_bind().dialect.name == "sqlite":
        # Acquire SQLite's writer reservation before savepoint reads. Otherwise two
        # deferred read snapshots can deadlock while both upgrade to a write lock.
        await session.execute(update(PaymentIdentity).where(false()).values(id=PaymentIdentity.id))
    for tx in transactions:
        is_food = is_food_mcc(tx.mcc_code)
        if not is_food and tx.mcc_code in AGGREGATOR_MCC_CODES | {"0000"}:
            from app.ingestion.sms_parser import is_genuine_food_transaction
            is_food = is_genuine_food_transaction(tx.merchant_name, tx.merchant_name, tx.amount)
        if not is_food:
            rejected += 1
            outcomes.append(IngestOutcome(source_id=tx.source_id, status="rejected", reason="not_food"))
            continue
        try:
            try:
                async with session.begin_nested():
                    status, changed, not_matched = await _ingest_one(session, tx)
            except IntegrityError:
                # Another request may win any shared alias (UPI, source or order) first.
                merchant = normalize_merchant_name(tx.merchant_name)
                utc_time = transaction_local_time(tx).astimezone(timezone.utc).replace(tzinfo=None)
                ids = _identity_ids(tx, merchant, utc_time)
                async with session.begin_nested():
                    existing_id = await _existing_transaction(session, tx, ids)
                    if existing_id is None:
                        raise
                    status, changed, not_matched = await _accept_existing(session, tx, ids, existing_id)
        except ImportRejected as error:
            rejected += 1
            outcomes.append(IngestOutcome(source_id=tx.source_id, status="rejected", reason=str(error)))
            continue
        if status == "inserted":
            ingested += 1
            unresolved += int(not_matched)
        else:
            duplicates += 1
        if changed:
            affected_users.add(tx.user_id)
        outcomes.append(IngestOutcome(
            source_id=tx.source_id, status=status,
            reason="order_details_updated" if status == "duplicate" and changed else "already_imported" if status == "duplicate" else None,
        ))
    await session.commit()
    return IngestResponse(
        ingested_count=ingested, classified_food_count=ingested, skipped_count=rejected,
        affected_users=sorted(affected_users), submitted_count=len(transactions),
        duplicate_count=duplicates, rejected_count=rejected, unresolved_count=unresolved,
        outcomes=outcomes,
    )

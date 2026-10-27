"""Classify food payments with stable aliases in an additive identity table."""

import json
import re
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from zoneinfo import ZoneInfo

from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import UpiTransaction, FoodPurchase, PaymentIdentity
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


async def _existing_transaction(session: AsyncSession, tx: TransactionIn, ids: list[str]) -> str | None:
    alias_rows = (await session.execute(
        select(PaymentIdentity.id, PaymentIdentity.transaction_id).where(
            PaymentIdentity.user_id == tx.user_id, PaymentIdentity.id.in_(ids),
        )
    )).all()
    aliases = {row.id: row.transaction_id for row in alias_rows}
    for identity_id in ids:
        if identity_id in aliases:
            return aliases[identity_id]
    conditions = [UpiTransaction.id.in_(ids)]
    if tx.upi_ref:
        # Covers legacy rows created with random UUIDs before idempotent ingestion.
        conditions.append(func.upper(UpiTransaction.upi_ref) == tx.upi_ref.strip().upper())
    row = await session.execute(
        select(UpiTransaction.id).where(
            UpiTransaction.user_id == tx.user_id, or_(*conditions)
        ).limit(1)
    )
    return row.scalar_one_or_none()


async def _register_missing_aliases(session: AsyncSession, user_id: str, transaction_id: str, ids: list[str]) -> None:
    # Never reassign a legacy alias or delete historic duplicates during an import.
    for identity_id in ids:
        if await session.get(PaymentIdentity, identity_id) is not None:
            continue
        try:
            async with session.begin_nested():
                session.add(PaymentIdentity(id=identity_id, user_id=user_id, transaction_id=transaction_id))
                await session.flush()
        except IntegrityError:
            # Another importer may have registered the same alias while this request waited.
            if await session.get(PaymentIdentity, identity_id) is None:
                raise


async def ingest_transactions(session: AsyncSession, transactions: list[TransactionIn]) -> IngestResponse:
    ingested = rejected = duplicates = unresolved = 0
    affected_users: set[str] = set()
    outcomes: list[IngestOutcome] = []

    for tx in transactions:
        is_food = is_food_mcc(tx.mcc_code)
        if not is_food and tx.mcc_code in AGGREGATOR_MCC_CODES | {"0000"}:
            from app.ingestion.sms_parser import is_genuine_food_transaction
            is_food = is_genuine_food_transaction(tx.merchant_name, tx.merchant_name, tx.amount)
        if not is_food:
            rejected += 1
            outcomes.append(IngestOutcome(source_id=tx.source_id, status="rejected", reason="not_food"))
            continue

        merchant = normalize_merchant_name(tx.merchant_name)
        local_time = transaction_local_time(tx)
        # Existing DateTime columns are timezone-naive: store consistently as UTC.
        utc_time = local_time.astimezone(timezone.utc).replace(tzinfo=None)
        ids = _identity_ids(tx, merchant, utc_time)
        existing_id = await _existing_transaction(session, tx, ids)
        if existing_id is not None:
            await _register_missing_aliases(session, tx.user_id, existing_id, ids)
            duplicates += 1
            outcomes.append(IngestOutcome(source_id=tx.source_id, status="duplicate", reason="already_imported"))
            continue

        restaurant_id = await match_restaurant_by_name(session, merchant)
        meal_type = determine_meal_type(local_time) if tx.time_precision == "exact" else "unknown"
        # Preserve all structured dish evidence for classification, even if the ledger description is short.
        evidence = " ".join([tx.raw_description or "", *tx.dish_names])
        cuisine = tx.cuisine if tx.cuisine and tx.cuisine != "unspecified" else detect_cuisine(merchant, evidence)
        if cuisine == "unspecified" and restaurant_id:
            cuisines = (await session.execute(
                select(Restaurant.cuisines).where(Restaurant.id == restaurant_id)
            )).scalar_one_or_none()
            if cuisines:
                cuisine = cuisines[0]

        known_day = tx.time_precision != "unknown"
        weekday = local_time.weekday() if known_day else -1
        upi_tx = UpiTransaction(
            id=ids[0], user_id=tx.user_id, transaction_time=utc_time,
            amount=tx.amount, merchant_name=merchant, merchant_id=tx.merchant_id,
            mcc_code=tx.mcc_code, upi_ref=tx.upi_ref.strip().upper() if tx.upi_ref else None,
            payment_app=tx.payment_app, raw_description=tx.raw_description,
        )
        purchase = FoodPurchase(
            id=str(uuid.uuid5(uuid.NAMESPACE_URL, f"food-purchase:{ids[0]}")),
            transaction_id=ids[0], user_id=tx.user_id, restaurant_id=restaurant_id,
            cuisine_detected=cuisine, meal_type=meal_type,
            price_band=determine_price_band(tx.amount), day_of_week=weekday,
            hour_of_day=local_time.hour if tx.time_precision == "exact" else -1,
            is_weekend=weekday >= 5, purchased_at=utc_time,
        )
        try:
            # Deterministic PK + savepoint handles concurrent retries without rolling back other rows.
            async with session.begin_nested():
                session.add(upi_tx)
                await session.flush()
                session.add(purchase)
                session.add_all([PaymentIdentity(id=identity_id, user_id=tx.user_id, transaction_id=ids[0]) for identity_id in ids])
                await session.flush()
        except IntegrityError:
            existing_id = await _existing_transaction(session, tx, ids)
            if existing_id is None:
                raise
            await _register_missing_aliases(session, tx.user_id, existing_id, ids)
            duplicates += 1
            outcomes.append(IngestOutcome(source_id=tx.source_id, status="duplicate", reason="already_imported"))
            continue

        ingested += 1
        unresolved += int(restaurant_id is None)
        affected_users.add(tx.user_id)
        outcomes.append(IngestOutcome(source_id=tx.source_id, status="inserted"))

    await session.commit()
    return IngestResponse(
        ingested_count=ingested, classified_food_count=ingested, skipped_count=rejected,
        affected_users=sorted(affected_users), submitted_count=len(transactions),
        duplicate_count=duplicates, rejected_count=rejected, unresolved_count=unresolved,
        outcomes=outcomes,
    )

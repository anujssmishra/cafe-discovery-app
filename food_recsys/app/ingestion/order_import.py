"""Safe order preview and conversion; uncertain payment matches are suggestions only."""

from datetime import datetime, timedelta, timezone

from sqlalchemy import and_, or_, select

from app.ingestion.pipeline import (
    ImportRejected, _existing_transaction, _identity_ids, _name_key,
    _contains_phrase, conflicting_order, order_conflict_reason,
    normalize_merchant_name, same_amount, transaction_local_time,
)
from app.models.transaction import FoodPurchase, UpiTransaction, OrderDetails
from app.schemas.transaction import FoodOrderIn, TransactionIn

ACCEPTED_STATUSES = {"completed", "paid", "delivered"}


def order_rejection(order: FoodOrderIn) -> str | None:
    if order.currency != "INR":
        return "unsupported_currency"
    for status in (order.status, order.order_status):
        if status is not None and status.strip().lower() not in ACCEPTED_STATUSES:
            return "order_not_completed"
    return None


def order_to_transaction(order: FoodOrderIn, user_id: str, now: datetime | None = None) -> TransactionIn:
    reason = order_rejection(order)
    if reason:
        raise ImportRejected(reason)
    platform = order.order_platform or order.platform or "Food App"
    descriptions = f" ({', '.join(order.dish_names or [])})" if order.dish_names else ""
    status = order.order_status or order.status
    return TransactionIn(
        user_id=user_id, transaction_time=order.order_time or now or datetime.now(timezone.utc),
        time_precision=order.time_precision, timezone=order.timezone,
        amount=order.amount, merchant_name=order.restaurant_name, mcc_code="5812",
        payment_app=platform, source_id=order.source_id, upi_ref=order.upi_ref,
        cuisine=order.cuisine, dish_names=order.dish_names or [],
        order_id=order.order_id, order_platform=order.order_platform,
        linked_transaction_id=order.linked_transaction_id,
        order_status=status.strip().lower() if status else None, currency="INR",
        raw_description=f"{platform}: Ordered from {order.restaurant_name}{descriptions}"[:500],
    )


async def order_candidates(session, tx: TransactionIn) -> list[dict]:
    statement = select(UpiTransaction, FoodPurchase).join(
        FoodPurchase, FoodPurchase.transaction_id == UpiTransaction.id,
    ).where(
        UpiTransaction.user_id == tx.user_id,
        UpiTransaction.amount.between(tx.amount - .005, tx.amount + .005),
        ~select(OrderDetails.id).where(
            OrderDetails.transaction_id == UpiTransaction.id, OrderDetails.user_id == tx.user_id,
        ).exists(),
    )
    if tx.time_precision != "unknown":
        local = transaction_local_time(tx)
        day_start = local.replace(hour=0, minute=0, second=0, microsecond=0)
        day_end = day_start + timedelta(days=1)
        utc_day_start = day_start.astimezone(timezone.utc).replace(tzinfo=None)
        utc_day_end = day_end.astimezone(timezone.utc).replace(tzinfo=None)
        same_date = and_(UpiTransaction.transaction_time >= utc_day_start,
                         UpiTransaction.transaction_time < utc_day_end)
        if tx.time_precision == "date":
            timing = same_date
        else:
            timing = or_(
                and_(FoodPurchase.hour_of_day < 0, same_date),
                and_(FoodPurchase.hour_of_day >= 0, UpiTransaction.transaction_time.between(
                    (local - timedelta(hours=2)).astimezone(timezone.utc).replace(tzinfo=None),
                    (local + timedelta(hours=2)).astimezone(timezone.utc).replace(tzinfo=None),
                )),
            )
        statement = statement.where(or_(FoodPurchase.day_of_week < 0, timing))
    rows = (await session.execute(statement.order_by(UpiTransaction.transaction_time.desc()).limit(100))).all()
    platform = (tx.order_platform or tx.payment_app or "").lower()
    merchant = _name_key(tx.merchant_name)
    aliases = {"swiggy": ["swiggy", "bundl technologies"], "zomato": ["zomato", "eternal limited"]}.get(platform, [])
    candidates = []
    for stored, purchase in rows:
        context = _name_key(f"{stored.payment_app or ''} {stored.merchant_name}")
        platform_match = any(_contains_phrase(context, alias) for alias in aliases)
        name_match = len(merchant) > 4 and (
            _contains_phrase(_name_key(stored.merchant_name), merchant)
            or _contains_phrase(merchant, _name_key(stored.merchant_name))
        )
        if not same_amount(stored.amount, tx.amount) or not (platform_match or name_match):
            continue
        precision = "exact" if purchase.hour_of_day >= 0 else "date" if purchase.day_of_week >= 0 else "unknown"
        instant = stored.transaction_time.replace(tzinfo=timezone.utc) if stored.transaction_time.tzinfo is None else stored.transaction_time
        candidates.append({
            "transaction_id": stored.id, "merchant_name": stored.merchant_name,
            "amount": stored.amount, "transaction_time": instant.isoformat() if precision != "unknown" else None,
            "payment_app": stored.payment_app, "time_precision": precision,
        })
        if len(candidates) == 10:
            break
    return candidates


async def preview_food_orders(session, user_id: str, orders: list[FoodOrderIn]) -> dict:
    previews = []
    for order in orders:
        result = {"source_id": order.source_id, "candidates": []}
        reason = order_rejection(order)
        if reason:
            previews.append({**result, "status": "rejected", "reason": reason})
            continue
        if not order.order_id:
            previews.append({**result, "status": "review", "reason": "missing_order_id"})
            continue
        try:
            tx = order_to_transaction(order, user_id)
            utc_time = transaction_local_time(tx).astimezone(timezone.utc).replace(tzinfo=None)
            ids = _identity_ids(tx, normalize_merchant_name(tx.merchant_name), utc_time)
            existing_id = await _existing_transaction(session, tx, ids)
            if existing_id is not None:
                stored = await session.scalar(select(UpiTransaction).where(
                    UpiTransaction.id == existing_id, UpiTransaction.user_id == user_id,
                ))
                if stored is None:
                    raise ImportRejected("linked_payment_not_found")
                if not same_amount(stored.amount, tx.amount):
                    raise ImportRejected("amount_mismatch")
                if tx.upi_ref and stored.upi_ref and tx.upi_ref.upper() != stored.upi_ref.upper():
                    raise ImportRejected("reference_conflict")
                different_order = await conflicting_order(session, tx, existing_id)
                if different_order is not None:
                    raise ImportRejected(order_conflict_reason(different_order, tx))
                previews.append({**result, "status": "duplicate", "existing_transaction_id": existing_id})
                continue
            candidates = await order_candidates(session, tx)
            previews.append({
                **result, "status": "review" if candidates else "new", "candidates": candidates,
                **({"reason": "possible_existing_payment"} if candidates else {}),
            })
        except ImportRejected as error:
            previews.append({**result, "status": "rejected", "reason": str(error)})
    return {"orders": previews}

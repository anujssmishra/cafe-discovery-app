"""Non-destructive reconciliation of legacy repeated UPI references in dining views."""

from sqlalchemy import and_, case, func, select

from app.models.transaction import FoodPurchase, UpiTransaction


def canonical_dining_ids(user_id):
    reference = func.trim(UpiTransaction.upi_ref)
    identity = case(
        (and_(UpiTransaction.upi_ref.is_not(None), reference != ""),
         "reference:" + func.upper(reference)),
        else_="record:" + UpiTransaction.id,
    )
    ranked = (
        select(UpiTransaction.id, func.row_number().over(
            partition_by=identity,
            order_by=(UpiTransaction.created_at, UpiTransaction.id),
        ).label("position"))
        .join(FoodPurchase, FoodPurchase.transaction_id == UpiTransaction.id)
        .where(UpiTransaction.user_id == user_id)
        .subquery()
    )
    return select(ranked.c.id).where(ranked.c.position == 1)

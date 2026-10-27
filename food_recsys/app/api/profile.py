import base64
import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Path, Query
from sqlalchemy import select, delete, func, or_, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.models.restaurant import Restaurant
from app.models.profile import TasteProfile, UserConsent
from app.models.transaction import FoodPurchase, UpiTransaction, PaymentIdentity, OrderDetails
from app.models.recommendation import RecommendationLog
from app.schemas.profile import TasteProfileOut, ConsentUpdateRequest, ConsentResponse
from app.profile.builder import build_taste_profile
from app.profile.records import canonical_dining_ids

router = APIRouter(prefix="/profile", tags=["Taste Profiles"])


@router.get("/{user_id}", response_model=TasteProfileOut)
async def get_profile(
    user_id: str = Path(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$"),
    session: AsyncSession = Depends(get_db),
):
    """Get the current taste intelligence profile for a user."""
    profile = await build_taste_profile(session, user_id)
    return TasteProfileOut.model_validate(profile)


@router.post("/{user_id}/rebuild", response_model=TasteProfileOut)
async def rebuild_profile(
    user_id: str = Path(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$"),
    session: AsyncSession = Depends(get_db),
):
    """Force recomputation of a user's taste profile from their latest transactions."""
    profile = await build_taste_profile(session, user_id)
    return TasteProfileOut.model_validate(profile)


@router.delete("/{user_id}", response_model=TasteProfileOut)
async def clear_profile(
    user_id: str = Path(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$"),
    session: AsyncSession = Depends(get_db),
):
    """Exercise DPDP Act 2023 Section 12 Right to Erasure (Right to be Forgotten).
    Permanently erases all food purchases, raw UPI records, recommendation logs, and resets taste profile.
    """
    # Delete imported order context before the payments it references.
    await session.execute(delete(OrderDetails).where(OrderDetails.user_id == user_id))
    # Delete dependent food purchases
    await session.execute(delete(FoodPurchase).where(FoodPurchase.user_id == user_id))
    # Delete raw upi transactions
    await session.execute(delete(PaymentIdentity).where(PaymentIdentity.user_id == user_id))
    await session.execute(delete(UpiTransaction).where(UpiTransaction.user_id == user_id))
    # Delete recommendation logs
    await session.execute(delete(RecommendationLog).where(RecommendationLog.user_id == user_id))
    # Delete taste profile so rebuild starts completely fresh
    await session.execute(delete(TasteProfile).where(TasteProfile.user_id == user_id))
    # Mark user consent as revoked/erased
    consent_stmt = select(UserConsent).where(UserConsent.user_id == user_id)
    consent_res = await session.execute(consent_stmt)
    consent = consent_res.scalar_one_or_none()
    if consent:
        consent.status = "revoked"
        consent.sms_processing_consent = False
        consent.revoked_at = datetime.now(timezone.utc)
    await session.commit()

    # Create fresh empty profile
    profile = await build_taste_profile(session, user_id)
    return TasteProfileOut.model_validate(profile)


@router.get("/{user_id}/consent", response_model=ConsentResponse)
async def get_user_consent(
    user_id: str = Path(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$"),
    session: AsyncSession = Depends(get_db),
):
    """Retrieve DPDP Act 2023 consent record for the specified user."""
    stmt = select(UserConsent).where(UserConsent.user_id == user_id)
    res = await session.execute(stmt)
    consent = res.scalar_one_or_none()
    if not consent:
        # Default pending consent record
        consent = UserConsent(
            user_id=user_id,
            status="pending",
            sms_processing_consent=False,
            dpdp_version="DPDP_ACT_2023_V1",
        )
        session.add(consent)
        await session.commit()
        await session.refresh(consent)
    return ConsentResponse.model_validate(consent)


@router.post("/{user_id}/consent", response_model=ConsentResponse)
async def update_user_consent(
    payload: ConsentUpdateRequest,
    user_id: str = Path(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$"),
    session: AsyncSession = Depends(get_db),
):
    """Record or update explicit affirmative consent under India DPDP Act 2023 Section 6, or revoke consent under Section 6(4)."""
    stmt = select(UserConsent).where(UserConsent.user_id == user_id)
    res = await session.execute(stmt)
    consent = res.scalar_one_or_none()

    now = datetime.now(timezone.utc)
    if not consent:
        consent = UserConsent(
            user_id=user_id,
            status=payload.status,
            sms_processing_consent=payload.sms_processing_consent,
            dpdp_version=payload.dpdp_version,
            granted_at=now if payload.status == "granted" else None,
            revoked_at=now if payload.status == "revoked" else None,
        )
        session.add(consent)
    else:
        consent.status = payload.status
        consent.sms_processing_consent = payload.sms_processing_consent
        consent.dpdp_version = payload.dpdp_version
        if payload.status == "granted":
            consent.granted_at = now
            consent.revoked_at = None
        elif payload.status == "revoked":
            consent.revoked_at = now

    await session.commit()
    await session.refresh(consent)
    return ConsentResponse.model_validate(consent)


@router.get("/{user_id}/transactions")
async def get_user_transactions(
    user_id: str = Path(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$"),
    limit: int = Query(100, ge=1, le=250),
    cursor: str | None = Query(None, max_length=512),
    session: AsyncSession = Depends(get_db),
):
    """Page classified dining records with independent whole-ledger totals."""
    where_user = and_(UpiTransaction.user_id == user_id,
                      UpiTransaction.id.in_(canonical_dining_ids(user_id)))
    totals = (await session.execute(
        select(func.count(UpiTransaction.id), func.coalesce(func.sum(UpiTransaction.amount), 0))
        .join(FoodPurchase, FoodPurchase.transaction_id == UpiTransaction.id)
        .where(where_user)
    )).one()
    statement = (
        select(UpiTransaction, FoodPurchase, Restaurant.name)
        .join(FoodPurchase, FoodPurchase.transaction_id == UpiTransaction.id)
        .outerjoin(Restaurant, Restaurant.id == FoodPurchase.restaurant_id)
        .where(where_user)
    )
    if cursor:
        try:
            time_text, last_id = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
            if not isinstance(last_id, str) or len(last_id) > 64:
                raise ValueError("Invalid ID")
            last_time = datetime.fromisoformat(time_text)
            if last_time.tzinfo:
                last_time = last_time.astimezone(timezone.utc).replace(tzinfo=None)
        except (ValueError, TypeError, json.JSONDecodeError, UnicodeDecodeError):
            raise HTTPException(status_code=400, detail="Invalid ledger cursor")
        statement = statement.where(or_(
            UpiTransaction.transaction_time < last_time,
            and_(UpiTransaction.transaction_time == last_time, UpiTransaction.id < last_id),
        ))
    records = (await session.execute(statement.order_by(
        UpiTransaction.transaction_time.desc(), UpiTransaction.id.desc()).limit(limit + 1))).all()
    has_more = len(records) > limit
    records = records[:limit]
    orders_by_transaction = {}
    if records:
        order_records = (await session.execute(select(OrderDetails).where(
            OrderDetails.user_id == user_id,
            OrderDetails.transaction_id.in_([row[0].id for row in records]),
        ).order_by(OrderDetails.platform, OrderDetails.order_id))).scalars().all()
        for order in order_records:
            orders_by_transaction.setdefault(order.transaction_id, []).append({
                "platform": order.platform, "order_id": order.order_id,
                "restaurant_name": order.merchant_name, "dish_names": order.dish_names,
                "status": order.order_status, "currency": order.currency,
                "time_precision": order.time_precision, "timezone": order.timezone,
                "order_time": order.order_time.replace(tzinfo=timezone.utc).isoformat()
                    if order.order_time else None,
            })
    transactions = []
    for tx, purchase, name in records:
        instant = tx.transaction_time.replace(tzinfo=timezone.utc) if tx.transaction_time.tzinfo is None else tx.transaction_time
        precision = "exact" if purchase.hour_of_day >= 0 else "date" if purchase.day_of_week >= 0 else "unknown"
        transactions.append({
            "id": tx.id, "transaction_time": instant.isoformat() if precision != "unknown" else None,
            "time_precision": precision, "merchant_name": tx.merchant_name,
            "amount": tx.amount, "payment_app": tx.payment_app,
            "cuisine": purchase.cuisine_detected, "meal_type": purchase.meal_type,
            "price_band": purchase.price_band, "restaurant_id": purchase.restaurant_id,
            "restaurant_name": name,
            "classification_status": "matched" if purchase.restaurant_id else "unresolved",
            "orders": orders_by_transaction.get(tx.id, []),
        })
    next_cursor = None
    if has_more and records:
        last = records[-1][0]
        next_cursor = base64.urlsafe_b64encode(json.dumps(
            [last.transaction_time.isoformat(), last.id]).encode()).decode().rstrip("=")
    return {
        "user_id": user_id, "total_count": totals[0], "total_spent": round(float(totals[1]), 2),
        "transactions": transactions, "has_more": has_more, "next_cursor": next_cursor,
    }

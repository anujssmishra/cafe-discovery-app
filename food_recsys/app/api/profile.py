from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Path
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.models.profile import TasteProfile, UserConsent
from app.models.transaction import FoodPurchase, UpiTransaction
from app.models.recommendation import RecommendationLog
from app.schemas.profile import TasteProfileOut, ConsentUpdateRequest, ConsentResponse
from app.profile.builder import build_taste_profile

router = APIRouter(prefix="/profile", tags=["Taste Profiles"])


@router.get("/{user_id}", response_model=TasteProfileOut)
async def get_profile(
    user_id: str = Path(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$"),
    session: AsyncSession = Depends(get_db),
):
    """Get the current taste intelligence profile for a user."""
    stmt = select(TasteProfile).where(TasteProfile.user_id == user_id)
    res = await session.execute(stmt)
    profile = res.scalar_one_or_none()
    
    if not profile:
        # Build if not already computed
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
    # Delete dependent food purchases
    await session.execute(delete(FoodPurchase).where(FoodPurchase.user_id == user_id))
    # Delete raw upi transactions
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
    limit: int = 250,
    session: AsyncSession = Depends(get_db),
):
    """Retrieve full chronological dining & payment ledger for a user."""
    stmt = (
        select(UpiTransaction, FoodPurchase)
        .outerjoin(FoodPurchase, UpiTransaction.id == FoodPurchase.transaction_id)
        .where(UpiTransaction.user_id == user_id)
        .order_by(UpiTransaction.transaction_time.desc())
        .limit(limit)
    )
    res = await session.execute(stmt)
    records = res.all()

    tx_list = []
    total_spent = 0.0
    for upi_tx, food_p in records:
        total_spent += upi_tx.amount
        tx_list.append({
            "id": upi_tx.id,
            "transaction_time": upi_tx.transaction_time.isoformat(),
            "merchant_name": upi_tx.merchant_name,
            "amount": upi_tx.amount,
            "payment_app": upi_tx.payment_app,
            "cuisine": food_p.cuisine_detected if food_p else "general_food",
            "meal_type": food_p.meal_type if food_p else "snack",
            "price_band": food_p.price_band if food_p else "moderate",
            "description": upi_tx.raw_description,
        })

    return {
        "user_id": user_id,
        "total_count": len(tx_list),
        "total_spent": round(total_spent, 2),
        "transactions": tx_list,
    }



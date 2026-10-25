"""Ingestion Pipeline: processes raw UPI transactions into classified FoodPurchase records."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.transaction import UpiTransaction, FoodPurchase
from app.models.restaurant import Restaurant
from app.schemas.transaction import TransactionIn, IngestResponse
from app.ingestion.mcc_classifier import is_food_mcc
from app.ingestion.merchant_resolver import (
    normalize_merchant_name,
    detect_cuisine,
    determine_meal_type,
    determine_price_band,
)


async def match_restaurant_by_name(session: AsyncSession, normalized_name: str) -> str | None:
    """Attempt exact or fuzzy keyword match to an existing restaurant in the catalogue."""
    # First exact name match (case-insensitive)
    stmt = select(Restaurant.id).where(Restaurant.name.ilike(normalized_name)).limit(1)
    res = await session.execute(stmt)
    matched_id = res.scalar_one_or_none()
    if matched_id:
        return matched_id
        
    # Check if a known restaurant name is contained in the merchant string
    stmt = select(Restaurant.id, Restaurant.name).where(Restaurant.is_active == True)
    res = await session.execute(stmt)
    rows = res.all()
    norm_lower = normalized_name.lower()
    for rest_id, rest_name in rows:
        # Strip branch qualifiers for brand match e.g. "Roastery Coffee House"
        base_name = rest_name.split("(")[0].strip().lower()
        if len(base_name) > 4 and (base_name in norm_lower or norm_lower in base_name):
            return rest_id
            
    return None


async def ingest_transactions(
    session: AsyncSession,
    transactions: list[TransactionIn],
) -> IngestResponse:
    """Ingest a batch of UPI transactions, classifying food purchases and storing them."""
    ingested_count = 0
    classified_food_count = 0
    skipped_count = 0
    affected_users: set[str] = set()

    for tx_in in transactions:
        is_food = is_food_mcc(tx_in.mcc_code)
        
        # Check aggregator / food delivery keywords if MCC is non-food/generic
        merchant_lower = tx_in.merchant_name.lower()
        if not is_food and any(kw in merchant_lower for kw in ["swiggy", "zomato", "eats", "restaurant", "cafe", "coffee", "dhaba", "bhojanalaya", "dosa", "biryani", "bakery"]):
            is_food = True

        if not is_food:
            skipped_count += 1
            continue

        clean_merchant = normalize_merchant_name(tx_in.merchant_name)
        matched_restaurant_id = await match_restaurant_by_name(session, clean_merchant)
        
        meal_type = determine_meal_type(tx_in.transaction_time)
        price_band = determine_price_band(tx_in.amount)
        cuisine = detect_cuisine(
            clean_merchant, 
            tx_in.raw_description, 
            amount=tx_in.amount, 
            meal_type=meal_type
        )
        
        # If cuisine is unspecified from text alone, but merchant matches a known catalogue restaurant,
        # inherit the verified cuisine from the catalogue record
        if cuisine == "unspecified" and matched_restaurant_id:
            rest_stmt = select(Restaurant.cuisines).where(Restaurant.id == matched_restaurant_id)
            rest_res = await session.execute(rest_stmt)
            rest_cuisines = rest_res.scalar_one_or_none()
            if rest_cuisines and len(rest_cuisines) > 0:
                cuisine = rest_cuisines[0]
        
        dt = tx_in.transaction_time
        day_of_week = dt.weekday()  # 0=Monday, 6=Sunday
        is_weekend = day_of_week >= 5

        # Create UpiTransaction
        upi_tx = UpiTransaction(
            user_id=tx_in.user_id,
            transaction_time=dt,
            amount=tx_in.amount,
            merchant_name=clean_merchant,
            merchant_id=tx_in.merchant_id,
            mcc_code=tx_in.mcc_code,
            upi_ref=tx_in.upi_ref,
            payment_app=tx_in.payment_app,
            raw_description=tx_in.raw_description,
        )
        session.add(upi_tx)
        await session.flush()  # populate upi_tx.id

        # Create FoodPurchase
        food_purchase = FoodPurchase(
            transaction_id=upi_tx.id,
            user_id=tx_in.user_id,
            restaurant_id=matched_restaurant_id,
            cuisine_detected=cuisine,
            meal_type=meal_type,
            price_band=price_band,
            day_of_week=day_of_week,
            hour_of_day=dt.hour,
            is_weekend=is_weekend,
            purchased_at=dt,
        )
        session.add(food_purchase)

        ingested_count += 1
        classified_food_count += 1
        affected_users.add(tx_in.user_id)

    await session.commit()

    return IngestResponse(
        ingested_count=ingested_count,
        classified_food_count=classified_food_count,
        skipped_count=skipped_count,
        affected_users=sorted(list(affected_users)),
    )

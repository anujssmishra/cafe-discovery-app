"""Taste Profile Builder: aggregates user food transactions into a structured taste intelligence profile."""

from datetime import datetime, timezone
from collections import defaultdict
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.transaction import FoodPurchase, UpiTransaction
from app.models.restaurant import Restaurant
from app.models.profile import TasteProfile


async def build_taste_profile(session: AsyncSession, user_id: str) -> TasteProfile:
    """Compute and persist the taste profile for a user based on their UPI food history."""
    
    # Query all food purchases with amount from transaction
    stmt = (
        select(
            FoodPurchase,
            UpiTransaction.amount,
            Restaurant.area,
            Restaurant.name.label("restaurant_name"),
        )
        .join(UpiTransaction, FoodPurchase.transaction_id == UpiTransaction.id)
        .outerjoin(Restaurant, FoodPurchase.restaurant_id == Restaurant.id)
        .where(FoodPurchase.user_id == user_id)
        .order_by(FoodPurchase.purchased_at.desc())
    )
    
    res = await session.execute(stmt)
    rows = res.all()
    
    if not rows:
        # Create or return empty profile if user has no transactions
        stmt_existing = select(TasteProfile).where(TasteProfile.user_id == user_id)
        res_existing = await session.execute(stmt_existing)
        existing = res_existing.scalar_one_or_none()
        if existing:
            return existing
            
        profile = TasteProfile(
            user_id=user_id,
            cuisine_affinities={},
            price_distribution={},
            meal_patterns={},
            top_restaurants={},
            frequent_areas={},
            total_food_transactions=0,
            avg_spend=0.0,
            computed_at=datetime.now(timezone.utc),
            version=1,
        )
        session.add(profile)
        await session.commit()
        return profile

    total_count = len(rows)
    total_amount = 0.0

    cuisine_counts: dict[str, int] = defaultdict(int)
    price_band_counts: dict[str, int] = defaultdict(int)
    meal_patterns: dict[str, dict[str, int]] = defaultdict(lambda: {"weekday": 0, "weekend": 0})
    top_restaurants: dict[str, int] = defaultdict(int)
    frequent_areas: dict[str, int] = defaultdict(int)

    for fp, amount, area, r_name in rows:
        total_amount += amount
        cuisine_counts[fp.cuisine_detected] += 1
        price_band_counts[fp.price_band] += 1
        
        day_category = "weekend" if fp.is_weekend else "weekday"
        meal_patterns[fp.meal_type][day_category] += 1
        
        if fp.restaurant_id:
            top_restaurants[fp.restaurant_id] += 1
        if area:
            frequent_areas[area] += 1

    # Normalize cuisine affinities strictly over verified cuisines (excluding 'unspecified' delivery orders)
    # This prevents generic aggregator pings from creating fake cuisine affinities or diluting genuine tastes.
    known_cuisine_counts = {
        cuisine: count 
        for cuisine, count in cuisine_counts.items() 
        if cuisine and cuisine != "unspecified"
    }
    total_known_cuisine = sum(known_cuisine_counts.values())

    if total_known_cuisine > 0:
        cuisine_affinities = {
            cuisine: round(count / total_known_cuisine, 4)
            for cuisine, count in sorted(known_cuisine_counts.items(), key=lambda x: x[1], reverse=True)
        }
    else:
        cuisine_affinities = {}

    # Normalize price distribution (0.0 to 1.0)
    price_distribution = {
        band: round(count / total_count, 4)
        for band, count in price_band_counts.items()
    }

    avg_spend = round(total_amount / total_count, 2) if total_count > 0 else 0.0

    # Fetch existing profile or create new
    stmt_profile = select(TasteProfile).where(TasteProfile.user_id == user_id)
    res_prof = await session.execute(stmt_profile)
    profile = res_prof.scalar_one_or_none()

    if profile:
        profile.cuisine_affinities = cuisine_affinities
        profile.price_distribution = price_distribution
        profile.meal_patterns = dict(meal_patterns)
        profile.top_restaurants = dict(top_restaurants)
        profile.frequent_areas = dict(frequent_areas)
        profile.total_food_transactions = total_count
        profile.avg_spend = avg_spend
        profile.computed_at = datetime.now(timezone.utc)
        profile.version += 1
    else:
        profile = TasteProfile(
            user_id=user_id,
            cuisine_affinities=cuisine_affinities,
            price_distribution=price_distribution,
            meal_patterns=dict(meal_patterns),
            top_restaurants=dict(top_restaurants),
            frequent_areas=dict(frequent_areas),
            total_food_transactions=total_count,
            avg_spend=avg_spend,
            computed_at=datetime.now(timezone.utc),
            version=1,
        )
        session.add(profile)

    await session.commit()
    await session.refresh(profile)
    return profile

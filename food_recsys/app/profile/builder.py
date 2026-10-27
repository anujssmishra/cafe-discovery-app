"""Aggregate classified dining records, retaining unknowns rather than inventing facts."""

from collections import defaultdict
from datetime import datetime, timezone
from types import SimpleNamespace

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from app.models.profile import TasteProfile
from app.models.restaurant import Restaurant
from app.models.transaction import FoodPurchase, UpiTransaction
from app.profile.records import canonical_dining_ids


def summarize(rows):
    counts, prices, areas, restaurants, names, spending = (defaultdict(int) for _ in range(6))
    meals = defaultdict(lambda: {"weekday": 0, "weekend": 0})
    total = 0.0
    unresolved = 0
    for purchase, amount, area, name in rows:
        total += amount
        counts[purchase.cuisine_detected] += 1
        spending[purchase.cuisine_detected] += amount
        prices[purchase.price_band] += 1
        if purchase.meal_type != "unknown":
            meals[purchase.meal_type]["weekend" if purchase.is_weekend else "weekday"] += 1
        if purchase.restaurant_id:
            restaurants[purchase.restaurant_id] += 1
            names[purchase.restaurant_id] = name or "Unknown restaurant"
        else:
            unresolved += 1
        if area:
            areas[area] += 1
    known = {k: v for k, v in counts.items() if k and k not in {"unspecified", "unknown", "general_food"}}
    known_count = sum(known.values())
    ranked = lambda values: dict(sorted(values.items(), key=lambda pair: (-pair[1], pair[0])))
    return dict(
        cuisine_affinities={k: round(v / known_count, 4) for k, v in ranked(known).items()} if known_count else {},
        price_distribution={k: round(v / len(rows), 4) for k, v in prices.items()} if rows else {},
        meal_patterns=dict(meals), top_restaurants=ranked(restaurants), frequent_areas=ranked(areas),
        top_restaurant_names=dict(names), total_food_transactions=len(rows),
        avg_spend=round(total / len(rows), 2) if rows else 0.0,
        known_cuisine_transactions=known_count, unresolved_transactions=unresolved,
        cuisine_spending_share={k: round(spending[k] / total, 4) for k in known} if total else {},
    )


async def purchase_rows(session, user_id, meal=None):
    statement = (
        select(FoodPurchase, UpiTransaction.amount, Restaurant.area, Restaurant.name)
        .join(UpiTransaction, FoodPurchase.transaction_id == UpiTransaction.id)
        .outerjoin(Restaurant, FoodPurchase.restaurant_id == Restaurant.id)
        .where(FoodPurchase.user_id == user_id)
        .where(UpiTransaction.id.in_(canonical_dining_ids(user_id)))
    )
    if meal:
        statement = statement.where(FoodPurchase.meal_type == meal)
    return (await session.execute(statement)).all()


async def build_taste_profile(session, user_id):
    values = summarize(await purchase_rows(session, user_id))
    profile = (await session.execute(select(TasteProfile).where(TasteProfile.user_id == user_id))).scalar_one_or_none()
    persisted = {k: v for k, v in values.items() if k in TasteProfile.__table__.columns}
    if profile is None:
        candidate = TasteProfile(user_id=user_id, **persisted,
                                 computed_at=datetime.now(timezone.utc), version=1)
        try:
            async with session.begin_nested():
                session.add(candidate)
                await session.flush()
            profile = candidate
        except IntegrityError:
            profile = (await session.execute(select(TasteProfile).where(
                TasteProfile.user_id == user_id))).scalar_one_or_none()
            if profile is None:
                raise
            values = summarize(await purchase_rows(session, user_id))
            persisted = {k: v for k, v in values.items() if k in TasteProfile.__table__.columns}
    if any(getattr(profile, key) != value for key, value in persisted.items()):
        for key, value in persisted.items():
            setattr(profile, key, value)
        profile.computed_at = datetime.now(timezone.utc)
        profile.version += 1
    await session.commit()
    # Additional read-model fields are derived without altering existing history schemas.
    for key, value in values.items():
        if key not in persisted:
            setattr(profile, key, value)
    return profile


async def meal_scoring_profile(session, profile, meal):
    """Use observed meal-specific preferences; global visits still determine novelty."""
    rows = await purchase_rows(session, profile.user_id, meal)
    if not rows:
        return profile, False
    specific = summarize(rows)
    return SimpleNamespace(
        cuisine_affinities=specific["cuisine_affinities"],
        price_distribution=specific["price_distribution"],
        top_restaurants=profile.top_restaurants, frequent_areas=profile.frequent_areas,
        avg_spend=specific["avg_spend"], meal_patterns=profile.meal_patterns,
    ), True

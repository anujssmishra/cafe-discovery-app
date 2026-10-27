"""Explainer: generates factual, human-readable recommendation reasons grounded in UPI transactions."""

from app.models.profile import TasteProfile
from app.models.restaurant import Restaurant
from app.schemas.recommendation import ScoreBreakdown

CUISINE_DISPLAY_NAMES = {
    "south_indian": "South Indian",
    "biryani": "Biryani",
    "mughlai": "Mughlai & Awadhi",
    "cafe_western": "Café & Coffee",
    "bakery": "Bakery & Bakes",
    "street_food": "Street Food & Chaat",
    "pizza": "Pizza",
    "burger": "Burgers & Quick Bites",
    "chinese_indo": "Indo-Chinese",
    "north_indian_curry": "North Indian",
    "tea_coffee": "Chai & Beverages",
    "dessert": "Desserts & Sweets",
    "healthy": "Healthy Bowls & Salads",
    "italian": "Italian Pastas",
}


def explain_recommendation(
    profile: TasteProfile,
    restaurant: Restaurant,
    scores: ScoreBreakdown,
    meal_context: str | None = None,
) -> list[str]:
    """Produce 2 to 4 transparent, data-driven reasons why this restaurant fits the user."""
    reasons: list[str] = []

    # 1. Cuisine reason
    best_cuisine = None
    best_affinity = 0.0
    for c in restaurant.cuisines:
        aff = profile.cuisine_affinities.get(c, 0.0)
        if aff > best_affinity:
            best_affinity = aff
            best_cuisine = c

    if best_cuisine and best_affinity > 0.05:
        pct = int(round(best_affinity * 100))
        disp = CUISINE_DISPLAY_NAMES.get(best_cuisine, best_cuisine.replace('_', ' ').title())
        highest_affinity = max(profile.cuisine_affinities.values(), default=0)
        unique_top = list(profile.cuisine_affinities.values()).count(highest_affinity) == 1
        if best_affinity == highest_affinity and unique_top:
            reasons.append(f"{disp} is your most frequent identified cuisine ({pct}% of orders with identified cuisine)")
        else:
            reasons.append(f"Matches your {disp} history ({pct}% of orders with identified cuisine)")
    elif restaurant.cuisines:
        disp = CUISINE_DISPLAY_NAMES.get(restaurant.cuisines[0], restaurant.cuisines[0].title())
        reasons.append(f"Features popular {disp} offerings")

    # 2. Price/Budget reason
    direct_price_pct = int(round(profile.price_distribution.get(restaurant.price_band, 0.0) * 100))
    if direct_price_pct >= 20:
        reasons.append(
            f"Fits your typical {restaurant.price_band} spending band "
            f"({direct_price_pct}% of your meals, avg ₹{profile.avg_spend:.0f}/order)"
        )

    # 3. Novelty / Familiarity reason
    past_visits = profile.top_restaurants.get(restaurant.id, 0)
    if past_visits == 0:
        reasons.append("No payments matched to this branch in your imported history")
    elif past_visits == 1:
        reasons.append("One imported payment matched to this branch")
    else:
        reasons.append(f"{past_visits} imported payments matched to this branch")

    # 4. Meal context / Time pattern reason
    if meal_context and meal_context in profile.meal_patterns:
        pattern = profile.meal_patterns[meal_context]
        total_meal_orders = pattern.get("weekday", 0) + pattern.get("weekend", 0)
        if total_meal_orders >= 3:
            reasons.append(f"You frequently order {meal_context} ({total_meal_orders} times in your history)")

    # 5. Geographic familiarity reason
    area_visits = profile.frequent_areas.get(restaurant.area, 0)
    if area_visits >= 3:
        reasons.append(f"Located in your familiar dining hub of {restaurant.area} ({area_visits} past visits)")

    # Return top 3 distinct reasons
    return reasons[:3] if len(reasons) >= 3 else reasons

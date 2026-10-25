"""Affinity Scoring: C (Cuisine), P (Price), N (Novelty), G (Geo) scoring functions."""

from app.models.profile import TasteProfile
from app.models.restaurant import Restaurant
from app.schemas.recommendation import ScoreBreakdown
from app.config import settings

# Adjacent price bands for soft tolerance
ADJACENT_PRICE_BANDS = {
    "budget": ["moderate"],
    "moderate": ["budget", "premium"],
    "premium": ["moderate", "luxury"],
    "luxury": ["premium"],
}


def compute_cuisine_score(profile: TasteProfile, restaurant: Restaurant) -> float:
    """Calculate cuisine match score between user affinities and restaurant offerings."""
    if not profile.cuisine_affinities:
        return 0.5  # Cold start neutral baseline
        
    if not restaurant.cuisines:
        return 0.2
        
    scores = [profile.cuisine_affinities.get(c, 0.0) for c in restaurant.cuisines]
    max_score = max(scores) if scores else 0.0
    
    # Slight boost if restaurant serves multiple cuisines the user loves
    loved_cuisines = [s for s in scores if s > 0.15]
    if len(loved_cuisines) > 1:
        return min(1.0, max_score * 1.15)
        
    return min(1.0, max_score)


def compute_price_score(profile: TasteProfile, restaurant: Restaurant) -> float:
    """Calculate price band fit with user spending habits."""
    if not profile.price_distribution:
        return 0.5  # Cold start neutral baseline
        
    target_band = restaurant.price_band
    direct_fit = profile.price_distribution.get(target_band, 0.0)
    
    # Add soft tolerance for adjacent price bands
    adjacent_fit = 0.0
    for adj in ADJACENT_PRICE_BANDS.get(target_band, []):
        adjacent_fit += profile.price_distribution.get(adj, 0.0) * 0.4
        
    return min(1.0, round(direct_fit + adjacent_fit, 4))


def compute_novelty_score(profile: TasteProfile, restaurant: Restaurant) -> float:
    """Reward discovery of unvisited spots, while still recognizing known favorites."""
    visit_count = profile.top_restaurants.get(restaurant.id, 0)
    
    if visit_count == 0:
        return 1.0  # Fresh discovery
    elif visit_count <= 2:
        return 0.75  # Tried before and liked
    elif visit_count <= 5:
        return 0.50  # Semi-regular
    else:
        return 0.25  # Frequent regular — down-weighted for discovery


def compute_geo_score(profile: TasteProfile, restaurant: Restaurant, requested_area: str | None = None) -> float:
    """Calculate geographic familiarity based on user's past dining areas."""
    if requested_area:
        # If user explicitly filtered for an area
        return 1.0 if restaurant.area.lower() == requested_area.lower() else 0.0

    if not profile.frequent_areas:
        return 0.5  # Neutral baseline
        
    total_area_visits = sum(profile.frequent_areas.values())
    if total_area_visits == 0:
        return 0.5
        
    area_visits = profile.frequent_areas.get(restaurant.area, 0)
    return min(1.0, round(area_visits / total_area_visits, 4))


def score_restaurant(
    profile: TasteProfile,
    restaurant: Restaurant,
    requested_area: str | None = None,
) -> ScoreBreakdown:
    """Calculate total composite score and breakdown for a restaurant."""
    c_score = compute_cuisine_score(profile, restaurant)
    p_score = compute_price_score(profile, restaurant)
    n_score = compute_novelty_score(profile, restaurant)
    g_score = compute_geo_score(profile, restaurant, requested_area)
    
    total = (
        settings.WEIGHT_CUISINE * c_score +
        settings.WEIGHT_PRICE * p_score +
        settings.WEIGHT_NOVELTY * n_score +
        settings.WEIGHT_GEO * g_score
    )
    
    return ScoreBreakdown(
        cuisine_score=round(c_score, 4),
        price_score=round(p_score, 4),
        novelty_score=round(n_score, 4),
        geo_score=round(g_score, 4),
        total_score=round(total, 4),
    )

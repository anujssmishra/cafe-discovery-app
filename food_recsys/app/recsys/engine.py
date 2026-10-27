"""Recommendation Engine: retrieves candidates, computes personalized scores, logs recs & returns ranked results."""

from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.restaurant import Restaurant
from app.models.recommendation import RecommendationLog
from app.schemas.restaurant import RestaurantOut
from app.schemas.recommendation import RecommendationItem, RecommendationResponse
from app.profile.builder import build_taste_profile, meal_scoring_profile
from app.recsys.scoring import score_restaurant
from app.recsys.explainer import explain_recommendation


async def get_recommendations(
    session: AsyncSession,
    user_id: str,
    n: int = 10,
    meal_context: str | None = None,
    area: str | None = None,
    city: str | None = None,
    cuisine: str | None = None,
) -> RecommendationResponse:
    """Generate top-N personalized restaurant recommendations for a user based on their UPI history."""
    
    # 1. Fetch or build taste profile
    profile = await build_taste_profile(session, user_id)
    scoring_profile = profile
    context_message = None
    if meal_context and meal_context != "any":
        scoring_profile, applied = await meal_scoring_profile(session, profile, meal_context)
        context_message = (
            f"Ranked using your recorded {meal_context.replace('_', ' ')} preferences."
            if applied else
            f"No recorded {meal_context.replace('_', ' ')} history yet; showing your overall matches."
        )

    # 2. Candidate retrieval from active restaurants
    stmt = select(Restaurant).where(Restaurant.is_active == True)
    if city:
        stmt = stmt.where(Restaurant.city.ilike(city))
    if area:
        stmt = stmt.where(Restaurant.area.ilike(area))
        
    res = await session.execute(stmt)
    restaurants = res.scalars().all()

    # 3. Score all candidates
    scored_candidates = []
    for r in restaurants:
        if cuisine and cuisine not in r.cuisines:
            continue
            
        breakdown = score_restaurant(scoring_profile, r, requested_area=area)
        reasons = explain_recommendation(scoring_profile, r, breakdown, meal_context=meal_context)
        scored_candidates.append((r, breakdown, reasons))

    # 4. Rank candidates: primary key = total_score desc, secondary key = avg_rating desc
    scored_candidates.sort(
        key=lambda item: (item[1].total_score, item[0].avg_rating or 0.0),
        reverse=True,
    )

    # 5. Take top N
    top_n = scored_candidates[:n]

    # 6. Build response items & log to DB
    recommendation_items: list[RecommendationItem] = []
    now = datetime.now(timezone.utc)

    for rank, (r, breakdown, reasons) in enumerate(top_n, start=1):
        rec_item = RecommendationItem(
            rank=rank,
            restaurant=RestaurantOut.model_validate(r),
            score=breakdown.total_score,
            reasons=reasons,
            score_breakdown=breakdown,
        )
        recommendation_items.append(rec_item)

        # Log recommendation to audit/analytics table
        log_entry = RecommendationLog(
            user_id=user_id,
            restaurant_id=r.id,
            score=breakdown.total_score,
            reasons=reasons,
            algorithm_version="cpng_v1",
            created_at=now,
        )
        session.add(log_entry)

    await session.commit()

    return RecommendationResponse(
        user_id=user_id,
        meal_context=meal_context or "any",
        generated_at=now,
        algorithm="cpng_v1_content_affinity",
        count=len(recommendation_items),
        recommendations=recommendation_items,
        context_message=context_message,
    )

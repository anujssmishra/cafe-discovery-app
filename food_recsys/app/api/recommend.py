from fastapi import APIRouter, Depends, Query, Path
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.recommendation import RecommendationResponse
from app.recsys.engine import get_recommendations

router = APIRouter(prefix="/recommend", tags=["Recommendations"])


@router.get("/{user_id}", response_model=RecommendationResponse)
async def recommend(
    user_id: str = Path(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$"),
    n: int = Query(10, ge=1, le=50, description="Number of recommendations to return"),
    meal: str | None = Query(None, description="Meal context: breakfast | lunch | snack | dinner | late_night"),
    area: str | None = Query(None, description="Filter by neighbourhood (e.g. Gomti Nagar, Hazratganj)"),
    city: str | None = Query(None, description="Filter by city (e.g. Lucknow)"),
    cuisine: str | None = Query(None, description="Optional specific cuisine filter"),
    session: AsyncSession = Depends(get_db),
):
    """Generate top-N personalized restaurant recommendations based on UPI transaction history."""
    return await get_recommendations(
        session=session,
        user_id=user_id,
        n=n,
        meal_context=meal,
        area=area,
        city=city,
        cuisine=cuisine,
    )

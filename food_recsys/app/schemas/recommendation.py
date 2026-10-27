from datetime import datetime
from pydantic import BaseModel
from app.schemas.restaurant import RestaurantOut


class ScoreBreakdown(BaseModel):
    cuisine_score: float
    price_score: float
    novelty_score: float
    geo_score: float
    total_score: float


class RecommendationItem(BaseModel):
    rank: int
    restaurant: RestaurantOut
    score: float
    reasons: list[str]
    score_breakdown: ScoreBreakdown


class RecommendationResponse(BaseModel):
    user_id: str
    meal_context: str
    generated_at: datetime
    algorithm: str
    count: int
    recommendations: list[RecommendationItem]
    context_message: str | None = None

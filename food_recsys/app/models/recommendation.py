import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base


class RecommendationLog(Base):
    __tablename__ = "recommendation_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    restaurant_id: Mapped[str] = mapped_column(String(36), ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False, index=True)
    score: Mapped[float] = mapped_column(Float, nullable=False)
    
    # List of explanation strings, e.g. ["Biryani makes up 22% of your food orders", "Matches budget tier"]
    reasons: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    
    algorithm_version: Mapped[str] = mapped_column(String(50), default="cpng_v1")
    was_clicked: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)

    restaurant: Mapped["Restaurant"] = relationship("Restaurant")

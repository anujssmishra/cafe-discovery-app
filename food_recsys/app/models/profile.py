import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Float, Integer, DateTime, JSON, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base


class UserConsent(Base):
    __tablename__ = "user_consents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(100), nullable=False, unique=True, index=True)
    dpdp_version: Mapped[str] = mapped_column(String(30), default="DPDP_ACT_2023_V1")
    status: Mapped[str] = mapped_column(String(20), default="granted")  # granted, revoked, pending
    sms_processing_consent: Mapped[bool] = mapped_column(Boolean, default=True)
    purpose: Mapped[str] = mapped_column(
        String(255),
        default="Automated dining preference intelligence and food recommendation generation under DPDP Act 2023",
    )
    granted_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    data_protection_officer: Mapped[str] = mapped_column(String(100), default="grievance@foodrecsys.app")


class TasteProfile(Base):
    __tablename__ = "taste_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(100), nullable=False, unique=True, index=True)
    
    # Dict of cuisine -> affinity score between 0.0 and 1.0
    # e.g. {"south_indian": 0.45, "biryani": 0.20, "cafe_western": 0.15, ...}
    cuisine_affinities: Mapped[dict[str, float]] = mapped_column(JSON, nullable=False, default=dict)
    
    # Dict of price_band -> proportion of spend
    # e.g. {"budget": 0.60, "moderate": 0.35, "premium": 0.05}
    price_distribution: Mapped[dict[str, float]] = mapped_column(JSON, nullable=False, default=dict)
    
    # Dict of meal_type -> weekday/weekend count
    # e.g. {"breakfast": {"weekday": 14, "weekend": 6}, "dinner": {"weekday": 10, "weekend": 12}}
    meal_patterns: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    
    # Dict of restaurant_id -> count of visits
    top_restaurants: Mapped[dict[str, int]] = mapped_column(JSON, nullable=False, default=dict)
    
    # Preferred/familiar areas: area_name -> count
    frequent_areas: Mapped[dict[str, int]] = mapped_column(JSON, nullable=False, default=dict)
    
    total_food_transactions: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    avg_spend: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    
    computed_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    version: Mapped[int] = mapped_column(Integer, default=1)

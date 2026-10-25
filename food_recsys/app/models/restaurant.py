import uuid
from sqlalchemy import String, Float, Boolean, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base


class Restaurant(Base):
    __tablename__ = "restaurants"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    city: Mapped[str] = mapped_column(String(100), nullable=False, default="Lucknow", index=True)
    area: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    address: Mapped[str | None] = mapped_column(String(500), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    
    # List of cuisine tags, e.g. ["south_indian", "breakfast"] or ["cafe_western", "bakery"]
    cuisines: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    
    # "budget" | "moderate" | "premium" | "luxury"
    price_band: Mapped[str] = mapped_column(String(30), nullable=False, default="moderate", index=True)
    
    # "cafe_app" | "manual" | "mock"
    source: Mapped[str] = mapped_column(String(50), nullable=False, default="manual")
    
    avg_rating: Mapped[float | None] = mapped_column(Float, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)

import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Float, Integer, Boolean, DateTime, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base


class UpiTransaction(Base):
    __tablename__ = "upi_transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    transaction_time: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    merchant_name: Mapped[str] = mapped_column(String(200), nullable=False)
    merchant_id: Mapped[str | None] = mapped_column(String(100), nullable=True)  # UPI VPA e.g. name@icici
    mcc_code: Mapped[str] = mapped_column(String(10), nullable=False, index=True)  # e.g. "5812", "5814"
    upi_ref: Mapped[str | None] = mapped_column(String(100), nullable=True)
    payment_app: Mapped[str | None] = mapped_column(String(50), nullable=True)  # e.g. "Google Pay"
    raw_description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationship to classified food purchase
    food_purchase: Mapped["FoodPurchase | None"] = relationship(
        "FoodPurchase", back_populates="transaction", uselist=False, cascade="all, delete-orphan"
    )


class FoodPurchase(Base):
    __tablename__ = "food_purchases"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    transaction_id: Mapped[str] = mapped_column(String(36), ForeignKey("upi_transactions.id", ondelete="CASCADE"), nullable=False, unique=True)
    user_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    restaurant_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("restaurants.id", ondelete="SET NULL"), nullable=True, index=True)
    
    cuisine_detected: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    meal_type: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # breakfast, lunch, dinner, snack, late_night
    price_band: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # budget, moderate, premium, luxury
    
    day_of_week: Mapped[int] = mapped_column(Integer, nullable=False)  # 0=Mon, 6=Sun
    hour_of_day: Mapped[int] = mapped_column(Integer, nullable=False)  # 0-23
    is_weekend: Mapped[bool] = mapped_column(Boolean, nullable=False)
    purchased_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)

    transaction: Mapped["UpiTransaction"] = relationship("UpiTransaction", back_populates="food_purchase")


class PaymentIdentity(Base):
    """Stable user-scoped import aliases; a new table avoids changing existing payments."""

    __tablename__ = "payment_identities"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    transaction_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("upi_transactions.id", ondelete="CASCADE"), nullable=False, index=True,
    )

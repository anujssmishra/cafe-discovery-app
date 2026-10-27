from datetime import datetime
from typing import Annotated, Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, Field, field_validator


Cuisine = Literal[
    "south_indian", "biryani", "mughlai", "cafe_western", "bakery",
    "street_food", "pizza", "burger", "chinese_indo", "north_indian_curry",
    "tea_coffee", "dessert", "healthy", "italian", "unspecified",
]
DishName = Annotated[str, Field(min_length=1, max_length=120)]
SourceId = Annotated[str, Field(min_length=1, max_length=200, pattern=r"^[A-Za-z0-9_.:@/-]+$")]


class PaymentIn(BaseModel):
    """Safe structured payment extracted on-device; never accepts a raw SMS body."""

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    source_id: SourceId | None = None
    merchant_name: str = Field(..., min_length=1, max_length=200)
    amount: float = Field(..., gt=0, le=500000, allow_inf_nan=False)
    transaction_time: datetime | None = None
    timezone: str = Field("Asia/Kolkata", max_length=64)
    upi_ref: str | None = Field(None, min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")
    payment_app: str | None = Field(None, max_length=64)
    cuisine: Cuisine | None = None
    dish_names: list[DishName] = Field(default_factory=list, max_length=20)

    @field_validator("timezone")
    @classmethod
    def validate_timezone(cls, value: str) -> str:
        try:
            ZoneInfo(value)
        except (ZoneInfoNotFoundError, ValueError):
            raise ValueError("timezone must be a valid IANA timezone")
        return value


class PaymentsBatchIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    user_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$")
    schema_version: Literal[1]
    payments: list[PaymentIn] = Field(..., min_length=1, max_length=1000)


class TransactionIn(BaseModel):
    user_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$", description="Alphanumeric user ID")
    transaction_time: datetime = Field(..., description="Timestamp of transaction")
    amount: float = Field(..., gt=0, le=500000, allow_inf_nan=False, description="Amount in INR")
    merchant_name: str = Field(..., min_length=1, max_length=200, description="Merchant name on UPI")
    merchant_id: str | None = Field(None, max_length=120, description="Merchant UPI VPA or ID")
    mcc_code: str = Field("5812", pattern=r"^\d{4}$", description="Merchant Category Code")
    upi_ref: str | None = Field(None, max_length=64, pattern=r"^[A-Za-z0-9_-]*$")
    payment_app: str | None = Field("Google Pay", max_length=64)
    raw_description: str | None = Field(None, max_length=500)
    source_id: SourceId | None = None
    timezone: str = Field("Asia/Kolkata", max_length=64)
    time_precision: Literal["exact", "date", "unknown"] = "exact"
    cuisine: Cuisine | None = None
    dish_names: list[DishName] = Field(default_factory=list, max_length=20)

    _validate_timezone = field_validator("timezone")(PaymentIn.validate_timezone.__func__)


class TransactionBatchIn(BaseModel):
    transactions: list[TransactionIn] = Field(..., min_length=1, max_length=1000)


class FoodPurchaseOut(BaseModel):
    id: str
    cuisine_detected: str
    meal_type: str
    price_band: str
    day_of_week: int
    hour_of_day: int
    is_weekend: bool
    purchased_at: datetime
    restaurant_id: str | None = None

    model_config = {"from_attributes": True}


class TransactionOut(BaseModel):
    id: str
    user_id: str
    transaction_time: datetime
    amount: float
    merchant_name: str
    merchant_id: str | None
    mcc_code: str
    food_purchase: FoodPurchaseOut | None = None

    model_config = {"from_attributes": True}


class IngestOutcome(BaseModel):
    source_id: str | None = None
    status: Literal["inserted", "duplicate", "rejected"]
    reason: str | None = None


class IngestResponse(BaseModel):
    ingested_count: int
    classified_food_count: int
    skipped_count: int
    affected_users: list[str]
    submitted_count: int = 0
    duplicate_count: int = 0
    rejected_count: int = 0
    unresolved_count: int = 0
    outcomes: list[IngestOutcome] = Field(default_factory=list)


class TimestampedSms(BaseModel):
    text: str = Field(..., max_length=2000, description="SMS text")
    received_at: datetime | None = Field(None, description="Timestamp when SMS was received on device")


class SmsIngestRequest(BaseModel):
    user_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$")
    sms_text: str | None = Field(None, max_length=2000)
    messages: list[Annotated[str, Field(max_length=2000)]] | None = Field(None, max_length=500)
    timestamped_messages: list[TimestampedSms] | None = Field(None, max_length=1000)


class FoodOrderIn(BaseModel):
    restaurant_name: str = Field(..., min_length=1, max_length=200)
    amount: float = Field(..., gt=0, le=100000, allow_inf_nan=False)
    order_time: datetime | None = None
    cuisine: Cuisine | None = None
    dish_names: list[DishName] | None = Field(None, max_length=20)
    platform: str | None = Field("Swiggy", max_length=64)
    source_id: SourceId | None = None
    timezone: str = Field("Asia/Kolkata", max_length=64)
    upi_ref: str | None = Field(None, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")

    _validate_timezone = field_validator("timezone")(PaymentIn.validate_timezone.__func__)


class FoodOrdersBatchIn(BaseModel):
    user_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$")
    orders: list[FoodOrderIn] = Field(..., min_length=1, max_length=1000)

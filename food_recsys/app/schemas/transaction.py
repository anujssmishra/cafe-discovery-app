import re
from datetime import datetime
from typing import Annotated, Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


Cuisine = Literal[
    "south_indian", "biryani", "mughlai", "cafe_western", "bakery",
    "street_food", "pizza", "burger", "chinese_indo", "north_indian_curry",
    "tea_coffee", "dessert", "healthy", "italian", "unspecified",
]
DishName = Annotated[str, Field(min_length=1, max_length=120)]
SourceId = Annotated[str, Field(min_length=1, max_length=200, pattern=r"^[A-Za-z0-9_.:@/-]+$")]

OrderId = Annotated[str, Field(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")]
LinkedTransactionId = Annotated[str, Field(pattern=r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")]
OrderPlatform = Literal["Swiggy", "Zomato"]
TimePrecision = Literal["exact", "date", "unknown"]


def normalize_platform(value):
    return {"swiggy": "Swiggy", "zomato": "Zomato"}.get(value.strip().lower(), value) if isinstance(value, str) else value


def canonical_order_source(model):
    source = model.source_id or ""
    if source.lower().startswith("order:") and (model.order_id or model.order_platform or source.lower().startswith(("order:swiggy:", "order:zomato:"))):
        match = re.fullmatch(r"order:(swiggy|zomato):([A-Za-z0-9_-]{1,64})", source, re.IGNORECASE)
        if not match:
            raise ValueError("Invalid order source_id")
        platform, order_id = normalize_platform(match.group(1)), match.group(2)
        if (model.order_id and model.order_id != order_id) or (model.order_platform and model.order_platform != platform):
            raise ValueError("Order source_id conflicts with order identity")
        model.order_platform, model.order_id = platform, order_id
    if model.order_id or model.order_platform:
        if not model.order_id or not model.order_platform:
            raise ValueError("order_id and order_platform must be supplied together")
        if model.amount > 100000:
            raise ValueError("Order amount exceeds the supported INR 100000 limit")
        model.source_id = f"order:{model.order_platform.lower()}:{model.order_id}"
    if model.linked_transaction_id and not model.order_id:
        raise ValueError("A linked transaction requires an order identity")
    return model


def mark_date_precision(value):
    if isinstance(value, dict):
        value = dict(value)
        timestamp = value.get("transaction_time")
        if isinstance(timestamp, str) and re.fullmatch(r"\d{4}-\d{2}-\d{2}", timestamp):
            value["time_precision"] = "date"
    return value


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
    time_precision: TimePrecision | None = None
    order_id: OrderId | None = None
    order_platform: OrderPlatform | None = None
    linked_transaction_id: LinkedTransactionId | None = None
    order_status: Literal["completed", "paid", "delivered"] | None = None
    currency: Literal["INR"] = "INR"

    @field_validator("timezone")
    @classmethod
    def validate_timezone(cls, value: str) -> str:
        try:
            ZoneInfo(value)
        except (ZoneInfoNotFoundError, ValueError):
            raise ValueError("timezone must be a valid IANA timezone")
        return value

    _normalize_platform = field_validator("order_platform", mode="before")(normalize_platform)
    _mark_date_precision = model_validator(mode="before")(mark_date_precision)

    @model_validator(mode="after")
    def validate_order(self):
        canonical_order_source(self)
        if self.transaction_time is None:
            self.time_precision = "unknown"
        elif self.time_precision is None:
            self.time_precision = "exact"
        return self


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
    order_id: OrderId | None = None
    order_platform: OrderPlatform | None = None
    linked_transaction_id: LinkedTransactionId | None = None
    order_status: Literal["completed", "paid", "delivered"] | None = None
    currency: Literal["INR"] = "INR"

    _validate_timezone = field_validator("timezone")(PaymentIn.validate_timezone.__func__)

    _normalize_platform = field_validator("order_platform", mode="before")(normalize_platform)
    _validate_order = model_validator(mode="after")(canonical_order_source)


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
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    restaurant_name: str = Field(..., min_length=1, max_length=200)
    amount: float = Field(..., gt=0, le=100000, allow_inf_nan=False)
    order_time: datetime | None = None
    cuisine: Cuisine | None = None
    dish_names: list[DishName] | None = Field(None, max_length=20)
    platform: str | None = Field("Swiggy", max_length=64)
    source_id: SourceId | None = None
    timezone: str = Field("Asia/Kolkata", max_length=64)
    upi_ref: str | None = Field(None, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")
    order_id: OrderId | None = None
    order_platform: OrderPlatform | None = None
    linked_transaction_id: LinkedTransactionId | None = None
    time_precision: TimePrecision | None = None
    status: str | None = Field(None, max_length=32)
    order_status: str | None = Field(None, max_length=32)
    currency: str = Field("INR", min_length=3, max_length=3)

    _validate_timezone = field_validator("timezone")(PaymentIn.validate_timezone.__func__)
    _normalize_platform = field_validator("platform", "order_platform", mode="before")(normalize_platform)

    @model_validator(mode="before")
    @classmethod
    def date_only_orders(cls, value):
        if isinstance(value, dict):
            value = dict(value)
            timestamp = value.get("order_time")
            if isinstance(timestamp, str) and re.fullmatch(r"\d{4}-\d{2}-\d{2}", timestamp):
                value["time_precision"] = "date"
        return value

    @model_validator(mode="after")
    def validate_order_context(self):
        self.currency = self.currency.upper()
        if self.order_id and self.order_platform is None:
            if self.platform in {"Swiggy", "Zomato"}:
                self.order_platform = self.platform
        canonical_order_source(self)
        if self.order_time is None:
            self.time_precision = "unknown"
        elif self.time_precision is None:
            self.time_precision = "exact"
        return self


class FoodOrdersBatchIn(BaseModel):
    user_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$")
    orders: list[FoodOrderIn] = Field(..., min_length=1, max_length=1000)

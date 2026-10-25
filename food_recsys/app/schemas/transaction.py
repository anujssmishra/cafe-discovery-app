from datetime import datetime
from pydantic import BaseModel, Field


class TransactionIn(BaseModel):
    user_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$", description="Alphanumeric user ID")
    transaction_time: datetime = Field(..., description="Timestamp of transaction")
    amount: float = Field(..., gt=0, le=500000, description="Amount in INR (capped at 5 lakhs NPCI limit)")
    merchant_name: str = Field(..., min_length=1, max_length=200, description="Merchant name on UPI")
    merchant_id: str | None = Field(None, max_length=120, description="Merchant UPI VPA or ID")
    mcc_code: str = Field("5812", pattern=r"^\d{4}$", description="Merchant Category Code (4 digits)")
    upi_ref: str | None = Field(None, max_length=64, pattern=r"^[A-Za-z0-9_-]*$")
    payment_app: str | None = Field("Google Pay", max_length=64, description="UPI app used")
    raw_description: str | None = Field(None, max_length=500)


class TransactionBatchIn(BaseModel):
    transactions: list[TransactionIn] = Field(..., min_length=1, max_length=1000, description="Batch of transactions (max 1000 per request)")


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


class IngestResponse(BaseModel):
    ingested_count: int
    classified_food_count: int
    skipped_count: int
    affected_users: list[str]


class TimestampedSms(BaseModel):
    text: str = Field(..., max_length=2000, description="SMS text")
    received_at: datetime | None = Field(None, description="Timestamp when SMS was received on device")


class SmsIngestRequest(BaseModel):
    user_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$", description="Alphanumeric user ID")
    sms_text: str | None = Field(None, max_length=2000, description="Single transactional SMS text to parse")
    messages: list[str] | None = Field(None, max_length=500, description="List of transactional SMS strings to parse")
    timestamped_messages: list[TimestampedSms] | None = Field(None, max_length=1000, description="List of timestamped SMS messages")


class FoodOrderIn(BaseModel):
    restaurant_name: str = Field(..., min_length=1, max_length=200, description="Restaurant name")
    amount: float = Field(..., gt=0, le=100000, description="Total order amount in INR")
    order_time: datetime | None = Field(None, description="Time order was placed")
    cuisine: str | None = Field(None, max_length=64, description="Cuisine if known")
    dish_names: list[str] | None = Field(None, max_length=20, description="List of dishes ordered")
    platform: str | None = Field("Swiggy", max_length=64, description="Swiggy, Zomato, Domino's, etc.")


class FoodOrdersBatchIn(BaseModel):
    user_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$", description="Target user ID")
    orders: list[FoodOrderIn] = Field(..., min_length=1, max_length=1000, description="List of food delivery orders")


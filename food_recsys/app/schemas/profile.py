from datetime import datetime, timezone
from pydantic import BaseModel, Field, field_validator


class TasteProfileOut(BaseModel):
    user_id: str
    cuisine_affinities: dict[str, float]
    price_distribution: dict[str, float]
    meal_patterns: dict
    top_restaurants: dict[str, int]
    top_restaurant_names: dict[str, str] = Field(default_factory=dict)
    frequent_areas: dict[str, int]
    total_food_transactions: int
    avg_spend: float
    computed_at: datetime
    version: int
    known_cuisine_transactions: int = 0
    unresolved_transactions: int = 0
    cuisine_spending_share: dict[str, float] = Field(default_factory=dict)

    @field_validator("computed_at")
    @classmethod
    def utc_computation_time(cls, value):
        return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value

    model_config = {"from_attributes": True}


class ConsentUpdateRequest(BaseModel):
    status: str = "granted"  # "granted" or "revoked"
    sms_processing_consent: bool = True
    dpdp_version: str = "DPDP_ACT_2023_V1"


class ConsentResponse(BaseModel):
    user_id: str
    dpdp_version: str
    status: str
    sms_processing_consent: bool
    purpose: str
    granted_at: datetime | None = None
    revoked_at: datetime | None = None
    data_protection_officer: str

    model_config = {"from_attributes": True}

from pydantic import BaseModel, Field


class RestaurantBase(BaseModel):
    name: str = Field(..., max_length=200)
    city: str = Field("Lucknow", max_length=100)
    area: str = Field(..., max_length=100)
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    cuisines: list[str] = Field(default_factory=list)
    price_band: str = Field("moderate", pattern="^(budget|moderate|premium|luxury)$")
    source: str = "manual"
    avg_rating: float | None = None
    is_active: bool = True


class RestaurantIn(RestaurantBase):
    pass


class RestaurantOut(RestaurantBase):
    id: str

    model_config = {"from_attributes": True}

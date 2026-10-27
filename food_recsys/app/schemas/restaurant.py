from pydantic import BaseModel, Field, model_validator


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


class PublicOffering(BaseModel):
    drink_type: str
    brewing_method: str | None = None
    price: float | None = None
    currency: str = "INR"
    checked_on: str | None = None
    source: str | None = None


class RestaurantOut(RestaurantBase):
    id: str
    photo_url: str | None = None
    hero_image_url: str | None = None
    website: str | None = None
    vibe_tags: list[str] = Field(default_factory=list)
    food_highlights: list[str] = Field(default_factory=list)
    offerings: list[PublicOffering] = Field(default_factory=list)
    checked_on: str | None = None

    @model_validator(mode="before")
    @classmethod
    def include_public_details(cls, value):
        if isinstance(value, dict):
            return value
        fields = {name: getattr(value, name) for name in RestaurantBase.model_fields}
        fields["id"] = value.id
        metadata = getattr(value, "catalogue_metadata", None)
        if metadata:
            # Only these public fields are exposed, even if an export contains extras.
            for key in ("photo_url", "hero_image_url", "website", "vibe_tags",
                        "food_highlights", "offerings", "checked_on"):
                if key in metadata.payload:
                    fields[key] = metadata.payload[key]
        return fields

    model_config = {"from_attributes": True}

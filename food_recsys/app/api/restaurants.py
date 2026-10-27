from fastapi import APIRouter, Depends, Query, HTTPException, Path
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.models.restaurant import Restaurant
from app.schemas.restaurant import RestaurantOut

router = APIRouter(prefix="/restaurants", tags=["Restaurants"])


def _escape_like(val: str) -> str:
    """Escape special SQL LIKE characters to prevent wildcard injection."""
    return val.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


@router.get("/metadata")
async def catalogue_metadata(session: AsyncSession = Depends(get_db)):
    restaurants = (await session.execute(select(Restaurant).where(Restaurant.is_active == True))).scalars().all()
    return {
        "areas": sorted({r.area for r in restaurants}),
        "cuisines": sorted({c for r in restaurants for c in r.cuisines}),
        "meal_options": ["any", "breakfast", "lunch", "snack", "dinner", "late_night"],
    }


@router.get("", response_model=list[RestaurantOut])
async def list_restaurants(
    city: str | None = Query(None, max_length=100),
    area: str | None = Query(None, max_length=100),
    cuisine: str | None = Query(None, max_length=50),
    price_band: str | None = Query(None, pattern="^(budget|moderate|premium|luxury)$"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    session: AsyncSession = Depends(get_db),
):
    """Filter active catalogue entries before applying the requested page size."""
    statement = select(Restaurant).where(Restaurant.is_active == True)
    if city:
        statement = statement.where(Restaurant.city.ilike(f"%{_escape_like(city.strip())}%", escape="\\"))
    if area:
        statement = statement.where(Restaurant.area.ilike(f"%{_escape_like(area.strip())}%", escape="\\"))
    if price_band:
        statement = statement.where(Restaurant.price_band == price_band)
    restaurants = (await session.execute(statement.order_by(Restaurant.name, Restaurant.id))).scalars().all()
    if cuisine:
        restaurants = [r for r in restaurants if cuisine in r.cuisines]
    return [RestaurantOut.model_validate(r) for r in restaurants[offset:offset + limit]]


@router.get("/{restaurant_id}", response_model=RestaurantOut)
async def get_restaurant(
    restaurant_id: str = Path(..., min_length=1, max_length=36, pattern=r"^[A-Za-z0-9_-]+$"),
    session: AsyncSession = Depends(get_db),
):
    """Retrieve details for a specific restaurant by UUID."""
    stmt = select(Restaurant).where(Restaurant.id == restaurant_id, Restaurant.is_active == True)
    res = await session.execute(stmt)
    restaurant = res.scalar_one_or_none()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    return RestaurantOut.model_validate(restaurant)

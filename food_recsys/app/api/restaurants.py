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


@router.get("", response_model=list[RestaurantOut])
async def list_restaurants(
    city: str | None = Query(None, max_length=100, description="Filter by city (e.g. Lucknow)"),
    area: str | None = Query(None, max_length=100, description="Filter by neighbourhood (e.g. Gomti Nagar)"),
    cuisine: str | None = Query(None, max_length=50, description="Filter by cuisine tag"),
    price_band: str | None = Query(None, pattern="^(budget|moderate|premium|luxury)$", description="budget | moderate | premium | luxury"),
    limit: int = Query(50, ge=1, le=200),
    session: AsyncSession = Depends(get_db),
):
    """Browse and filter active restaurants in the catalogue."""
    stmt = select(Restaurant).where(Restaurant.is_active == True)
    
    if city:
        clean_city = _escape_like(city.strip())
        stmt = stmt.where(Restaurant.city.ilike(f"%{clean_city}%"))
    if area:
        clean_area = _escape_like(area.strip())
        stmt = stmt.where(Restaurant.area.ilike(f"%{clean_area}%"))
    if price_band:
        stmt = stmt.where(Restaurant.price_band == price_band)
        
    stmt = stmt.order_by(Restaurant.name.asc()).limit(limit)
    res = await session.execute(stmt)
    restaurants = res.scalars().all()
    
    if cuisine:
        restaurants = [r for r in restaurants if cuisine in r.cuisines]
        
    return [RestaurantOut.model_validate(r) for r in restaurants]


@router.get("/{restaurant_id}", response_model=RestaurantOut)
async def get_restaurant(
    restaurant_id: str = Path(..., min_length=1, max_length=36, pattern=r"^[A-Za-z0-9_-]+$"),
    session: AsyncSession = Depends(get_db),
):
    """Retrieve details for a specific restaurant by UUID."""
    stmt = select(Restaurant).where(Restaurant.id == restaurant_id)
    res = await session.execute(stmt)
    restaurant = res.scalar_one_or_none()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    return RestaurantOut.model_validate(restaurant)

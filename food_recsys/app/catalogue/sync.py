"""Import explicit public catalogue exports without touching user histories.

Usage: python -m app.catalogue.sync path/to/public-catalogue.json
"""

import asyncio
import json
import sys
from pathlib import Path

from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.models.restaurant import Restaurant, RestaurantMetadata
from app.schemas.restaurant import RestaurantOut

SNAPSHOT = Path(__file__).with_name("cafes.json")
PUBLIC_DETAILS = ("photo_url", "hero_image_url", "website", "vibe_tags",
                  "food_highlights", "offerings", "checked_on")


class CatalogueExport(BaseModel):
    schema_version: int = Field(1, ge=1, le=1)
    restaurants: list[RestaurantOut]


async def insert_restaurant_if_absent(session, values: dict) -> bool:
    """Atomically reserve a restaurant UUID without changing an existing owner's row."""
    dialect = session.get_bind().dialect.name
    if dialect == "sqlite":
        from sqlalchemy.dialects.sqlite import insert
    elif dialect == "postgresql":
        from sqlalchemy.dialects.postgresql import insert
    else:
        # The supported runtimes are SQLite/Postgres; keep a safe fallback for other engines.
        try:
            async with session.begin_nested():
                session.add(Restaurant(**values))
                await session.flush()
            return True
        except IntegrityError:
            if await session.get(Restaurant, values["id"]) is None:
                raise
            return False
    result = await session.execute(
        insert(Restaurant).values(**values).on_conflict_do_nothing(index_elements=[Restaurant.id])
    )
    return result.rowcount == 1


async def sync_public_catalogue(session, data: dict, *, origin: str = "export") -> int:
    """Upsert public records; return newly inserted rows, leaving unrelated records intact.

    The insert coordinates concurrent SQLite writers; the following row lock coordinates
    Postgres updates. Source/origin checks use a fresh read after that coordination.
    """
    catalogue = CatalogueExport.model_validate(data)
    identifiers = [r.id for r in catalogue.restaurants]
    if len(identifiers) != len(set(identifiers)):
        raise ValueError("Catalogue export contains duplicate restaurant IDs")
    count = 0
    try:
        # All importers lock shared IDs in the same order to avoid Postgres deadlocks.
        for incoming in sorted(catalogue.restaurants, key=lambda row: row.id):
            values = incoming.model_dump(include={
                "id", "name", "city", "area", "address", "latitude", "longitude",
                "price_band", "is_active", "avg_rating", "cuisines",
            })
            values["source"] = "cafe_app"
            inserted = await insert_restaurant_if_absent(session, values)
            restaurant = (await session.execute(
                select(Restaurant).where(Restaurant.id == incoming.id)
                .with_for_update().execution_options(populate_existing=True)
            )).scalar_one()
            if restaurant.source != "cafe_app":
                raise ValueError(f"Catalogue ID belongs to another source: {incoming.id}")
            if (origin == "bundle" and restaurant.catalogue_metadata is not None
                    and restaurant.catalogue_metadata.payload.get("_sync_origin") == "export"):
                # Restarting must not replace a newer live export with the bundled snapshot.
                continue
            for key in ("name", "city", "area", "address", "latitude", "longitude",
                        "price_band", "is_active", "avg_rating"):
                setattr(restaurant, key, getattr(incoming, key))
            # PHP has no cuisine taxonomy; omitted cuisine evidence must not erase enrichment.
            if inserted or "cuisines" in incoming.model_fields_set or restaurant.cuisines is None:
                restaurant.cuisines = incoming.cuisines
            restaurant.source = "cafe_app"
            details = incoming.model_dump(include=set(PUBLIC_DETAILS), mode="json")
            details["_sync_origin"] = origin
            if restaurant.catalogue_metadata is None:
                restaurant.catalogue_metadata = RestaurantMetadata(payload=details)
            else:
                restaurant.catalogue_metadata.payload = details
            count += int(inserted)
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    return count


async def main(path: str):
    from app.db.session import engine, AsyncSessionLocal
    from app.models.base import Base
    data = json.loads(Path(path).read_text())
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        count = await sync_public_catalogue(session, data)
    await engine.dispose()
    print(f"Synchronized public catalogue; added {count} new records")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python -m app.catalogue.sync public-catalogue.json")
    asyncio.run(main(sys.argv[1]))

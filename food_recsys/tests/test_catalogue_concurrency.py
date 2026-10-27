"""Concurrent catalogue startup and persistent upgrade checks with synthetic data."""

import asyncio
import uuid

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

import app.mock.restaurants as seeds
from app.catalogue.sync import sync_public_catalogue
from app.models.base import Base
from app.models.restaurant import Restaurant
from app.schemas.restaurant import RestaurantOut


def public_cafe(**changes):
    return {
        "id": "f1000000-0000-0000-0000-000000000001", "name": "Synthetic seeded cafe",
        "city": "Synthetic City", "area": "Synthetic Area", "source": "cafe_app",
        "cuisines": ["bakery"], "price_band": "moderate", "is_active": True,
        "photo_url": "https://example.test/old-photo.jpg", "vibe_tags": ["Synthetic quiet"],
        "offerings": [{"drink_type": "Coffee", "price": 120, "currency": "INR"}],
        **changes,
    }


async def create_database(path):
    engine = create_async_engine(f"sqlite+aiosqlite:///{path}")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    return engine, async_sessionmaker(engine, expire_on_commit=False)


@pytest.mark.asyncio
async def test_two_catalogue_importers_insert_each_uuid_once(tmp_path):
    engine, sessions = await create_database(tmp_path / "concurrent-import.db")
    cafes = [public_cafe(), public_cafe(id="f1000000-0000-0000-0000-000000000002", name="Second synthetic cafe")]

    async def worker(rows):
        async with sessions() as session:
            return await sync_public_catalogue(session, {"schema_version": 1, "restaurants": rows})

    try:
        counts = await asyncio.gather(worker(cafes), worker(list(reversed(cafes))))
        assert sum(counts) == 2
        async with sessions() as session:
            assert await session.scalar(select(func.count()).select_from(Restaurant)) == 2
            rows = (await session.execute(select(Restaurant))).scalars().all()
            assert all(row.catalogue_metadata is not None for row in rows)
    finally:
        await engine.dispose()


@pytest.mark.asyncio
async def test_export_wins_over_concurrent_or_later_bundle_and_metadata_is_public(tmp_path):
    engine, sessions = await create_database(tmp_path / "concurrent-origin.db")
    bundle = public_cafe()
    live = public_cafe(
        name="Synthetic live export", area="Synthetic new area", is_active=False,
        photo_url="https://example.test/live-photo.jpg", cuisines=["healthy"],
        private_notes="Never expose", member_email="private@example.test",
    )

    async def worker(data, origin):
        async with sessions() as session:
            return await sync_public_catalogue(session, {"schema_version": 1, "restaurants": [data]}, origin=origin)

    try:
        assert sum(await asyncio.gather(worker(bundle, "bundle"), worker(live, "export"))) == 1
        # A restart is a fresh ORM session, rather than reusing cached relationship state.
        assert await worker(bundle, "bundle") == 0
        async with sessions() as session:
            row = (await session.execute(select(Restaurant).where(Restaurant.id == live["id"]))).scalar_one()
            payload = RestaurantOut.model_validate(row).model_dump()
            assert (row.name, row.area, row.is_active, row.cuisines) == (live["name"], live["area"], False, ["healthy"])
            assert payload["photo_url"] == live["photo_url"]
            assert row.catalogue_metadata.payload["_sync_origin"] == "export"
            assert "private_notes" not in payload
            assert "private_notes" not in row.catalogue_metadata.payload
            assert "member_email" not in payload
    finally:
        await engine.dispose()


@pytest.mark.asyncio
async def test_two_startups_preserve_legacy_manual_rows_and_insert_seed_names_once(tmp_path, monkeypatch):
    engine, sessions = await create_database(tmp_path / "concurrent-startup.db")
    cafes = [public_cafe()]
    manual = [
        {"name": "Synthetic legacy kitchen", "city": "Synthetic City", "area": "Seed Area", "cuisines": ["pizza"], "price_band": "budget"},
        {"name": "Synthetic new kitchen", "city": "Synthetic City", "area": "Seed Area", "cuisines": ["bakery"], "price_band": "moderate"},
    ]
    monkeypatch.setattr(seeds, "CAFE_APP_SEEDS", cafes)
    monkeypatch.setattr(seeds, "ADDITIONAL_RESTAURANTS", manual)
    async with sessions() as session:
        session.add(Restaurant(id="legacy-random-id", name=manual[0]["name"], city="Curated City",
                               area="Curated Area", cuisines=["healthy"], price_band="premium", source="manual"))
        await session.commit()

    async def startup():
        async with sessions() as session:
            return await seeds.seed_restaurants(session)

    try:
        assert sum(await asyncio.gather(startup(), startup())) == 2
        assert await startup() == 0
        async with sessions() as session:
            assert await session.scalar(select(func.count()).select_from(Restaurant)) == 3
            legacy = await session.get(Restaurant, "legacy-random-id")
            assert (legacy.city, legacy.area, legacy.cuisines, legacy.price_band) == ("Curated City", "Curated Area", ["healthy"], "premium")
            new = (await session.execute(select(Restaurant).where(Restaurant.name == manual[1]["name"]))).scalar_one()
            assert new.id == str(uuid.uuid5(uuid.NAMESPACE_URL, f"food-recsys:seed-restaurant:{manual[1]['name'].casefold()}"))
    finally:
        await engine.dispose()


@pytest.mark.asyncio
async def test_source_collision_rolls_back_the_whole_export(tmp_path):
    engine, sessions = await create_database(tmp_path / "source-ownership.db")
    first = public_cafe()
    collision = public_cafe(id="f1000000-0000-0000-0000-000000000002", name="Owned manual row")
    async with sessions() as session:
        session.add(Restaurant(id=collision["id"], name="Original curated manual row", city="Synthetic City",
                               area="Curated Area", cuisines=["healthy"], source="manual"))
        await session.commit()
        with pytest.raises(ValueError, match="another source"):
            await sync_public_catalogue(session, {"schema_version": 1, "restaurants": [first, collision]})
        assert await session.get(Restaurant, first["id"]) is None
        row = await session.get(Restaurant, collision["id"])
        assert (row.name, row.source) == ("Original curated manual row", "manual")
    await engine.dispose()


@pytest.mark.asyncio
async def test_existing_restaurant_table_upgrades_additively_and_keeps_enrichment(tmp_path):
    engine = create_async_engine(f"sqlite+aiosqlite:///{tmp_path / 'legacy-upgrade.db'}")
    # Model columns on Restaurant are unchanged; the old installation has no metadata table.
    async with engine.begin() as connection:
        await connection.run_sync(lambda sync_connection: Restaurant.__table__.create(sync_connection))
        await connection.execute(Restaurant.__table__.insert().values(
            id=public_cafe()["id"], name="Legacy synthetic cafe", city="Synthetic City",
            area="Legacy Area", source="cafe_app", cuisines=["healthy"], price_band="premium",
        ))
        await connection.run_sync(Base.metadata.create_all)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    incoming = public_cafe()
    del incoming["cuisines"]  # PHP has no taxonomy; do not erase curated enrichment.
    try:
        async with sessions() as session:
            assert await sync_public_catalogue(session, {"schema_version": 1, "restaurants": [incoming]}) == 0
        async with sessions() as session:
            row = (await session.execute(select(Restaurant).where(Restaurant.id == incoming["id"]))).scalar_one()
            assert row.cuisines == ["healthy"]
            assert row.name == incoming["name"]
            assert row.catalogue_metadata.payload["photo_url"] == incoming["photo_url"]
    finally:
        await engine.dispose()

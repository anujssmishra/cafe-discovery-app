import os
import sys
from pathlib import Path

# Ensure food_recsys package root is on sys.path
FOOD_RECSYS_ROOT = Path(__file__).resolve().parent.parent
if str(FOOD_RECSYS_ROOT) not in sys.path:
    sys.path.insert(0, str(FOOD_RECSYS_ROOT))

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

# Use in-memory SQLite for test isolation
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"

from app.main import app
from app.models.base import Base
from app.db.session import get_db
from app.mock.restaurants import seed_restaurants
from app.mock.transactions import generate_mock_transactions_for_persona
from app.ingestion.pipeline import ingest_transactions
from app.profile.builder import build_taste_profile

test_engine = create_async_engine(
    "sqlite+aiosqlite:///:memory:",
    connect_args={"check_same_thread": False},
    future=True,
)
TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


@pytest_asyncio.fixture(scope="function")
async def db_session():
    """Provides a fresh database session with tables and restaurants seeded."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with TestSessionLocal() as session:
        await seed_restaurants(session)
        yield session

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(db_session):
    """FastAPI async test client with database override."""
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()

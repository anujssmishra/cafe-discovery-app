import pytest
from datetime import datetime
from zoneinfo import ZoneInfo
from app.ingestion.pipeline import ingest_transactions
from app.profile.builder import build_taste_profile
from app.schemas.transaction import TransactionIn


@pytest.mark.asyncio
async def test_build_taste_profile(db_session):
    txs = [
        TransactionIn(
            user_id="profile_tester",
            transaction_time=datetime(2026, 10, 15, 8, 30, tzinfo=ZoneInfo("Asia/Kolkata")),
            amount=140.0,
            merchant_name="SAGAR RATNA HAZRATGANJ",
            mcc_code="5812",
        ),
        TransactionIn(
            user_id="profile_tester",
            transaction_time=datetime(2026, 10, 16, 9, 0, tzinfo=ZoneInfo("Asia/Kolkata")),
            amount=120.0,
            merchant_name="CURRY LEAF SOUTH INDIAN",
            mcc_code="5812",
        ),
        TransactionIn(
            user_id="profile_tester",
            transaction_time=datetime(2026, 10, 17, 20, 30, tzinfo=ZoneInfo("Asia/Kolkata")),
            amount=250.0,
            merchant_name="IDRIS BIRYANI CHOWK",
            mcc_code="5812",
        ),
    ]

    await ingest_transactions(db_session, txs)
    profile = await build_taste_profile(db_session, "profile_tester")

    assert profile.user_id == "profile_tester"
    assert profile.total_food_transactions == 3
    assert profile.avg_spend == 170.0  # (140 + 120 + 250) / 3 = 170.0

    # South Indian (2 out of 3 = 66.7%), Biryani (1 out of 3 = 33.3%)
    assert "south_indian" in profile.cuisine_affinities
    assert profile.cuisine_affinities["south_indian"] > 0.6
    assert "biryani" in profile.cuisine_affinities

    # Price distribution: 2 budget (<=150), 1 moderate (250)
    assert profile.price_distribution["budget"] > 0.6
    assert profile.price_distribution["moderate"] > 0.3

    # Meal patterns: breakfast and dinner
    assert "breakfast" in profile.meal_patterns
    assert "dinner" in profile.meal_patterns

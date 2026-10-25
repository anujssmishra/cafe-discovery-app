import pytest
from app.mock.transactions import generate_mock_transactions_for_persona
from app.ingestion.pipeline import ingest_transactions
from app.profile.builder import build_taste_profile
from app.recsys.engine import get_recommendations


@pytest.mark.asyncio
async def test_recsys_south_indian_persona(db_session):
    # Ingest mock transactions for South Indian regular
    mock_txs = generate_mock_transactions_for_persona("south_indian_regular", days=60)
    await ingest_transactions(db_session, mock_txs)
    await build_taste_profile(db_session, "user_south_indian")

    # Generate recommendations
    recs = await get_recommendations(db_session, "user_south_indian", n=5)

    assert recs.count == 5
    top_rec = recs.recommendations[0]

    # Verify top recommendation is South Indian
    assert any("south_indian" in c for c in top_rec.restaurant.cuisines)
    assert top_rec.score > 0.6
    assert len(top_rec.reasons) >= 1
    # Check that explanation mentions South Indian
    assert any("South Indian" in reason for reason in top_rec.reasons)


@pytest.mark.asyncio
async def test_recsys_cafe_hopper_persona(db_session):
    # Ingest mock transactions for Cafe Hopper
    mock_txs = generate_mock_transactions_for_persona("cafe_hopper", days=60)
    await ingest_transactions(db_session, mock_txs)
    await build_taste_profile(db_session, "user_cafe_hopper")

    recs = await get_recommendations(db_session, "user_cafe_hopper", n=5)

    assert recs.count == 5
    top_rec = recs.recommendations[0]

    # Verify top recommendation is a Cafe/Bakery
    assert any(c in ["cafe_western", "bakery"] for c in top_rec.restaurant.cuisines)
    assert top_rec.score > 0.6
    assert any("Café" in r or "Bakery" in r for r in top_rec.reasons)


@pytest.mark.asyncio
async def test_recsys_budget_student_persona(db_session):
    mock_txs = generate_mock_transactions_for_persona("budget_student", days=60)
    await ingest_transactions(db_session, mock_txs)
    await build_taste_profile(db_session, "user_budget_student")

    recs = await get_recommendations(db_session, "user_budget_student", n=5)

    assert recs.count == 5
    top_rec = recs.recommendations[0]

    # Top recommendations should fit budget tier
    assert top_rec.restaurant.price_band in ["budget", "moderate"]
    assert any(c in ["street_food", "tea_coffee", "burger", "pizza"] for c in top_rec.restaurant.cuisines)

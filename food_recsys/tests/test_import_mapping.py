"""Synthetic import regressions: no device messages or production data."""
import asyncio
from datetime import datetime, timezone

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.ingestion.pipeline import ingest_transactions, match_restaurant_by_name
from app.models.base import Base
from app.models.restaurant import Restaurant
from app.models.transaction import FoodPurchase, UpiTransaction
from app.schemas.transaction import TransactionIn


def payment(**changes):
    data = {
        "user_id": "synthetic_mapping", "source_id": "sms:100",
        "transaction_time": datetime(2026, 10, 23, 18, 45, tzinfo=timezone.utc),
        "merchant_name": "Synthetic Kitchen", "amount": 250.0,
        "upi_ref": "900000123456", "timezone": "Asia/Kolkata",
    }
    return TransactionIn(**(data | changes))


@pytest.mark.asyncio
async def test_retries_and_cross_source_refs_do_not_inflate_counts(db_session):
    first = await ingest_transactions(db_session, [payment()])
    retry = await ingest_transactions(db_session, [payment(), payment(source_id="statement:200")])
    assert first.ingested_count == 1
    assert (retry.ingested_count, retry.duplicate_count, retry.submitted_count) == (0, 2, 2)
    assert [outcome.source_id for outcome in retry.outcomes] == ["sms:100", "statement:200"]
    assert [outcome.status for outcome in retry.outcomes] == ["duplicate", "duplicate"]
    assert await db_session.scalar(select(func.count()).select_from(FoodPurchase)) == 1
    assert (await ingest_transactions(db_session, [payment(user_id="another_synthetic_user")])).ingested_count == 1


@pytest.mark.asyncio
async def test_legacy_reference_and_source_identity_without_reference(db_session):
    db_session.add(UpiTransaction(
        id="legacy-random-uuid", user_id="synthetic_mapping",
        transaction_time=datetime(2026, 10, 23, 18, 45), amount=250,
        merchant_name="Synthetic Kitchen", mcc_code="5812", upi_ref="legacyref",
    ))
    await db_session.commit()
    assert (await ingest_transactions(db_session, [payment(upi_ref="LEGACYREF")])).duplicate_count == 1
    assert (await ingest_transactions(db_session, [payment(source_id="sms:101", upi_ref=None)])).ingested_count == 1
    assert (await ingest_transactions(db_session, [payment(source_id="sms:101", upi_ref=None)])).duplicate_count == 1
    # Similar genuine purchases stay separate rather than fuzzy amount/day deduplication.
    distinct = await ingest_transactions(db_session, [payment(
        source_id="sms:102", upi_ref=None,
        transaction_time=datetime(2026, 10, 23, 18, 46, tzinfo=timezone.utc),
    )])
    assert distinct.ingested_count == 1


@pytest.mark.asyncio
async def test_concurrent_ref_retry_has_one_stored_payment(tmp_path):
    engine = create_async_engine(f"sqlite+aiosqlite:///{tmp_path / 'synthetic-concurrent.db'}")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    sessions = async_sessionmaker(engine, expire_on_commit=False)

    async def worker(source):
        async with sessions() as session:
            return await ingest_transactions(session, [payment(source_id=source)])

    try:
        results = await asyncio.gather(worker("sms:one"), worker("statement:two"))
        assert sum(result.ingested_count for result in results) == 1
        assert sum(result.duplicate_count for result in results) == 1
        async with sessions() as session:
            assert await session.scalar(select(func.count()).select_from(UpiTransaction)) == 1
            assert await session.scalar(select(func.count()).select_from(FoodPurchase)) == 1
    finally:
        await engine.dispose()


@pytest.mark.asyncio
async def test_local_timezone_drives_meal_weekday_and_storage(db_session):
    await ingest_transactions(db_session, [payment()])
    purchase = await db_session.scalar(select(FoodPurchase).where(FoodPurchase.user_id == "synthetic_mapping"))
    assert (purchase.meal_type, purchase.hour_of_day) == ("late_night", 0)
    assert (purchase.day_of_week, purchase.is_weekend) == (5, True)
    stored = await db_session.scalar(select(UpiTransaction).where(UpiTransaction.user_id == "synthetic_mapping"))
    assert stored.transaction_time == datetime(2026, 10, 23, 18, 45)


@pytest.mark.asyncio
async def test_branch_matching_resolves_only_unique_active_branch(db_session):
    db_session.add_all([
        Restaurant(id="synthetic_branch_a", name="Synthetic Cafe (Area A)", area="Area A", cuisines=["cafe_western"]),
        Restaurant(id="synthetic_branch_b", name="Synthetic Cafe (Area B)", area="Area B", cuisines=["cafe_western"]),
        Restaurant(id="synthetic_inactive", name="Closed Synthetic Cafe", area="Area A", cuisines=[], is_active=False),
    ])
    await db_session.commit()
    assert await match_restaurant_by_name(db_session, "Synthetic Cafe Area B") == "synthetic_branch_b"
    assert await match_restaurant_by_name(db_session, "Synthetic Cafe") is None
    assert await match_restaurant_by_name(db_session, "Closed Synthetic Cafe") is None
    result = await ingest_transactions(db_session, [payment(merchant_name="Synthetic Cafe")])
    assert (result.ingested_count, result.unresolved_count) == (1, 1)


@pytest.mark.asyncio
async def test_structured_contract_echoes_outcomes_and_retries(client):
    payload = {
        "user_id": "structured_synthetic", "schema_version": 1,
        "payments": [{
            "source_id": "sms:501", "merchant_name": "Independent Synthetic Outlet",
            "amount": 300, "transaction_time": "2026-10-24T20:00:00+05:30",
            "timezone": "Asia/Kolkata", "upi_ref": "900000500001",
            "cuisine": "south_indian", "dish_names": ["Dosa"],
        }],
    }
    first = (await client.post("/api/v1/ingest/payments", json=payload)).json()
    assert first["status"] == "success"
    assert (first["submitted_count"], first["ingested_count"], first["duplicate_count"], first["rejected_count"]) == (1, 1, 0, 0)
    assert first["outcomes"] == [{"source_id": "sms:501", "status": "inserted", "reason": None}]
    assert first["unresolved_count"] == 1
    assert first["taste_profile"]["top_cuisines"] == {"south_indian": 1.0}
    retry = (await client.post("/api/v1/ingest/payments", json=payload)).json()
    assert (retry["ingested_count"], retry["duplicate_count"]) == (0, 1)
    assert retry["taste_profile"]["version"] == first["taste_profile"]["version"]
    assert retry["outcomes"][0]["status"] == "duplicate"


@pytest.mark.asyncio
@pytest.mark.parametrize("change", [
    {"timezone": "Unknown/Somewhere"}, {"cuisine": "invented_cuisine"},
    {"merchant_name": "  "}, {"amount": -1}, {"source_id": "../invalid id"},
    {"raw_text": "This must not be accepted"}, {"dish_names": ["x" * 121]},
])
async def test_structured_contract_rejects_invalid_or_raw_fields(client, change):
    body = {"merchant_name": "Synthetic Kitchen", "amount": 100} | change
    response = await client.post("/api/v1/ingest/payments", json={
        "user_id": "structured_synthetic", "schema_version": 1, "payments": [body],
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_missing_time_is_unknown_and_all_dishes_contribute(client, db_session):
    response = await client.post("/api/v1/ingest/payments", json={
        "user_id": "synthetic_without_time", "schema_version": 1,
        "payments": [{"source_id": "order:missing-time", "merchant_name": "Synthetic Kitchen", "amount": 180}],
    })
    assert response.status_code == 200
    purchase = await db_session.scalar(select(FoodPurchase).where(FoodPurchase.user_id == "synthetic_without_time"))
    assert (purchase.meal_type, purchase.hour_of_day, purchase.day_of_week) == ("unknown", -1, -1)
    response = await client.post("/api/v1/ingest/food-orders", json={
        "user_id": "synthetic_all_dishes", "orders": [
            {"restaurant_name": "Synthetic Outlet A", "amount": 200, "cuisine": "south_indian"},
            {"restaurant_name": "Synthetic Outlet B", "amount": 200, "dish_names": ["One", "Two", "Three", "Dosa"]},
        ],
    })
    assert response.status_code == 200
    assert response.json()["taste_profile"]["top_cuisines"] == {"south_indian": 1.0}


@pytest.mark.asyncio
async def test_legacy_sms_reports_rejected_rows_and_retains_dish_evidence(client):
    response = await client.post("/api/v1/ingest/sms", json={
        "user_id": "synthetic_sms_evidence", "messages": [
            "Your Swiggy order from Synthetic Kitchen of Rs 280 for dosa is placed!",
            "Paid Rs 299 to Steam Games via UPI Ref 900000123456.",
        ],
    })
    result = response.json()
    assert response.status_code == 200
    assert (result["submitted_count"], result["ingested_count"], result["rejected_count"]) == (2, 1, 1)
    assert [item["status"] for item in result["outcomes"]] == ["inserted", "rejected"]
    assert result["taste_profile"]["top_cuisines"] == {"south_indian": 1.0}
    empty = (await client.post("/api/v1/ingest/sms", json={
        "user_id": "synthetic_no_food", "messages": ["Your synthetic OTP is 123456"],
    })).json()
    assert empty["status"] == "no_transactions_found"
    assert (empty["parsed_transactions_count"], empty["ingested_count"], empty["rejected_count"]) == (0, 0, 1)
    assert empty["submitted_count"] == 1


@pytest.mark.asyncio
async def test_statement_rejects_nonfood_and_invalid_dates_without_fabricating_meals(client, db_session):
    content = """Date,Narration,Debit
24/10/2026,UPI-SYNTHETIC CAFE-900000100001,200
24/10/2026,UPI-STEAM GAMES-900000100002,299
unknown,UPI-SYNTHETIC CAFE-900000100003,200
"""
    response = await client.post("/api/v1/ingest/statement", data={"user_id": "synthetic_statement"}, files={"file": ("synthetic.csv", content, "text/csv")})
    result = response.json()
    assert response.status_code == 200
    assert (result["submitted_count"], result["ingested_count"], result["rejected_count"]) == (3, 1, 2)
    assert {item["reason"] for item in result["outcomes"] if item["status"] == "rejected"} == {"not_food", "invalid_timestamp"}
    purchase = await db_session.scalar(select(FoodPurchase).where(FoodPurchase.user_id == "synthetic_statement"))
    assert (purchase.meal_type, purchase.hour_of_day, purchase.day_of_week) == ("unknown", -1, 5)
    retry = (await client.post("/api/v1/ingest/statement", data={"user_id": "synthetic_statement"}, files={"file": ("synthetic.csv", content, "text/csv")})).json()
    assert (retry["ingested_count"], retry["duplicate_count"], retry["rejected_count"]) == (0, 1, 2)


@pytest.mark.asyncio
async def test_retry_repairs_a_profile_build_interrupted_after_import(client, db_session):
    await ingest_transactions(db_session, [payment()])
    response = await client.post("/api/v1/ingest/payments", json={
        "user_id": "synthetic_mapping", "schema_version": 1,
        "payments": [{
            "source_id": "sms:100", "merchant_name": "Synthetic Kitchen", "amount": 250,
            "transaction_time": "2026-10-23T18:45:00Z", "upi_ref": "900000123456",
        }],
    })
    result = response.json()
    assert response.status_code == 200
    assert (result["ingested_count"], result["duplicate_count"]) == (0, 1)
    assert result["taste_profile"]["total_food_transactions"] == 1


@pytest.mark.asyncio
async def test_source_alias_survives_missing_or_newly_enriched_reference(db_session):
    # A foreground retry may omit a reference already present in a historical import.
    assert (await ingest_transactions(db_session, [payment()])).ingested_count == 1
    retry = await ingest_transactions(db_session, [payment(upi_ref=None)])
    assert (retry.ingested_count, retry.duplicate_count) == (0, 1)
    # A later import may discover the reference for an earlier source-only payment.
    first = payment(source_id="sms:200", upi_ref=None, transaction_time=datetime(2026, 10, 24, 15, tzinfo=timezone.utc))
    enriched = first.model_copy(update={"upi_ref": "900000987654"})
    assert (await ingest_transactions(db_session, [first])).ingested_count == 1
    assert (await ingest_transactions(db_session, [enriched])).duplicate_count == 1
    # The newly registered reference also deduplicates a third, unrelated source identifier.
    assert (await ingest_transactions(db_session, [enriched.model_copy(update={"source_id": "statement:300"})])).duplicate_count == 1
    assert await db_session.scalar(select(func.count()).select_from(UpiTransaction)) == 2


@pytest.mark.asyncio
async def test_concurrent_source_alias_race_rolls_back_losing_transaction(tmp_path):
    engine = create_async_engine(f"sqlite+aiosqlite:///{tmp_path / 'synthetic-source-race.db'}")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    sessions = async_sessionmaker(engine, expire_on_commit=False)

    async def worker(reference):
        async with sessions() as session:
            return await ingest_transactions(session, [payment(upi_ref=reference)])

    try:
        results = await asyncio.gather(worker("900000123456"), worker(None))
        assert sum(result.ingested_count for result in results) == 1
        assert sum(result.duplicate_count for result in results) == 1
        async with sessions() as session:
            assert await session.scalar(select(func.count()).select_from(UpiTransaction)) == 1
            assert await session.scalar(select(func.count()).select_from(FoodPurchase)) == 1
    finally:
        await engine.dispose()


@pytest.mark.asyncio
async def test_distinct_references_or_sources_do_not_merge_on_same_coarse_time(db_session):
    transactions = [
        payment(source_id="sms:distinct-one", upi_ref="900000000001"),
        payment(source_id="sms:distinct-two", upi_ref="900000000002"),
        payment(source_id="sms:distinct-three", upi_ref=None),
        payment(source_id="sms:distinct-four", upi_ref=None),
    ]
    result = await ingest_transactions(db_session, transactions)
    assert (result.ingested_count, result.duplicate_count) == (4, 0)
    # An exact retry with no identifiers is still idempotent.
    anonymous = payment(source_id=None, upi_ref=None)
    assert (await ingest_transactions(db_session, [anonymous, anonymous])).duplicate_count == 1

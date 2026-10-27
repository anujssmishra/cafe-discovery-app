"""Synthetic Swiggy/Zomato imports, identity linking and receipt evidence retention."""

import asyncio
from datetime import datetime, timezone

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.ingestion.order_import import order_to_transaction
from app.ingestion.pipeline import ingest_transactions
from app.models.base import Base
from app.models.transaction import FoodPurchase, OrderDetails, PaymentIdentity, UpiTransaction
from app.schemas.transaction import FoodOrderIn, TransactionIn

USER = "synthetic_order_user"


def order_payment(**changes):
    return {
        "merchant_name": "Synthetic Dosa Kitchen", "amount": 300,
        "transaction_time": "2026-10-26T20:15:00+05:30", "timezone": "Asia/Kolkata",
        "order_id": "ORDER_001", "order_platform": "Swiggy", "order_status": "delivered",
        "dish_names": ["Dosa", "Filter Coffee"], "cuisine": "south_indian",
        **changes,
    }


def preview_order(**changes):
    return {
        "restaurant_name": "Synthetic Dosa Kitchen", "amount": 300,
        "order_time": "2026-10-26T20:15:00+05:30", "timezone": "Asia/Kolkata",
        "order_id": "ORDER_001", "platform": "Swiggy", "status": "delivered",
        "dish_names": ["Dosa", "Filter Coffee"], "cuisine": "south_indian", **changes,
    }


async def pay(client, payments, user=USER):
    response = await client.post("/api/v1/ingest/payments", json={
        "schema_version": 1, "user_id": user, "payments": payments,
    })
    assert response.status_code == 200, response.text
    return response.json()


async def bank_payment(client, db_session, *, user=USER, reference="900000700001", source="sms:bank", time="2026-10-26T20:00:00+05:30", amount=300):
    await pay(client, [{
        "source_id": source, "merchant_name": "Swiggy", "amount": amount,
        "transaction_time": time, "upi_ref": reference, "payment_app": "Synthetic Bank",
    }], user)
    return await db_session.scalar(select(UpiTransaction).where(
        UpiTransaction.user_id == user, UpiTransaction.merchant_name == "Swiggy",
    ).order_by(UpiTransaction.transaction_time.desc()))


@pytest.mark.asyncio
async def test_order_repeat_and_platform_scoping(client, db_session):
    first = await pay(client, [order_payment(order_platform="swiggy")])
    retry = await pay(client, [order_payment(source_id="order:swiggy:ORDER_001")])
    other_platform = await pay(client, [order_payment(order_platform="Zomato")])
    assert first["outcomes"][0]["source_id"] == "order:swiggy:ORDER_001"
    assert (first["ingested_count"], retry["ingested_count"], retry["duplicate_count"], other_platform["ingested_count"]) == (1, 0, 1, 1)
    assert await db_session.scalar(select(func.count()).select_from(UpiTransaction)) == 2
    assert await db_session.scalar(select(func.count()).select_from(FoodPurchase)) == 2
    assert await db_session.scalar(select(func.count()).select_from(OrderDetails)) == 2


@pytest.mark.asyncio
async def test_shared_upi_enriches_one_bank_purchase_and_partial_retry_keeps_evidence(client, db_session):
    bank = await bank_payment(client, db_session)
    original_time = bank.transaction_time
    imported = await pay(client, [order_payment(upi_ref="900000700001")])
    assert (imported["ingested_count"], imported["duplicate_count"]) == (0, 1)
    assert imported["taste_profile"]["total_food_transactions"] == 1
    assert imported["taste_profile"]["top_cuisines"] == {"south_indian": 1}
    assert imported["outcomes"][0]["reason"] == "order_details_updated"
    details = await db_session.scalar(select(OrderDetails).where(OrderDetails.user_id == USER))
    assert details.transaction_id == bank.id
    assert details.dish_names == ["Dosa", "Filter Coffee"]
    assert details.order_time == datetime(2026, 10, 26, 14, 45)
    assert bank.transaction_time == original_time  # Keep the actual bank payment instant.
    assert bank.payment_app == "Synthetic Bank"

    retry = await pay(client, [order_payment(
        merchant_name="Swiggy", transaction_time=None, cuisine=None, dish_names=[], order_status=None,
    )])
    assert (retry["ingested_count"], retry["duplicate_count"]) == (0, 1)
    await db_session.refresh(details)
    assert (details.merchant_name, details.cuisine, details.dish_names, details.time_precision, details.order_status) == (
        "Synthetic Dosa Kitchen", "south_indian", ["Dosa", "Filter Coffee"], "exact", "delivered",
    )
    assert details.order_time == datetime(2026, 10, 26, 14, 45)
    assert await db_session.scalar(select(func.count()).select_from(FoodPurchase)) == 1


@pytest.mark.asyncio
async def test_partial_merchant_guess_does_not_replace_explicit_cuisine(client, db_session):
    await pay(client, [order_payment(merchant_name="Synthetic Cafe", cuisine="north_indian_curry", dish_names=["Paneer"])])
    await pay(client, [order_payment(merchant_name="Synthetic Cafe", cuisine=None, dish_names=[])])
    details = await db_session.scalar(select(OrderDetails))
    purchase = await db_session.scalar(select(FoodPurchase))
    assert details.cuisine == purchase.cuisine_detected == "north_indian_curry"
    assert details.dish_names == ["Paneer"]


@pytest.mark.asyncio
async def test_explicit_link_requires_owner_amount_and_unclaimed_platform_order(client, db_session):
    bank = await bank_payment(client, db_session, reference=None)
    wrong_amount = await pay(client, [order_payment(linked_transaction_id=bank.id, amount=301)])
    assert wrong_amount["outcomes"][0]["reason"] == "amount_mismatch"
    foreign = await pay(client, [order_payment(linked_transaction_id=bank.id)], user="different_synthetic_user")
    assert foreign["outcomes"][0]["reason"] == "linked_payment_not_found"
    assert await db_session.scalar(select(func.count()).select_from(OrderDetails)) == 0

    linked = await pay(client, [order_payment(linked_transaction_id=bank.id)])
    assert (linked["ingested_count"], linked["duplicate_count"]) == (0, 1)
    conflicting = await pay(client, [order_payment(order_id="ORDER_002", linked_transaction_id=bank.id)])
    assert conflicting["outcomes"][0]["reason"] == "payment_already_has_platform_order"
    assert await db_session.scalar(select(func.count()).select_from(UpiTransaction)) == 1
    assert await db_session.scalar(select(func.count()).select_from(OrderDetails)) == 1


@pytest.mark.asyncio
async def test_conflicting_order_and_upi_aliases_are_not_overwritten(client, db_session):
    bank = await bank_payment(client, db_session)
    await pay(client, [order_payment()])
    details = await db_session.scalar(select(OrderDetails))
    original_order_transaction = details.transaction_id
    assert original_order_transaction != bank.id
    conflict = await pay(client, [order_payment(upi_ref="900000700001")])
    assert conflict["outcomes"][0] == {
        "source_id": "order:swiggy:ORDER_001", "status": "rejected", "reason": "identity_conflict",
    }
    await db_session.refresh(details)
    assert details.transaction_id == original_order_transaction
    assert await db_session.scalar(select(func.count()).select_from(UpiTransaction)) == 2


@pytest.mark.asyncio
async def test_preview_exact_identity_and_ambiguous_candidates_never_mutates(client, db_session):
    bank = await bank_payment(client, db_session)
    before = await db_session.scalar(select(func.count()).select_from(PaymentIdentity))
    exact = await client.post("/api/v1/ingest/food-orders/preview", json={
        "user_id": USER, "orders": [preview_order(upi_ref="900000700001")],
    })
    assert exact.status_code == 200
    assert exact.json()["orders"][0] == {
        "source_id": "order:swiggy:ORDER_001", "status": "duplicate", "candidates": [], "existing_transaction_id": bank.id,
    }
    await bank_payment(client, db_session, reference="900000700002", source="sms:second", time="2026-10-26T20:05:00+05:30")
    await bank_payment(client, db_session, user="different_synthetic_user", reference="900000700003", source="sms:private-other")
    response = await client.post("/api/v1/ingest/food-orders/preview", json={
        "user_id": USER, "orders": [preview_order()],
    })
    result = response.json()["orders"][0]
    assert result["status"] == "review"
    assert result["reason"] == "possible_existing_payment"
    assert len(result["candidates"]) == 2
    assert {row["merchant_name"] for row in result["candidates"]} == {"Swiggy"}
    assert await db_session.scalar(select(func.count()).select_from(OrderDetails)) == 0
    # Only the two additional bank captures registered aliases, never the preview.
    assert await db_session.scalar(select(func.count()).select_from(PaymentIdentity)) == before + 4


@pytest.mark.asyncio
async def test_new_preview_and_date_only_import_do_not_invent_meal(client, db_session):
    response = await client.post("/api/v1/ingest/food-orders/preview", json={
        "user_id": USER, "orders": [preview_order(order_time="2026-10-26")],
    })
    assert response.json()["orders"][0]["status"] == "new"
    await pay(client, [order_payment(transaction_time="2026-10-26")])
    purchase = await db_session.scalar(select(FoodPurchase))
    details = await db_session.scalar(select(OrderDetails))
    assert (purchase.meal_type, purchase.hour_of_day, purchase.day_of_week) == ("unknown", -1, 0)
    assert details.time_precision == "date"


@pytest.mark.asyncio
async def test_cancelled_refunded_and_non_inr_orders_are_terminal_rejections(client, db_session):
    orders = [preview_order(status="cancelled"), preview_order(order_id="ORDER_002", status="refunded"), preview_order(order_id="ORDER_003", currency="USD")]
    preview = await client.post("/api/v1/ingest/food-orders/preview", json={"user_id": USER, "orders": orders})
    assert preview.status_code == 200
    assert [row["status"] for row in preview.json()["orders"]] == ["rejected"] * 3
    imported = await client.post("/api/v1/ingest/food-orders", json={"user_id": USER, "orders": orders})
    assert imported.status_code == 200
    assert (imported.json()["ingested_count"], imported.json()["rejected_count"]) == (0, 3)
    assert await db_session.scalar(select(func.count()).select_from(UpiTransaction)) == 0
    invalid = await client.post("/api/v1/ingest/payments", json={
        "schema_version": 1, "user_id": USER, "payments": [order_payment(order_status="cancelled")],
    })
    assert invalid.status_code == 422


@pytest.mark.asyncio
@pytest.mark.parametrize("fields", [
    {"raw_sms": "Synthetic sensitive raw body"}, {"account_number": "1234567890"},
    {"source_id": "order:zomato:DIFFERENT"}, {"currency": "USD"},
])
async def test_unknown_private_fields_and_conflicting_sources_are_rejected(client, fields):
    response = await client.post("/api/v1/ingest/payments", json={
        "schema_version": 1, "user_id": USER, "payments": [order_payment(**fields)],
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_preview_rejects_private_fields_instead_of_silently_retaining_them(client):
    response = await client.post("/api/v1/ingest/food-orders/preview", json={
        "user_id": USER, "orders": [preview_order(raw_receipt="Synthetic private receipt")],
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_concurrent_orders_cannot_attach_two_charges_to_one_platform_payment(tmp_path):
    engine = create_async_engine(f"sqlite+aiosqlite:///{tmp_path / 'synthetic-orders.db'}")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    bank = TransactionIn(user_id=USER, source_id="sms:concurrent-bank", merchant_name="Swiggy", amount=300,
                         transaction_time=datetime(2026, 10, 26, 14, 30, tzinfo=timezone.utc))
    async with sessions() as session:
        await ingest_transactions(session, [bank])
        transaction_id = await session.scalar(select(UpiTransaction.id))

    async def worker(order_id):
        async with sessions() as session:
            tx = order_to_transaction(FoodOrderIn(**preview_order(order_id=order_id, linked_transaction_id=transaction_id)), USER)
            return await ingest_transactions(session, [tx])

    try:
        results = await asyncio.gather(worker("ORDER_A"), worker("ORDER_B"))
        assert sum(result.duplicate_count for result in results) == 1
        assert sum(result.rejected_count for result in results) == 1
        async with sessions() as session:
            assert await session.scalar(select(func.count()).select_from(UpiTransaction)) == 1
            assert await session.scalar(select(func.count()).select_from(FoodPurchase)) == 1
            assert await session.scalar(select(func.count()).select_from(OrderDetails)) == 1
    finally:
        await engine.dispose()


@pytest.mark.asyncio
async def test_preview_and_ingest_refuse_a_different_order_on_an_attached_payment(client, db_session):
    bank = await bank_payment(client, db_session)
    await pay(client, [order_payment(upi_ref="900000700001")])
    for platform in ["Swiggy", "Zomato"]:
        response = await client.post("/api/v1/ingest/food-orders/preview", json={
            "user_id": USER, "orders": [preview_order(
                order_id="DIFFERENT_ORDER", platform=platform, upi_ref="900000700001",
            )],
        })
        assert response.status_code == 200
        result = response.json()["orders"][0]
        assert result["status"] == "rejected"
        assert result["reason"] in {"payment_already_has_platform_order", "payment_already_has_order"}
        imported = await pay(client, [order_payment(
            order_id="DIFFERENT_ORDER", order_platform=platform, linked_transaction_id=bank.id,
        )])
        assert imported["outcomes"][0]["status"] == "rejected"
    # An already-attached charge is not a review candidate for an unrelated receipt.
    preview = await client.post("/api/v1/ingest/food-orders/preview", json={
        "user_id": USER, "orders": [preview_order(order_id="NEW_UNLINKED_ORDER")],
    })
    assert preview.json()["orders"][0]["status"] == "new"
    assert preview.json()["orders"][0]["candidates"] == []
    assert await db_session.scalar(select(func.count()).select_from(OrderDetails)) == 1


@pytest.mark.asyncio
async def test_order_amount_limit_matches_preview_contract(client):
    response = await client.post("/api/v1/ingest/payments", json={
        "schema_version": 1, "user_id": USER, "payments": [order_payment(amount=100001)],
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_exact_order_previews_date_only_bank_charge_from_the_same_local_day(client):
    await pay(client, [{
        "source_id": "statement:date-only", "merchant_name": "Swiggy", "amount": 300,
        "transaction_time": "2026-10-26", "payment_app": "Statement Upload",
    }])
    response = await client.post("/api/v1/ingest/food-orders/preview", json={
        "user_id": USER, "orders": [preview_order()],
    })
    assert response.status_code == 200
    preview = response.json()["orders"][0]
    assert preview["status"] == "review"
    assert len(preview["candidates"]) == 1
    assert preview["candidates"][0]["time_precision"] == "date"

"""Order context stays user-scoped and is removed with the purchase history."""
import pytest
from sqlalchemy import select
from app.models.transaction import OrderDetails, UpiTransaction, FoodPurchase


@pytest.mark.asyncio
async def test_order_context_appears_in_ledger_and_erases_without_affecting_other_user(client, db_session):
    for user in ("order_owner", "other_owner"):
        response = await client.post("/api/v1/ingest/payments", json={
            "schema_version": 1, "user_id": user, "payments": [{
                "source_id": "order:swiggy:SYNTHETIC_1", "order_id": "SYNTHETIC_1",
                "order_platform": "Swiggy", "order_status": "delivered", "currency": "INR",
                "merchant_name": "Synthetic Cafe", "amount": 280,
                "transaction_time": "2026-10-26T19:30:00+05:30", "timezone": "Asia/Kolkata",
                "time_precision": "exact", "dish_names": ["Synthetic sandwich"],
            }],
        })
        assert response.status_code == 200, response.text
        assert response.json()["ingested_count"] == 1
    ledger = (await client.get("/api/v1/profile/order_owner/transactions")).json()
    assert ledger["total_count"] == 1
    assert ledger["total_spent"] == 280
    assert ledger["transactions"][0]["orders"] == [{
        "platform": "Swiggy", "order_id": "SYNTHETIC_1", "restaurant_name": "Synthetic Cafe",
        "dish_names": ["Synthetic sandwich"], "status": "delivered", "currency": "INR",
        "time_precision": "exact", "timezone": "Asia/Kolkata", "order_time": "2026-10-26T14:00:00+00:00",
    }]
    response = await client.delete("/api/v1/profile/order_owner")
    assert response.status_code == 200
    for model in (OrderDetails, UpiTransaction, FoodPurchase):
        assert not (await db_session.execute(select(model).where(model.user_id == "order_owner"))).scalars().all()
        assert len((await db_session.execute(select(model).where(model.user_id == "other_owner"))).scalars().all()) == 1
    assert (await client.get("/api/v1/profile/order_owner/transactions")).json()["total_count"] == 0

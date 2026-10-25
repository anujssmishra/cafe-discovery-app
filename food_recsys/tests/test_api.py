import pytest


@pytest.mark.asyncio
async def test_health_endpoint(client):
    res = await client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"
    assert data["database"] == "connected"


@pytest.mark.asyncio
async def test_restaurants_api(client):
    res = await client.get("/api/v1/restaurants?limit=10")
    assert res.status_code == 200
    data = res.json()
    assert len(data) > 0
    assert "name" in data[0]
    assert "area" in data[0]

    # Filter by area
    res_area = await client.get("/api/v1/restaurants?area=Hazratganj")
    assert res_area.status_code == 200
    for r in res_area.json():
        assert "Hazratganj" in r["area"]


@pytest.mark.asyncio
async def test_mock_generate_and_recommend_pipeline(client):
    # 1. Generate mock data for South Indian regular
    res_gen = await client.post("/api/v1/ingest/mock/generate?persona=south_indian_regular&days=45")
    assert res_gen.status_code == 200
    gen_data = res_gen.json()
    assert gen_data["persona"] == "south_indian_regular"
    assert gen_data["transactions_generated"] > 0

    user_id = gen_data["user_id"]

    # 2. Get profile
    res_prof = await client.get(f"/api/v1/profile/{user_id}")
    assert res_prof.status_code == 200
    prof = res_prof.json()
    assert prof["user_id"] == user_id
    assert prof["total_food_transactions"] > 0
    assert "south_indian" in prof["cuisine_affinities"]

    # 3. Get recommendations
    res_rec = await client.get(f"/api/v1/recommend/{user_id}?n=5")
    assert res_rec.status_code == 200
    recs = res_rec.json()
    assert recs["user_id"] == user_id
    assert len(recs["recommendations"]) == 5
    top = recs["recommendations"][0]
    assert "restaurant" in top
    assert "score" in top
    assert len(top["reasons"]) >= 1


@pytest.mark.asyncio
async def test_sms_ingest_api(client):
    sms_payload = {
        "user_id": "test_sms_user",
        "messages": [
            "Sent Rs.340.00 from HDFC Bank A/C **1234 to ROASTERY COFFEE HOUSE on 24-OCT-26 via UPI Ref 429812456789.",
            "Paid Rs. 220.00 to The Hazelnut Factory via Google Pay. UPI Ref: 429877665544.",
        ],
    }
    res = await client.post("/api/v1/ingest/sms", json=sms_payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "success"
    assert data["parsed_transactions_count"] == 2
    assert data["taste_profile"]["total_food_transactions"] == 2

    # Verify recommendations reflect the SMS transactions
    rec_res = await client.get("/api/v1/recommend/test_sms_user?n=3")
    assert rec_res.status_code == 200
    recs = rec_res.json()["recommendations"]
    assert len(recs) == 3
    # Top rec should be cafe/bakery
    assert any("cafe_western" in c or "bakery" in c for c in recs[0]["restaurant"]["cuisines"])


@pytest.mark.asyncio
async def test_food_orders_ingest_api(client):
    payload = {
        "user_id": "test_food_app_user",
        "orders": [
            {
                "restaurant_name": "Dastarkhwan",
                "amount": 650.0,
                "platform": "Zomato",
                "dish_names": ["Galawati Kebab", "Mughlai Paratha"],
            },
            {
                "restaurant_name": "The Belgian Waffle Co",
                "amount": 290.0,
                "platform": "Swiggy",
                "dish_names": ["Triple Chocolate Waffle"],
            },
        ],
    }
    res = await client.post("/api/v1/ingest/food-orders", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "success"
    assert data["orders_count"] == 2
    assert data["taste_profile"]["total_food_transactions"] == 2

    assert "mughlai" in data["taste_profile"]["top_cuisines"]
    assert "dessert" in data["taste_profile"]["top_cuisines"]

    # Verify recommendations reflect the food delivery orders
    rec_res = await client.get("/api/v1/recommend/test_food_app_user?n=3")
    assert rec_res.status_code == 200
    recs = rec_res.json()["recommendations"]
    assert len(recs) == 3



@pytest.mark.asyncio
async def test_statement_ingest_api(client):
    csv_content = """Date,Narration,Chq/Ref No,Value Dt,Withdrawal Amt,Deposit Amt,Closing Balance
15/10/2026,UPI-SAGAR RATNA-SAGARRATNA@ICICI-429812456789-PAYMENT,429812456789,15/10/2026,180.00,,45200.00
16/10/2026,UPI-CURRY LEAF-CURRYLEAF@OKHDFCBANK-429812456790-PAYMENT,429812456790,16/10/2026,140.00,,45060.00
17/10/2026,SALARY CREDIT,SAL001,17/10/2026,,75000.00,120060.00
"""
    files = {"file": ("statement.csv", csv_content, "text/csv")}
    data = {"user_id": "test_statement_user"}

    res = await client.post("/api/v1/ingest/statement", data=data, files=files)
    assert res.status_code == 200
    res_data = res.json()
    assert res_data["status"] == "success"
    assert res_data["parsed_transactions_count"] == 2
    assert res_data["taste_profile"]["total_food_transactions"] == 2
    assert "south_indian" in res_data["taste_profile"]["top_cuisines"]


@pytest.mark.asyncio
async def test_dashboard_ui(client):
    res = await client.get("/")
    assert res.status_code == 200
    assert "Food RecSys" in res.text
    assert "UPI Taste Intelligence" in res.text


@pytest.mark.asyncio
async def test_clear_profile_endpoint(client):
    user_id = "test_clear_user"
    # Ingest one SMS
    await client.post(
        "/api/v1/ingest/sms",
        json={
            "user_id": user_id,
            "sms_text": "Sent Rs.350.00 from HDFC Bank A/C **1234 to THE HAZELNUT FACTORY on 24-OCT-26 via UPI Ref 429812456789.",
        },
    )
    prof_res = await client.get(f"/api/v1/profile/{user_id}")
    assert prof_res.json()["total_food_transactions"] == 1

    # Clear profile
    del_res = await client.delete(f"/api/v1/profile/{user_id}")
    assert del_res.status_code == 200
    assert del_res.json()["total_food_transactions"] == 0

    # Verify recommendations still work cleanly (cold start)
    rec_res = await client.get(f"/api/v1/recommend/{user_id}?n=3")
    assert rec_res.status_code == 200
    assert len(rec_res.json()["recommendations"]) == 3


@pytest.mark.asyncio
async def test_dpdp_consent_endpoints(client):
    user_id = "test_dpdp_consent_user"

    # 1. Initial consent check (defaults to pending)
    res = await client.get(f"/api/v1/profile/{user_id}/consent")
    assert res.status_code == 200
    consent = res.json()
    assert consent["status"] == "pending"
    assert consent["sms_processing_consent"] is False
    assert consent["dpdp_version"] == "DPDP_ACT_2023_V1"

    # 2. Grant explicit affirmative consent under Section 6
    grant_res = await client.post(
        f"/api/v1/profile/{user_id}/consent",
        json={"status": "granted", "sms_processing_consent": True},
    )
    assert grant_res.status_code == 200
    granted_consent = grant_res.json()
    assert granted_consent["status"] == "granted"
    assert granted_consent["sms_processing_consent"] is True
    assert granted_consent["granted_at"] is not None

    # 3. Revoke consent under Section 6(4)
    revoke_res = await client.post(
        f"/api/v1/profile/{user_id}/consent",
        json={"status": "revoked", "sms_processing_consent": False},
    )
    assert revoke_res.status_code == 200
    revoked_consent = revoke_res.json()
    assert revoked_consent["status"] == "revoked"
    assert revoked_consent["sms_processing_consent"] is False
    assert revoked_consent["revoked_at"] is not None


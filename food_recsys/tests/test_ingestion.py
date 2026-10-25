import pytest
from datetime import datetime, timezone
from app.ingestion.mcc_classifier import is_food_mcc, get_mcc_category
from app.ingestion.merchant_resolver import (
    normalize_merchant_name,
    detect_cuisine,
    determine_meal_type,
    determine_price_band,
)
from app.ingestion.pipeline import ingest_transactions
from app.schemas.transaction import TransactionIn


def test_mcc_classifier():
    assert is_food_mcc("5812") is True
    assert is_food_mcc("5814") is True
    assert is_food_mcc("5462") is True
    assert is_food_mcc("5541") is False  # Fuel service
    assert is_food_mcc("4121") is False  # Taxi
    assert get_mcc_category("5812") == "restaurant"
    assert get_mcc_category("5462") == "bakery"


def test_merchant_resolver_normalization():
    assert "Roastery Coffee House" in normalize_merchant_name("UPI-ROASTERY COFFEE HOUSE-PAY@ICICI")
    assert "Idris Biryani" in normalize_merchant_name("PAYTM-IDRIS BIRYANI CHOWK@PAYTM")


def test_cuisine_detection():
    assert detect_cuisine("Sagar Ratna Dosa Corner") == "south_indian"
    assert detect_cuisine("Idris Dum Biryani") == "biryani"
    assert detect_cuisine("The Hazelnut Factory") == "cafe_western"
    assert detect_cuisine("The Cherry Tree Bakery") == "bakery"
    assert detect_cuisine("Sharma Tea Stall") == "street_food"
    assert detect_cuisine("Domino's Pizza") == "pizza"

    # Strict adherence to 'Unknown facts remain unknown':
    # Generic delivery aggregators without restaurant or dish info must return 'unspecified'
    assert detect_cuisine("Swiggy") == "unspecified"
    assert detect_cuisine("Swiggy Food") == "unspecified"
    assert detect_cuisine("Zomato") == "unspecified"
    assert detect_cuisine("Zepto") == "unspecified"

    # Ensure NO speculative guessing based on meal timing or amount
    assert detect_cuisine("Swiggy", amount=150, meal_type="breakfast") == "unspecified"
    assert detect_cuisine("Swiggy", amount=750, meal_type="lunch") == "unspecified"
    assert detect_cuisine("Swiggy", amount=500, meal_type="late_night") == "unspecified"
    assert detect_cuisine("Swiggy", amount=350, meal_type="snack") == "unspecified"
    assert detect_cuisine("Swiggy", amount=400, meal_type="dinner") == "unspecified"

    # But if specific restaurant / dish is present in description, detect correctly
    assert detect_cuisine("Swiggy", "Swiggy: Ordered from Sagar Ratna") == "south_indian"
    assert detect_cuisine("Swiggy", "Swiggy: Ordered from The Belgian Waffle Co") == "dessert"
    assert detect_cuisine("Zomato", "Zomato: Ordered from Dastarkhwan") == "mughlai"
    assert detect_cuisine("Zomato", "Ordered Galawati Kebab from Lucknow") == "mughlai"


def test_meal_type_and_price_bands():
    # Morning: 8:30 AM -> breakfast
    dt_morning = datetime(2026, 10, 24, 8, 30, tzinfo=timezone.utc)
    assert determine_meal_type(dt_morning) == "breakfast"

    # Lunch: 13:00 -> lunch
    dt_lunch = datetime(2026, 10, 24, 13, 0, tzinfo=timezone.utc)
    assert determine_meal_type(dt_lunch) == "lunch"

    # Evening snack: 17:00 -> snack
    dt_snack = datetime(2026, 10, 24, 17, 0, tzinfo=timezone.utc)
    assert determine_meal_type(dt_snack) == "snack"

    # Dinner: 20:30 -> dinner
    dt_dinner = datetime(2026, 10, 24, 20, 30, tzinfo=timezone.utc)
    assert determine_meal_type(dt_dinner) == "dinner"

    # Price bands
    assert determine_price_band(80.0) == "budget"
    assert determine_price_band(250.0) == "moderate"
    assert determine_price_band(650.0) == "premium"
    assert determine_price_band(1200.0) == "luxury"


@pytest.mark.asyncio
async def test_ingest_pipeline(db_session):
    txs = [
        TransactionIn(
            user_id="test_user_1",
            transaction_time=datetime(2026, 10, 20, 9, 0, tzinfo=timezone.utc),
            amount=160.0,
            merchant_name="CURRY LEAF SOUTH INDIAN",
            merchant_id="curryleaf@icici",
            mcc_code="5812",
        ),
        TransactionIn(
            user_id="test_user_1",
            transaction_time=datetime(2026, 10, 21, 13, 30, tzinfo=timezone.utc),
            amount=900.0,
            merchant_name="INDIAN OIL PETROL",
            merchant_id="iocl@upi",
            mcc_code="5541",  # Non-food, should be skipped
        ),
        TransactionIn(
            user_id="test_user_1",
            transaction_time=datetime(2026, 10, 21, 20, 0, tzinfo=timezone.utc),
            amount=220.0,
            merchant_name="SAGAR RATNA DOSA",
            merchant_id="sagarratna@paytm",
            mcc_code="5812",
        ),
    ]

    res = await ingest_transactions(db_session, txs)
    assert res.ingested_count == 2
    assert res.classified_food_count == 2
    assert res.skipped_count == 1
    assert "test_user_1" in res.affected_users

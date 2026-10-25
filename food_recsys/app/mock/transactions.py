"""Mock UPI transaction generator simulating realistic Indian dining habits across 90 days."""

import random
from datetime import datetime, timedelta, timezone
from app.schemas.transaction import TransactionIn

PERSONA_PROFILES = {
    "south_indian_regular": {
        "user_id": "user_south_indian",
        "description": "Devoted South Indian breakfast & filter coffee lover, occasional weekend biryani",
        "primary_merchants": [
            ("SAGAR RATNA HAZRATGANJ", "sagarratna@icici", "5812", (150, 300), "breakfast", 0.35),
            ("CURRY LEAF SOUTH INDIAN", "curryleaf@okhdfcbank", "5812", (120, 220), "breakfast", 0.25),
            ("DAKSHIN UDUPI CAFE", "dakshin@paytm", "5814", (80, 180), "breakfast", 0.15),
            ("SWAMI DOSA CORNER", "swami@okaxis", "5814", (90, 160), "dinner", 0.10),
            ("IDRIS BIRYANI CHOWK", "idrisbiryani@upi", "5812", (180, 320), "dinner", 0.08),
            ("SHARMA TEA STALL", "sharmatea@upi", "5814", (40, 80), "snack", 0.07),
        ],
        "tx_frequency_per_week": 8,
    },
    "cafe_hopper": {
        "user_id": "user_cafe_hopper",
        "description": "Specialty coffee enthusiast & weekend brunch lover",
        "primary_merchants": [
            ("ROASTERY COFFEE HOUSE GOMTI", "roastery@icici", "5812", (450, 950), "snack", 0.28),
            ("THE HAZELNUT FACTORY HAZRATGANJ", "hazelnut@okhdfcbank", "5462", (300, 650), "snack", 0.24),
            ("THIRD WAVE COFFEE GOMTI", "thirdwave@paytm", "5812", (280, 520), "breakfast", 0.18),
            ("THE CHERRY TREE BAKERY", "cherrytree@upi", "5462", (250, 500), "snack", 0.12),
            ("CAPPUCCINO BLAST", "cappuccinoblast@upi", "5812", (400, 850), "dinner", 0.10),
            ("OVERFLOW COFFEE PALASSIO", "overflow@okaxis", "5812", (350, 600), "lunch", 0.08),
        ],
        "tx_frequency_per_week": 6,
    },
    "budget_student": {
        "user_id": "user_budget_student",
        "description": "Street food fan, chai lover & late-night budget diner",
        "primary_merchants": [
            ("SHARMA TEA STALL", "sharmatea@upi", "5814", (30, 80), "snack", 0.30),
            ("ROYAL CAFE BASKET CHAAT", "royalchaat@paytm", "5814", (90, 150), "snack", 0.20),
            ("ROLLSKING INDIRA NAGAR", "rollsking@okaxis", "5814", (80, 160), "dinner", 0.18),
            ("NAINITAL MOMOS GOMTI", "nainitalmomos@upi", "5814", (70, 140), "dinner", 0.14),
            ("NBC NOTHING BEFORE COFFEE", "nbc@paytm", "5814", (70, 130), "snack", 0.10),
            ("DOMINOS PIZZA HAZRATGANJ", "dominos@icici", "5814", (150, 250), "dinner", 0.08),
        ],
        "tx_frequency_per_week": 11,
    },
}


def generate_mock_transactions_for_persona(persona_key: str, days: int = 90) -> list[TransactionIn]:
    """Generate realistic UPI food transactions for a given persona over past N days."""
    if persona_key not in PERSONA_PROFILES:
        raise ValueError(f"Unknown persona: {persona_key}. Choose from: {list(PERSONA_PROFILES.keys())}")

    p = PERSONA_PROFILES[persona_key]
    user_id = p["user_id"]
    merchants = p["primary_merchants"]
    freq_per_week = p["tx_frequency_per_week"]

    # Calculate total transactions to generate
    total_tx = int((days / 7.0) * freq_per_week)
    
    now = datetime.now(timezone.utc)
    transactions: list[TransactionIn] = []

    # Unpack merchant distribution
    m_choices = [m for m in merchants]
    m_weights = [m[5] for m in merchants]

    apps = ["Google Pay", "PhonePe", "Paytm UPI", "Cred UPI"]

    for i in range(total_tx):
        # Pick random day in the past N days
        day_offset = random.uniform(0, days)
        tx_date = now - timedelta(days=day_offset)

        # Pick merchant based on weighted affinity
        chosen_m = random.choices(m_choices, weights=m_weights, k=1)[0]
        m_name, vpa, mcc, price_range, typical_meal, _ = chosen_m

        # Set realistic time based on typical meal
        if typical_meal == "breakfast":
            hour = random.randint(7, 10)
            minute = random.randint(0, 59)
        elif typical_meal == "lunch":
            hour = random.randint(12, 14)
            minute = random.randint(0, 59)
        elif typical_meal == "snack":
            hour = random.randint(16, 18)
            minute = random.randint(0, 59)
        elif typical_meal == "dinner":
            hour = random.randint(19, 22)
            minute = random.randint(0, 59)
        else:
            hour = random.randint(11, 21)
            minute = random.randint(0, 59)

        tx_time = tx_date.replace(hour=hour, minute=minute, second=random.randint(0, 59))

        # Amount with slight variance
        base_amount = random.uniform(price_range[0], price_range[1])
        # Weekend boost (people order slightly more on weekends)
        if tx_time.weekday() >= 5:
            base_amount *= random.uniform(1.1, 1.35)

        amount = round(base_amount, 2)
        ref_id = f"UPI{tx_time.strftime('%Y%m%d%H%M')}{random.randint(1000, 9999)}"

        tx = TransactionIn(
            user_id=user_id,
            transaction_time=tx_time,
            amount=amount,
            merchant_name=m_name,
            merchant_id=vpa,
            mcc_code=mcc,
            upi_ref=ref_id,
            payment_app=random.choice(apps),
            raw_description=f"Paid to {m_name} via UPI",
        )
        transactions.append(tx)

    # Sort chronologically
    transactions.sort(key=lambda t: t.transaction_time)
    return transactions

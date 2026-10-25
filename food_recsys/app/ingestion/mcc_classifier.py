"""MCC (Merchant Category Code) Classifier for UPI transactions."""

FOOD_MCC_CODES: dict[str, dict] = {
    "5812": {
        "category": "restaurant",
        "description": "Eating Places and Restaurants (Full Service / Dining)",
        "is_food": True,
    },
    "5814": {
        "category": "fast_food",
        "description": "Fast Food Restaurants / Quick Service",
        "is_food": True,
    },
    "5462": {
        "category": "bakery",
        "description": "Bakeries and Confectioneries",
        "is_food": True,
    },
    "5813": {
        "category": "bar_lounge",
        "description": "Drinking Places, Bars, Taverns, Lounges",
        "is_food": True,
    },
    "5499": {
        "category": "specialty_food",
        "description": "Misc Food Stores, Specialty, Delis, Juice Bars",
        "is_food": True,
    },
    "5441": {
        "category": "confectionery",
        "description": "Candy, Nut, and Confectionery Stores",
        "is_food": True,
    },
}

# Generic aggregator codes that might contain food if merchant name indicates so
AGGREGATOR_MCC_CODES = {"7399", "7299", "8999"}


def is_food_mcc(mcc_code: str) -> bool:
    """Check if an MCC code directly belongs to food and dining."""
    code = str(mcc_code).strip()
    return code in FOOD_MCC_CODES


def get_mcc_category(mcc_code: str) -> str:
    """Get the standard category name for a food MCC code."""
    code = str(mcc_code).strip()
    if code in FOOD_MCC_CODES:
        return FOOD_MCC_CODES[code]["category"]
    return "other"

"""Merchant Resolver: normalizes merchant text, detects cuisines, assigns meal types & price bands."""

import re
from datetime import datetime

# Controlled cuisine taxonomy
CUISINE_KEYWORDS: dict[str, list[str]] = {
    "south_indian": [
        "south indian", "curry leaf", "dosa", "idli", "vada", "sambar", "saravana", "sagar ratna", "udupi", "murugan", 
        "dakshin", "naivedyam", "filter coffee", "sankalp", "swami", "chettinad", "malabar"
    ],
    "biryani": [
        "biryani", "dum biryani", "behrouz", "idris", "bikkgane", "paradise biryani", "hyderabadi biryani"
    ],
    "mughlai": [
        "dastarkhwan", "tundey", "wahid", "naushijaan", "kebab", "galawati", "nihari", "korma", "sheermal", "mughlai", "awadhi", "nawab"
    ],
    "cafe_western": [
        "cafe", "café", "coffee", "roastery", "hazelnut factory", "third wave", "blue tokai", 
        "starbucks", "costa", "barista", "brew", "cappuccino blast", "espresso", "overflow"
    ],
    "bakery": [
        "bakery", "bakehouse", "patisserie", "cake", "pastry", "sourdough", "croissant", 
        "cherry tree", "theobroma", "melting point", "let's bake"
    ],
    "street_food": [
        "basket chaat", "chaat", "pani puri", "golgappa", "samosa", "kachori", "chhole bhature", "roll", 
        "sharma tea", "royal cafe chaat", "tikki", "pav bhaji", "vada pav", "momos"
    ],
    "pizza": [
        "pizza", "domino", "pizza hut", "mojo pizza", "la pinoz", "tossin", "cantiere"
    ],
    "burger": [
        "burger", "mcdonald", "burger king", "wendy", "truffles", "sliders"
    ],
    "chinese_indo": [
        "chinese", "noodle", "fried rice", "manchurian", "dimsum", "wok", "chowmein", 
        "mainland china", "berco"
    ],
    "north_indian_curry": [
        "punjabi", "dhaba", "paneer", "dal makhani", "tadka", "thali", "shudh shakahari", 
        "rasoi", "bhojanalaya", "motimahal", "pind balluchi"
    ],
    "tea_coffee": [
        "chai", "tea stall", "chaayos", "chai point", "tea post", "nothing before coffee", "nbc"
    ],
    "dessert": [
        "ice cream", "gelato", "kulfi", "waffle", "falooda", "natural ice cream", 
        "baskin robbins", "chacoco", "hons"
    ],
    "healthy": [
        "salad", "smoothie", "fresh factory", "subway", "bowl", "house of no sugar", "fit food"
    ],
    "italian": [
        "pasta", "risotto", "italian", "trattoria"
    ],
}


def normalize_merchant_name(raw_name: str) -> str:
    """Clean and standardize merchant name from UPI descriptor."""
    if not raw_name:
        return "Unknown Food Outlet"
    
    name = raw_name.upper().strip()
    # Strip common UPI prefixes/suffixes
    name = re.sub(r'^(UPI[-/]|PAYTM[-/]|GPAY[-/]|PHONEPE[-/]|BHIM[-/])', '', name)
    name = re.sub(r'(@[A-Z0-9.-]+)', '', name)  # strip @vpa
    name = re.sub(r'[-_/\\]', ' ', name)
    name = re.sub(r'\s+', ' ', name).strip()
    return name.title() if name else "Unknown Outlet"


# Pre-sorted list of (keyword, cuisine) by length descending for greedy match
_SORTED_KEYWORD_PAIRS = sorted(
    [(kw, cuisine) for cuisine, keywords in CUISINE_KEYWORDS.items() for kw in keywords],
    key=lambda x: len(x[0]),
    reverse=True,
)


def detect_cuisine(
    merchant_name: str, 
    raw_description: str | None = None,
    amount: float | None = None,
    meal_type: str | None = None,
) -> str:
    """Infer the primary cuisine from the merchant name and description.
    
    Adheres strictly to AGENTS.md Principle 4: 'Unknown facts remain unknown.'
    Does NOT speculate cuisine based on meal timing (e.g. morning != south_indian,
    late_night != burger) or transaction amount (e.g. > Rs 600 != biryani).
    Does NOT default unknown merchants to 'street_food' or generic words to 'north_indian_curry'.
    Returns 'unspecified' when specific dish or cuisine indicators are absent.
    """
    text = f"{merchant_name} {raw_description or ''}".lower()
    
    # Priority matching: longer, more specific keywords match first with word boundaries
    for kw, cuisine in _SORTED_KEYWORD_PAIRS:
        if re.search(r'\b' + re.escape(kw) + r'\b', text):
            return cuisine
                
    # Explicit culinary category keywords
    if "cafe" in text or "coffee" in text or "espresso" in text:
        return "cafe_western"
    if "bakery" in text or "bake" in text or "cake" in text or "pastry" in text:
        return "bakery"
    if "pizza" in text or "pizzeria" in text:
        return "pizza"
    if "burger" in text:
        return "burger"
    if "biryani" in text:
        return "biryani"
    if "dosa" in text or "idli" in text or "vada" in text:
        return "south_indian"
    if "chaat" in text:
        return "street_food"
    if "waffle" in text or "ice cream" in text or "gelato" in text or "kulfi" in text:
        return "dessert"
    if "chai" in text or "tea stall" in text:
        return "tea_coffee"
    if "noodle" in text or "dimsum" in text or "momo" in text:
        return "chinese_indo"

    # When no specific dish or cuisine is mentioned, the cuisine is unknown/unspecified.
    return "unspecified"


def determine_meal_type(dt: datetime) -> str:
    """Determine meal category based on the hour of the transaction."""
    hour = dt.hour + (dt.minute / 60.0)
    
    if 5.0 <= hour < 11.0:
        return "breakfast"
    elif 11.0 <= hour < 15.5:
        return "lunch"
    elif 15.5 <= hour < 18.5:
        return "snack"
    elif 18.5 <= hour < 23.5:
        return "dinner"
    else:
        return "late_night"


def determine_price_band(amount: float) -> str:
    """Determine price band from transaction amount."""
    if amount <= 150.0:
        return "budget"
    elif amount <= 400.0:
        return "moderate"
    elif amount <= 800.0:
        return "premium"
    else:
        return "luxury"

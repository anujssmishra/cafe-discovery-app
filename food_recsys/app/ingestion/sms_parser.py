"""SMS Parser: extracts structured UPI transaction details strictly for food & dining alerts.
Filters out non-food bank debits (credit cards, loans, failed txs, e-commerce, investments, travel).
"""

import hashlib
import re
from datetime import datetime, timezone
from dataclasses import dataclass
from zoneinfo import ZoneInfo
from app.schemas.transaction import TransactionIn
from app.ingestion.merchant_resolver import normalize_merchant_name, detect_cuisine

@dataclass
class ParsedSms:
    amount: float
    merchant_name: str
    merchant_id: str | None
    transaction_time: datetime
    upi_ref: str | None
    bank_app: str
    raw_text: str
    time_precision: str = "exact"
    cuisine: str = "unspecified"
    source_id: str | None = None


MAX_FOOD_AMOUNT_INR = 15000.0  # Cap on personal food/dining: orders > Rs 15,000 are not everyday meals
MIN_FOOD_AMOUNT_INR = 10.0     # Reject micro pings / 1-rupee checks

# Common Indian Banks and Apps
BANK_APP_PATTERNS = [
    (r"\bHDFC\b", "HDFC Bank"),
    (r"\bSBI\b|State Bank", "SBI"),
    (r"\bICICI\b", "ICICI Bank"),
    (r"\bAxis\b", "Axis Bank"),
    (r"\bKotak\b", "Kotak Bank"),
    (r"\bIndus\b|\bIndusInd\b", "IndusInd Bank"),
    (r"\bCanara\b", "Canara Bank"),
    (r"\bPNB\b|Punjab National", "PNB"),
    (r"\bBOB\b|Bank of Baroda", "Bank of Baroda"),
    (r"\bSwiggy\b", "Swiggy"),
    (r"\bZomato\b", "Zomato"),
    (r"\bZepto\b", "Zepto"),
    (r"\bBlinkit\b", "Blinkit"),
    (r"\bEatSure\b", "EatSure"),
    (r"\bDomino\b", "Domino's"),
    (r"\bGoogle Pay\b|\bGPay\b", "Google Pay"),
    (r"\bPhonePe\b", "PhonePe"),
    (r"\bPaytm\b", "Paytm"),
]

# Verified food platforms and national / regional restaurant brands
FOOD_PLATFORMS = {
    "swiggy", "zomato", "zepto", "blinkit", "eatsure", "domino", "kfc",
    "pizza hut", "mcdonald", "burger king", "subway", "starbucks", "chai point",
    "chaayos", "haldiram", "bikanervala", "theobroma", "hazelnut", "blue tokai",
    "third wave", "thirdwave", "chelvies", "cafe coffee day", "roastery", "dastarkhwan",
    "royal cafe", "sagar ratna", "belgian waffle", "coffeeangel", "naico", "terracotta",
    "magicpin", "costa coffee", "barista", "gossip n bite", "mio marito", "vendiman",
    "dunkin", "sweet shop", "sweetshop", "mithai", "canteen", "moti mahal"
}

# Generic food / dining keywords that qualify a merchant as food
FOOD_KEYWORDS = {
    "cafe", "café", "coffee", "roaster", "roastery", "restaurant", "dhaba", "bakery",
    "bakes", "patisserie", "sweets", "sweetshop", "chaat", "bistro", "kitchen",
    "dining", "pizzeria", "pizza", "burger", "tea", "chai", "brewery", "gelato",
    "waffle", "dosa", "biryani", "kebab", "tandoor", "foodworks",
    "shawarma", "barbeque", "bbq", "eatery", "food", "rolls", "thali", "curry", "diner",
    "mahal", "rasoi", "bhojanalaya", "mithai", "canteen", "snack", "snacks", "bite", "bites",
    "vendiman", "belgian", "cream", "icecream", "chole", "kulche", "pav", "paratha"
}

# Non-food patterns in SMS text
SMS_BODY_EXCLUSIONS = {
    "failed", "declined", "insufficient balance", "unsuccessful", "reversed",
    "credit card", "sbi card", "fastag", "toll plaza", "mutual fund", "mandate for",
    "auto debit mandate", "statement generated"
}

# Non-food merchant names/brands
MERCHANT_EXCLUSIONS = {
    "cred", "cred club", "billdesk", "cheq", "onecard", "sbi card", "hdfc card", "axis card",
    "amazon", "amaz", "flipkart", "myntra", "meesho", "nykaa", "uber", "ola", "rapido",
    "irctc", "makemytrip", "goibibo", "indigo", "airtel", "jio", "vodafone", "vi", "bsnl",
    "fastag", "toll", "hpcl", "bpcl", "iocl", "petrol", "fuel", "dispute", "insufficient balance",
    "food merchant", "upi food merchant", "process the auto debit", "pack benefits", "gift card",
    "giftcard", "lic", "policybazaar", "zerodha", "groww", "investment", "grofers"
}

# Month map for date parsing e.g. Oct -> 10
MONTH_MAP = {
    "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
    "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12
}


def _extract_amount(text: str) -> float | None:
    """Extract payment amount in INR from text."""
    currency = r"(?:Rs\.?|INR|\u20B9)\s*([0-9,]+(?:\.[0-9]{1,2})?)"
    # Prefer the amount next to payment/debit wording, not the available balance or a discount.
    patterns = [
        r"(?:sent|paid|spent|payment(?:\s+of)?|debited\s*(?:by|for|with)?)\s*" + currency,
        currency + r"\s+(?:has\s+been\s+)?(?:was\s+)?(?:debited|paid|spent)",
        currency,
    ]
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                return float(match.group(1).replace(",", ""))
            except ValueError:
                continue

    # Alternative: "debited for/by 340.00"
    m2 = re.search(r"debited (?:by|for|with)\s*(?:Rs\.?|INR|\u20B9)?\s*([0-9,]+(?:\.[0-9]{1,2})?)", text, re.IGNORECASE)
    if m2:
        try:
            return float(m2.group(1).replace(",", ""))
        except ValueError:
            pass
            
    return None


def _extract_upi_ref(text: str) -> str | None:
    """Extract UPI reference/RRN number."""
    m = re.search(r"(?:UPI Ref(?: no)?|Ref(?: no|erence)?|RRN)[:\s]+([A-Za-z0-9]+)", text, re.IGNORECASE)
    if m:
        return m.group(1).strip()
    return None


def _extract_bank_app(text: str) -> str:
    """Identify the source bank or UPI app from SMS."""
    for pattern, name in BANK_APP_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            return name
    return "UPI"


def _extract_date(text: str, fallback_time: datetime | None = None) -> datetime:
    """Read local bank date/time; retain a provided SMS receipt instant as fallback."""
    zone = ZoneInfo("Asia/Kolkata")
    now = fallback_time or datetime.now(zone)
    now = now.replace(tzinfo=zone) if now.tzinfo is None else now.astimezone(zone)
    dt = now
    date_patterns = [
        r"\b(\d{1,2})[-/]([A-Za-z]{3})[-/](\d{2,4})\b",
        r"\b(\d{1,2})([A-Za-z]{3})(\d{2,4})\b",
        r"\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b",
    ]
    for pattern in date_patterns:
        match = re.search(pattern, text)
        if not match:
            continue
        day, month, year = match.groups()
        month_number = MONTH_MAP.get(month.lower()) if month.isalpha() else int(month)
        if month_number is None:
            continue
        try:
            dt = now.replace(year=int(year) + (2000 if len(year) == 2 else 0), month=month_number, day=int(day))
            break
        except ValueError:
            continue
    clock = re.search(r"\b(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?\b", text, re.IGNORECASE)
    if clock:
        hour, minute, second, period = clock.groups()
        hour = int(hour)
        if period:
            if not 1 <= hour <= 12:
                return dt
            hour = hour % 12 + (12 if period.upper() == "PM" else 0)
        try:
            dt = dt.replace(hour=hour, minute=int(minute), second=int(second or 0), microsecond=0)
        except ValueError:
            pass
    return dt


def _time_precision(text: str, fallback: datetime | None) -> str:
    if fallback is not None or re.search(r"\b\d{1,2}:\d{2}(?::\d{2})?\b", text):
        return "exact"
    if re.search(r"\b\d{1,2}(?:[-/]?[A-Za-z]{3}[-/]?|[-/]\d{1,2}[-/])\d{2,4}\b", text):
        return "date"
    return "unknown"


def _has_keyword(text: str, keyword: str) -> bool:
    # Word boundaries prevent tea/roll/cream from matching Steam/Controller/Screaming.
    return re.search(r"(?<!\w)" + re.escape(keyword) + r"(?:s|'s)?(?!\w)", text, re.IGNORECASE) is not None


def _extract_merchant_and_vpa(text: str) -> tuple[str | None, str | None]:
    """Extract candidate merchant name and VPA from text."""
    vpa = None
    merchant = None

    # 0. Check food delivery app specific restaurant patterns: e.g. "order from <Restaurant>", "meal from <Restaurant>"
    m_food = re.search(
        r"(?:order\s+(?:from|at)|meal\s+(?:from|at)|confirmed\s+at)\s+([A-Za-z0-9\s&'.-]{2,40}?)(?:\s+(?:of|worth|\(|for|\!|\.|\,)|$)",
        text,
        re.IGNORECASE,
    )
    if m_food:
        candidate = m_food.group(1).strip()
        if candidate and len(candidate) > 2 and not re.match(r"^(?:Rs\.?|INR|\u20B9|\d+)", candidate, re.IGNORECASE):
            merchant = candidate

    # 1. Check for UPI handle: e.g. "UPI:THE HAZELNUT FACTORY@okhdfcbank"
    if not merchant:
        upi_vpa_match = re.search(r"\bUPI:([A-Za-z0-9\s_.-]+@[A-Za-z0-9.-]+)\b", text, re.IGNORECASE)
        if upi_vpa_match:
            vpa = upi_vpa_match.group(1).strip()
            merchant = vpa.split("@")[0].strip()
        else:
            vpa_match = re.search(r"\b([A-Za-z0-9_.-]+@[A-Za-z0-9.-]+)\b", text)
            if vpa_match:
                vpa = vpa_match.group(1)

    # 2. Match "UPI:<MERCHANT> Ref:" (when no @vpa)
    if not merchant:
        m_upi = re.search(r"\bUPI:([A-Za-z0-9\s&'.-]+?)(?:@[A-Za-z0-9.-]+|Ref|\.|\,|$)", text, re.IGNORECASE)
        if m_upi:
            candidate = m_upi.group(1).strip()
            if candidate and len(candidate) > 2 and not re.match(r"^(?:Rs\.?|INR|\u20B9|\d+)", candidate, re.IGNORECASE):
                merchant = candidate

    # 3. Match "towards UPI/<MERCHANT>/..."
    if not merchant:
        m1 = re.search(r"towards\s+UPI/([^/]+)/", text, re.IGNORECASE)
        if m1:
            merchant = m1.group(1).strip()

    # 4. Search for "by <MERCHANT>" or "to <MERCHANT>" or "at <MERCHANT>"
    if not merchant:
        for m in re.finditer(r"\b(?:by|paid to|sent to|\bto|\bat)\s+([A-Za-z0-9\s&'.-]{2,40}?)\s*(?:\(UPI|\bvia\b|\bon\b|\bRef\b|\.|\,|$)", text, re.IGNORECASE):
            cand = m.group(1).strip()
            if re.match(r"^(?:Rs\.?|INR|\u20B9|\d+|A/c|VPA|Bal)", cand, re.IGNORECASE):
                continue
            if len(cand) > 2:
                merchant = cand
                break

    # Clean artifacts
    if merchant:
        merchant = re.sub(r"\b(UPI|Ref|A/c|Acct|Bank|from|successful|on|Not you|ending with|via)\b", "", merchant, flags=re.IGNORECASE).strip()
        merchant = re.sub(r"[-_/\\]", " ", merchant).strip()
        merchant = re.sub(r"\s+", " ", merchant)
        merchant = merchant.rstrip(".,;: ")
        if not merchant or len(merchant) < 2:
            merchant = None

    return merchant, vpa


def is_genuine_food_transaction(text: str, merchant: str | None, amount: float) -> bool:
    """Strictly verify if a transaction is a genuine food/dining expense."""
    # 1. Sanity Check Amount Bounds (Reject > Rs 15,000 like 140,000 or 150,000 non-food debits)
    if amount < MIN_FOOD_AMOUNT_INR or amount > MAX_FOOD_AMOUNT_INR:
        return False

    lower_text = text.lower()
    merchant_lower = (merchant or "").lower().strip()

    # 2. Rejection of failed or credit card/financial SMS patterns using word boundaries
    for ex in SMS_BODY_EXCLUSIONS:
        if re.search(r'\b' + re.escape(ex) + r'\b', lower_text):
            return False

    # 3. Rejection of non-food merchant names (Amazon, CRED, Fastag, etc.)
    for ex in MERCHANT_EXCLUSIONS:
        if re.search(r'\b' + re.escape(ex) + r'\b', merchant_lower) or merchant_lower == ex:
            return False

    # 4. Positive Food Verification: Must match food platform or dining keyword
    combined = f"{lower_text} {merchant_lower}"
    has_platform = any(_has_keyword(combined, p) for p in FOOD_PLATFORMS)
    has_food_keyword = any(_has_keyword(combined, k) for k in FOOD_KEYWORDS)

    if has_platform or has_food_keyword:
        return True

    return False


def parse_sms(sms_text: str, default_date: datetime | None = None) -> ParsedSms | None:
    """Parse a single transactional SMS alert into a structured ParsedSms object strictly for food/dining."""
    clean_text = sms_text.strip()
    if not clean_text:
        return None

    lower = clean_text.lower()

    # Reject credits, refunds, salaries
    if any(kw in lower for kw in ["credited", "credit with", "salary", "refund", "received from", "deposited"]):
        return None

    # Must be debit or food app order confirmation
    is_food_app = any(_has_keyword(lower, app) for app in FOOD_PLATFORMS)
    is_debit = any(kw in lower for kw in ["sent", "debited", "paid", "payment", "spent", "txn"]) or (
        is_food_app and any(kw in lower for kw in ["order", "worth", "placed", "delivered", "confirmed", "meal"])
    )
    if not is_debit:
        return None

    amount = _extract_amount(clean_text)
    if not amount or amount <= 0:
        return None

    merchant_name, merchant_vpa = _extract_merchant_and_vpa(clean_text)

    # If food app alert with no restaurant specified, default to the platform name
    if not merchant_name and is_food_app:
        for app in ["swiggy", "zomato", "zepto", "blinkit", "eatsure", "domino", "kfc", "mcdonald", "burger king"]:
            if _has_keyword(lower, app):
                merchant_name = app.title()
                break

    # Strictly verify transaction is genuine food/dining (rejects Cred Club, 1.4L Axis debits, Insufficient Balance, etc.)
    if not is_genuine_food_transaction(clean_text, merchant_name, amount):
        return None

    if not merchant_name:
        return None

    clean_name = normalize_merchant_name(merchant_name)
    tx_time = _extract_date(clean_text, default_date)
    upi_ref = _extract_upi_ref(clean_text)
    bank_app = _extract_bank_app(clean_text)

    return ParsedSms(
        amount=amount,
        merchant_name=clean_name,
        merchant_id=merchant_vpa,
        transaction_time=tx_time,
        upi_ref=upi_ref,
        bank_app=bank_app,
        raw_text=clean_text,
        time_precision=_time_precision(clean_text, default_date),
        cuisine=detect_cuisine(clean_name, clean_text),
        source_id="sms:" + hashlib.sha256((clean_text + (default_date.isoformat() if default_date else "")).encode()).hexdigest(),
    )


def sms_to_transaction_in(parsed: ParsedSms, user_id: str) -> TransactionIn:
    """Convert a ParsedSms into a standard TransactionIn model with strict PII protection."""
    safe_desc = f"SMS ({parsed.bank_app}): Paid Rs {parsed.amount:.2f} to {parsed.merchant_name}"
    return TransactionIn(
        user_id=user_id,
        transaction_time=parsed.transaction_time,
        amount=parsed.amount,
        merchant_name=parsed.merchant_name,
        merchant_id=parsed.merchant_id,
        mcc_code="5812",
        upi_ref=parsed.upi_ref,
        payment_app=parsed.bank_app,
        raw_description=safe_desc[:500],
        source_id=parsed.source_id,
        time_precision=parsed.time_precision,
        cuisine=parsed.cuisine,
    )


def parse_sms_batch(
    sms_list: list[str | tuple[str, datetime | None]], 
    user_id: str
) -> list[TransactionIn]:
    """Parse a batch of raw SMS strings (or tuple of (text, timestamp)) into a list of TransactionIn objects."""
    results: list[TransactionIn] = []
    for item in sms_list:
        if isinstance(item, tuple):
            text, dt = item
        else:
            text, dt = item, None
        parsed = parse_sms(text, default_date=dt)
        if parsed:
            results.append(sms_to_transaction_in(parsed, user_id))
    return results

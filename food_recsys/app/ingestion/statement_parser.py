"""Bank Statement CSV Parser: extracts UPI food transactions from bank statement CSV files."""

import csv
import hashlib
import json
import io
import re
from datetime import datetime
from zoneinfo import ZoneInfo
from app.schemas.transaction import TransactionIn, IngestOutcome
from app.ingestion.sms_parser import is_genuine_food_transaction

# Common non-food financial narrations to exclude
EXCLUDED_NARRATIONS = [
    "salary", "interest", "dividend", "zerodha", "groww", "mutual fund", "sip", 
    "atm cash", "atm wdl", "cash wdl", "card bill", "credit card", "loan", 
    "neft cr", "rtgs cr", "imps cr", "refund", "reversal", "tax"
]

# Date format candidates
DATE_FORMATS = [
    "%d/%m/%Y", "%d-%m-%Y", "%d/%m/%y", "%d-%m-%y",
    "%Y-%m-%d", "%d-%b-%Y", "%d-%b-%y", "%d %b %Y", "%d %b %y",
]


def _parse_amount(val: str | None) -> float | None:
    """Parse amount string (handles commas, currency symbols, and Cr/Dr tags)."""
    if not val:
        return None
    clean = re.sub(r"[^\d.-]", "", val.replace(",", "")).strip()
    try:
        amt = float(clean)
        return amt if amt > 0 else None
    except ValueError:
        return None


def _parse_date(date_str: str | None) -> datetime | None:
    """Parse Indian local dates; an invalid date must never become today's purchase."""
    if not date_str:
        return None
    clean = date_str.strip()
    zone = ZoneInfo("Asia/Kolkata")
    try:
        dt = datetime.fromisoformat(clean.replace("Z", "+00:00"))
        return dt.replace(tzinfo=zone) if dt.tzinfo is None else dt.astimezone(zone)
    except ValueError:
        pass
    for fmt in DATE_FORMATS:
        for suffix in (" %H:%M:%S", " %H:%M", " %I:%M %p", ""):
            try:
                return datetime.strptime(clean, fmt + suffix).replace(tzinfo=zone)
            except ValueError:
                continue
    return None


def _extract_merchant_from_narration(narration: str) -> tuple[str, str | None, str | None]:
    """Extract clean merchant name, VPA, and UPI ref from bank narration line."""
    clean = narration.strip()
    vpa = None
    upi_ref = None

    # Check for VPA
    vpa_match = re.search(r"\b([A-Za-z0-9_.-]+@[A-Za-z0-9.-]+)\b", clean)
    if vpa_match:
        vpa = vpa_match.group(1)

    # Check for 12-digit UPI reference number
    ref_match = re.search(r"\b(\d{12})\b", clean)
    if ref_match:
        upi_ref = ref_match.group(1)

    # Patterns like UPI-MERCHANT-VPA-REF
    if clean.upper().startswith("UPI"):
        # Split on delimiter (- or /)
        parts = [p.strip() for p in re.split(r"[-/]", clean) if p.strip()]
        # Skip "UPI" prefix
        meaningful = [p for p in parts if p.upper() != "UPI" and not re.match(r"^\d{12}$", p) and "@" not in p and p.upper() not in ["PAYMENT", "DR", "CR"]]
        if meaningful:
            merchant = meaningful[0]
        elif vpa:
            merchant = vpa.split("@")[0].replace(".", " ").replace("-", " ")
        else:
            merchant = clean
    elif clean.upper().startswith("POS"):
        # POS merchant e.g. "POS 429812456789 ROASTERY COFFEE HOUSE"
        sub = re.sub(r"^POS\s+(?:\d+\s+)?", "", clean, flags=re.IGNORECASE)
        merchant = sub
    else:
        # Fallback to general text
        merchant = clean

    # Clean merchant name
    merchant = re.sub(r"\b(UPI|POS|NEFT|IMPS|PAYMENT|CR|DR|REF)\b", "", merchant, flags=re.IGNORECASE)
    merchant = re.sub(r"[-_/\\]", " ", merchant).strip()
    merchant = re.sub(r"\s+", " ", merchant)
    return merchant.title() if merchant else "Food Merchant", vpa, upi_ref


def parse_statement_csv(
    csv_content: str, user_id: str, rejections: list[IngestOutcome] | None = None,
) -> list[TransactionIn]:
    """Parse bank statement CSV and extract debit food transactions."""
    transactions: list[TransactionIn] = []
    
    # Read rows
    f = io.StringIO(csv_content.strip())
    reader = csv.reader(f)
    rows = [r for r in reader if any(cell.strip() for cell in r)]
    
    if not rows:
        return []

    # 1. Identify header row
    header_idx = -1
    date_col = -1
    narration_col = -1
    debit_col = -1

    for idx, row in enumerate(rows[:15]):  # Search within top 15 rows for headers
        row_lower = [c.strip().lower() for c in row]
        for c_idx, cell in enumerate(row_lower):
            if any(k in cell for k in ["date", "txn date", "value date", "post date"]):
                date_col = c_idx
            if any(k in cell for k in ["narration", "description", "particulars", "remarks"]):
                narration_col = c_idx
            if any(k in cell for k in ["debit", "withdrawal", "dr amount", "dr (inr)"]):
                debit_col = c_idx
        
        if date_col != -1 and narration_col != -1 and debit_col != -1:
            header_idx = idx
            break

    # If standard header not found, fallback to common column positions: Date (0), Narration (1), Debit (2)
    if header_idx == -1:
        header_idx = 0
        date_col = 0
        narration_col = 1
        debit_col = 2

    # 2. Parse data rows
    for row in rows[header_idx + 1:]:
        source_id = "statement:" + hashlib.sha256(json.dumps(row, separators=(",", ":")).encode()).hexdigest()

        def reject(reason: str) -> None:
            if rejections is not None:
                rejections.append(IngestOutcome(source_id=source_id, status="rejected", reason=reason))

        if len(row) <= max(date_col, narration_col, debit_col):
            reject("invalid_row")
            continue

        narration = row[narration_col].strip()
        if not narration:
            reject("missing_merchant")
            continue

        # Check for non-food exclusions
        narr_lower = narration.lower()
        if any(re.search(r"\b" + re.escape(exc) + r"\b", narr_lower) for exc in EXCLUDED_NARRATIONS):
            reject("not_food")
            continue

        # Extract amount
        debit_val = row[debit_col].strip()
        amount = _parse_amount(debit_val)
        if not amount or amount <= 0:
            reject("not_debit")
            continue

        # Extract date
        date_val = row[date_col].strip()
        tx_time = _parse_date(date_val)
        if tx_time is None:
            reject("invalid_timestamp")
            continue

        # Extract merchant
        merchant, vpa, upi_ref = _extract_merchant_from_narration(narration)
        if not is_genuine_food_transaction(narration, merchant, amount):
            reject("not_food")
            continue

        tx = TransactionIn(
            user_id=user_id,
            transaction_time=tx_time,
            amount=amount,
            merchant_name=merchant,
            merchant_id=vpa,
            mcc_code="5812",
            upi_ref=upi_ref,
            payment_app="Statement Upload",
            raw_description=f"Statement: Paid Rs {amount:.2f} to {merchant}"[:500],
            source_id=source_id,
            time_precision="exact" if re.search(r"\b\d{1,2}:\d{2}", date_val) else "date",
        )
        transactions.append(tx)

    return transactions

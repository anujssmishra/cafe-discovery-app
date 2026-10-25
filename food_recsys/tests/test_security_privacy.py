import io
import pytest
from app.ingestion.sms_parser import parse_sms, sms_to_transaction_in
from app.ingestion.statement_parser import parse_statement_csv


def test_sms_pii_redaction_in_description():
    """Verify that sensitive bank account numbers and raw text are not leaked into the stored description."""
    sensitive_sms = "Sent Rs.340.00 from HDFC Bank A/C **1234 to ROASTERY COFFEE HOUSE on 24-OCT-26 via UPI Ref 429812456789. Avail Bal: Rs 45,210.00."
    parsed = parse_sms(sensitive_sms)
    assert parsed is not None

    tx_in = sms_to_transaction_in(parsed, user_id="privacy_user")
    
    # Check that account number and balance are NOT stored in raw_description
    assert "**1234" not in tx_in.raw_description
    assert "45,210" not in tx_in.raw_description
    assert "Avail Bal" not in tx_in.raw_description
    assert "Roastery Coffee House" in tx_in.raw_description


def test_statement_pii_redaction_in_description():
    """Verify that statement narration accounts and remarks are clean in description."""
    csv_data = """Date,Narration,Chq/Ref No,Value Dt,Withdrawal Amt,Deposit Amt,Closing Balance
15/10/2026,UPI-ROASTERY-ROASTERY@ICICI-429812456789-A/C 12345678901234,429812456789,15/10/2026,480.00,,45200.00
"""
    txs = parse_statement_csv(csv_data, user_id="privacy_user")
    assert len(txs) == 1
    # Check that account number is not in description
    assert "12345678901234" not in txs[0].raw_description
    assert txs[0].raw_description == "Statement: Paid Rs 480.00 to Roastery"


@pytest.mark.asyncio
async def test_invalid_user_id_rejected_by_api(client):
    """Verify that injection or control characters in user_id are rejected."""
    # Attempt path traversal or script in user_id
    res = await client.get("/api/v1/profile/user%3Cscript%3E")
    assert res.status_code in [400, 422]

    # Attempt spaces / invalid characters
    res_rec = await client.get("/api/v1/recommend/user%20name%20invalid")
    assert res_rec.status_code in [400, 422]


@pytest.mark.asyncio
async def test_file_size_limit_on_statement_upload(client):
    """Verify that oversized file uploads are rejected with 413 Payload Too Large."""
    # Create 6MB of dummy CSV data (exceeds 5MB limit)
    large_csv = "Date,Narration,Debit\n" + ("15/10/2026,UPI-TEST-TEST@UPI,100.00\n" * 180000)
    files = {"file": ("large_statement.csv", large_csv, "text/csv")}
    data = {"user_id": "test_upload_user"}

    res = await client.post("/api/v1/ingest/statement", data=data, files=files)
    assert res.status_code == 413
    assert "too large" in res.json()["detail"].lower()


@pytest.mark.asyncio
async def test_security_headers_present(client):
    """Verify standard OWASP security headers are present on API responses."""
    res = await client.get("/health")
    assert res.status_code == 200
    assert res.headers.get("X-Content-Type-Options") == "nosniff"
    assert res.headers.get("X-Frame-Options") == "DENY"
    assert res.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert "camera=()" in res.headers.get("Permissions-Policy", "")


@pytest.mark.asyncio
async def test_batch_size_cap_enforced(client):
    """Verify that batch payloads exceeding 1000 items are rejected with 422."""
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()
    # Construct 1001 transactions
    oversized_list = [
        {"user_id": "test_user", "transaction_time": now, "amount": 100.0, "merchant_name": "Test Cafe"}
        for _ in range(1001)
    ]
    res = await client.post("/api/v1/ingest", json={"transactions": oversized_list})
    assert res.status_code == 422

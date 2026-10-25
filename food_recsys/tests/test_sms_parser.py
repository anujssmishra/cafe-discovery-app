import pytest
from datetime import datetime, timezone
from app.ingestion.sms_parser import parse_sms, parse_sms_batch


def test_parse_hdfc_sms():
    sms = "Sent Rs.340.00 from HDFC Bank A/C **1234 to ROASTERY COFFEE HOUSE on 24-OCT-26 via UPI Ref 429812456789. Not you? Call 1800..."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 340.00
    assert "Roastery Coffee House" in parsed.merchant_name
    assert parsed.bank_app == "HDFC Bank"
    assert parsed.upi_ref == "429812456789"
    assert parsed.transaction_time.day == 24
    assert parsed.transaction_time.month == 10
    assert parsed.transaction_time.year == 2026


def test_parse_sbi_sms():
    sms = "Dear SBI UPI User, your A/c ending with 5678 debited by Rs.120.00 on 24Oct26 by SAGAR RATNA (UPI Ref no 429812112233)"
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 120.00
    assert "Sagar Ratna" in parsed.merchant_name
    assert parsed.bank_app == "SBI"
    assert parsed.upi_ref == "429812112233"
    assert parsed.transaction_time.day == 24
    assert parsed.transaction_time.month == 10


def test_parse_icici_sms():
    sms = "ICICI Bank Acct XX789 debited with Rs 450.00 on 24-Oct-26. UPI:THE HAZELNUT FACTORY@okhdfcbank. Ref:429899001122."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 450.00
    assert "The Hazelnut Factory" in parsed.merchant_name
    assert parsed.merchant_id == "THE HAZELNUT FACTORY@okhdfcbank"
    assert parsed.bank_app == "ICICI Bank"
    assert parsed.upi_ref == "429899001122"


def test_parse_axis_sms():
    sms = "Axis Bank: Rs 180.00 debited from A/c XX3456 on 23-10-26 via UPI to CHERRY TREE BAKERY. Ref 429855443322."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 180.00
    assert "Cherry Tree Bakery" in parsed.merchant_name
    assert parsed.bank_app == "Axis Bank"


def test_parse_kotak_sms():
    sms = "Kotak Bank: Rs 90.00 debited from A/c ..9012 on 24-Oct-26 to SHARMA TEA STALL. UPI Ref 429811002233."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 90.00
    assert "Sharma Tea Stall" in parsed.merchant_name
    assert parsed.bank_app == "Kotak Bank"


def test_parse_phonepe_sms():
    sms = "Payment of Rs.280 to Dastarkhwan successful on PhonePe. Ref No: 429844332211."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 280.00
    assert "Dastarkhwan" in parsed.merchant_name
    assert parsed.bank_app == "PhonePe"


def test_parse_gpay_sms():
    sms = "Paid Rs. 350.00 to Third Wave Coffee via Google Pay. UPI Ref: 429877665544."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 350.00
    assert "Third Wave Coffee" in parsed.merchant_name
    assert parsed.bank_app == "Google Pay"


def test_parse_paytm_sms():
    sms = "Rs. 80 paid to Royal Cafe Basket Chaat on Paytm. UPI Ref 429866554433."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 80.00
    assert "Royal Cafe Basket Chaat" in parsed.merchant_name
    assert parsed.bank_app == "Paytm"


def test_ignore_credit_or_spam_sms():
    sms_credit = "Your salary of Rs 75,000.00 credited to A/c **1234 on 01-OCT-26."
    assert parse_sms(sms_credit) is None

    sms_otp = "Your OTP for login is 492102. Do not share with anyone."
    assert parse_sms(sms_otp) is None


def test_parse_sms_batch():
    messages = [
        "Sent Rs.340.00 from HDFC Bank A/C **1234 to ROASTERY COFFEE HOUSE on 24-OCT-26 via UPI Ref 429812456789.",
        "Dear SBI UPI User, your A/c ending with 5678 debited by Rs.120.00 on 24Oct26 by SAGAR RATNA (UPI Ref no 429812112233)",
        "Your OTP for payment is 123456",  # Spam / non-debit
    ]
    txs = parse_sms_batch(messages, user_id="real_user_sms")
    assert len(txs) == 2
    assert txs[0].user_id == "real_user_sms"
    assert txs[0].amount == 340.00
    assert txs[1].amount == 120.00


def test_parse_swiggy_sms():
    sms = "Your Swiggy order from The Belgian Waffle Co of Rs 280 is placed! Track on app."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 280.0
    assert "Belgian Waffle" in parsed.merchant_name
    assert parsed.bank_app == "Swiggy"


def test_parse_zomato_sms():
    sms = "Order placed! Your meal from Dastarkhwan worth Rs 680 is being prepared. Track on Zomato."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 680.0
    assert "Dastarkhwan" in parsed.merchant_name
    assert parsed.bank_app == "Zomato"


def test_parse_indusind_sms():
    sms = "IndusInd Bank: INR 350.00 debited from A/c XX1234 on 24-10-26 to MOTI MAHAL. UPI Ref 429811002299."
    parsed = parse_sms(sms)
    assert parsed is not None
    assert parsed.amount == 350.0
    assert parsed.merchant_name == "Moti Mahal" or "Moti Mahal" in parsed.merchant_name
    assert parsed.bank_app == "IndusInd Bank"


def test_ignore_large_non_food_transfers():
    # Flaw reported by user: 140000 and 150000 marked as food
    sms_large_transfer = "Axis Bank: Paid Rs 140000.00 to Investment Fund on 20-OCT-26 via UPI. Ref 998877."
    assert parse_sms(sms_large_transfer) is None

    sms_failed_150k = "Axis Bank: Transaction of Rs 150000.00 failed due to Insufficient Balance on 18-OCT-26."
    assert parse_sms(sms_failed_150k) is None

    sms_cred = "SMS (SBI): Paid Rs 162398.00 to Cred Club on 15-OCT-26 via UPI Ref 112233."
    assert parse_sms(sms_cred) is None


def test_ignore_credit_card_and_failed_alerts():
    sms_cc = "Dear Customer, Rs 12,450.00 debited from A/c for your SBI Credit Card ending 5127."
    assert parse_sms(sms_cc) is None

    sms_dispute = "SMS (IndusInd Bank): Paid Rs 442.00 to Dispute. In case of dispute call 1800."
    assert parse_sms(sms_dispute) is None

    sms_mandate = "Axis Bank: To process the auto debit of Rs 59.00 for mandate 12345."
    assert parse_sms(sms_mandate) is None


def test_ignore_e_commerce_and_travel_and_telecom():
    sms_amazon = "SBI: Paid INR 723.00 at Amaz on 12-OCT-26 via UPI."
    assert parse_sms(sms_amazon) is None

    sms_fastag = "Rs 500.00 debited for SBI Fastag NETC Toll Plaza."
    assert parse_sms(sms_fastag) is None

    sms_recharge = "Paid Rs 2999.00 for Airtel. Check Pack Benefits on Airtel Thanks app."
    assert parse_sms(sms_recharge) is None


def test_ignore_p2p_person_transfers():
    # Self or peer transfers to individuals without dining context
    sms_p2p = "SMS (SBI): Paid Rs 10000.00 to Anuj S S Mishra via UPI Ref 998811."
    assert parse_sms(sms_p2p) is None

    sms_friend = "Sent Rs 2500.00 to Rashi Goenka on 14-OCT-26 via UPI."
    assert parse_sms(sms_friend) is None



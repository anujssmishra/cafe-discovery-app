import pytest
from app.ingestion.statement_parser import parse_statement_csv


def test_parse_hdfc_style_csv():
    csv_data = """Date,Narration,Chq/Ref No,Value Dt,Withdrawal Amt,Deposit Amt,Closing Balance
15/10/2026,UPI-ROASTERY COFFEE HOUSE-ROASTERY@ICICI-429812456789-PAYMENT,429812456789,15/10/2026,480.00,,45200.00
16/10/2026,SALARY CREDIT FROM ACME CORP,SAL123456,16/10/2026,,85000.00,130200.00
17/10/2026,UPI-THE HAZELNUT FACTORY-HAZELNUT@OKHDFCBANK-429812456790-PAYMENT,429812456790,17/10/2026,350.00,,129850.00
18/10/2026,ZERODHA BROKING MUTUAL FUND SIP,ZER098765,18/10/2026,5000.00,,124850.00
19/10/2026,UPI-SAGAR RATNA-SAGARRATNA@PAYTM-429812456791-PAYMENT,429812456791,19/10/2026,190.00,,124660.00
"""
    txs = parse_statement_csv(csv_data, user_id="user_statement_test")
    
    # Salary and Zerodha SIP should be excluded; only the 3 food/coffee transactions extracted
    assert len(txs) == 3
    assert txs[0].amount == 480.00
    assert "Roastery Coffee House" in txs[0].merchant_name
    assert txs[0].user_id == "user_statement_test"

    assert txs[1].amount == 350.00
    assert "The Hazelnut Factory" in txs[1].merchant_name

    assert txs[2].amount == 190.00
    assert "Sagar Ratna" in txs[2].merchant_name


def test_parse_sbi_style_csv():
    csv_data = """Txn Date,Description,Ref No,Debit,Credit,Balance
20-Oct-2026,UPI/429812456789/IDRIS BIRYANI/CHOWK/PAYTM,429812456789,280.00,,21400.00
21-Oct-2026,ATM CASH WDL S1AN001,ATM987,10000.00,,11400.00
22-Oct-2026,POS 429812456790 THIRD WAVE COFFEE GOMTI,POS4298,220.00,,11180.00
"""
    txs = parse_statement_csv(csv_data, user_id="user_sbi_test")
    
    # ATM Cash withdrawal should be excluded; 2 dining transactions extracted
    assert len(txs) == 2
    assert txs[0].amount == 280.00
    assert "Idris Biryani" in txs[0].merchant_name

    assert txs[1].amount == 220.00
    assert "Third Wave Coffee" in txs[1].merchant_name


def test_empty_or_invalid_csv():
    assert parse_statement_csv("", user_id="empty_test") == []
    assert parse_statement_csv("just some random text without columns", user_id="random_test") == []

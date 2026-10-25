import 'package:flutter_test/flutter_test.dart';
import 'package:food_recsys_mobile/services/on_device_sms_parser.dart';

void main() {
  group('OnDeviceSmsParser Tests', () {
    test('Parses HDFC Bank UPI debit correctly', () {
      const sms = 'Sent Rs.340.00 from HDFC Bank A/C **1234 to ROASTERY COFFEE HOUSE on 24-OCT-26 via UPI Ref 429812456789.';
      final payment = OnDeviceSmsParser.parse(sms);

      expect(payment, isNotNull);
      expect(payment!.amount, equals(340.0));
      expect(payment.bank, equals('HDFC Bank'));
      expect(payment.normalizedMerchant, contains('ROASTERY COFFEE HOUSE'));
      expect(payment.redactedText.contains('**1234'), isFalse);
    });

    test('Parses SBI UPI debit correctly', () {
      const sms = 'Dear SBI UPI User, your A/c ending with 5678 debited by Rs.120.00 on 24Oct26 by SAGAR RATNA (UPI Ref no 429812112233)';
      final payment = OnDeviceSmsParser.parse(sms);

      expect(payment, isNotNull);
      expect(payment!.amount, equals(120.0));
      expect(payment.bank, equals('SBI'));
      expect(payment.normalizedMerchant, contains('SAGAR RATNA'));
    });

    test('Parses ICICI Bank VPA debit correctly', () {
      const sms = 'ICICI Bank Acct XX789 debited with Rs 450.00 on 24-Oct-26. UPI:THE HAZELNUT FACTORY@okhdfcbank. Ref:429899001122.';
      final payment = OnDeviceSmsParser.parse(sms);

      expect(payment, isNotNull);
      expect(payment!.amount, equals(450.0));
      expect(payment.bank, equals('ICICI Bank'));
      expect(payment.normalizedMerchant, contains('THE HAZELNUT FACTORY'));
    });

    test('Parses Swiggy food delivery alert and extracts restaurant', () {
      const sms = 'Your Swiggy order from The Belgian Waffle Co of Rs 280 is placed! Delivery partner arriving soon.';
      final payment = OnDeviceSmsParser.parse(sms);

      expect(payment, isNotNull);
      expect(payment!.amount, equals(280.0));
      expect(payment.bank, equals('Swiggy'));
      expect(payment.normalizedMerchant, contains('Belgian Waffle'));
    });

    test('Parses Zomato food delivery alert and extracts restaurant', () {
      const sms = 'Order placed! Your meal from Dastarkhwan worth Rs 680 is being prepared. Track on Zomato.';
      final payment = OnDeviceSmsParser.parse(sms);

      expect(payment, isNotNull);
      expect(payment!.amount, equals(680.0));
      expect(payment.bank, equals('Zomato'));
      expect(payment.normalizedMerchant, contains('Dastarkhwan'));
    });

    test('Parses IndusInd Bank UPI debit correctly', () {
      const sms = 'IndusInd Bank: INR 350.00 debited from A/c XX1234 on 24-10-26 to MOTI MAHAL. UPI Ref 429811002299.';
      final payment = OnDeviceSmsParser.parse(sms);

      expect(payment, isNotNull);
      expect(payment!.amount, equals(350.0));
      expect(payment.bank, equals('IndusInd Bank'));
      expect(payment.normalizedMerchant, contains('MOTI MAHAL'));
    });

    test('Redacts sensitive PII from alert', () {
      const sms = 'Your A/C ending with 4321 debited by Rs.250.00. Bal: 45,200.00. Call 9876543210 if not done by you.';
      final redacted = OnDeviceSmsParser.redactPii(sms);

      expect(redacted.contains('4321'), isFalse);
      expect(redacted.contains('45,200.00'), isFalse);
      expect(redacted.contains('9876543210'), isFalse);
      expect(redacted.contains('[REDACTED]'), isTrue);
    });

    test('Ignores salary credits and non-debit alerts', () {
      const salarySms = 'Your A/C **1234 has been credited with INR 75,000.00 on 01-Nov-26 by SALARY TRANSFER.';
      final payment = OnDeviceSmsParser.parse(salarySms);

      expect(payment, isNull);
    });

    test('Strictly rejects large financial debits (e.g. 140000 and 150000 reported by user)', () {
      const sms140k = 'Axis Bank: Paid Rs 140000.00 to Food Merchant on 20-OCT-26 via UPI. Ref 998877.';
      expect(OnDeviceSmsParser.parse(sms140k), isNull);

      const sms150kFailed = 'Axis Bank: Transaction of Rs 150000.00 failed due to Insufficient Balance on 18-OCT-26.';
      expect(OnDeviceSmsParser.parse(sms150kFailed), isNull);

      const smsCred = 'SMS (SBI): Paid Rs 162398.00 to Cred Club on 15-OCT-26 via UPI Ref 112233.';
      expect(OnDeviceSmsParser.parse(smsCred), isNull);
    });

    test('Rejects credit card bills, failed alerts, telecom, and non-food merchants', () {
      const ccSms = 'Dear Customer, Rs 12,450.00 debited from A/c for your SBI Credit Card ending 5127.';
      expect(OnDeviceSmsParser.parse(ccSms), isNull);

      const amazonSms = 'SBI: Paid INR 723.00 at Amaz on 12-OCT-26 via UPI.';
      expect(OnDeviceSmsParser.parse(amazonSms), isNull);

      const fastagSms = 'Rs 500.00 debited for SBI Fastag NETC Toll Plaza.';
      expect(OnDeviceSmsParser.parse(fastagSms), isNull);

      const telecomSms = 'Paid Rs 2999.00 for Airtel. Check Pack Benefits on Airtel Thanks app.';
      expect(OnDeviceSmsParser.parse(telecomSms), isNull);

      const p2pSms = 'SMS (SBI): Paid Rs 10000.00 to Anuj S S Mishra via UPI Ref 998811.';
      expect(OnDeviceSmsParser.parse(p2pSms), isNull);
    });
  });
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_recsys_mobile/services/api_service.dart';
import 'package:food_recsys_mobile/services/on_device_sms_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('on-device payment crosses the API boundary without raw SMS', () async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiService(client: MockClient((request) async {
      expect(request.url.path, '/api/v1/ingest/payments');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['schema_version'], 1);
      expect(body['user_id'], 'contract_user');
      final payment = (body['payments'] as List).single as Map;
      expect(payment['merchant_name'], 'Dastarkhwan');
      expect(payment['amount'], 280);
      expect(payment['upi_ref'], '900000123456');
      expect(payment['timezone'], 'Asia/Kolkata');
      expect(payment.containsKey('sms_text'), false);
      expect(payment.containsKey('redacted_text'), false);
      return http.Response(
          jsonEncode({
            'status': 'success',
            'ingested_count': 1,
            'outcomes': [
              {'source_id': payment['source_id'], 'status': 'inserted'}
            ],
          }),
          200);
    }));
    final parsed = OnDeviceSmsParser.parse(
      'Payment of Rs.280 to Dastarkhwan successful on PhonePe. Ref No: 900000123456.',
    )!;
    final response =
        await api.ingestPayments('contract_user', [parsed.toPaymentPayload()]);
    expect(response['ingested_count'], 1);
  });

  test('ledger API preserves opaque cursor and pagination size', () async {
    final api = ApiService(client: MockClient((request) async {
      expect(
          request.url.queryParameters, {'limit': '100', 'cursor': 'opaque+/='});
      return http.Response(
          '{"transactions":[],"total_count":251,"total_spent":25100,"has_more":false}',
          200);
    }));
    final ledger =
        await api.getTransactions('contract_user', cursor: 'opaque+/=');
    expect(ledger['total_count'], 251);
  });

  test('saved server remains selected when disconnected', () async {
    SharedPreferences.setMockInitialValues(
        {'api_base_url': 'http://configured.invalid:8000'});
    final api = ApiService(client: MockClient((request) async {
      fail('Initialization must not replace a configured data source');
    }));
    await api.init();
    expect(api.baseUrl, 'http://configured.invalid:8000');
  });
}

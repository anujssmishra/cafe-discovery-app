import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:food_recsys_mobile/services/api_service.dart';
import 'package:food_recsys_mobile/services/sms_listener_service.dart';
import 'package:food_recsys_mobile/services/payment_import_queue.dart';

class PaymentApi extends ApiService {
  final calls = <List<Map<String, dynamic>>>[];
  bool fail = false;
  String endpoint = 'https://synthetic.invalid';
  final destinations = <String?>[];
  void Function()? afterUpload;
  @override
  String get baseUrl => endpoint;
  String resultStatus = 'inserted';
  @override
  Future<Map<String, dynamic>> ingestPayments(
      String userId, List<Map<String, dynamic>> payments,
      {String? endpoint}) async {
    calls.add(payments);
    destinations.add(endpoint);
    afterUpload?.call();
    if (fail) throw StateError('offline');
    return {
      'outcomes': payments
          .map((p) => {'source_id': p['source_id'], 'status': resultStatus})
          .toList()
    };
  }
}

SmsMessage message(int id, {String? text, String sender = 'PHONEPE'}) =>
    SmsMessage.fromMap({}, [])
      ..id = id
      ..address = sender
      ..body = text ??
          'Payment of Rs.280 to Synthetic Cafe successful on PhonePe. Ref No: ${900000000000 + id}.'
      ..date = DateTime.utc(2026, 10, 24, 18, 45).millisecondsSinceEpoch;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({
        'dpdp_consent_granted': true,
        'api_base_url': 'https://synthetic.invalid'
      }));

  test(
      'registered foreground callback stops capturing after tracking is paused',
      () async {
    final api = PaymentApi();
    late Future<void> Function(SmsMessage) callback;
    final service = SmsListenerService(api,
        requestSmsPermission: () async => true,
        registerListener: (handler) => callback = handler);
    expect(await service.startListening(), true);
    await service.stopListening();
    await callback(message(1));
    expect(api.calls, isEmpty);
    expect(await PaymentImportQueue().pendingCount('user_my_real_data'), 0);
  });

  test(
      'background capture persists safe fields and resumes without raw SMS upload',
      () async {
    final api = PaymentApi();
    final queue = PaymentImportQueue();
    await queue.setTracking(true, 'synthetic-user');
    await queueBackgroundPayment(message(1), queue);
    expect(await queue.pendingCount('synthetic-user'), 1);
    await queue.setTracking(false, 'synthetic-user');
    final service = SmsListenerService(api, queue: queue);
    service.setActiveUserId('synthetic-user');
    final result = await service.resumePendingImports();
    expect(result.ingestedCount, 1);
    final payload = api.calls.single.single;
    expect(payload['merchant_name'], 'Synthetic Cafe');
    expect(payload['timezone'], 'Asia/Kolkata');
    expect(payload['transaction_time'], '2026-10-24T18:45:00.000Z');
    expect(payload.containsKey('text'), false);
    expect(payload.containsKey('sender'), false);
  });

  test(
      'background handler ignores messages after tracking stop or consent withdrawal',
      () async {
    final queue = PaymentImportQueue();
    await queue.setTracking(false, 'synthetic-user');
    await queueBackgroundPayment(message(1), queue);
    await queue.setTracking(true, 'synthetic-user');
    await (await SharedPreferences.getInstance())
        .setBool('dpdp_consent_granted', false);
    await queueBackgroundPayment(message(2), queue);
    expect(await queue.pendingCount('synthetic-user'), 0);
  });

  test(
      'historical scan visits every processing page and resumes from durable checkpoint',
      () async {
    final api = PaymentApi();
    final requestedAfterIds = <int?>[];
    final service = SmsListenerService(api,
        requestSmsPermission: () async => true,
        inboxReader: (afterId) async {
          requestedAfterIds.add(afterId);
          return [
            for (var id = 1; id <= 7; id++)
              if (afterId == null || id > afterId) message(id)
          ];
        });
    final result = await service.scanHistoricalInbox(maxMessages: 3);
    expect(result.totalScanned, 7);
    expect(result.validDiningFound, 7);
    expect(result.ingestedCount, 7);
    expect(result.pendingCount, 0);
    final again = await service.scanHistoricalInbox(maxMessages: 3);
    expect(again.totalScanned, 0);
    expect(requestedAfterIds, [null, 7]);
  });

  test('a dining alert beyond 5000 non-food messages is imported', () async {
    final api = PaymentApi();
    final service = SmsListenerService(api,
        requestSmsPermission: () async => true,
        inboxReader: (_) async => [
              for (var id = 1; id <= 5000; id++)
                message(id, text: 'Synthetic appointment reminder.'),
              message(5001),
            ]);
    final result = await service.scanHistoricalInbox();
    expect(result.totalScanned, 5001);
    expect(result.validDiningFound, 1);
    expect(result.ingestedCount, 1);
    expect(result.pendingCount, 0);
  });

  test(
      'failed chunks remain durable; successful retries acknowledge actual outcomes',
      () async {
    final api = PaymentApi()..fail = true;
    final service = SmsListenerService(api,
        requestSmsPermission: () async => true,
        inboxReader: (_) async => [message(1), message(2)]);
    final failed = await service.scanHistoricalInbox();
    expect(failed.totalScanned, 2);
    expect(failed.validDiningFound, 2);
    expect(failed.ingestedCount, 0);
    expect(failed.pendingCount, 2);
    expect(failed.error, isNotNull);
    api.fail = false;
    api.resultStatus = 'duplicate';
    final retried = await service.retryPendingImports();
    expect(retried.ingestedCount, 0);
    expect(retried.duplicateCount, 2);
    expect(retried.pendingCount, 0);
  });
  test('a confirmed duplicate after an uncertain upload refreshes profile once',
      () async {
    final api = PaymentApi()..fail = true;
    final service = SmsListenerService(api,
        requestSmsPermission: () async => true,
        inboxReader: (_) async => [message(1)]);
    var refreshes = 0;
    await service.resumePendingImports(onNewIngestion: () => refreshes++);
    final first = await service.scanHistoricalInbox();
    expect(first.pendingCount, 1);
    expect(refreshes, 0);
    api.fail = false;
    api.resultStatus = 'duplicate';
    final retry = await service.retryPendingImports();
    expect(retry.ingestedCount, 0);
    expect(retry.duplicateCount, 1);
    expect(refreshes, 1);
    await service.retryPendingImports();
    expect(refreshes, 1);
  });

  test(
      'restoring the saved tracking state notifies subscribers without captures',
      () async {
    final api = PaymentApi();
    await PaymentImportQueue().setTracking(true, 'user_my_real_data');
    final service = SmsListenerService(api,
        requestSmsPermission: () async => true, registerListener: (_) {});
    final observedStates = <bool>[];
    service.addListener(() => observedStates.add(service.isListening));
    await service.resumePendingImports();
    expect(service.isListening, true);
    expect(observedStates, contains(true));
    await service.stopListening();
    expect(observedStates.last, false);
    service.dispose();
  });

  test('historical checkpoints belong to user and endpoint', () async {
    final api = PaymentApi();
    final checkpoints = <int?>[];
    final service = SmsListenerService(api,
        requestSmsPermission: () async => true,
        inboxReader: (afterId) async {
          checkpoints.add(afterId);
          return afterId == null ? [message(1)] : [];
        });
    expect((await service.scanHistoricalInbox()).ingestedCount, 1);
    api.endpoint = 'https://second.invalid';
    expect((await service.scanHistoricalInbox()).ingestedCount, 1);
    expect(checkpoints, [null, null]);
    expect(api.destinations,
        ['https://synthetic.invalid', 'https://second.invalid']);
  });

  test('one active import freezes its destination across all upload chunks',
      () async {
    final api = PaymentApi();
    final queue = PaymentImportQueue();
    for (var id = 0; id < 101; id++) {
      await queue.enqueue(
          'user_my_real_data',
          {
            'source_id': 'synthetic-$id',
            'merchant_name': 'Synthetic Cafe',
            'amount': 100,
            'timezone': 'Asia/Kolkata',
          },
          endpoint: api.baseUrl);
    }
    final service = SmsListenerService(api, queue: queue);
    api.afterUpload = () => api.endpoint = 'https://second.invalid';
    final result = await service.retryPendingImports();
    expect(result.ingestedCount, 101);
    expect(api.destinations,
        ['https://synthetic.invalid', 'https://synthetic.invalid']);
    expect(service.recentLogs, isEmpty);
  });

  test(
      'changing servers during a permission prompt cannot start an old listener',
      () async {
    final api = PaymentApi();
    final permission = Completer<bool>();
    final requested = Completer<void>();
    var registered = false;
    final service = SmsListenerService(api,
        requestSmsPermission: () {
          requested.complete();
          return permission.future;
        },
        registerListener: (_) => registered = true);
    final start = service.startListening();
    await requested.future;
    api.endpoint = 'https://second.invalid';
    permission.complete(true);
    expect(await start, false);
    expect(registered, false);
    expect(service.isListening, false);
  });
}

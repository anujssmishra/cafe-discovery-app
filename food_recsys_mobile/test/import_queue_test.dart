import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_recsys_mobile/services/payment_import_queue.dart';

Map<String, dynamic> payment(String id) => {
      'source_id': id,
      'merchant_name': 'Synthetic Cafe',
      'amount': 100,
      'timezone': 'Asia/Kolkata',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() =>
      SharedPreferences.setMockInitialValues({'dpdp_consent_granted': true}));

  test(
      'independent capture keys preserve parallel foreground/background writes',
      () async {
    final foreground = PaymentImportQueue();
    final background = PaymentImportQueue();
    await Future.wait([
      foreground.enqueue('synthetic-user', payment('one'),
          channel: 'foreground'),
      background.enqueue(
          'synthetic-user', {...payment('two'), 'text': 'PRIVATE INBOX TEXT'},
          channel: 'background'),
    ]);
    expect(await foreground.pendingCount('synthetic-user'), 2);
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs
        .getKeys()
        .where((key) => key.startsWith(PaymentImportQueue.entryPrefix))) {
      expect(prefs.getString(key), isNot(contains('PRIVATE INBOX TEXT')));
      expect(jsonDecode(prefs.getString(key)!)['payment']['merchant_name'],
          'Synthetic Cafe');
    }
  });

  test(
      'network failure survives a new queue instance and retries with same source id',
      () async {
    final queue = PaymentImportQueue();
    await queue.enqueue('synthetic-user', payment('one'));
    final failed = await queue.flush(
        'synthetic-user', (_, __) async => throw StateError('offline'));
    expect(failed.ingestedCount, 0);
    expect(failed.pendingCount, 1);
    final restarted = PaymentImportQueue();
    final retried = await restarted.flush(
        'synthetic-user',
        (_, payments) async => {
              'outcomes': [
                {
                  'source_id': payments.single['source_id'],
                  'status': 'inserted'
                }
              ],
            });
    expect(retried.ingestedCount, 1);
    expect(retried.pendingCount, 0);
  });

  test('only acknowledged individual outcomes leave queue, never batch length',
      () async {
    final queue = PaymentImportQueue();
    for (final id in ['inserted', 'duplicate', 'rejected', 'missing']) {
      await queue.enqueue('synthetic-user', payment(id));
    }
    final result = await queue.flush(
        'synthetic-user',
        (_, __) async => {
              'ingested_count': 999,
              'unresolved_count': 1,
              'outcomes': [
                {'source_id': 'inserted', 'status': 'inserted'},
                {'source_id': 'duplicate', 'status': 'duplicate'},
                {'source_id': 'rejected', 'status': 'rejected'},
              ],
            });
    expect(result.ingestedCount, 1);
    expect(result.duplicateCount, 1);
    expect(result.rejectedCount, 1);
    expect(result.unresolvedCount, 1);
    expect(result.pendingCount, 1);
    expect(result.error, isNotNull);
  });

  test('legacy response counts cannot mark missing outcomes successful',
      () async {
    final queue = PaymentImportQueue();
    await queue.enqueue('synthetic-user', payment('one'));
    final result = await queue.flush('synthetic-user',
        (_, __) async => {'status': 'success', 'parsed_count': 0});
    expect(result.ingestedCount, 0);
    expect(result.pendingCount, 1);
  });

  test('consent and tracking are checked from persisted state', () async {
    final queue = PaymentImportQueue();
    expect(
        await queue.enqueue('synthetic-user', payment('one'),
            requireTracking: true),
        false);
    await queue.setTracking(true, 'synthetic-user');
    expect(
        await queue.enqueue('synthetic-user', payment('one'),
            requireTracking: true),
        true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dpdp_consent_granted', false);
    var uploaded = false;
    final result = await queue.flush('synthetic-user', (_, __) async {
      uploaded = true;
      return {};
    });
    expect(uploaded, false);
    expect(result.pendingCount, 1);
    expect(await queue.enqueue('synthetic-user', payment('two')), false);
  });

  test('erasure waits for in-flight upload and blocks new enqueue', () async {
    final queue = PaymentImportQueue();
    await queue.enqueue('synthetic-user', payment('one'));
    final started = Completer<void>();
    final response = Completer<Map<String, dynamic>>();
    final upload = queue.flush('synthetic-user', (_, __) {
      started.complete();
      return response.future;
    });
    await started.future;
    var cleared = false;
    final clear = queue.clear('synthetic-user').then((_) => cleared = true);
    expect(await queue.enqueue('synthetic-user', payment('two')), false);
    expect(cleared, false);
    response.complete({
      'outcomes': [
        {'source_id': 'one', 'status': 'inserted'}
      ]
    });
    await upload;
    await clear;
    expect(cleared, true);
    expect(await queue.pendingCount('synthetic-user'), 0);
  });
  test(
      'a delayed capture from another queue cannot resurrect after erasure and regrant',
      () async {
    final persistenceStarted = Completer<void>();
    final releasePersistence = Completer<void>();
    final background =
        PaymentImportQueue(persistCapture: (prefs, key, value) async {
      if (!persistenceStarted.isCompleted) persistenceStarted.complete();
      await releasePersistence.future;
      return prefs.setString(key, value);
    });
    final foreground = PaymentImportQueue();
    await background.setTracking(true, 'synthetic-user');
    final capture = background.enqueue(
        'synthetic-user', payment('before-erasure'),
        requireTracking: true, channel: 'background');
    await persistenceStarted.future;
    await foreground.setTracking(false, 'synthetic-user');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dpdp_consent_granted', false);
    await foreground.clear('synthetic-user');
    await prefs.setBool('dpdp_consent_granted', true);
    releasePersistence.complete();
    expect(
        await capture, true); // The old isolate really did write after clear.
    await prefs.reload();
    expect(
        prefs
            .getKeys()
            .where((key) => key.startsWith(PaymentImportQueue.entryPrefix)),
        isNotEmpty);
    var uploads = 0;
    final result = await foreground.flush('synthetic-user', (_, __) async {
      uploads++;
      return {};
    });
    expect(uploads, 0);
    expect(result.pendingCount, 0);
    expect(await background.pendingCount('synthetic-user'), 0);
    await background.enqueue(
        'synthetic-user', payment('new-consented-capture'));
    final fresh = await foreground.flush(
        'synthetic-user',
        (_, rows) async => {
              'outcomes': [
                {'source_id': rows.single['source_id'], 'status': 'inserted'}
              ],
            });
    expect(fresh.ingestedCount, 1);
  });

  test('uploads select the captured endpoint and retain other source queues',
      () async {
    final queue = PaymentImportQueue();
    await queue.enqueue('synthetic-user', payment('source-a'),
        endpoint: 'https://a.invalid');
    await queue.enqueue('synthetic-user', payment('source-b'),
        endpoint: 'https://b.invalid');
    final sent = <String>[];
    final result = await queue.flush('synthetic-user', (_, rows) async {
      sent.addAll(rows.map((row) => row['source_id'].toString()));
      return {
        'outcomes': rows
            .map((row) => {'source_id': row['source_id'], 'status': 'inserted'})
            .toList()
      };
    }, endpoint: 'https://b.invalid');
    expect(sent, ['source-b']);
    expect(result.ingestedCount, 1);
    expect(
        await queue.pendingCount('synthetic-user',
            endpoint: 'https://a.invalid'),
        1);
    expect(
        await queue.pendingCount('synthetic-user',
            endpoint: 'https://b.invalid'),
        0);
  });
}

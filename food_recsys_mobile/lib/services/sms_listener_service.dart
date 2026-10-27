import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'on_device_sms_parser.dart';
import 'payment_import_queue.dart';
import 'food_order_parser.dart';
import '../config/constants.dart';
export 'payment_import_queue.dart' show ImportSummary;

/// Android may invoke this in a separate isolate. Persist extracted fields only;
/// the foreground lifecycle retries uploads after consent has been checked.
@pragma('vm:entry-point')
Future<void> backgroundSmsHandler(SmsMessage message) async {
  await queueBackgroundPayment(message, PaymentImportQueue());
}

@visibleForTesting
Future<void> queueBackgroundPayment(
    SmsMessage message, PaymentImportQueue queue) async {
  if (!await queue.hasConsent(requireTracking: true)) return;
  final userId = await queue.activeUserId;
  if (userId == null) return;
  final parsed = _parseMessage(message);
  if (parsed == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final endpoint =
      prefs.getString('api_base_url') ?? AppConstants.defaultWifiApiUrl;
  await queue.enqueue(userId, parsed.toPaymentPayload(),
      channel: 'background', requireTracking: true, endpoint: endpoint);
}

ParsedPayment? _parseMessage(SmsMessage message) => OnDeviceSmsParser.parse(
      message.body ?? '',
      sender: message.address,
      timestamp: message.date == null || message.date! <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(message.date!, isUtc: true),
    );

class IngestedSmsLog {
  final DateTime timestamp;
  final String merchant;
  final double amount;
  final String? bank;
  final bool success;
  final String status;
  IngestedSmsLog(
      {required this.timestamp,
      required this.merchant,
      required this.amount,
      this.bank,
      required this.success,
      this.status = 'inserted'});
}

class InboxScanResult {
  final int totalScanned;
  final int validDiningFound;
  final int ingestedCount;
  final int duplicateCount;
  final int rejectedCount;
  final int unresolvedCount;
  final int pendingCount;
  final List<ParsedPayment> payments;
  final String? error;
  InboxScanResult(
      {required this.totalScanned,
      required this.validDiningFound,
      required this.ingestedCount,
      required this.payments,
      this.error,
      this.duplicateCount = 0,
      this.rejectedCount = 0,
      this.unresolvedCount = 0,
      this.pendingCount = 0});
}

typedef InboxReader = Future<List<SmsMessage>> Function(int? afterId);
typedef SmsRegistrar = void Function(
    Future<void> Function(SmsMessage) callback);

class SmsListenerService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService;
  final PaymentImportQueue _queue;
  final Future<bool> Function()? _requestSmsPermission;
  final InboxReader? _inboxReader;
  final SmsRegistrar? _registerListener;
  bool _isListening = false;
  String _activeUserId = 'user_my_real_data';
  Function()? _onNewIngestion;
  final Map<String, Future<ImportSummary>> _activeRetries = {};
  String? _listeningEndpoint;
  int _captureGeneration = 0;
  bool _disposed = false;

  void _publishState() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _apiService.removeListener(_endpointChanged);
    _logStream.close();
    super.dispose();
  }

  final List<IngestedSmsLog> _recentLogs = [];
  final StreamController<IngestedSmsLog> _logStream =
      StreamController<IngestedSmsLog>.broadcast();

  SmsListenerService(this._apiService,
      {PaymentImportQueue? queue,
      Future<bool> Function()? requestSmsPermission,
      InboxReader? inboxReader,
      SmsRegistrar? registerListener})
      : _queue = queue ?? PaymentImportQueue(),
        _requestSmsPermission = requestSmsPermission,
        _inboxReader = inboxReader,
        _registerListener = registerListener {
    _apiService.addListener(_endpointChanged);
  }

  void _endpointChanged() {
    ++_captureGeneration;
    _isListening = false;
    _listeningEndpoint = null;
    _recentLogs.clear();
    _publishState();
  }

  bool get isListening => _isListening;
  List<IngestedSmsLog> get recentLogs => List.unmodifiable(_recentLogs);
  Stream<IngestedSmsLog> get logStream => _logStream.stream;
  void setActiveUserId(String userId) => _activeUserId = userId;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications
        .initialize(const InitializationSettings(android: androidSettings));
  }

  Future<bool> _permissionGranted() async => _requestSmsPermission != null
      ? await _requestSmsPermission!()
      : (await Permission.sms.request()).isGranted;

  Future<bool> startListening({Function()? onNewIngestion}) async {
    final endpoint = _apiService.baseUrl;
    final generation = _captureGeneration;
    if (!await _queue.hasConsent()) return false;
    _onNewIngestion = onNewIngestion ?? _onNewIngestion;
    try {
      if (!await _permissionGranted()) {
        _isListening = false;
        _publishState();
        await _queue.setTracking(false, _activeUserId);
        return false;
      }
      if (generation != _captureGeneration ||
          endpoint != _apiService.baseUrl ||
          !await _queue.hasConsent()) return false;
      await _queue.setTracking(true, _activeUserId);
      if (generation != _captureGeneration || endpoint != _apiService.baseUrl) {
        await _queue.setTracking(false, _activeUserId);
        return false;
      }
      _listeningEndpoint = endpoint;
      _isListening = true;
      _publishState();
      if (_registerListener != null) {
        _registerListener!(handleForegroundMessage);
      } else {
        Telephony.instance.listenIncomingSms(
          onNewMessage: handleForegroundMessage,
          onBackgroundMessage: backgroundSmsHandler,
          listenInBackground: true,
        );
      }
      await retryPendingImports();
      return true;
    } catch (_) {
      _isListening = false;
      _publishState();
      await _queue.setTracking(false, _activeUserId);
      return false;
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    _publishState();
    await _queue.setTracking(false, _activeUserId);
  }

  Future<ImportSummary> resumePendingImports(
      {Function()? onNewIngestion}) async {
    _onNewIngestion = onNewIngestion ?? _onNewIngestion;
    if (!await _queue.hasConsent()) {
      _isListening = false;
      _publishState();
      await _queue.setTracking(false, _activeUserId);
      return ImportSummary(
          pendingCount: await _queue.pendingCount(_activeUserId,
              endpoint: _apiService.baseUrl));
    }
    final result = await retryPendingImports();
    if (await _queue.trackingEnabled && !_isListening) {
      await startListening(onNewIngestion: _onNewIngestion);
    }
    return result;
  }

  Future<void> clearPendingImports() async {
    _captureGeneration++;
    await _queue.clear(_activeUserId);
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs
        .getKeys()
        .where((key) =>
            key.startsWith('sms_scan_checkpoint_') &&
            key.endsWith('_$_activeUserId'))
        .toList()) {
      await prefs.remove(key);
    }
    _recentLogs.clear();
    _publishState();
  }

  Future<ImportSummary> retryPendingImports({String? endpoint}) {
    final destination = endpoint ?? _apiService.baseUrl;
    if (_activeRetries[destination] != null) {
      return _activeRetries[destination]!;
    }
    final retry = _retryPendingImports(destination);
    _activeRetries[destination] = retry;
    return retry.whenComplete(() => _activeRetries.remove(destination));
  }

  Future<ImportSummary> _retryPendingImports(String endpoint) async {
    final result = await _queue.flush(
        _activeUserId,
        (userId, payments) =>
            _apiService.ingestPayments(userId, payments, endpoint: endpoint),
        endpoint: endpoint);
    if (_apiService.baseUrl != endpoint) return result;
    for (final outcome in result.outcomes) {
      final payment = outcome['_payment'];
      if (payment is! Map) continue;
      final merchant = payment['merchant_name']?.toString() ?? 'Dining payment';
      _record(
          ParsedPayment(
            amount: (payment['amount'] as num?)?.toDouble() ?? 0,
            rawMerchant: merchant,
            normalizedMerchant: merchant,
            redactedText: '',
            bank: payment['payment_app']?.toString(),
            timestamp: DateTime.tryParse(
                payment['transaction_time']?.toString() ?? ''),
          ),
          outcome['status'].toString());
    }
    if (_apiService.baseUrl == endpoint &&
        result.ingestedCount + result.duplicateCount > 0) {
      _onNewIngestion?.call();
    }
    _publishState();
    return result;
  }

  @visibleForTesting
  Future<void> handleForegroundMessage(SmsMessage message) async {
    if (_listeningEndpoint != _apiService.baseUrl) {
      await stopListening();
      return;
    }
    if (!_isListening || !await _queue.hasConsent(requireTracking: true)) {
      return;
    }
    final parsed = _parseMessage(message);
    if (parsed == null) return;
    final payload = parsed.toPaymentPayload();
    if (!await _queue.enqueue(_activeUserId, payload,
        requireTracking: true, endpoint: _listeningEndpoint)) {
      return;
    }
    final result = await retryPendingImports();
    final outcomes = result.outcomes
        .where((outcome) => outcome['source_id'] == payload['source_id']);
    if (outcomes.isNotEmpty) {
      final status = outcomes.first['status'].toString();
      if (status == 'inserted') {
        try {
          await _showPaymentNotification(
              parsed.normalizedMerchant, parsed.amount);
        } catch (_) {}
      }
    }
  }

  String _checkpointKeyFor(String endpoint) =>
      'sms_scan_checkpoint_${stablePaymentSourceId(endpoint)}_$_activeUserId';

  Future<List<SmsMessage>> _readInbox(int? afterId) async {
    if (_inboxReader != null) return _inboxReader!(afterId);
    return Telephony.instance.getInboxSms(
      columns: [
        SmsColumn.ID,
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE
      ],
      filter: afterId == null
          ? null
          : SmsFilter.where(SmsColumn.ID).greaterThan('$afterId'),
      sortOrder: [OrderBy(SmsColumn.ID, sort: Sort.ASC)],
    );
  }

  /// maxMessages controls cooperative processing pages, never truncates history.
  /// The checkpoint advances only after an eligible payment is durably queued.
  Future<InboxScanResult> scanHistoricalInbox(
      {int maxMessages = 5000,
      Function(int scanned, int found)? onProgress}) async {
    var scanned = 0;
    final generation = _captureGeneration;
    final endpoint = _apiService.baseUrl;
    final checkpointKey = _checkpointKeyFor(endpoint);
    final payments = <ParsedPayment>[];
    final summaries = <ImportSummary>[];
    String? error;
    try {
      if (!await _queue.hasConsent()) {
        throw StateError('Consent is required before reading the SMS inbox.');
      }
      if (!await _permissionGranted()) {
        throw StateError(
            'SMS permission not granted. Allow SMS permission in settings.');
      }
      final prefs = await SharedPreferences.getInstance();
      final checkpoint = prefs.getInt(checkpointKey);
      final messages = await _readInbox(checkpoint);
      messages.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      final pageSize = maxMessages < 1 ? 5000 : maxMessages;
      for (final message in messages) {
        if (generation != _captureGeneration ||
            endpoint != _apiService.baseUrl) {
          error = 'Scan stopped because pending imports were cleared.';
          break;
        }
        if (!await _queue.hasConsent()) {
          error = 'Scan paused because consent was withdrawn.';
          break;
        }
        if (generation != _captureGeneration ||
            endpoint != _apiService.baseUrl) {
          break;
        }
        final parsed = _parseMessage(message);
        if (parsed != null) {
          if (!await _queue.enqueue(_activeUserId, parsed.toPaymentPayload(),
              channel: 'inbox', endpoint: endpoint)) {
            error = 'Scan paused because consent was withdrawn.';
            break;
          }
          payments.add(parsed);
        }
        scanned++;
        if (message.id != null) await prefs.setInt(checkpointKey, message.id!);
        if (scanned % 25 == 0 || scanned == messages.length) {
          onProgress?.call(scanned, payments.length);
          await Future<void>.delayed(Duration.zero);
        }
        if (scanned % pageSize == 0) {
          summaries.add(endpoint == _apiService.baseUrl
              ? await retryPendingImports(endpoint: endpoint)
              : ImportSummary(
                  pendingCount: await _queue.pendingCount(_activeUserId,
                      endpoint: endpoint)));
        }
      }
    } catch (_) {
      error = scanned == 0
          ? 'Unable to read SMS inbox. Check consent and SMS permission.'
          : 'Scan interrupted. Saved payments remain queued.';
    }
    summaries.add(endpoint == _apiService.baseUrl
        ? await retryPendingImports(endpoint: endpoint)
        : ImportSummary(
            pendingCount:
                await _queue.pendingCount(_activeUserId, endpoint: endpoint)));
    final result = ImportSummary(
      ingestedCount: summaries.fold(0, (sum, item) => sum + item.ingestedCount),
      duplicateCount:
          summaries.fold(0, (sum, item) => sum + item.duplicateCount),
      rejectedCount: summaries.fold(0, (sum, item) => sum + item.rejectedCount),
      unresolvedCount:
          summaries.fold(0, (sum, item) => sum + item.unresolvedCount),
      pendingCount: summaries.last.pendingCount,
      outcomes: summaries.expand((item) => item.outcomes).toList(),
      error: summaries.last.error,
    );
    return InboxScanResult(
        totalScanned: scanned,
        validDiningFound: payments.length,
        ingestedCount: result.ingestedCount,
        duplicateCount: result.duplicateCount,
        rejectedCount: result.rejectedCount,
        unresolvedCount: result.unresolvedCount,
        pendingCount: result.pendingCount,
        payments: payments,
        error: error ?? result.error);
  }

  Future<ImportSummary> importManualSms(String rawText) async {
    if (!await _queue.hasConsent()) {
      return const ImportSummary(
          error: 'Consent is required before importing a payment.');
    }
    final parsed = OnDeviceSmsParser.parse(rawText);
    if (parsed == null) {
      return const ImportSummary(
          rejectedCount: 1,
          error: 'No valid dining payment detected in this text.');
    }
    await _queue.enqueue(_activeUserId, parsed.toPaymentPayload(),
        channel: 'manual', endpoint: _apiService.baseUrl);
    final result = await retryPendingImports();
    return result;
  }

  Future<Map<String, dynamic>> importFoodOrders(
      List<Map<String, dynamic>> orders) async {
    final endpoint = _apiService.baseUrl;
    final generation = _captureGeneration;
    if (!await _queue.hasConsent()) {
      throw StateError('Consent is required before importing orders.');
    }
    if (orders.length > 1000) {
      throw ArgumentError('Import at most 1,000 orders at a time.');
    }
    final rejected = <Map<String, dynamic>>[];
    String? interrupted;
    for (var index = 0; index < orders.length; index++) {
      if (generation != _captureGeneration || endpoint != _apiService.baseUrl) {
        interrupted =
            'Import stopped because the data source changed or imports were cleared.';
        break;
      }
      final input = orders[index];
      final order =
          FoodOrderParser.fromOrderPayload(input, rowNumber: index + 1);
      final link = input['linked_transaction_id'];
      final validLink = link == null ||
          (link is String &&
              RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
                  .hasMatch(link));
      if (!order.isImportable || !validLink) {
        rejected.add({
          'source_id': order.sourceId ?? 'invalid-order-row-${index + 1}',
          'status': 'rejected',
          'reason':
              !validLink ? 'invalid_payment_link' : 'invalid_or_excluded_order',
        });
        continue;
      }
      final saved = await _queue.enqueue(_activeUserId,
          order.toPaymentPayload(linkedTransactionId: link as String?),
          channel: 'food-order', endpoint: endpoint);
      if (!saved) {
        interrupted = 'Import paused. Check consent before retrying.';
        break;
      }
    }
    final result = generation == _captureGeneration &&
            endpoint == _apiService.baseUrl
        ? await retryPendingImports(endpoint: endpoint)
        : ImportSummary(
            pendingCount:
                await _queue.pendingCount(_activeUserId, endpoint: endpoint));
    return {
      'submitted_count': orders.length,
      'ingested_count': result.ingestedCount,
      'duplicate_count': result.duplicateCount,
      'rejected_count': result.rejectedCount + rejected.length,
      'unresolved_count': result.unresolvedCount,
      'pending_count': result.pendingCount,
      'outcomes': [...result.outcomes, ...rejected],
      if (interrupted ?? result.error case final error?) 'error': error,
    };
  }

  void _record(ParsedPayment parsed, String status) {
    final log = IngestedSmsLog(
        timestamp: parsed.timestamp ?? DateTime.now(),
        merchant: parsed.normalizedMerchant,
        amount: parsed.amount,
        bank: parsed.bank,
        success: status == 'inserted',
        status: status);
    _recentLogs.insert(0, log);
    if (_recentLogs.length > 50) _recentLogs.removeLast();
    if (!_disposed) _logStream.add(log);
    _publishState();
  }

  Future<void> _showPaymentNotification(String merchant, double amount) async {
    const androidDetails = AndroidNotificationDetails(
        'food_recsys_channel', 'Food RecSys UPI Ingestion',
        channelDescription:
            'Alerts when dining payments update your taste profile',
        importance: Importance.high,
        priority: Priority.high);
    await _notifications.show(
        DateTime.now().millisecond,
        'Taste profile updated',
        'Imported ₹${amount.toStringAsFixed(0)} at $merchant.',
        const NotificationDetails(android: androidDetails));
  }
}

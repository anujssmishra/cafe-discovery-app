import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'on_device_sms_parser.dart';

// Top-level background handler for incoming SMS (required by Android Telephony)
@pragma('vm:entry-point')
void backgroundSmsHandler(SmsMessage message) {
  debugPrint('Background SMS received: ${message.body}');
  // On-device parsing and handling runs even when app is minimized
}

class IngestedSmsLog {
  final DateTime timestamp;
  final String merchant;
  final double amount;
  final String? bank;
  final bool success;

  IngestedSmsLog({
    required this.timestamp,
    required this.merchant,
    required this.amount,
    this.bank,
    required this.success,
  });
}

class InboxScanResult {
  final int totalScanned;
  final int validDiningFound;
  final int ingestedCount;
  final List<ParsedPayment> payments;
  final String? error;

  InboxScanResult({
    required this.totalScanned,
    required this.validDiningFound,
    required this.ingestedCount,
    required this.payments,
    this.error,
  });
}

class SmsListenerService {
  final Telephony _telephony = Telephony.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService;

  bool _isListening = false;
  String _activeUserId = 'user_my_real_data';
  final List<IngestedSmsLog> _recentLogs = [];
  final StreamController<IngestedSmsLog> _logStream = StreamController<IngestedSmsLog>.broadcast();

  SmsListenerService(this._apiService);

  bool get isListening => _isListening;
  List<IngestedSmsLog> get recentLogs => List.unmodifiable(_recentLogs);
  Stream<IngestedSmsLog> get logStream => _logStream.stream;

  void setActiveUserId(String userId) {
    _activeUserId = userId;
  }

  Future<void> init() async {
    // 1. Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    // 2. Request Notification Permission on Android 13+
    await Permission.notification.request();
  }

  /// Request SMS permissions and start listening for real-time UPI debit alerts
  Future<bool> startListening({Function()? onNewIngestion}) async {
    try {
      final smsStatus = await Permission.sms.request();
      if (!smsStatus.isGranted) {
        debugPrint('SMS permission denied by user');
        _isListening = false;
        return false;
      }

      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          final body = message.body ?? '';
          final sender = message.address ?? '';
          debugPrint('Foreground SMS received from $sender: $body');
          await _processIncomingSms(body, sender, onNewIngestion);
        },
        onBackgroundMessage: backgroundSmsHandler,
        listenInBackground: true,
      );

      _isListening = true;
      return true;
    } catch (e) {
      debugPrint('Failed to start SMS listener: $e');
      _isListening = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  /// Scan historical SMS inbox on the device for past bank debits & food delivery alerts (Swiggy, Zomato, etc.)
  Future<InboxScanResult> scanHistoricalInbox({
    int maxMessages = 5000,
    Function(int scanned, int found)? onProgress,
  }) async {
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      return InboxScanResult(
        totalScanned: 0,
        validDiningFound: 0,
        ingestedCount: 0,
        payments: [],
        error: 'SMS permission not granted. Please allow SMS permission in settings.',
      );
    }

    try {
      final messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        sortOrder: [
          OrderBy(SmsColumn.DATE, sort: Sort.DESC),
        ],
      );

      final totalToProcess = messages.length > maxMessages ? maxMessages : messages.length;
      final List<ParsedPayment> foundPayments = [];
      final List<Map<String, dynamic>> batchPayload = [];

      for (int i = 0; i < totalToProcess; i++) {
        final sms = messages[i];
        final body = sms.body ?? '';
        final sender = sms.address ?? '';
        DateTime? smsDate;
        if (sms.date != null && sms.date! > 0) {
          smsDate = DateTime.fromMillisecondsSinceEpoch(sms.date!);
        }

        final parsed = OnDeviceSmsParser.parse(
          body,
          sender: sender,
          timestamp: smsDate,
        );

        if (parsed != null) {
          foundPayments.add(parsed);
          batchPayload.add({
            'text': parsed.redactedText,
            'received_at': smsDate?.toUtc().toIso8601String(),
          });
        }

        if (onProgress != null && (i % 25 == 0 || i == totalToProcess - 1)) {
          onProgress(i + 1, foundPayments.length);
        }
      }

      int totalIngested = 0;
      if (batchPayload.isNotEmpty) {
        // Send in chunks of 100
        const chunkSize = 100;
        for (var i = 0; i < batchPayload.length; i += chunkSize) {
          final end = (i + chunkSize > batchPayload.length) ? batchPayload.length : i + chunkSize;
          final chunk = batchPayload.sublist(i, end);
          final res = await _apiService.ingestTimestampedSmsBatch(_activeUserId, chunk);
          totalIngested += (res['parsed_transactions_count'] as int? ?? chunk.length);
        }

        // Add to local recent logs
        for (final p in foundPayments.take(20)) {
          _recentLogs.insert(0, IngestedSmsLog(
            timestamp: p.timestamp ?? DateTime.now(),
            merchant: p.normalizedMerchant,
            amount: p.amount,
            bank: p.bank,
            success: true,
          ));
        }
      }

      return InboxScanResult(
        totalScanned: totalToProcess,
        validDiningFound: foundPayments.length,
        ingestedCount: totalIngested,
        payments: foundPayments,
      );
    } catch (e) {
      debugPrint('Error scanning historical inbox: $e');
      return InboxScanResult(
        totalScanned: 0,
        validDiningFound: 0,
        ingestedCount: 0,
        payments: [],
        error: e.toString(),
      );
    }
  }

  /// Import structured food app order history (Swiggy, Zomato, etc.)
  Future<Map<String, dynamic>> importFoodOrders(List<Map<String, dynamic>> orders) async {
    final res = await _apiService.ingestFoodOrders(_activeUserId, orders);
    for (final o in orders) {
      _recentLogs.insert(0, IngestedSmsLog(
        timestamp: o['order_time'] != null ? DateTime.parse(o['order_time']) : DateTime.now(),
        merchant: o['restaurant_name'] ?? 'Food App',
        amount: (o['amount'] as num?)?.toDouble() ?? 0.0,
        bank: o['platform'] ?? 'Food App',
        success: true,
      ));
    }
    return res;
  }

  /// Process an SMS message (on-device PII redaction + API dispatch)
  Future<ParsedPayment?> _processIncomingSms(String rawText, String sender, Function()? onNewIngestion) async {
    final parsed = OnDeviceSmsParser.parse(rawText, sender: sender);
    if (parsed == null) {
      debugPrint('SMS ignored: not a dining/UPI debit');
      return null;
    }

    try {
      // Ingest into FastAPI RecSys using on-device redacted text (safe, zero PII)
      final result = await _apiService.ingestSms(_activeUserId, parsed.redactedText);
      final isSuccess = result['status'] == 'success';

      final log = IngestedSmsLog(
        timestamp: DateTime.now(),
        merchant: parsed.normalizedMerchant,
        amount: parsed.amount,
        bank: parsed.bank,
        success: isSuccess,
      );

      _recentLogs.insert(0, log);
      _logStream.add(log);

      if (isSuccess) {
        // Show local Android notification
        await _showPaymentNotification(parsed.normalizedMerchant, parsed.amount);
        if (onNewIngestion != null) {
          onNewIngestion();
        }
      }

      return parsed;
    } catch (e) {
      debugPrint('Error dispatching SMS to API: $e');
      return null;
    }
  }

  Future<void> _showPaymentNotification(String merchant, double amount) async {
    const androidDetails = AndroidNotificationDetails(
      'food_recsys_channel',
      'Food RecSys UPI Ingestion',
      channelDescription: 'Alerts when UPI dining payments update your taste profile',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      '🍽️ Taste Profile Updated!',
      'Detected ₹${amount.toStringAsFixed(0)} at $merchant. Recommendations refreshed.',
      details,
    );
  }
}

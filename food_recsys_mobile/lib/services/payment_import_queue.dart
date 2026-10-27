import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class ImportSummary {
  final int submittedCount;
  final int ingestedCount;
  final int duplicateCount;
  final int rejectedCount;
  final int unresolvedCount;
  final int pendingCount;
  final List<Map<String, dynamic>> outcomes;
  final String? error;

  const ImportSummary(
      {this.submittedCount = 0,
      this.ingestedCount = 0,
      this.duplicateCount = 0,
      this.rejectedCount = 0,
      this.unresolvedCount = 0,
      this.pendingCount = 0,
      this.outcomes = const [],
      this.error});
}

typedef PaymentUploader = Future<Map<String, dynamic>> Function(
    String userId, List<Map<String, dynamic>> payments);

/// One preference key per capture prevents foreground/background list writes
/// from overwriting each other. Raw SMS and inbox contents are never persisted.
class PaymentImportQueue {
  static const entryPrefix = 'payment_import_v1_';
  static const trackingKey = 'sms_tracking_enabled';
  static const activeUserKey = 'sms_active_user_id';
  static String _epochKey(String userId) => 'payment_erasure_epoch_v1_$userId';
  final Future<SharedPreferences> Function() _preferences;
  final Future<bool> Function(SharedPreferences, String, String)
      _persistCapture;
  final Map<String, Future<ImportSummary>> _activeFlushes = {};
  int _sequence = 0;
  bool _clearing = false;
  int _generation = 0;
  final Set<Future<bool>> _pendingWrites = {};

  PaymentImportQueue(
      {Future<SharedPreferences> Function()? preferences,
      Future<bool> Function(SharedPreferences, String, String)? persistCapture})
      : _preferences = preferences ?? SharedPreferences.getInstance,
        _persistCapture = persistCapture ??
            ((prefs, key, value) => prefs.setString(key, value));

  String _newEpoch() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';

  Future<SharedPreferences> _load() async {
    final prefs = await _preferences();
    await prefs.reload(); // Background isolates have independent caches.
    return prefs;
  }

  Future<bool> hasConsent({bool requireTracking = false}) async {
    final prefs = await _load();
    return prefs.getBool('dpdp_consent_granted') == true &&
        (!requireTracking || prefs.getBool(trackingKey) == true);
  }

  Future<void> setTracking(bool enabled, String userId) async {
    final prefs = await _load();
    await prefs.setString(activeUserKey, userId);
    await prefs.setBool(trackingKey, enabled);
  }

  Future<bool> get trackingEnabled async =>
      (await _load()).getBool(trackingKey) == true;
  Future<String?> get activeUserId async =>
      (await _load()).getString(activeUserKey);

  Future<bool> enqueue(String userId, Map<String, dynamic> payment,
      {String channel = 'foreground',
      bool requireTracking = false,
      String? endpoint}) {
    final write = _enqueue(userId, payment,
        channel: channel, requireTracking: requireTracking, endpoint: endpoint);
    _pendingWrites.add(write);
    return write.whenComplete(() => _pendingWrites.remove(write));
  }

  Future<bool> _enqueue(String userId, Map<String, dynamic> payment,
      {required String channel,
      required bool requireTracking,
      String? endpoint}) async {
    final generation = _generation;
    final capturePreferences = await _load();
    // Bind the capture to the persisted erasure epoch before async persistence.
    // A delayed write from another isolate remains stale after erasure/regrant.
    final captureEpoch =
        capturePreferences.getString(_epochKey(userId)) ?? 'initial';
    if (_clearing ||
        capturePreferences.getBool('dpdp_consent_granted') != true ||
        (requireTracking && capturePreferences.getBool(trackingKey) != true)) {
      return false;
    }
    const allowed = {
      'source_id',
      'merchant_name',
      'amount',
      'transaction_time',
      'timezone',
      'upi_ref',
      'payment_app',
      'cuisine',
      'dish_names',
      'order_id',
      'order_platform',
      'order_status',
      'currency',
      'linked_transaction_id',
      'time_precision'
    };
    final safePayment = Map<String, dynamic>.fromEntries(
      payment.entries.where((entry) => allowed.contains(entry.key)),
    );
    if (safePayment['source_id'] == null) {
      throw ArgumentError('A queued payment requires a source_id');
    }
    final prefs = await _load();
    if (_clearing || generation != _generation) return false;
    final key =
        '$entryPrefix$channel-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}-${_sequence++}';
    return _persistCapture(
        prefs,
        key,
        jsonEncode({
          'user_id': userId,
          'erasure_epoch': captureEpoch,
          'endpoint': endpoint,
          'payment': safePayment,
        }));
  }

  Future<List<MapEntry<String, Map<String, dynamic>>>> _entries(String userId,
      {String? endpoint, bool includeAllEndpoints = false}) async {
    final prefs = await _load();
    final epoch = prefs.getString(_epochKey(userId)) ?? 'initial';
    final entries = <MapEntry<String, Map<String, dynamic>>>[];
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(entryPrefix))) {
      try {
        final record =
            jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
        if (record['user_id'] == userId) {
          if ((record['erasure_epoch'] ?? 'initial') != epoch) {
            await prefs.remove(key);
            continue;
          }
          if (!includeAllEndpoints && record['endpoint'] != endpoint) continue;
          entries.add(MapEntry(
              key, Map<String, dynamic>.from(record['payment'] as Map)));
        }
      } catch (_) {
        // Leave unreadable captures for recovery; never claim they were imported.
      }
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  Future<int> pendingCount(String userId, {String? endpoint}) async =>
      (await _entries(userId,
              endpoint: endpoint, includeAllEndpoints: endpoint == null))
          .length;

  Future<void> clear(String userId) async {
    _clearing = true;
    _generation++;
    try {
      // Persist a tombstone before waiting: other queue instances/isolate writes
      // are outside this instance's barriers and must be invalidated durably.
      var prefs = await _load();
      await prefs.setString(_epochKey(userId), _newEpoch());
      await Future.wait(_pendingWrites.toList());
      await Future.wait(_activeFlushes.values.toList());
      final entries = await _entries(userId, includeAllEndpoints: true);
      prefs = await _load();
      for (final entry in entries) {
        await prefs.remove(entry.key);
      }
      // Captures started during the erasure window must not survive either.
      await prefs.setString(_epochKey(userId), _newEpoch());
      await _entries(userId, includeAllEndpoints: true);
    } finally {
      _clearing = false;
    }
  }

  Future<ImportSummary> flush(String userId, PaymentUploader upload,
      {String? endpoint}) {
    final key = '$userId|$endpoint';
    if (_activeFlushes[key] != null) return _activeFlushes[key]!;
    final future = _flush(userId, upload, endpoint: endpoint);
    _activeFlushes[key] = future;
    return future.whenComplete(() => _activeFlushes.remove(key));
  }

  Future<ImportSummary> _flush(String userId, PaymentUploader upload,
      {String? endpoint}) async {
    var submitted = 0,
        inserted = 0,
        duplicates = 0,
        rejected = 0,
        unresolved = 0;
    String? error;
    final allOutcomes = <Map<String, dynamic>>[];
    while (!_clearing && await hasConsent()) {
      final epoch = (await _load()).getString(_epochKey(userId)) ?? 'initial';
      final entries = await _entries(userId, endpoint: endpoint);
      if (entries.isEmpty) break;
      final batch = entries.take(100).toList();
      try {
        final prefsBeforeUpload = await _load();
        if ((prefsBeforeUpload.getString(_epochKey(userId)) ?? 'initial') !=
            epoch) {
          continue;
        }
        if (prefsBeforeUpload.getBool('dpdp_consent_granted') != true) break;
        final response =
            await upload(userId, batch.map((entry) => entry.value).toList());
        submitted += batch.length;
        final rawOutcomes = response['outcomes'];
        if (rawOutcomes is! List) {
          error = 'Import was not confirmed. Payments remain queued for retry.';
          break;
        }
        final unmatched = batch.toList();
        final prefs = await _load();
        for (final raw in rawOutcomes) {
          if (raw is! Map) continue;
          final outcome = Map<String, dynamic>.from(raw);
          final status = outcome['status'];
          if (!{'inserted', 'duplicate', 'rejected'}.contains(status)) continue;
          final index = unmatched.indexWhere(
              (entry) => entry.value['source_id'] == outcome['source_id']);
          if (index < 0) continue;
          final entry = unmatched.removeAt(index);
          await prefs.remove(entry.key);
          allOutcomes.add({...outcome, '_payment': entry.value});
          if (status == 'inserted') inserted++;
          if (status == 'duplicate') duplicates++;
          if (status == 'rejected') rejected++;
        }
        unresolved += (response['unresolved_count'] as num?)?.toInt() ?? 0;
        if (unmatched.isNotEmpty) {
          error =
              'Some payments were not confirmed and remain queued for retry.';
          break;
        }
      } catch (_) {
        error =
            'Upload unavailable. Payments are saved on this device for retry.';
        break;
      }
    }
    return ImportSummary(
        submittedCount: submitted,
        ingestedCount: inserted,
        duplicateCount: duplicates,
        rejectedCount: rejected,
        unresolvedCount: unresolved,
        pendingCount: await pendingCount(userId, endpoint: endpoint),
        outcomes: allOutcomes,
        error: error);
  }
}

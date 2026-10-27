import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/sms_listener_service.dart';
import '../services/on_device_sms_parser.dart';
import '../providers/taste_provider.dart';
import '../providers/recs_provider.dart';
import '../widgets/dpdp_consent_dialog.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'food_order_import_screen.dart';

class SmsIngestTab extends StatefulWidget {
  const SmsIngestTab({super.key});

  @override
  State<SmsIngestTab> createState() => _SmsIngestTabState();
}

class _SmsIngestTabState extends State<SmsIngestTab> {
  final TextEditingController _smsController = TextEditingController();
  bool _isIngesting = false;
  String? _statusMessage;
  bool _statusSuccess = false;
  ParsedPayment? _previewPayment;
  StreamSubscription<IngestedSmsLog>? _logSubscription;

  // Historical SMS Inbox Scan State
  bool _isScanningInbox = false;
  String? _scanStatusText;
  InboxScanResult? _lastScanResult;
  String? _displayEndpoint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final endpoint = context.watch<ApiService>().baseUrl;
    if (_displayEndpoint != endpoint) {
      _displayEndpoint = endpoint;
      _isScanningInbox = false;
      _isIngesting = false;
      _scanStatusText = null;
      _statusMessage = null;
      _lastScanResult = null;
    }
    _logSubscription ??=
        context.read<SmsListenerService>().logStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _smsController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() => _previewPayment = null);
      return;
    }
    final parsed = OnDeviceSmsParser.parse(text);
    setState(() => _previewPayment = parsed);
  }

  Future<bool> _ensureConsent(TasteProvider taste) async {
    if (taste.hasDpdpConsent) return true;
    final granted = await DpdpConsentDialog.show(context);
    if (!mounted || granted != true) return false;
    await taste.grantConsent();
    return mounted;
  }

  String _summary(ImportSummary result) =>
      '${result.ingestedCount} inserted • ${result.duplicateCount} duplicates • '
      '${result.rejectedCount} rejected • ${result.unresolvedCount} unresolved • '
      '${result.pendingCount} pending';

  Future<void> _scanHistoricalInbox() async {
    final endpoint = context.read<ApiService>().baseUrl;
    final taste = context.read<TasteProvider>();
    final recs = context.read<RecsProvider>();
    final service = context.read<SmsListenerService>();
    if (!await _ensureConsent(taste) ||
        !mounted ||
        context.read<ApiService>().baseUrl != endpoint) return;
    setState(() {
      _isScanningInbox = true;
      _scanStatusText = 'Accessing phone SMS inbox...';
      _lastScanResult = null;
    });
    final result =
        await service.scanHistoricalInbox(onProgress: (scanned, found) {
      if (mounted && context.read<ApiService>().baseUrl == endpoint) {
        setState(() => _scanStatusText =
            'Scanned $scanned SMS • $found eligible dining payments');
      }
    });
    if (!mounted || context.read<ApiService>().baseUrl != endpoint) return;
    if (result.ingestedCount + result.duplicateCount > 0) {
      await taste.fetchProfile();
      await recs.fetchRecommendations(taste.activeUserId);
    }
    if (!mounted || context.read<ApiService>().baseUrl != endpoint) return;
    setState(() {
      _isScanningInbox = false;
      _lastScanResult = result;
      _scanStatusText =
          '${result.totalScanned} scanned • ${result.validDiningFound} eligible\n'
          '${result.ingestedCount} inserted • ${result.duplicateCount} duplicates • '
          '${result.rejectedCount} rejected • ${result.unresolvedCount} unresolved • '
          '${result.pendingCount} pending'
          '${result.error == null ? '' : '\n${result.error}'}';
    });
  }

  Future<void> _retryPending() async {
    final endpoint = context.read<ApiService>().baseUrl;
    final taste = context.read<TasteProvider>();
    final recs = context.read<RecsProvider>();
    final service = context.read<SmsListenerService>();
    if (!await _ensureConsent(taste) ||
        !mounted ||
        context.read<ApiService>().baseUrl != endpoint) return;
    setState(() => _isIngesting = true);
    final result = await service.retryPendingImports();
    if (!mounted || context.read<ApiService>().baseUrl != endpoint) return;
    if (result.ingestedCount + result.duplicateCount > 0) {
      await taste.fetchProfile();
      await recs.fetchRecommendations(taste.activeUserId);
    }
    if (!mounted || context.read<ApiService>().baseUrl != endpoint) return;
    setState(() {
      _isIngesting = false;
      _statusSuccess = result.error == null;
      _statusMessage =
          '${_summary(result)}${result.error == null ? '' : '\n${result.error}'}';
    });
  }

  Future<void> _submitManualSms() async {
    final endpoint = context.read<ApiService>().baseUrl;
    final text = _smsController.text.trim();
    if (text.isEmpty) return;
    final taste = context.read<TasteProvider>();
    final recs = context.read<RecsProvider>();
    final service = context.read<SmsListenerService>();
    if (!await _ensureConsent(taste) ||
        !mounted ||
        context.read<ApiService>().baseUrl != endpoint) return;
    setState(() {
      _isIngesting = true;
      _statusMessage = 'Extracting payment fields on this device...';
    });
    final result = await service.importManualSms(text);
    if (!mounted || context.read<ApiService>().baseUrl != endpoint) return;
    if (result.ingestedCount + result.duplicateCount > 0) {
      await taste.fetchProfile();
      await recs.fetchRecommendations(taste.activeUserId);
    }
    if (!mounted || context.read<ApiService>().baseUrl != endpoint) return;
    setState(() {
      _isIngesting = false;
      _statusSuccess = result.error == null && result.rejectedCount == 0;
      _statusMessage =
          '${_summary(result)}${result.error == null ? '' : '\n${result.error}'}';
      if (result.ingestedCount + result.duplicateCount > 0) {
        _smsController.clear();
        _previewPayment = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final smsService = context.watch<SmsListenerService>();
    final tasteProvider = context.watch<TasteProvider>();
    final recsProvider = context.read<RecsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📥 Data & SMS Ingest Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Swiggy & Zomato orders',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                        'Import a CSV, JSON or text file, or paste a receipt. '
                        'Review restaurants, dishes and possible payment matches before saving.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const FoodOrderImportScreen(),
                      )),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Import Swiggy / Zomato'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 1. One-Tap Full Phone Inbox Scanner Card
            Card(
              color: const Color(0xFF131D31),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side:
                    BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.history_edu,
                              color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan Full SMS Inbox',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary),
                              ),
                              Text(
                                'Dining payment alerts',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Reads historical messages from your inbox. Automatically parses bank debits (HDFC, ICICI, SBI, Axis, Kotak, IndusInd) and food orders (Swiggy, Zomato, Zepto) while stripping account numbers and balances on-device.',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed:
                            _isScanningInbox ? null : _scanHistoricalInbox,
                        icon: _isScanningInbox
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.search, size: 20),
                        label: Text(
                          _isScanningInbox
                              ? 'Scanning Inbox...'
                              : 'Scan Phone SMS & Ingest Past Debits',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    if (_scanStatusText != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _scanStatusText!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _lastScanResult != null
                                ? AppTheme.primary
                                : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Automatic Background Tracking Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (smsService.isListening
                                    ? AppTheme.primary
                                    : AppTheme.textMuted)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            smsService.isListening
                                ? Icons.sync
                                : Icons.sync_disabled,
                            color: smsService.isListening
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Real-Time Background Listener',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary),
                              ),
                              Text(
                                smsService.isListening
                                    ? 'Active • Listening for payment SMS'
                                    : 'Paused',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: smsService.isListening
                                      ? AppTheme.primary
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: smsService.isListening,
                          activeThumbColor: AppTheme.primary,
                          onChanged: (enabled) async {
                            if (enabled) {
                              if (!tasteProvider.hasDpdpConsent) {
                                final granted =
                                    await DpdpConsentDialog.show(context);
                                if (granted != true) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Auto-tracking requires DPDP Act 2023 consent.')),
                                    );
                                  }
                                  return;
                                }
                                await tasteProvider.grantConsent();
                                if (!mounted) return;
                              }

                              final ok = await smsService.startListening(
                                onNewIngestion: () {
                                  if (!mounted) return;
                                  tasteProvider.fetchProfile();
                                  recsProvider.fetchRecommendations(
                                      tasteProvider.activeUserId);
                                },
                              );
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'SMS permission required for auto-tracking')),
                                );
                              }
                            } else {
                              await smsService.stopListening();
                            }
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saves extracted dining payments on this device. Pending uploads retry when the app opens or resumes.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Manual Test & Paste Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Test or Paste SMS Alert',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),

                    // Quick Sample Buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: AppConstants.sampleSms.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.border),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                _smsController.text = e.value;
                                _onTextChanged(e.value);
                              },
                              child: Text('+ ${e.key} Sample',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.secondary)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Text Input
                    TextField(
                      controller: _smsController,
                      maxLines: 3,
                      onChanged: _onTextChanged,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText:
                            'Paste any Indian transactional SMS or food delivery alert here...',
                        hintStyle: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),

                    if (_previewPayment != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Merchant: ${_previewPayment!.normalizedMerchant}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primary),
                                ),
                                Text(
                                  '₹${_previewPayment!.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Only payment fields are uploaded. Raw SMS stays on this device.',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textMuted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isIngesting ? null : _submitManualSms,
                        icon: _isIngesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.bolt, size: 18),
                        label: Text(
                          _isIngesting ? 'Processing...' : 'Parse & Ingest SMS',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),

                    TextButton.icon(
                      onPressed: _isIngesting || _isScanningInbox
                          ? null
                          : _retryPending,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry pending imports'),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusSuccess
                              ? AppTheme.primary
                              : AppTheme.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. Recent Captures Feed
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🕒 Recent Import Outcomes',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    if (smsService.recentLogs.isEmpty)
                      const Text(
                        'No transactions ingested yet. Scan your SMS inbox above or use real-time tracking.',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      )
                    else
                      ...smsService.recentLogs.take(15).map((log) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.merchant,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary),
                                  ),
                                  Text(
                                    '${log.status} • ${log.bank ?? 'UPI'} • ${log.timestamp.day}/${log.timestamp.month} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${log.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

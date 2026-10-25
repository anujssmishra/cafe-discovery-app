import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/taste_provider.dart';
import '../providers/recs_provider.dart';
import '../widgets/dpdp_consent_dialog.dart';
import '../config/theme.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _urlController = TextEditingController();
  bool _testingConnection = false;
  String? _connectionStatus;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    final apiService = context.read<ApiService>();
    _urlController.text = apiService.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = null;
    });

    final apiService = context.read<ApiService>();
    await apiService.setBaseUrl(_urlController.text);

    final ok = await apiService.checkHealth();
    setState(() {
      _testingConnection = false;
      _connectionSuccess = ok;
      _connectionStatus = ok ? '✓ Connected to Food RecSys API!' : '✗ Cannot reach server at this address.';
    });

    if (ok && mounted) {
      final tasteProvider = context.read<TasteProvider>();
      final recsProvider = context.read<RecsProvider>();
      await tasteProvider.fetchProfile();
      await tasteProvider.checkConsent();
      await recsProvider.fetchRecommendations(tasteProvider.activeUserId);
    }
  }

  Future<void> _autoDetect() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = 'Scanning candidate endpoints...';
    });
    final apiService = context.read<ApiService>();
    final detected = await apiService.autoDetectWorkingEndpoint();
    if (detected != null) {
      _urlController.text = detected;
      setState(() {
        _testingConnection = false;
        _connectionSuccess = true;
        _connectionStatus = '✓ Connected to $detected!';
      });
      if (mounted) {
        final tasteProvider = context.read<TasteProvider>();
        final recsProvider = context.read<RecsProvider>();
        await tasteProvider.fetchProfile();
        await tasteProvider.checkConsent();
        await recsProvider.fetchRecommendations(tasteProvider.activeUserId);
      }
    } else {
      setState(() {
        _testingConnection = false;
        _connectionSuccess = false;
        _connectionStatus = '✗ Cannot reach server. Verify Mac is on same Wi-Fi or USB connected.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasteProvider = context.watch<TasteProvider>();
    final recsProvider = context.watch<RecsProvider>();

    final consentDate = tasteProvider.consentGrantedAt;
    final consentDateFormatted = consentDate != null
        ? '${consentDate.day}/${consentDate.month}/${consentDate.year}'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings & Privacy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Server Configuration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌐 RecSys Server Endpoint',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Use http://10.0.2.2:8000 for Android emulator, or your computer’s local IP (e.g. http://192.168.83.100:8000) for your Samsung Galaxy phone.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quick Connection Presets
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.wifi, size: 14, color: AppTheme.primary),
                          label: const Text('Wi-Fi (192.168.83.100)', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                          backgroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: AppTheme.border),
                          onPressed: () {
                            _urlController.text = 'http://192.168.83.100:8000';
                            _testConnection();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.usb, size: 14, color: AppTheme.secondary),
                          label: const Text('USB (localhost)', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                          backgroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: AppTheme.border),
                          onPressed: () {
                            _urlController.text = 'http://localhost:8000';
                            _testConnection();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.travel_explore, size: 14, color: AppTheme.warning),
                          label: const Text('Auto-Detect', style: TextStyle(fontSize: 11, color: AppTheme.warning)),
                          backgroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: AppTheme.warning),
                          onPressed: _autoDetect,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white),
                        onPressed: _testingConnection ? null : _testConnection,
                        icon: _testingConnection
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.network_check, size: 16),
                        label: const Text('Save & Test Connection'),
                      ),
                    ),
                    if (_connectionStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _connectionStatus!,
                        style: TextStyle(
                          color: _connectionSuccess ? AppTheme.primary : AppTheme.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Real Dining Profile Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '👤 My Dining Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Real Data',
                            style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Account Identifier: ${tasteProvider.activeUserId}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transactions Ingested: ${tasteProvider.totalTransactions} food orders recorded',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // DPDP Act 2023 Statutory Consent & Compliance Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: tasteProvider.hasDpdpConsent ? AppTheme.primary.withOpacity(0.4) : AppTheme.warning.withOpacity(0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🇮🇳',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Data Protection (DPDP Act 2023)',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              Text(
                                'Digital Personal Data Protection Act, 2023 • India',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Consent Status Badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: tasteProvider.hasDpdpConsent ? const Color(0xFF064E3B) : const Color(0xFF451A03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tasteProvider.hasDpdpConsent ? AppTheme.primary.withOpacity(0.3) : AppTheme.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tasteProvider.hasDpdpConsent ? Icons.check_circle : Icons.warning_amber_rounded,
                            color: tasteProvider.hasDpdpConsent ? AppTheme.primary : AppTheme.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tasteProvider.hasDpdpConsent
                                  ? 'Active Affirmative Consent (Granted ${consentDateFormatted ?? "recently"})'
                                  : 'Consent Not Granted / Revoked',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: tasteProvider.hasDpdpConsent ? AppTheme.primary : AppTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // View Notice Button (Section 5)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.secondary),
                          foregroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => DpdpConsentDialog.show(context, isReviewOnly: true),
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text('Review DPDP Act Section 5 Notice'),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Grant or Revoke Consent Button (Section 6 & 6(4))
                    if (tasteProvider.hasDpdpConsent) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.warning),
                            foregroundColor: AppTheme.warning,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.surface,
                                title: const Text('Revoke SMS Processing Consent?'),
                                content: const Text(
                                  'Under DPDP Act 2023 Sec 6(4), withdrawing consent halts all on-device SMS parsing immediately. Existing taste intelligence is preserved until you request erasure.',
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.black),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Revoke Consent'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await tasteProvider.revokeConsent();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('SMS processing consent revoked.')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text('Revoke SMS Consent (Section 6(4))'),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () async {
                            final granted = await DpdpConsentDialog.show(context);
                            if (granted == true) {
                              await tasteProvider.grantConsent();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Explicit affirmative consent recorded.')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Grant Affirmative Consent (Section 6)'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Right to Erasure / Right to be Forgotten (Section 12)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.danger),
                          foregroundColor: AppTheme.danger,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              title: const Text('Exercise Right to Erasure?'),
                              content: const Text(
                                'Under DPDP Act 2023 Section 12 (Right to Erasure / Right to be Forgotten), this will permanently purge all transactions, food orders, and reset your taste profile on the server.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Permanently Erase'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final ok = await tasteProvider.exerciseRightToErasure();
                            await recsProvider.fetchRecommendations(tasteProvider.activeUserId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ok ? 'All personal data erased (Right to be Forgotten enforced).' : 'Failed to erase data.')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_forever, size: 16),
                        label: const Text('🗑️ Right to Erasure / Forgotten (Sec 12)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // RBI / NPCI Financial Data Redaction Guarantee
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.security, size: 18, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'RBI & NPCI Financial Safeguards',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      '• Zero Account Exposure: Bank account digits (**1234, XX5678) and debit card numbers are masked on-device in memory.\n'
                      '• Zero Balance Capture: Available bank balances and credit limits are purged instantly before any network call.\n'
                      '• Pure Dining Filter: Only merchant names matching dining and food delivery (Swiggy, Zomato, Zepto, Blinkit) are processed.\n'
                      '• Zero Credential Access: OTPs, PINs, and personal communications are strictly never touched or logged.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Grievance Redressal Mechanism (Section 13)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.gavel, size: 18, color: AppTheme.secondary),
                        SizedBox(width: 8),
                        Text(
                          'Grievance Redressal (Section 13)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Designated Data Protection / Grievance Officer:\n'
                      'Email: grievance@foodrecsys.app\n'
                      'Response Time: Within 72 hours\n'
                      'Applicable Jurisdiction: Data Protection Board of India (DPBI)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
                    ),
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

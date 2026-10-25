import 'package:flutter/material.dart';
import '../config/theme.dart';

class DpdpConsentDialog extends StatefulWidget {
  final bool isReviewOnly;
  final VoidCallback? onConsentGranted;
  final VoidCallback? onConsentDenied;

  const DpdpConsentDialog({
    super.key,
    this.isReviewOnly = false,
    this.onConsentGranted,
    this.onConsentDenied,
  });

  static Future<bool?> show(
    BuildContext context, {
    bool isReviewOnly = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: isReviewOnly,
      builder: (ctx) => DpdpConsentDialog(
        isReviewOnly: isReviewOnly,
        onConsentGranted: () => Navigator.pop(ctx, true),
        onConsentDenied: () => Navigator.pop(ctx, false),
      ),
    );
  }

  @override
  State<DpdpConsentDialog> createState() => _DpdpConsentDialogState();
}

class _DpdpConsentDialogState extends State<DpdpConsentDialog> {
  bool _checkboxChecked = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_user, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '🇮🇳 DPDP Act 2023 Consent Notice',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Digital Personal Data Protection Act, 2023 (India)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isReviewOnly)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notice Header
                      _buildSectionHeader('1. STATUTORY NOTICE UNDER SECTION 5', Icons.info_outline),
                      const SizedBox(height: 6),
                      const Text(
                        'Food RecSys acts as Data Fiduciary. Before processing your personal data, we provide this notice describing the purpose, scope, and your legal rights under Indian law.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.45),
                      ),
                      const SizedBox(height: 14),

                      // Purpose
                      _buildSectionHeader('2. SPECIFIED PURPOSE OF PROCESSING', Icons.track_changes),
                      const SizedBox(height: 6),
                      const Text(
                        'Your device’s transactional notifications and SMS debits from food delivery applications (Swiggy, Zomato, Zepto, Blinkit, EatSure) and UPI alerts are parsed locally to extract:\n'
                        '• Restaurant & merchant brand name (e.g. Dastarkhwan, Roastery)\n'
                        '• Dining transaction amount (for budget and price tier estimation)\n'
                        '• Timestamp and day of week (for breakfast/lunch/dinner profiling)\n'
                        '• Cuisine classification to recommend matching cafes and dining spots.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.45),
                      ),
                      const SizedBox(height: 14),

                      // Financial Redaction Guarantee
                      _buildSectionHeader('3. STRICT FINANCIAL PRIVACY (RBI / NPCI STANDARDS)', Icons.lock_outline),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🛡️ On-Device Redaction Guarantee:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '• Bank account digits (**1234, XX5678) and card numbers are masked in memory and NEVER stored or uploaded.\n'
                              '• Available bank balances and credit limits are purged instantly.\n'
                              '• OTPs, PINs, passwords, and personal chats are strictly excluded.\n'
                              '• Non-dining transactions (salary, investments, utility bills) are immediately discarded.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Principal Rights
                      _buildSectionHeader('4. YOUR RIGHTS UNDER DPDP ACT 2023', Icons.shield_outlined),
                      const SizedBox(height: 6),
                      const Text(
                        '• Right to Withdraw Consent (Sec 6(4)): You may withdraw your consent at any time via Settings. All active listeners will stop immediately.\n'
                        '• Right to Erasure / Right to be Forgotten (Sec 12): You may permanently delete your taste profile, dining ledger, and recommendations.\n'
                        '• Right to Access (Sec 11): You can inspect the full chronological ledger of all processed transactions at any time.\n'
                        '• Grievance Redressal (Sec 13): Contact the designated Data Protection Officer at grievance@foodrecsys.app.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer with Checkbox & Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: widget.isReviewOnly
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close Notice', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  : Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _checkboxChecked = !_checkboxChecked),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _checkboxChecked,
                                activeColor: AppTheme.primary,
                                checkColor: Colors.black,
                                onChanged: (val) => setState(() => _checkboxChecked = val ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'I have read and agree to the DPDP Act 2023 notice and explicitly consent to on-device dining SMS parsing.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textPrimary, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.border),
                                  foregroundColor: AppTheme.textMuted,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: widget.onConsentDenied ?? () => Navigator.pop(context, false),
                                child: const Text('Disagree / Deny'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _checkboxChecked ? AppTheme.primary : AppTheme.surfaceElevated,
                                  foregroundColor: _checkboxChecked ? Colors.black : AppTheme.textMuted,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _checkboxChecked
                                    ? (widget.onConsentGranted ?? () => Navigator.pop(context, true))
                                    : null,
                                child: const Text('Agree & Consent', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.secondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

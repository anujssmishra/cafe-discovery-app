import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/taste_provider.dart';
import '../widgets/cuisine_bar.dart';
import '../widgets/dpdp_consent_dialog.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class TasteProfileTab extends StatelessWidget {
  const TasteProfileTab({super.key});

  void _showTransactionsModal(BuildContext context, String userId) {
    final apiService = context.read<ApiService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: apiService.getTransactions(userId, limit: 250),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Failed to load dining ledger: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.danger)),
                    ),
                  );
                }

                final data = snapshot.data ?? {};
                final totalSpent = (data['total_spent'] as num?)?.toDouble() ?? 0.0;
                final txList = (data['transactions'] as List<dynamic>?) ?? [];

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📜 Complete Dining Ledger',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${txList.length} verified orders • ₹${totalSpent.toStringAsFixed(0)} total',
                                style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textMuted),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppTheme.border, height: 1),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: txList.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E293B), height: 16),
                        itemBuilder: (context, i) {
                          final tx = txList[i] as Map<String, dynamic>;
                          final merchant = tx['merchant_name'] ?? 'Food Merchant';
                          final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                          final app = tx['payment_app'] ?? 'UPI';
                          final rawDate = tx['transaction_time']?.toString() ?? '';
                          final dtStr = rawDate.length >= 16 ? rawDate.substring(0, 16).replaceFirst('T', ' ') : rawDate;
                          final meal = tx['meal_type']?.toString().toUpperCase() ?? 'MEAL';
                          final rawCuisine = tx['cuisine']?.toString() ?? '';
                          final isDeliveryOnly = rawCuisine == 'unspecified';
                          final cuisineDisplay = isDeliveryOnly ? 'DELIVERY' : rawCuisine.replaceAll('_', ' ').toUpperCase();

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.restaurant, color: AppTheme.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      merchant,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$dtStr • $app',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppTheme.border),
                                          ),
                                          child: Text(
                                            meal,
                                            style: const TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        if (cuisineDisplay.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F172A),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppTheme.border),
                                            ),
                                            child: Text(
                                              cuisineDisplay,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDeliveryOnly ? AppTheme.textMuted : AppTheme.primary,
                                                fontWeight: isDeliveryOnly ? FontWeight.normal : FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${amt.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasteProvider = context.watch<TasteProvider>();
    final profile = tasteProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Taste Intelligence'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await tasteProvider.fetchProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: AppTheme.primary, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppConstants.userDisplayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF064E3B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield, color: AppTheme.primary, size: 11),
                                    SizedBox(width: 4),
                                    Text(
                                      'DPDP Act 2023 Compliant',
                                      style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: AppTheme.secondary, size: 20),
                      tooltip: 'DPDP Privacy Notice',
                      onPressed: () => DpdpConsentDialog.show(context, isReviewOnly: true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Overview Card with Ledger Access Button
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'UPI Food Transactions',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          Text(
                            '${profile?.totalFoodTransactions ?? 0} orders',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Average Spend / Meal',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          Text(
                            '₹${(profile?.avgSpend ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Taste Intelligence Version',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          Text(
                            'v${profile?.version ?? 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.secondary),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppTheme.border),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showTransactionsModal(context, tasteProvider.activeUserId),
                          icon: const Icon(Icons.receipt_long, color: AppTheme.primary, size: 18),
                          label: Text(
                            'View Full Dining Ledger (${profile?.totalFoodTransactions ?? 0} Orders)',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Cuisine Affinities Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🥘 Top Cuisine Affinities',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      if (profile == null || profile.cuisineAffinities.isEmpty)
                        const Text(
                          'No food orders recorded yet. Auto-ingest an SMS to build cuisine affinities.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        )
                      else
                        ...profile.cuisineAffinities.entries.take(5).map((e) {
                          return CuisineBar(cuisineKey: e.key, score: e.value);
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Price Band Distribution Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 Price Tier Distribution',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      if (profile == null || profile.priceDistribution.isEmpty)
                        const Text(
                          'No spending tiers detected yet.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        )
                      else
                        ...profile.priceDistribution.entries.map((e) {
                          final pct = (e.value * 100).round();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${e.key[0].toUpperCase()}${e.key.substring(1)} Tier',
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  '$pct%',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.warning),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Frequent Dining Hubs Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📍 Frequent Neighbourhoods',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      if (profile == null || profile.frequentAreas.isEmpty)
                        const Text(
                          'All areas in Lucknow',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        )
                      else
                        ...profile.frequentAreas.entries.take(4).map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                                Text('${e.value} visits', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
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
      ),
    );
  }
}

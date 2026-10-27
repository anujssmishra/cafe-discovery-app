import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/taste_provider.dart';
import '../models/taste_profile.dart';
import '../widgets/cuisine_bar.dart';
import '../widgets/dpdp_consent_dialog.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'dining_ledger_sheet.dart';
import 'restaurant_detail_screen.dart';

class TasteProfileTab extends StatelessWidget {
  const TasteProfileTab({super.key});

  void _showTransactionsModal(BuildContext context, String userId) {
    final apiService = context.read<ApiService>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => DiningLedgerSheet(
          apiService: apiService,
          userId: userId,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TasteProvider>();
    final profile = provider.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Taste intelligence'), actions: [
        IconButton(
          tooltip: 'Privacy notice',
          icon: const Icon(Icons.info_outline),
          onPressed: () => DpdpConsentDialog.show(context, isReviewOnly: true),
        ),
      ]),
      body: RefreshIndicator(
        onRefresh: provider.fetchProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(AppConstants.userDisplayName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (provider.isLoading) const LinearProgressIndicator(),
            if (provider.errorMessage != null)
              _card('Profile could not be refreshed', [
                Text(profile == null
                    ? 'Your dining history is unavailable. Retry when connected.'
                    : 'Showing the last loaded profile. Your saved history has not been cleared.'),
                TextButton(
                    onPressed: provider.fetchProfile,
                    child: const Text('Retry profile')),
              ]),
            if (profile != null)
              ..._profileCards(context, provider, profile)
            else if (provider.errorMessage == null && !provider.isLoading)
              _card('Profile not loaded', [
                TextButton(
                    onPressed: provider.fetchProfile,
                    child: const Text('Load profile')),
              ]),
          ],
        ),
      ),
    );
  }

  List<Widget> _profileCards(
      BuildContext context, TasteProvider provider, TasteProfile profile) {
    final cuisines = profile.cuisineAffinities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final areas = profile.frequentAreas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final restaurants = profile.topRestaurants.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final computedAt = profile.computedAt;
    return [
      if (computedAt != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
              'Updated ${DateFormat('d MMM y, HH:mm').format(computedAt.toLocal())} (local)',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ),
      if (profile.totalFoodTransactions == 0)
        _card('No dining transactions yet', [
          const Text(
              'Import dining payments from the Auto-Ingest tab to build your profile.'),
        ]),
      _card('Dining overview', [
        _stat('Food transactions', '${profile.totalFoodTransactions} orders'),
        _stat(
            'Average spend / transaction',
            profile.totalFoodTransactions == 0
                ? 'Not available yet'
                : '₹${profile.avgSpend.toStringAsFixed(2)}'),
        _stat('Profile version', 'v${profile.version}'),
        if (profile.knownCuisineTransactions != null)
          _stat('Transactions with identified cuisine',
              '${profile.knownCuisineTransactions} of ${profile.totalFoodTransactions}'),
        if (profile.unresolvedTransactions != null &&
            profile.unresolvedTransactions! > 0)
          Text(
              '${profile.unresolvedTransactions} payments have not been linked to a specific restaurant branch.',
              style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              _showTransactionsModal(context, provider.activeUserId),
          icon: const Icon(Icons.receipt_long),
          label: const Text('View dining ledger'),
        ),
      ]),
      _card('Cuisine affinities', [
        const Text('Share of transactions with a known cuisine.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        if (cuisines.isEmpty)
          const Text('Cuisine information is not available yet.')
        else
          ...cuisines.map(
              (entry) => CuisineBar(cuisineKey: entry.key, score: entry.value)),
      ]),
      _card('Price tiers', [
        if (profile.priceDistribution.isEmpty)
          const Text('Spending tiers are not available yet.')
        else
          ...profile.priceDistribution.entries.map((entry) => _stat(
              entry.key.replaceAll('_', ' '),
              '${(entry.value * 100).round()}%')),
      ]),
      _card('Meal patterns', [
        if (profile.mealPatterns.isEmpty)
          const Text('Meal timing is not available yet.')
        else
          ...profile.mealPatterns.entries.map((entry) {
            final pattern = entry.value is Map ? entry.value as Map : const {};
            final weekday = (pattern['weekday'] as num?)?.toInt() ?? 0;
            final weekend = (pattern['weekend'] as num?)?.toInt() ?? 0;
            return _stat(entry.key.replaceAll('_', ' '),
                '$weekday weekday • $weekend weekend');
          }),
      ]),
      _card('Most visited restaurants', [
        if (restaurants.isEmpty)
          const Text('No restaurants have been linked to your payments yet.')
        else
          ...restaurants.map((entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(profile.topRestaurantNames[entry.key] ??
                    'Restaurant name not recorded'),
                subtitle: Text('${entry.value} payments'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => RestaurantDetailScreen(
                    apiService: context.read<ApiService>(),
                    restaurantId: entry.key,
                  ),
                )),
              )),
      ]),
      _card('Frequent neighbourhoods', [
        if (areas.isEmpty)
          const Text('No neighbourhoods have been linked to your payments yet.')
        else
          ...areas.map((entry) => _stat(entry.key, '${entry.value} payments')),
      ]),
    ];
  }

  Widget _card(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ]),
      )),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

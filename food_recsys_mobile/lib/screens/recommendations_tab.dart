import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/taste_provider.dart';
import '../providers/recs_provider.dart';
import '../widgets/rec_card.dart';
import '../config/theme.dart';

class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({super.key});

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final tasteProvider = context.read<TasteProvider>();
    context
        .read<RecsProvider>()
        .fetchRecommendations(tasteProvider.activeUserId);
  }

  @override
  Widget build(BuildContext context) {
    final tasteProvider = context.watch<TasteProvider>();
    final recsProvider = context.watch<RecsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🍽️ Food RecSys',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'Curated for You • Taste Intelligence',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            tooltip: 'Refresh',
            onPressed: () {
              recsProvider.fetchRecommendations(tasteProvider.activeUserId);
              tasteProvider.fetchProfile();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await tasteProvider.fetchProfile();
          await recsProvider.fetchRecommendations(tasteProvider.activeUserId);
        },
        child: Column(
          children: [
            // Filters Bar (Meal chips & Area dropdown)
            _buildFiltersBar(tasteProvider, recsProvider),

            // Main Recommendations Content
            Expanded(
              child: _buildBody(tasteProvider, recsProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar(
      TasteProvider tasteProvider, RecsProvider recsProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Column(
        children: [
          // Meal chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: recsProvider.mealOptions.map((meal) {
                final isSelected = recsProvider.selectedMeal == meal;
                final label = meal == 'any'
                    ? 'All Day'
                    : '${meal.substring(0, 1).toUpperCase()}${meal.substring(1)}'
                        .replaceAll('_', ' ');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) =>
                        recsProvider.setMeal(meal, tasteProvider.activeUserId),
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color:
                              isSelected ? AppTheme.primary : AppTheme.border),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Area dropdown row
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              const Text('Area: ',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: recsProvider.selectedArea,
                    isDense: true,
                    dropdownColor: AppTheme.surface,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w600),
                    items: recsProvider.areaOptions.map((area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(area),
                      );
                    }).toList(),
                    onChanged: (newArea) {
                      if (newArea != null) {
                        recsProvider.setArea(
                            newArea, tasteProvider.activeUserId);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          if (recsProvider.filtersWarning != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(recsProvider.filtersWarning!,
                  style:
                      const TextStyle(color: AppTheme.warning, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(TasteProvider tasteProvider, RecsProvider recsProvider) {
    if (recsProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Analyzing UPI taste habits...',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (recsProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppTheme.danger),
              const SizedBox(height: 12),
              const Text(
                'Cannot connect to RecSys API',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => recsProvider
                    .fetchRecommendations(tasteProvider.activeUserId),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = recsProvider.recommendations;
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          if (recsProvider.response?.contextMessage != null)
            Text(recsProvider.response!.contextMessage!),
          const SizedBox(height: 16),
          const Text('No restaurants match current filters.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      );
    }

    final contextMessage = recsProvider.response?.contextMessage;
    final showContextMessage =
        contextMessage != null && contextMessage.isNotEmpty;
    final showColdStart = tasteProvider.isCleanProfile;
    final extraCount = (showColdStart ? 1 : 0) + (showContextMessage ? 1 : 0);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length + extraCount,
      itemBuilder: (context, index) {
        if (showContextMessage && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(contextMessage,
                style: const TextStyle(color: AppTheme.textSecondary)),
          );
        }
        if (showColdStart && index == (showContextMessage ? 1 : 0)) {
          // Cold-start helper banner
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.secondary.withOpacity(0.4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppTheme.secondary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No dining history yet. These are general discovery suggestions. Import dining payments in Auto-Ingest to personalize them.',
                    style: TextStyle(
                        color: Color(0xFF93C5FD), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }

        final item = items[index - extraCount];
        return RecCard(item: item);
      },
    );
  }
}

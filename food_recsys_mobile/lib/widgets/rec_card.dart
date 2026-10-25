import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class RecCard extends StatelessWidget {
  final RecommendationItem item;

  const RecCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final r = item.restaurant;
    final pctScore = (item.score * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Rank, Name, Score
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank Badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${item.rank}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (r.source == 'cafe_app') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 16, color: AppTheme.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📍 ${r.area}, ${r.city}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Match %
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$pctScore%',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Match',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tags row (Price tier, cuisines)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTag('${r.priceBand.toUpperCase()} TIER', AppTheme.warning),
                ...r.cuisines.map((c) {
                  final disp = AppConstants.cuisineNames[c] ?? c.replaceAll('_', ' ');
                  return _buildTag(disp, AppTheme.secondary);
                }),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 10),

            // Factual Reasons List
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: item.reasons.map((reason) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✓ ',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFCBD5E1),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

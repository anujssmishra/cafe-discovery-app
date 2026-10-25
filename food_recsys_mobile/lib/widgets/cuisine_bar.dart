import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class CuisineBar extends StatelessWidget {
  final String cuisineKey;
  final double score;

  const CuisineBar({super.key, required this.cuisineKey, required this.score});

  @override
  Widget build(BuildContext context) {
    final displayName = AppConstants.cuisineNames[cuisineKey] ?? cuisineKey.replaceAll('_', ' ');
    final pct = (score * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF0F172A),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

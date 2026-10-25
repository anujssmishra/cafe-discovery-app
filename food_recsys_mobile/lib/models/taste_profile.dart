class TasteProfile {
  final String userId;
  final Map<String, double> cuisineAffinities;
  final Map<String, double> priceDistribution;
  final Map<String, dynamic> mealPatterns;
  final Map<String, int> topRestaurants;
  final Map<String, int> frequentAreas;
  final int totalFoodTransactions;
  final double avgSpend;
  final int version;

  TasteProfile({
    required this.userId,
    required this.cuisineAffinities,
    required this.priceDistribution,
    required this.mealPatterns,
    required this.topRestaurants,
    required this.frequentAreas,
    required this.totalFoodTransactions,
    required this.avgSpend,
    required this.version,
  });

  factory TasteProfile.empty(String userId) {
    return TasteProfile(
      userId: userId,
      cuisineAffinities: {},
      priceDistribution: {},
      mealPatterns: {},
      topRestaurants: {},
      frequentAreas: {},
      totalFoodTransactions: 0,
      avgSpend: 0.0,
      version: 1,
    );
  }

  factory TasteProfile.fromJson(Map<String, dynamic> json) {
    // Parse affinities safely
    final rawCuisines = json['cuisine_affinities'] as Map<String, dynamic>? ?? {};
    final parsedCuisines = rawCuisines.map((k, v) => MapEntry(k, (v as num).toDouble()));

    // Parse prices safely
    final rawPrices = json['price_distribution'] as Map<String, dynamic>? ?? {};
    final parsedPrices = rawPrices.map((k, v) => MapEntry(k, (v as num).toDouble()));

    // Parse areas safely
    final rawAreas = json['frequent_areas'] as Map<String, dynamic>? ?? {};
    final parsedAreas = rawAreas.map((k, v) => MapEntry(k, (v as num).toInt()));

    return TasteProfile(
      userId: json['user_id'] ?? '',
      cuisineAffinities: parsedCuisines,
      priceDistribution: parsedPrices,
      mealPatterns: json['meal_patterns'] as Map<String, dynamic>? ?? {},
      topRestaurants: (json['top_restaurants'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      frequentAreas: parsedAreas,
      totalFoodTransactions: (json['total_food_transactions'] as num?)?.toInt() ?? 0,
      avgSpend: (json['avg_spend'] as num?)?.toDouble() ?? 0.0,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

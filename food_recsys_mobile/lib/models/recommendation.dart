import 'restaurant.dart';

class ScoreBreakdown {
  final double cuisineScore;
  final double priceScore;
  final double noveltyScore;
  final double geoScore;
  final double totalScore;

  ScoreBreakdown({
    required this.cuisineScore,
    required this.priceScore,
    required this.noveltyScore,
    required this.geoScore,
    required this.totalScore,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      cuisineScore: (json['cuisine_score'] as num?)?.toDouble() ?? 0.0,
      priceScore: (json['price_score'] as num?)?.toDouble() ?? 0.0,
      noveltyScore: (json['novelty_score'] as num?)?.toDouble() ?? 0.0,
      geoScore: (json['geo_score'] as num?)?.toDouble() ?? 0.0,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RecommendationItem {
  final int rank;
  final Restaurant restaurant;
  final double score;
  final List<String> reasons;
  final ScoreBreakdown scoreBreakdown;

  RecommendationItem({
    required this.rank,
    required this.restaurant,
    required this.score,
    required this.reasons,
    required this.scoreBreakdown,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      restaurant: Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      reasons: (json['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      scoreBreakdown: ScoreBreakdown.fromJson(json['score_breakdown'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class RecommendationResponse {
  final String userId;
  final String mealContext;
  final int count;
  final List<RecommendationItem> recommendations;

  RecommendationResponse({
    required this.userId,
    required this.mealContext,
    required this.count,
    required this.recommendations,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    final list = json['recommendations'] as List<dynamic>? ?? [];
    return RecommendationResponse(
      userId: json['user_id'] ?? '',
      mealContext: json['meal_context'] ?? 'any',
      count: (json['count'] as num?)?.toInt() ?? list.length,
      recommendations: list.map((e) => RecommendationItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

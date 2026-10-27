class Restaurant {
  final String id;
  final String name;
  final String city;
  final String area;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> cuisines;
  final String priceBand;
  final double? avgRating;
  final String source;
  final bool isActive;
  final String? photoUrl;
  final String? heroImageUrl;
  final String? website;
  final List<String> vibeTags;
  final List<String> foodHighlights;
  final List<Map<String, dynamic>> offerings;

  Restaurant({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    this.address,
    this.latitude,
    this.longitude,
    required this.cuisines,
    required this.priceBand,
    this.avgRating,
    required this.source,
    required this.isActive,
    this.photoUrl,
    this.heroImageUrl,
    this.website,
    this.vibeTags = const [],
    this.foodHighlights = const [],
    this.offerings = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'],
      latitude: (json['latitude'] != null)
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: (json['longitude'] != null)
          ? (json['longitude'] as num).toDouble()
          : null,
      cuisines: (json['cuisines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      priceBand: json['price_band'] ?? 'unknown',
      avgRating: (json['avg_rating'] != null)
          ? (json['avg_rating'] as num).toDouble()
          : null,
      source: json['source'] ?? 'unknown',
      isActive: json['is_active'] ?? false,
      photoUrl: json['photo_url'] as String?,
      heroImageUrl: json['hero_image_url'] as String?,
      website: json['website'] as String?,
      vibeTags: (json['vibe_tags'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      foodHighlights: (json['food_highlights'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      offerings: (json['offerings'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }
}

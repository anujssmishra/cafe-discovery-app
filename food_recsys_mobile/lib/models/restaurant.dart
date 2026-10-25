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
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'],
      latitude: (json['latitude'] != null) ? (json['latitude'] as num).toDouble() : null,
      longitude: (json['longitude'] != null) ? (json['longitude'] as num).toDouble() : null,
      cuisines: (json['cuisines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      priceBand: json['price_band'] ?? 'moderate',
      avgRating: (json['avg_rating'] != null) ? (json['avg_rating'] as num).toDouble() : null,
      source: json['source'] ?? 'manual',
      isActive: json['is_active'] ?? true,
    );
  }
}

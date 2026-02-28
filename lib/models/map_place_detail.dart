import 'map_place.dart';

/// A single review for a place/challenge.
class Review {
  final String id;
  final String username;
  final DateTime date;
  final double rating;
  final String comment;

  const Review({
    required this.id,
    required this.username,
    required this.date,
    required this.rating,
    required this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      username: json['username'] as String,
      date: DateTime.parse(json['date'] as String),
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
    );
  }
}

/// Full detail for a map place/challenge, used by the Challenge Detail screen.
///
/// Extends the map listing data with optional listing fields (hours, category,
/// image) and reviews. In production this will be returned by a dedicated
/// API (e.g. GET /places/:id or /challenges/:id); for now the repository
/// builds it from [MapPlace] and stub reviews.
class MapPlaceDetail {
  /// Core fields from [MapPlace].
  final String id;
  final String title;
  final String description;
  final String location;
  final String priceLabel;
  final double latitude;
  final double longitude;
  final String colorHex;

  /// Optional listing details (null if not available).
  final String? imageUrl;
  final String? category;
  final String? hours;
  final List<String> tags;
  final double? distanceKm;
  final String? estimatedDuration;
  final String? difficulty;
  final int? rewardPoints;

  final List<Review> reviews;

  const MapPlaceDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.priceLabel,
    required this.latitude,
    required this.longitude,
    required this.colorHex,
    this.imageUrl,
    this.category,
    this.hours,
    this.tags = const [],
    this.distanceKm,
    this.estimatedDuration,
    this.difficulty,
    this.rewardPoints,
    this.reviews = const [],
  });

  /// Build from a [MapPlace] plus optional overrides and reviews.
  factory MapPlaceDetail.fromMapPlace(
    MapPlace place, {
    String? imageUrl,
    String? category,
    String? hours,
    List<String>? tags,
    double? distanceKm,
    String? estimatedDuration,
    String? difficulty,
    int? rewardPoints,
    List<Review>? reviews,
  }) {
    return MapPlaceDetail(
      id: place.id,
      title: place.title,
      description: place.description,
      location: place.location,
      priceLabel: place.priceLabel,
      latitude: place.latitude,
      longitude: place.longitude,
      colorHex: place.colorHex,
      imageUrl: imageUrl,
      category: category,
      hours: hours,
      tags: tags ?? [],
      distanceKm: distanceKm,
      estimatedDuration: estimatedDuration,
      difficulty: difficulty,
      rewardPoints: rewardPoints,
      reviews: reviews ?? [],
    );
  }

  double get averageRating {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }
}

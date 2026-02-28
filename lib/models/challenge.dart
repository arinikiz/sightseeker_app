class Challenge {
  final String id;
  final String title;
  final String description;
  final String type; // photo, food, activity
  final double latitude;
  final double longitude;
  final int points;
  final String difficulty; // easy, medium, hard
  final String badge;
  final Map<String, dynamic>? sponsor;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.points,
    required this.difficulty,
    required this.badge,
    this.sponsor,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      points: json['points'] as int,
      difficulty: json['difficulty'] as String,
      badge: json['badge'] as String,
      sponsor: json['sponsor'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'points': points,
      'difficulty': difficulty,
      'badge': badge,
      'sponsor': sponsor,
    };
  }
}

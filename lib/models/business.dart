class Business {
  final String id;
  final String name;
  final String type; // restaurant, tourism, attraction, gallery
  final double? latitude;
  final double? longitude;
  final List<String> sponsoredChallenges;

  Business({
    required this.id,
    required this.name,
    required this.type,
    this.latitude,
    this.longitude,
    List<String>? sponsoredChallenges,
  }) : sponsoredChallenges = sponsoredChallenges ?? [];

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sponsoredChallenges: List<String>.from(json['sponsoredChallenges'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'sponsoredChallenges': sponsoredChallenges,
    };
  }
}

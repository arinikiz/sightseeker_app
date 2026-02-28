import 'package:flutter/foundation.dart';

/// Data model representing a place that can appear on the map.
///
/// This is the shape that the backend endpoint should eventually return
/// (or be easily mappable to), so that the map UI can stay unchanged.
class MapPlace {
  final String id;
  final String title;
  final String location;
  final String priceLabel;
  final String description;
  final double latitude;
  final double longitude;
  /// Hex color string used to derive marker color (for example: "#E53935").
  final String colorHex;

  const MapPlace({
    required this.id,
    required this.title,
    required this.location,
    required this.priceLabel,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.colorHex,
  });

  factory MapPlace.fromJson(Map<String, dynamic> json) {
    return MapPlace(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      priceLabel: json['price_label'] as String,
      description: json['description'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      colorHex: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'location': location,
      'price_label': priceLabel,
      'description': description,
      'lat': latitude,
      'lng': longitude,
      'color': colorHex,
    };
  }

  @override
  String toString() {
    return 'MapPlace(id: $id, title: $title, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapPlace && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

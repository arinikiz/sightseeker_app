import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'route_stop.dart';

/// A named route with stops and an estimated duration.
/// Used for the Routes screen to display a path on the map.
class AppRoute {
  final String id;
  final String title;
  final List<RouteStop> stops;
  /// Estimated duration in minutes.
  final int durationMinutes;
  /// Ordered path points for drawing the polyline (can include points between stops).
  final List<LatLng> polylinePoints;
  /// Human-readable duration from Directions API (e.g. "18 mins").
  final String? durationText;
  /// Human-readable distance from Directions API (e.g. "9.2 km").
  final String? distanceText;

  const AppRoute({
    required this.id,
    required this.title,
    required this.stops,
    required this.durationMinutes,
    required this.polylinePoints,
    this.durationText,
    this.distanceText,
  });

  RouteStop? get origin => stops.isNotEmpty ? stops.first : null;
  RouteStop? get destination => stops.length > 1 ? stops.last : null;
}

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A single stop on a route (e.g. restaurant or point of interest).
class RouteStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const RouteStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  LatLng get position => LatLng(latitude, longitude);
}

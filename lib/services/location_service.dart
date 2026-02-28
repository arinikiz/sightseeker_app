import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Map<String, double>> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  Future<bool> isNearChallenge(
    double lat,
    double lng, {
    double radiusMeters = 500,
  }) async {
    final current = await getCurrentLocation();
    final distance = Geolocator.distanceBetween(
      current['latitude']!,
      current['longitude']!,
      lat,
      lng,
    );
    return distance <= radiusMeters;
  }
}

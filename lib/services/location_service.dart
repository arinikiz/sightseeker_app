class LocationService {
  // TODO: Implement GPS + geofencing using geolocator package

  Future<Map<String, double>> getCurrentLocation() async {
    // TODO: Return {latitude, longitude}
    throw UnimplementedError();
  }

  Future<bool> isNearChallenge(double lat, double lng, {double radiusMeters = 200}) async {
    // TODO: Check if user is within radius of a challenge location
    throw UnimplementedError();
  }
}

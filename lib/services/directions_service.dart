import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys_provider.dart';

/// Thrown when the Directions API returns a non-OK status.
class DirectionsException implements Exception {
  final String status;
  final String? message;
  DirectionsException(this.status, [this.message]);
  @override
  String toString() => message != null ? '$status: $message' : status;
}

/// Result of a Google Directions API call: decoded polyline points, duration, and distance.
class DirectionsResult {
  final List<LatLng> polylinePoints;
  final int durationMinutes;
  /// Human-readable duration from the API (e.g. "18 mins").
  final String? durationText;
  /// Human-readable distance from the API (e.g. "9.2 km").
  final String? distanceText;

  const DirectionsResult({
    required this.polylinePoints,
    required this.durationMinutes,
    this.durationText,
    this.distanceText,
  });
}

/// Fetches real route geometry and duration from the Google Directions API.
class DirectionsService {
  DirectionsService({String? apiKey})
      : _apiKey = apiKey ?? getGoogleMapsApiKey();

  final String _apiKey;

  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Fetches driving directions from origin to destination.
  /// Uses [departureTimeNow] to request duration_in_traffic when supported.
  /// Returns null if the API key is missing, the request fails, or the response has no routes.
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    bool departureTimeNow = true,
  }) async {
    if (_apiKey.isEmpty) return null;

    final queryParams = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'key': _apiKey,
      'mode': 'driving',
    };
    if (departureTimeNow) {
      queryParams['departure_time'] = 'now';
    }
    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') {
        final errorMessage = data['error_message'] as String?;
        throw DirectionsException(status ?? 'UNKNOWN', errorMessage);
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>?;
      final encodedPoints = overviewPolyline?['points'] as String?;
      if (encodedPoints == null || encodedPoints.isEmpty) return null;

      final points = _decodePolyline(encodedPoints);
      if (points.isEmpty) return null;

      int durationSeconds = 0;
      String? durationText;
      String? distanceText;
      final legs = route['legs'] as List<dynamic>?;
      if (legs != null && legs.isNotEmpty) {
        final leg = legs.first as Map<String, dynamic>;
        final duration = leg['duration'] as Map<String, dynamic>?;
        if (duration != null && duration['value'] != null) {
          durationSeconds = (duration['value'] as num).toInt();
        }
        durationText = (leg['duration_in_traffic'] as Map<String, dynamic>?)?['text'] as String? ??
            duration?['text'] as String?;
        distanceText = (leg['distance'] as Map<String, dynamic>?)?['text'] as String?;
      }
      final durationMinutes = (durationSeconds / 60).ceil();

      return DirectionsResult(
        polylinePoints: points,
        durationMinutes: durationMinutes > 0 ? durationMinutes : 1,
        durationText: durationText,
        distanceText: distanceText,
      );
    } on DirectionsException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Decodes a Google encoded polyline string into a list of [LatLng].
  /// See: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}

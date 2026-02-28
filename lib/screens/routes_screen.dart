import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/theme.dart';
import '../data/hardcoded_routes.dart';
import '../models/app_route.dart';
import '../services/directions_service.dart' show DirectionsService, DirectionsResult, DirectionsException;

/// Routes tab screen: shows a map with a route polyline and markers,
/// and a bottom card with route title, stop tiles, and estimated duration.
/// Uses the Google Directions API to show real driving directions between stops.
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  GoogleMapController? _mapController;
  final DirectionsService _directionsService = DirectionsService();

  /// Currently displayed route (polyline and duration from Directions API when available).
  late AppRoute _currentRoute;

  bool _isLoadingDirections = true;
  String? _directionsError;

  /// Red hue for origin/destination markers.
  static const double _redHue = 0.0; // BitmapDescriptor.hueRed

  @override
  void initState() {
    super.initState();
    _currentRoute = hardcodedRoutes.isNotEmpty
        ? hardcodedRoutes.first
        : _placeholderRoute();
    _fetchDirections();
  }

  /// Fetches real directions from the Google Directions API and updates the route.
  Future<void> _fetchDirections() async {
    final origin = _currentRoute.origin;
    final destination = _currentRoute.destination;
    if (origin == null || destination == null) {
      setState(() {
        _isLoadingDirections = false;
        _directionsError = 'Route needs at least two stops.';
      });
      return;
    }

    setState(() {
      _isLoadingDirections = true;
      _directionsError = null;
    });

    try {
      final result = await _directionsService.getDirections(
        origin: origin.position,
        destination: destination.position,
      );

      if (!mounted) return;
      setState(() {
        _isLoadingDirections = false;
        if (result != null) {
          _currentRoute = AppRoute(
            id: _currentRoute.id,
            title: _currentRoute.title,
            stops: _currentRoute.stops,
            durationMinutes: result.durationMinutes,
            polylinePoints: result.polylinePoints,
            durationText: result.durationText,
            distanceText: result.distanceText,
          );
          _directionsError = null;
        } else {
          _directionsError = 'Could not load directions. Check your API key and network.';
        }
      });
    } on DirectionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDirections = false;
        _directionsError = e.message ?? 'Directions error: ${e.status}';
      });
    }
  }

  AppRoute _placeholderRoute() {
    return AppRoute(
      id: 'placeholder',
      title: 'No routes',
      stops: [],
      durationMinutes: 0,
      polylinePoints: [],
    );
  }

  /// Initial camera position: centered on the route bounds (stops or polyline).
  CameraPosition get _initialCameraPosition {
    final points = _currentRoute.polylinePoints;
    final stops = _currentRoute.stops;
    if (points.isNotEmpty) {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      final center = LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );
      return CameraPosition(target: center, zoom: 15);
    }
    if (stops.length >= 2) {
      final a = stops.first.position;
      final b = stops.last.position;
      final center = LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );
      return CameraPosition(target: center, zoom: 14);
    }
    return const CameraPosition(
      target: LatLng(22.3193, 114.1694),
      zoom: 14,
    );
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};
    final origin = _currentRoute.origin;
    final destination = _currentRoute.destination;
    if (origin != null) {
      markers.add(
        Marker(
          markerId: MarkerId('origin_${origin.id}'),
          position: origin.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(_redHue),
          zIndex: 1,
        ),
      );
    }
    if (destination != null && destination.id != origin?.id) {
      markers.add(
        Marker(
          markerId: MarkerId('destination_${destination.id}'),
          position: destination.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(_redHue),
          zIndex: 2,
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final points = _currentRoute.polylinePoints;
    if (points.length < 2) return {};
    // White border effect: draw a slightly wider white line under the dark line.
    return {
      Polyline(
        polylineId: const PolylineId('route_border'),
        points: points,
        color: Colors.white,
        width: 8,
        zIndex: 0,
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: const Color(0xFF424242),
        width: 5,
        zIndex: 1,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Routes'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () {
                  // TODO: open menu / options
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.menu, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          // Loading overlay while fetching directions
          if (_isLoadingDirections)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Loading directions…',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Error message when directions fail
          if (_directionsError != null && !_isLoadingDirections)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _directionsError!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchDirections,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Bottom route card (matching screenshot)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _RouteCard(
              route: _currentRoute,
              isLoadingDuration: _isLoadingDirections,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom white card: route title, stop tiles, estimated duration.
class _RouteCard extends StatelessWidget {
  final AppRoute route;
  final bool isLoadingDuration;

  const _RouteCard({required this.route, this.isLoadingDuration = false});

  /// Reddish-brown used for stop tiles in the screenshot.
  static const Color _stopTileColor = Color(0xFF6D4C41);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 16),
              // Stop tiles (e.g. Mama's Restaurant, Luk Yueng)
              if (route.stops.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: route.stops.map((stop) {
                    return Material(
                      color: _stopTileColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Text(
                            stop.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              // ETA and distance row (matches Directions API text: "ETA: 18 mins • Distance: 9.2 km")
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule,
                      size: 20,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Duration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoadingDuration
                              ? '—'
                              : (route.durationText != null && route.distanceText != null
                                  ? 'ETA: ${route.durationText} • Distance: ${route.distanceText}'
                                  : route.durationMinutes > 0
                                      ? '${route.durationMinutes} min'
                                      : '— min'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

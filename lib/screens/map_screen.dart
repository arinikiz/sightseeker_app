import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../models/map_place.dart';
import '../services/api_service.dart';
import '../services/map_places_repository.dart';
import '../widgets/map_place_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(22.3193, 114.1694), // Hong Kong
    zoom: 12,
  );

  GoogleMapController? _mapController;

  final MapPlacesRepository _repository =
      ApiMapPlacesRepository(ApiService());

  final List<_ChallengerPlace> _places = [];

  Set<Marker> _markers = {};

  _ChallengerPlace? _selectedPlace;

  final Map<String, BitmapDescriptor> _defaultIcons = {};
  final Map<String, BitmapDescriptor> _selectedIcons = {};
  bool _iconsReady = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await _repository.loadPlaces();
      if (!mounted) return;
      setState(() {
        _places
          ..clear()
          ..addAll(
            places.map(_mapPlaceToChallenger),
          );
        _buildMarkers();
      });
      await _loadMarkerIcons();
    } catch (_) {
      // If loading fails we simply leave the map empty for now.
    }
  }

  _ChallengerPlace _mapPlaceToChallenger(MapPlace place) {
    final color = _parseColor(place.colorHex);
    final hue = _colorToHue(color);
    return _ChallengerPlace(
      id: place.id,
      title: place.title,
      location: place.location,
      priceLabel: place.priceLabel,
      description: place.description,
      position: LatLng(place.latitude, place.longitude),
      markerHue: hue,
      markerColor: color,
    );
  }

  Color _parseColor(String hex) {
    var value = hex.trim();
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    return Color(int.parse(value, radix: 16));
  }

  double _colorToHue(Color color) {
    return HSLColor.fromColor(color).hue;
  }

  void _onMarkerTapped(_ChallengerPlace place) {
    setState(() {
      if (_selectedPlace?.id == place.id) {
        _selectedPlace = null;
      } else {
        _selectedPlace = place;
      }
      _buildMarkers();
    });
  }

  void _buildMarkers() {
    _markers = _places.map((place) {
      final isSelected = place.id == _selectedPlace?.id;

      BitmapDescriptor icon;
      if (_iconsReady) {
        icon = isSelected
            ? _selectedIcons[place.id] ??
                BitmapDescriptor.defaultMarkerWithHue(place.markerHue)
            : _defaultIcons[place.id] ??
                BitmapDescriptor.defaultMarkerWithHue(place.markerHue);
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(place.markerHue);
      }

      return Marker(
        markerId: MarkerId(place.id),
        position: place.position,
        icon: icon,
        zIndex: isSelected ? 2 : 1,
        onTap: () => _onMarkerTapped(place),
      );
    }).toSet();
  }

  Future<void> _loadMarkerIcons() async {
    final Map<String, BitmapDescriptor> defaultIcons = {};
    final Map<String, BitmapDescriptor> selectedIcons = {};

    for (final place in _places) {
      // Slightly smaller, compact markers for default state,
      // and a modestly larger version for the selected state.
      final normal =
          await _buildMarkerBitmap(place.markerColor, 52, isSelected: false);
      final selected =
          await _buildMarkerBitmap(place.markerColor, 68, isSelected: true);
      defaultIcons[place.id] = normal;
      selectedIcons[place.id] = selected;
    }

    if (!mounted) return;

    setState(() {
      _defaultIcons
        ..clear()
        ..addAll(defaultIcons);
      _selectedIcons
        ..clear()
        ..addAll(selectedIcons);
      _iconsReady = true;
      _buildMarkers();
    });
  }

  Future<BitmapDescriptor> _buildMarkerBitmap(
    Color color,
    double size, {
    required bool isSelected,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Overall canvas is square; we'll position the circular marker slightly
    // toward the top so there is room to draw the pointer stem underneath.
    final double centerX = size / 2;
    final double circleRadius = size * 0.26;
    final Offset circleCenter = Offset(centerX, size * 0.36);

    // Optional glow when selected, matching the soft halo from the design.
    if (isSelected) {
      final Paint glowPaint = Paint()
        ..color = color.withOpacity(0.45);
      canvas.drawCircle(
        circleCenter,
        circleRadius * 1.8,
        glowPaint,
      );
    }

    // Pointer stem beneath the circle.
    final Path stemPath = Path()
      ..moveTo(circleCenter.dx, circleCenter.dy + circleRadius)
      ..lineTo(circleCenter.dx - circleRadius * 0.55, size - size * 0.12)
      ..lineTo(circleCenter.dx + circleRadius * 0.55, size - size * 0.12)
      ..close();
    final Paint stemPaint = Paint()..color = color;
    canvas.drawPath(stemPath, stemPaint);

    // White backing circle to match the crisp ring.
    final double outerRadius = circleRadius + size * 0.06;
    final Paint backingPaint = Paint()..color = Colors.white;
    canvas.drawCircle(circleCenter, outerRadius, backingPaint);

    // Colored ring around the photo.
    final Paint ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06;
    canvas.drawCircle(circleCenter, outerRadius - ringPaint.strokeWidth / 2,
        ringPaint);

    // Inner circular "photo" area with a blue-toned gradient similar to the mock.
    final Rect photoRect =
        Rect.fromCircle(center: circleCenter, radius: circleRadius);
    final Paint photoPaint = Paint()
      ..shader = ui.Gradient.linear(
        photoRect.topLeft,
        photoRect.bottomRight,
        const [
          Color(0xFF6EC6FF),
          Color(0xFF01579B),
        ],
      );

    canvas.save();
    final Path clipPath = Path()..addOval(photoRect);
    canvas.clipPath(clipPath);
    canvas.drawRect(photoRect, photoPaint);
    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image =
        await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlace = _selectedPlace;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Base interactive map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onTap: (_) {
                // Close any open marker/card when tapping on the map background.
                if (_selectedPlace != null) {
                  setState(() {
                    _selectedPlace = null;
                    _buildMarkers();
                  });
                }
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
          // Subtle gradient overlay to improve text legibility
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Bottom place details card for the currently selected marker
          if (selectedPlace != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + kBottomNavigationBarHeight,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),
                  child: MapPlaceCard(
                    placeId: selectedPlace.id,
                    title: selectedPlace.title,
                    location: selectedPlace.location,
                    priceLabel: selectedPlace.priceLabel,
                    description: selectedPlace.description,
                    onViewDetails: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.challengeDetail,
                        arguments: selectedPlace.id,
                      );
                    },
                    onStartChallenge: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.challengeDetail,
                        arguments: selectedPlace.id,
                      );
                    },
                  ),
                ),
              ),
            ),
          // Bottom drag handle-style indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengerPlace {
  final String id;
  final String title;
  final String location;
  final String priceLabel;
  final String description;
  final LatLng position;
  final double markerHue;
  final Color markerColor;

  const _ChallengerPlace({
    required this.id,
    required this.title,
    required this.location,
    required this.priceLabel,
    required this.description,
    required this.position,
    required this.markerHue,
    required this.markerColor,
  });
}

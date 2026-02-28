import '../models/map_place.dart';
import '../models/map_place_detail.dart';
import 'api_service.dart';
import 'dataBaseInteractions.dart';

/// Abstraction for loading map places.
///
/// `MapScreen` depends only on this interface so that switching from
/// hardcoded/demo data to a real backend endpoint does not require
/// changing the UI code.
abstract class MapPlacesRepository {
  Future<List<MapPlace>> loadPlaces();

  /// Fetches full detail for a single place by id (for the Challenge Detail screen).
  /// Returns null if not found. In production, replace with API call (e.g. GET /places/:id).
  Future<MapPlaceDetail?> getPlaceDetailById(String id);
}

/// Repository that will ultimately talk to the backend API.
///
/// For now this returns a few hardcoded places so the UI can work
/// without a live endpoint. When the backend is ready, implement this
/// using [ApiService] and keep `MapScreen` unchanged.
class ApiMapPlacesRepository implements MapPlacesRepository {
  final ApiService apiService;

  ApiMapPlacesRepository(this.apiService);

  static const List<MapPlace> _stubPlaces = [
    MapPlace(
      id: 'big_buddha',
      title: 'Big Buddha Challenge',
      location: 'Lantau Island, Hong Kong',
      priceLabel: '230 HKD',
      description:
          'Climb the steps to the iconic Tian Tan Buddha, take in panoramic views, and unlock a special achievement at the summit.',
      latitude: 22.2530,
      longitude: 113.9048,
      colorHex: '#E53935',
    ),
    MapPlace(
      id: 'kowloon_challenge',
      title: 'Kowloon Night Lights',
      location: 'Kowloon, Hong Kong',
      priceLabel: 'Free',
      description:
          'Stroll through the neon-lit streets of Kowloon, discover hidden alleys, and capture three photo checkpoints.',
      latitude: 22.3050,
      longitude: 114.1850,
      colorHex: '#FFB300',
    ),
    MapPlace(
      id: 'victoria_peak',
      title: 'Victoria Peak Trail',
      location: 'Victoria Peak, Hong Kong',
      priceLabel: '120 HKD',
      description:
          'Hike up to Victoria Peak, complete the scenic loop, and collect virtual tokens at each viewpoint platform.',
      latitude: 22.3350,
      longitude: 114.1600,
      colorHex: '#43A047',
    ),
  ];

  @override
  Future<List<MapPlace>> loadPlaces() async {
    try {
      final challenges = await ChallengeService().fetchAllChallenges();
      if (challenges.isNotEmpty) {
        return challenges.map((c) {
          final loc = c['location'] as List<dynamic>? ?? [];
          final lat = loc.length >= 1 ? (loc[0] as num).toDouble() : 22.3193;
          final lng = loc.length >= 2 ? (loc[1] as num).toDouble() : 114.1694;
          return MapPlace(
            id: c['chlgID'] as String,
            title: c['title'] as String? ?? '',
            location: 'Hong Kong',
            priceLabel: 'Free',
            description: c['description'] as String? ?? '',
            latitude: lat,
            longitude: lng,
            colorHex: '#43A047',
          );
        }).toList();
      }
    } catch (_) {}
    return _stubPlaces;
  }

  @override
  Future<MapPlaceDetail?> getPlaceDetailById(String id) async {
    // 1. Try stub (map) places first.
    final matches = _stubPlaces.where((p) => p.id == id).toList();
    if (matches.isNotEmpty) {
      final place = matches.first;
      final stubReviews = _stubReviewsFor(id);
      return MapPlaceDetail.fromMapPlace(
        place,
        category: 'Adventure',
        hours: 'Sunrise – Sunset',
        tags: ['hiking', 'photo', 'landmark'],
        distanceKm: id == 'big_buddha' ? 12.0 : (id == 'victoria_peak' ? 5.0 : 2.0),
        estimatedDuration: id == 'big_buddha' ? '2–3 hours' : '1–2 hours',
        difficulty: id == 'big_buddha' ? 'Medium' : 'Easy',
        rewardPoints: 150,
        reviews: stubReviews,
      );
    }
    // 2. Fallback: load from Firestore (e.g. profile joined/completed challenges).
    final firestoreDetail = await fetchChallengeDetailById(id);
    if (firestoreDetail == null) return null;
    return MapPlaceDetail(
      id: firestoreDetail['id'] as String,
      title: firestoreDetail['title'] as String,
      description: firestoreDetail['description'] as String,
      location: firestoreDetail['location'] as String,
      priceLabel: firestoreDetail['priceLabel'] as String? ?? '',
      latitude: (firestoreDetail['latitude'] as num).toDouble(),
      longitude: (firestoreDetail['longitude'] as num).toDouble(),
      colorHex: firestoreDetail['colorHex'] as String? ?? '#43A047',
      imageUrl: firestoreDetail['imageUrl'] as String?,
      category: firestoreDetail['category'] as String?,
      hours: firestoreDetail['hours'] as String?,
      tags: List<String>.from(firestoreDetail['tags'] ?? []),
      distanceKm: (firestoreDetail['distanceKm'] as num?)?.toDouble(),
      estimatedDuration: firestoreDetail['estimatedDuration'] as String?,
      difficulty: firestoreDetail['difficulty'] as String?,
      rewardPoints: firestoreDetail['rewardPoints'] as int?,
      reviews: const [],
    );
  }

  static List<Review> _stubReviewsFor(String placeId) {
    if (placeId == 'big_buddha') {
      return [
        Review(
          id: 'r1',
          username: 'TravelerHK',
          date: DateTime(2025, 2, 10),
          rating: 4.8,
          comment: 'Amazing views from the top. The steps are quite a workout!',
        ),
        Review(
          id: 'r2',
          username: 'Wanderlust',
          date: DateTime(2025, 1, 28),
          rating: 4.5,
          comment: 'Worth the trip. Get there early to avoid the crowds.',
        ),
      ];
    }
    if (placeId == 'kowloon_challenge') {
      return [
        Review(
          id: 'r3',
          username: 'NightOwl',
          date: DateTime(2025, 2, 15),
          rating: 4.9,
          comment: 'Best night photography challenge in HK. Neon lights are incredible.',
        ),
      ];
    }
    return [];
  }
}


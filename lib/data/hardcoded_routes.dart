import '../models/app_route.dart';
import '../models/route_stop.dart';

/// Hardcoded routes for the Routes screen until backend is connected.
/// Uses real places in Kowloon, Hong Kong so the Directions API returns valid routes.
/// Polyline and duration are filled by [DirectionsService] from the Google Directions API.
final List<AppRoute> hardcodedRoutes = [
  AppRoute(
    id: 'kowloon-food-track',
    title: 'Kowloon Food Track',
    durationMinutes: 0, // Replaced by Directions API result
    stops: const [
      // Tim Ho Wan (Sham Shui Po) – 9–11 Fuk Wing St, real Michelin-recommended dim sum
      RouteStop(
        id: 'tim-ho-wan-sham-shui-po',
        name: 'Tim Ho Wan (Sham Shui Po)',
        latitude: 22.329244,
        longitude: 114.16645,
      ),
      // Din Tai Fung (Tsim Sha Tsui) – 132 Nathan Rd, Mira Place One
      RouteStop(
        id: 'din-tai-fung-tsim-sha-tsui',
        name: 'Din Tai Fung (Tsim Sha Tsui)',
        latitude: 22.300951,
        longitude: 114.172173,
      ),
    ],
    polylinePoints: const [], // Filled by Directions API
  ),
];

/// Single entry point for API keys.
/// On web: reads window.GMAPS_API_KEY (set by web/maps_key.local.js) so Directions API uses the same key as the map.
/// On iOS/Android: uses api_keys.dart (set api key there or in api_keys.local.dart for Directions to work).
import 'api_keys_impl_web.dart' if (dart.library.io) 'api_keys_impl_io.dart' as _impl;

String getGoogleMapsApiKey() => _impl.getGoogleMapsApiKey();

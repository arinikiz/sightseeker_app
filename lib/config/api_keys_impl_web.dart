// Only used when compiling for web. Reads the key set by web/maps_key.local.js
// so the Directions API uses the same key as the map.
import 'dart:html' as html;

String getGoogleMapsApiKey() {
  try {
    final w = html.window as dynamic;
    final k = w.GMAPS_API_KEY;
    if (k != null && k is String && k.isNotEmpty) return k;
  } catch (_) {}
  return '';
}

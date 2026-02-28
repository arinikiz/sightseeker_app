// Used on iOS, Android, etc. Prefers api_keys.local.dart (gitignored) so your key isn’t committed.
import 'api_keys.dart';
import 'api_keys.local.dart' as local;

String getGoogleMapsApiKey() =>
    local.googleMapsApiKey.isNotEmpty ? local.googleMapsApiKey : googleMapsApiKey;

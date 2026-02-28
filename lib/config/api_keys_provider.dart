/// Single entry point for API keys. Uses api_keys.dart (blank in repo).
/// For a local override: copy api_keys.local.template.dart to api_keys.local.dart
/// and paste your key (that file is gitignored). Build succeeds without it.
import 'api_keys.dart';

String getGoogleMapsApiKey() => googleMapsApiKey;

# API Keys Setup (New Developer Checklist)

No secrets are committed. Each developer adds their own keys locally.

## 1. Dart (single source: `getGoogleMapsApiKey()`)

- **Committed:** `lib/config/api_keys.dart` (blank). Code uses `getGoogleMapsApiKey()` from `config/api_keys_provider.dart`.
- **Optional local override:** Copy `lib/config/api_keys.local.template.dart` to `lib/config/api_keys.local.dart`, paste your key. That file is gitignored. The app currently reads from `api_keys.dart` only, so build succeeds without the local file; use platform configs (web/android/ios) below for the key.

## 2. Web (Google Maps JS)

- **Where to paste:** `web/maps_key.local.js` (and optionally `lib/web/maps_key.local.js` if your app serves from there)
- **First time:** Create the file with:  
  `window.GMAPS_API_KEY = 'YOUR_GOOGLE_MAPS_API_KEY';`
- **Note:** The key file is in `.gitignore`. The Maps JavaScript API must be loaded in `index.html` (see the script tags that load `maps_key.local.js` and then `https://maps.googleapis.com/maps/api/js?key=...`). If the key file is missing, the map will load with a blank key (no tiles) and you may see "Cannot read properties of undefined (reading 'maps')".

## 3. Android

- **Where to paste:** `android/local.properties`
- **Add a line:**  
  `MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY`
- **Note:** `android/local.properties` is already in `.gitignore`. The app uses this via `manifestPlaceholders` in `android/app/build.gradle`.

## 4. iOS

- **Where to paste:** `ios/Flutter/Secrets.xcconfig`
- **First time:** Copy `ios/Flutter/Secrets.xcconfig.template` to `ios/Flutter/Secrets.xcconfig` and set:  
  `GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY`
- **Note:** `ios/Flutter/Secrets.xcconfig` is in `.gitignore`.  
  `Debug.xcconfig` and `Release.xcconfig` already include it with `#include? "Secrets.xcconfig"`.  
  The key is read in `AppDelegate` from `Info.plist` → `GoogleMapsAPIKey`.

---

## Summary

| Platform | File to create/edit | Key variable / content |
|----------|---------------------|-------------------------|
| **Dart** | `lib/config/api_keys.local.dart` | `const String googleMapsApiKey = '...';` |
| **Web**  | `web/maps_key.local.js`           | `window.GMAPS_API_KEY = '...';` |
| **Android** | `android/local.properties`    | `MAPS_API_KEY=...` |
| **iOS**  | `ios/Flutter/Secrets.xcconfig`    | `GOOGLE_MAPS_API_KEY=...` |

Use the same Google Maps API key in all four places (or separate keys per platform if you prefer).

/// Configuration for Google Maps / Places.
///
/// The SAME key is referenced in three places — keep them in sync:
///   1. `android/app/src/main/AndroidManifest.xml` (com.google.android.geo.API_KEY)
///   2. `ios/Runner/AppDelegate.swift` (GMSServices.provideAPIKey)
///   3. [apiKey] below — used for Places API (New) HTTP requests.
///
/// Enable these APIs for the key in Google Cloud Console:
///   • Maps SDK for Android
///   • Maps SDK for iOS
///   • Places API (New)
class GoogleMapsConfig {
  GoogleMapsConfig._();

  /// TODO: paste your Google Maps API key here (used for Places HTTP calls).
  static const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static bool get isConfigured =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GOOGLE_MAPS_API_KEY';
}

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Resolves the user's current position, handling permissions gracefully and
/// falling back to a sensible default so the map always has something to show.
class LocationService {
  /// Default location used when permissions are denied or GPS is unavailable.
  /// (Munich city center — adjust as needed.)
  static const LatLng fallbackLocation = LatLng(48.1374, 11.5755);

  /// Returns the best-effort current location, never throwing.
  Future<LatLng> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return fallbackLocation;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallbackLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return fallbackLocation;
    }
  }
}

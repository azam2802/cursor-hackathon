import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'geo_constants.dart';

/// Typed outcome of [LocationService.ensurePermission].
///
/// Distinguishes the cases the UI must handle differently:
/// * [granted] — location may be read.
/// * [denied] — user declined, but can be asked again.
/// * [deniedForever] — user permanently declined; only the system settings
///   page can re-enable it (see [LocationService.openLocationSettings]).
/// * [serviceDisabled] — device location services (GPS) are turned off.
enum LocationPermissionStatus { granted, denied, deniedForever, serviceDisabled }

/// Wraps [Geolocator] for the Geo-Tag Catch feature: permission handling,
/// current position, a live position stream, and pure distance/bearing math.
///
/// The static helpers ([distanceMeters], [bearingDegrees], [isWithinOpenRadius])
/// are pure and unit-testable without a device.
class LocationService {
  const LocationService();

  /// Default settings for both one-shot and streamed position reads.
  ///
  /// High accuracy is required for the ~20 m open radius; a 2 m distance filter
  /// keeps the stream responsive while moving without flooding updates.
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 2,
  );

  /// Ensures location services are enabled and permission is granted,
  /// requesting permission if needed.
  ///
  /// Returns a [LocationPermissionStatus] so callers can surface the right
  /// message and, for [LocationPermissionStatus.deniedForever], an
  /// "open settings" path.
  Future<LocationPermissionStatus> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _mapPermission(permission);
  }

  static LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }

  /// One-shot high-accuracy position read.
  ///
  /// Callers should invoke [ensurePermission] first; this rethrows the
  /// underlying [Geolocator] errors (e.g. permission/service exceptions).
  Future<Position> currentPosition() {
    return Geolocator.getCurrentPosition(locationSettings: _locationSettings);
  }

  /// Live stream of position updates (high accuracy, 2 m distance filter).
  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(locationSettings: _locationSettings);
  }

  /// Great-circle distance in meters between two coordinates.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Initial bearing in degrees from point 1 to point 2, normalized to 0..360.
  ///
  /// [Geolocator.bearingBetween] returns -180..180; this maps it onto a
  /// compass-friendly 0..360 range.
  static double bearingDegrees(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final bearing = Geolocator.bearingBetween(lat1, lng1, lat2, lng2);
    return (bearing + 360) % 360;
  }

  /// Whether [distanceMeters] is within the openable radius.
  static bool isWithinOpenRadius(double distanceMeters) {
    return distanceMeters <= kOpenRadiusMeters;
  }

  /// Maps a distance in meters to a [ProximityTier] for UI copy/gating.
  static ProximityTier tierFor(double distanceMeters) {
    return tierForDistance(distanceMeters);
  }

  /// Opens the OS app-settings page so the user can re-enable a permission
  /// that was denied forever. Returns `true` if the settings page opened.
  Future<bool> openLocationSettings() {
    return ph.openAppSettings();
  }
}

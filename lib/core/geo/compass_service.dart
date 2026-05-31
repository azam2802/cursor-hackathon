import 'package:flutter_compass/flutter_compass.dart';

/// Wraps [FlutterCompass] for the Geo-Tag Catch AR overlay.
///
/// Exposes the device heading as a simple `Stream<double?>` of compass
/// degrees in the range 0..360 (0 = magnetic north). Emits `null` when the
/// device has no magnetometer or the reading is momentarily unavailable, so
/// callers can degrade gracefully to distance-only navigation.
class CompassService {
  const CompassService();

  /// Live stream of the device heading in degrees (0..360), or `null` when a
  /// heading cannot be determined.
  ///
  /// On platforms/devices without a compass sensor, [FlutterCompass.events]
  /// itself may be `null`; we surface that as a single `null` emission rather
  /// than throwing, keeping the overlay rendering safely.
  Stream<double?> headingStream() {
    final events = FlutterCompass.events;
    if (events == null) {
      return Stream<double?>.value(null);
    }
    return events.map((event) => _normalize(event.heading));
  }

  /// Normalizes a raw heading into the 0..360 range, preserving `null`.
  static double? _normalize(double? heading) {
    if (heading == null) {
      return null;
    }
    final normalized = heading % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:summer_activity/core/geo/geo_constants.dart';
import 'package:summer_activity/core/geo/location_service.dart';

void main() {
  group('LocationService.distanceMeters', () {
    test('is ~0 for identical coordinates', () {
      final d = LocationService.distanceMeters(55.751244, 37.618423,
          55.751244, 37.618423);
      expect(d, closeTo(0, 0.01));
    });

    test('matches a known great-circle distance (Moscow -> St. Petersburg)', () {
      // Kremlin (Moscow) to Palace Square (St. Petersburg): ~633 km.
      final d = LocationService.distanceMeters(
          55.751244, 37.618423, 59.939095, 30.315868);
      expect(d, closeTo(633000, 5000));
    });

    test('is symmetric (A->B equals B->A)', () {
      final ab = LocationService.distanceMeters(
          55.751244, 37.618423, 59.939095, 30.315868);
      final ba = LocationService.distanceMeters(
          59.939095, 30.315868, 55.751244, 37.618423);
      expect(ab, closeTo(ba, 0.5));
    });
  });

  group('LocationService.bearingDegrees', () {
    test('is normalized to the 0..360 range', () {
      // Heading roughly west/south should normalize to a positive bearing
      // instead of the raw -180..180 value from Geolocator.
      final b = LocationService.bearingDegrees(
          55.751244, 37.618423, 59.939095, 30.315868);
      expect(b, greaterThanOrEqualTo(0));
      expect(b, lessThan(360));
    });

    test('points roughly north when target is due north', () {
      final b = LocationService.bearingDegrees(0, 0, 1, 0);
      expect(b, closeTo(0, 1));
    });

    test('points roughly east when target is due east', () {
      final b = LocationService.bearingDegrees(0, 0, 0, 1);
      expect(b, closeTo(90, 1));
    });

    test('points roughly west when target is due west (normalized to ~270)', () {
      final b = LocationService.bearingDegrees(0, 0, 0, -1);
      expect(b, closeTo(270, 1));
    });
  });

  group('LocationService.isWithinOpenRadius', () {
    test('is true at and within the open radius', () {
      expect(LocationService.isWithinOpenRadius(0), isTrue);
      expect(LocationService.isWithinOpenRadius(10), isTrue);
      expect(LocationService.isWithinOpenRadius(kOpenRadiusMeters), isTrue);
    });

    test('is false beyond the open radius', () {
      expect(LocationService.isWithinOpenRadius(kOpenRadiusMeters + 0.01),
          isFalse);
      expect(LocationService.isWithinOpenRadius(100), isFalse);
    });
  });

  group('LocationService.tierFor', () {
    test('delegates to tierForDistance', () {
      expect(LocationService.tierFor(5), ProximityTier.openable);
      expect(LocationService.tierFor(50), ProximityTier.near);
      expect(LocationService.tierFor(500), ProximityTier.far);
    });
  });
}

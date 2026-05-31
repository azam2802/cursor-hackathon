import 'package:flutter_test/flutter_test.dart';
import 'package:summer_activity/core/geo/geo_constants.dart';

void main() {
  group('tierForDistance', () {
    test('is openable at the open-radius boundary (<= 20 m)', () {
      expect(tierForDistance(0), ProximityTier.openable);
      expect(tierForDistance(10), ProximityTier.openable);
      expect(tierForDistance(kOpenRadiusMeters), ProximityTier.openable);
    });

    test('is near just beyond the open radius up to the near boundary', () {
      expect(tierForDistance(kOpenRadiusMeters + 0.01), ProximityTier.near);
      expect(tierForDistance(50), ProximityTier.near);
      expect(tierForDistance(kNearRadiusMeters), ProximityTier.near);
    });

    test('is far beyond the near radius', () {
      expect(tierForDistance(kNearRadiusMeters + 0.01), ProximityTier.far);
      expect(tierForDistance(500), ProximityTier.far);
    });

    test('clamps negative distance to 0 (openable)', () {
      expect(tierForDistance(-1), ProximityTier.openable);
      expect(tierForDistance(-9999), ProximityTier.openable);
    });
  });
}

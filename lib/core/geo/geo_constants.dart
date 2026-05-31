/// Geo-related constants and proximity tiers for the Geo-Tag Catch feature.
///
/// These values are pure data with no Flutter/plugin dependencies so they can
/// be reused by both the UI and unit tests without a device.
library;

/// Single source of truth for the radius (in meters) within which a cache can
/// be "opened" in the AR view. Acceptable design range is 15–25 m.
const double kOpenRadiusMeters = 20;

/// Upper bound (in meters) for the "near" tier. Inside this distance — but
/// still beyond [kOpenRadiusMeters] — the user is considered close to the
/// target. Beyond it, the target is "far".
const double kNearRadiusMeters = 100;

/// Discrete proximity buckets used to drive UI copy and gating.
///
/// * [far] — the user is well away from the cache.
/// * [near] — the user is closing in but cannot open yet.
/// * [openable] — the user is within [kOpenRadiusMeters] and may open it.
enum ProximityTier { far, near, openable }

/// Maps a raw distance in meters to a [ProximityTier].
///
/// Boundaries are inclusive on the lower tier: exactly [kOpenRadiusMeters] is
/// [ProximityTier.openable], and exactly [kNearRadiusMeters] is
/// [ProximityTier.near]. Negative input is clamped to `0`.
ProximityTier tierForDistance(double meters) {
  final distance = meters < 0 ? 0 : meters;
  if (distance <= kOpenRadiusMeters) {
    return ProximityTier.openable;
  }
  if (distance <= kNearRadiusMeters) {
    return ProximityTier.near;
  }
  return ProximityTier.far;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Presentational AR overlay drawn on top of the camera preview.
///
/// Pure/stateless: it is fully driven by [heading], [targetBearing],
/// [distanceMeters] and [openable]. It renders a center crosshair, a floating
/// cache pin/bubble that rotates toward the target, a directional arrow, and a
/// live distance badge — reusing the existing `geo_tag_screen` visual language
/// (mint bubble + triangle tail, mint crosshair).
class ArOverlay extends StatelessWidget {
  const ArOverlay({
    super.key,
    required this.heading,
    required this.targetBearing,
    required this.distanceMeters,
    this.openable = false,
    this.cacheLabel = 'Тайник',
  });

  /// Current device heading in degrees (0..360), or `null` when the compass is
  /// unavailable. When `null` the rotating elements fall back to pointing
  /// straight ahead so the overlay never disappears.
  final double? heading;

  /// Bearing from the user to the cache in degrees (0..360).
  final double targetBearing;

  /// Live distance to the cache in meters.
  final double distanceMeters;

  /// Whether the user is within the open radius; emphasizes the pin (glow).
  /// The actual open interaction is handled elsewhere (GEO-007).
  final bool openable;

  /// Short label shown inside the cache bubble.
  final String cacheLabel;

  /// Relative angle (degrees) of the target from where the device points.
  /// 0 = dead ahead, positive = to the right.
  double get _relativeAngleDegrees {
    final h = heading ?? 0;
    final relative = (targetBearing - h) % 360;
    return relative < 0 ? relative + 360 : relative;
  }

  @override
  Widget build(BuildContext context) {
    final relativeRadians = _relativeAngleDegrees * math.pi / 180;

    return IgnorePointer(
      child: Stack(
        children: [
          // Floating cache pin/bubble, offset toward the target direction.
          Align(
            alignment: const Alignment(0, -0.45),
            child: ArCacheBubble(
              label: cacheLabel,
              relativeRadians: relativeRadians,
              openable: openable,
            ),
          ),
          // Center crosshair.
          const Center(child: ArCrosshair()),
          // Directional arrow near the bottom, rotated toward the cache.
          Align(
            alignment: const Alignment(0, 0.7),
            child: ArDirectionArrow(relativeRadians: relativeRadians),
          ),
          // Live distance badge, top-right.
          Positioned(
            top: 12,
            right: 12,
            child: ArDistanceBadge(distanceMeters: distanceMeters),
          ),
        ],
      ),
    );
  }
}

/// Formats a distance in meters as Russian copy: «38 м» (< 1 km) or «1.2 км».
String formatDistance(double meters) {
  final safe = meters < 0 ? 0.0 : meters;
  if (safe < 1000) {
    return '${safe.round()} м';
  }
  final km = safe / 1000;
  return '${km.toStringAsFixed(1)} км';
}

/// The mint cache "pin" bubble with a triangle tail, matching the existing
/// `geo_tag_screen` mockup. Slides horizontally with the relative target angle
/// and glows when [openable].
class ArCacheBubble extends StatelessWidget {
  const ArCacheBubble({
    super.key,
    required this.label,
    required this.relativeRadians,
    required this.openable,
  });

  final String label;
  final double relativeRadians;
  final bool openable;

  @override
  Widget build(BuildContext context) {
    // Map the relative angle onto a horizontal offset so the pin drifts toward
    // the side the cache is on (clamped to keep it on-screen).
    final dx = (math.sin(relativeRadians)).clamp(-1.0, 1.0) * 90;

    return Transform.translate(
      offset: Offset(dx, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.mint,
                width: openable ? 3 : 2,
              ),
              boxShadow: openable
                  ? [
                      BoxShadow(
                        color: AppColors.mint.withValues(alpha: 0.6),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: AppTextStyles.body(
                size: 11,
                weight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(12, 7),
            painter: _TrianglePainter(AppColors.mint),
          ),
        ],
      ),
    );
  }
}

/// Mint crosshair reticle at the center of the viewport.
class ArCrosshair extends StatelessWidget {
  const ArCrosshair({super.key});

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0xCC00C9A7);
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 56, height: 2, color: lineColor),
          Container(width: 2, height: 56, color: lineColor),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mint, width: 2.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// A directional arrow that rotates to point toward the cache relative to the
/// direction the device is facing.
class ArDirectionArrow extends StatelessWidget {
  const ArDirectionArrow({super.key, required this.relativeRadians});

  final double relativeRadians;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: relativeRadians,
        child: const Icon(
          Icons.navigation,
          color: AppColors.white,
          size: 34,
        ),
      ),
    );
  }
}

/// Live distance badge using the existing mint pill style.
class ArDistanceBadge extends StatelessWidget {
  const ArDistanceBadge({super.key, required this.distanceMeters});

  final double distanceMeters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        formatDistance(distanceMeters),
        style: AppTextStyles.body(
          size: 11,
          weight: FontWeight.w900,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Draws the small downward triangle tail beneath the cache bubble.
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

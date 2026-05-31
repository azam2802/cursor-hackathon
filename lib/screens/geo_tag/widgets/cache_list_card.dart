import 'package:flutter/material.dart';

import '../../../core/geo/models/geo_cache.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Formats a raw distance in meters for display.
///
/// Under 1 km it is rounded to whole meters («38 м»); at 1 km and above it
/// switches to kilometers with one decimal («1.2 км»). Negative input is
/// clamped to zero. Exposed as a top-level function so tests can use it.
String formatDistance(double meters) {
  final safe = meters < 0 ? 0.0 : meters;
  if (safe < 1000) {
    return '${safe.round()} м';
  }
  final km = safe / 1000;
  return '${km.toStringAsFixed(1)} км';
}

/// A presentational list item for a single geo cache (тайник).
///
/// Shows the cache title, its owner, the formatted distance from the user and
/// an opened/new badge. Purely visual: distance and opened state are passed in
/// and tap handling is delegated via [onTap].
class CacheListCard extends StatelessWidget {
  const CacheListCard({
    super.key,
    required this.cache,
    this.distanceMeters,
    this.isOpened = false,
    this.onTap,
  });

  /// The cache to display.
  final GeoCache cache;

  /// Distance from the user in meters, or `null` while the position is unknown.
  final double? distanceMeters;

  /// Whether the current user has already opened this cache.
  final bool isOpened;

  /// Invoked when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = cache.title.isEmpty ? 'Тайник' : cache.title;
    final ownerLabel =
        cache.ownerName.isEmpty ? 'Аноним' : 'от ${cache.ownerName}';
    final distanceLabel =
        distanceMeters == null ? '—' : formatDistance(distanceMeters!);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpened ? AppColors.mint : const Color(0xFFE3F4EE),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.display(
                        size: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                        size: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StateBadge(isOpened: isOpened),
                  const SizedBox(height: 8),
                  Text(
                    distanceLabel,
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w900,
                      color: AppColors.mint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill that distinguishes an opened cache from a brand-new one.
class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.isOpened});

  final bool isOpened;

  @override
  Widget build(BuildContext context) {
    final background = isOpened ? AppColors.mint : AppColors.sand;
    final textColor = isOpened ? AppColors.white : AppColors.textDark;
    final label = isOpened ? 'открыт' : 'новый';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.body(
          size: 11,
          weight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}

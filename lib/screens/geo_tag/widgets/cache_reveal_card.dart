import 'package:flutter/material.dart';

import '../../../core/geo/models/geo_cache.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Celebratory reveal card shown once a [GeoCache] has been "opened" in the AR
/// view.
///
/// Purely presentational: it renders the cache's title, owner, message and
/// (optionally) its stored photo, plus a «Готово» button. All interaction is
/// delegated to [onClose]; the widget performs no data writes itself.
class CacheRevealCard extends StatelessWidget {
  const CacheRevealCard({
    super.key,
    required this.cache,
    required this.onClose,
  });

  /// The freshly opened cache whose contents are revealed.
  final GeoCache cache;

  /// Invoked when the user dismisses the reveal via «Готово».
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title = cache.title.isEmpty ? 'Тайник' : cache.title;
    final ownerLabel =
        cache.ownerName.isEmpty ? 'Аноним' : 'от ${cache.ownerName}';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.mint, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.mint.withValues(alpha: 0.45),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _RevealHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display(
                        size: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(
                        size: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                    if (cache.photoUrl != null) ...[
                      const SizedBox(height: 16),
                      _RevealPhoto(photoUrl: cache.photoUrl!),
                    ],
                    if (cache.message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _MessageBubble(message: cache.message),
                    ],
                    const SizedBox(height: 20),
                    _DoneButton(onPressed: onClose),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mint gradient banner with the celebratory "opened" headline.
class _RevealHeader extends StatelessWidget {
  const _RevealHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mint, AppColors.leaf],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.celebration_rounded,
            color: AppColors.white,
            size: 44,
          ),
          const SizedBox(height: 8),
          Text(
            'Тайник открыт!',
            style: AppTextStyles.display(size: 18, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

/// Network photo with themed loading and error fallbacks.
class _RevealPhoto extends StatelessWidget {
  const _RevealPhoto({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return const ColoredBox(
              color: AppColors.geoBg,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(AppColors.mint),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => const _PhotoError(),
        ),
      ),
    );
  }
}

/// Placeholder shown when the stored photo cannot be loaded.
class _PhotoError extends StatelessWidget {
  const _PhotoError();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.geoBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: AppColors.mint,
              size: 36,
            ),
            const SizedBox(height: 6),
            Text(
              'Фото недоступно',
              style: AppTextStyles.body(size: 12, color: AppColors.textMid),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft mint-tinted bubble holding the cache author's message.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.geoBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: AppTextStyles.body(
          size: 14,
          color: AppColors.textDark,
          height: 1.4,
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Готово',
          style: AppTextStyles.body(
            size: 15,
            weight: FontWeight.w900,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

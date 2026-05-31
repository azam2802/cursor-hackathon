import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// A reusable form tile for attaching an optional photo to a cache.
///
/// When [photo] is `null` it renders an empty, dashed-looking drop zone with
/// "camera" and "gallery" actions. When a photo is selected it shows a rounded
/// thumbnail preview with a remove button. All picking/removal logic is owned
/// by the parent via the callbacks so this widget stays presentation-only.
class PhotoPickerTile extends StatelessWidget {
  const PhotoPickerTile({
    super.key,
    required this.photo,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
    this.enabled = true,
  });

  /// Currently selected photo, or `null` when none is attached.
  final File? photo;

  /// Invoked to capture a new photo with the camera.
  final VoidCallback onPickCamera;

  /// Invoked to select a photo from the gallery.
  final VoidCallback onPickGallery;

  /// Invoked to clear the current selection.
  final VoidCallback onRemove;

  /// When `false`, all actions are disabled (e.g. while submitting).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = photo;
    if (selected != null) {
      return _PhotoPreview(
        photo: selected,
        onRemove: enabled ? onRemove : null,
      );
    }
    return _EmptyPicker(
      onPickCamera: enabled ? onPickCamera : null,
      onPickGallery: enabled ? onPickGallery : null,
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo, required this.onRemove});

  final File photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.file(
            photo,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 18, color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker({
    required this.onPickCamera,
    required this.onPickGallery,
  });

  final VoidCallback? onPickCamera;
  final VoidCallback? onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.geoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mint, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'Добавьте фото (необязательно)',
            style: AppTextStyles.body(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PickButton(
                icon: Icons.photo_camera_outlined,
                label: 'Камера',
                onTap: onPickCamera,
              ),
              const SizedBox(width: 12),
              _PickButton(
                icon: Icons.photo_library_outlined,
                label: 'Галерея',
                onTap: onPickGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: AppColors.mint),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

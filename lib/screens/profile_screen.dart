import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Profile destination.
///
/// No design was provided for this tab yet, so it ships as a friendly
/// placeholder. The layout leaves room to drop in real profile content later.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 44,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Профиль', style: AppTextStyles.display(size: 22)),
                const SizedBox(height: 6),
                Text(
                  'Здесь скоро появится твой профиль',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(
                    size: 13,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

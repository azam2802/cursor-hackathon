import 'package:flutter/material.dart';

/// Centralized color palette for the SummerDrift app.
///
/// Mirrors the design tokens defined in `summerdrift_bright_redesign.html`.
class AppColors {
  AppColors._();

  // Brand palette
  static const Color sun = Color(0xFFFFD037);
  static const Color coral = Color(0xFFFF5C3A);
  static const Color mint = Color(0xFF00C9A7);
  static const Color sky = Color(0xFF3DBBFF);
  static const Color lilac = Color(0xFFC77DFF);
  static const Color cream = Color(0xFFFFF9EE);
  static const Color sand = Color(0xFFFFE8B0);
  static const Color leaf = Color(0xFF00A86B);
  static const Color warm = Color(0xFFFF8C42);

  // Text
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMid = Color(0xFF4A4060);
  static const Color textLight = Color(0xFF8B7FA0);
  static const Color white = Color(0xFFFFFFFF);

  // Inactive nav tint
  static const Color navInactive = Color(0xFFB0A8C8);

  // Per-screen backgrounds
  static const Color rouletteBg = Color(0xFFFFF3D4);
  static const Color rouletteHero = Color(0xFFFFE17A);
  static const Color moodBg = Color(0xFFFFF0E8);
  static const Color geoBg = Color(0xFFE8FBF5);
}

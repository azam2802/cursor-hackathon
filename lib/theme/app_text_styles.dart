import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography helpers for SummerDrift.
///
/// The design uses `Righteous` for display headings and `Nunito` for body
/// text. We load both via google_fonts so no asset bundling is required.
class AppTextStyles {
  AppTextStyles._();

  /// Display / heading font (Righteous).
  static TextStyle display({
    double size = 18,
    Color color = AppColors.textDark,
    double letterSpacing = 0,
    double height = 1.1,
  }) {
    return GoogleFonts.righteous(
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Body font (Nunito).
  static TextStyle body({
    double size = 12,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textMid,
    double letterSpacing = 0,
    double height = 1.3,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

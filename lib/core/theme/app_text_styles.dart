import 'package:flutter/material.dart';

/// App text styles
/// Converted from Global CSS React app typography
class AppTextStyles {
  AppTextStyles._();

  // Font weights
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight normal = FontWeight.w400;

  // Base font size (16px from CSS)
  static const double baseFontSize = 16.0;

  // Text sizes
  static const double text2xl = 24.0; // ~1.5rem
  static const double textXl = 20.0; // ~1.25rem
  static const double textLg = 18.0; // ~1.125rem
  static const double textBase = 16.0; // 1rem
  static const double textSm = 14.0; // ~0.875rem
  static const double textXs = 12.0; // ~0.75rem

  // Line height
  static const double lineHeight = 1.5;

  // ========== HEADING STYLES ==========

  /// H1 - Large heading
  static const TextStyle h1 = TextStyle(
    fontSize: text2xl,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// H2 - Medium heading
  static const TextStyle h2 = TextStyle(
    fontSize: textXl,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// H3 - Small heading
  static const TextStyle h3 = TextStyle(
    fontSize: textLg,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// H4 - Extra small heading
  static const TextStyle h4 = TextStyle(
    fontSize: textBase,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  // ========== BODY TEXT STYLES ==========

  /// Body text - Large
  static const TextStyle bodyLarge = TextStyle(
    fontSize: textLg,
    fontWeight: normal,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// Body text - Medium (default)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: textBase,
    fontWeight: normal,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// Body text - Small
  static const TextStyle bodySmall = TextStyle(
    fontSize: textSm,
    fontWeight: normal,
    height: lineHeight,
    letterSpacing: 0,
  );

  // ========== LABEL STYLES ==========

  /// Label - Large
  static const TextStyle labelLarge = TextStyle(
    fontSize: textBase,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// Label - Medium
  static const TextStyle labelMedium = TextStyle(
    fontSize: textSm,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// Label - Small
  static const TextStyle labelSmall = TextStyle(
    fontSize: textXs,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  // ========== BUTTON STYLES ==========

  /// Button text - Large
  static const TextStyle buttonLarge = TextStyle(
    fontSize: textBase,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// Button text - Medium
  static const TextStyle buttonMedium = TextStyle(
    fontSize: textSm,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// Button text - Small
  static const TextStyle buttonSmall = TextStyle(
    fontSize: textXs,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0,
  );

  // ========== INPUT STYLES ==========

  /// Input text
  static const TextStyle input = TextStyle(
    fontSize: textBase,
    fontWeight: normal,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// Input hint text
  static const TextStyle inputHint = TextStyle(
    fontSize: textBase,
    fontWeight: normal,
    height: lineHeight,
    letterSpacing: 0,
  );

  // ========== CAPTION STYLES ==========

  /// Caption text
  static const TextStyle caption = TextStyle(
    fontSize: textSm,
    fontWeight: normal,
    height: lineHeight,
    letterSpacing: 0,
  );

  /// Overline text
  static const TextStyle overline = TextStyle(
    fontSize: textXs,
    fontWeight: medium,
    height: lineHeight,
    letterSpacing: 0.5,
  );
}

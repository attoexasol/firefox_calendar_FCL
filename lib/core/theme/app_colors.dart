import 'package:flutter/material.dart';

/// App color constants for light and dark themes
/// Converted from Global CSS React app
class AppColors {
  AppColors._();

  // ========== LIGHT THEME COLORS ==========

  // Primary Colors
  static const Color primaryLight = Color(0xFFFF6B35);
  static const Color primaryForegroundLight = Color(0xFFFFFFFF);

  // Secondary Colors
  static const Color secondaryLight = Color(0xFF1F1147);
  static const Color secondaryForegroundLight = Color(0xFFFFFFFF);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color foregroundLight = Color(0xFF252525); // oklch(0.145 0 0)

  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardForegroundLight = Color(0xFF252525);

  // Popover Colors
  static const Color popoverLight = Color(0xFFFFFFFF);
  static const Color popoverForegroundLight = Color(0xFF252525);

  // Muted Colors
  static const Color mutedLight = Color(0xFFECECF0);
  static const Color mutedForegroundLight = Color(0xFF717182);

  // Accent Colors
  static const Color accentLight = Color(0xFFFFF5F2);
  static const Color accentForegroundLight = Color(0xFF1F1147);

  // Destructive Colors
  static const Color destructiveLight = Color(0xFFD4183D);
  static const Color destructiveForegroundLight = Color(0xFFFFFFFF);

  // Border and Input Colors
  static const Color borderLight = Color(0x1A000000); // rgba(0, 0, 0, 0.1)
  static const Color inputLight = Colors.transparent;
  static const Color inputBackgroundLight = Color(0xFFF3F3F5);
  static const Color switchBackgroundLight = Color(0xFFCBCED4);

  // Ring Color (focus/active states)
  static const Color ringLight = Color(0xFFFF6B35);

  // Chart Colors
  static const Color chart1Light = Color(0xFFFF6B35);
  static const Color chart2Light = Color(0xFF1F1147);
  static const Color chart3Light = Color(
    0xFF3A5A9E,
  ); // oklch(0.398 0.07 227.392)
  static const Color chart4Light = Color(
    0xFFE8D76C,
  ); // oklch(0.828 0.189 84.429)
  static const Color chart5Light = Color(
    0xFFD9B847,
  ); // oklch(0.769 0.188 70.08)

  // Sidebar Colors (Light)
  static const Color sidebarLight = Color(0xFFFBFBFB); // oklch(0.985 0 0)
  static const Color sidebarForegroundLight = Color(0xFF252525);
  static const Color sidebarPrimaryLight = Color(0xFF1F1147);
  static const Color sidebarPrimaryForegroundLight = Color(0xFFFBFBFB);
  static const Color sidebarAccentLight = Color(0xFFF7F7F7); // oklch(0.97 0 0)
  static const Color sidebarAccentForegroundLight = Color(
    0xFF343434,
  ); // oklch(0.205 0 0)
  static const Color sidebarBorderLight = Color(0xFFEBEBEB); // oklch(0.922 0 0)
  static const Color sidebarRingLight = Color(0xFFFF6B35);

  // ========== DARK THEME COLORS ==========

  // Primary Colors
  static const Color primaryDark = Color(0xFFFF6B35);
  static const Color primaryForegroundDark = Color(0xFFFFFFFF);

  // Secondary Colors
  static const Color secondaryDark = Color(0xFF3D2A75);
  static const Color secondaryForegroundDark = Color(0xFFFBFBFB);

  // Background Colors
  static const Color backgroundDark = Color(0xFF1F1147);
  static const Color foregroundDark = Color(0xFFFBFBFB); // oklch(0.985 0 0)

  // Card Colors
  static const Color cardDark = Color(0xFF2A1A5E);
  static const Color cardForegroundDark = Color(0xFFFBFBFB);

  // Popover Colors
  static const Color popoverDark = Color(0xFF2A1A5E);
  static const Color popoverForegroundDark = Color(0xFFFBFBFB);

  // Muted Colors
  static const Color mutedDark = Color(0xFF3D2A75);
  static const Color mutedForegroundDark = Color(
    0xFFB5B5B5,
  ); // oklch(0.708 0 0)

  // Accent Colors
  static const Color accentDark = Color(0xFF3D2A75);
  static const Color accentForegroundDark = Color(0xFFFBFBFB);

  // Destructive Colors
  static const Color destructiveDark = Color(
    0xFF7A2831,
  ); // oklch(0.396 0.141 25.723)
  static const Color destructiveForegroundDark = Color(
    0xFFCF6A6A,
  ); // oklch(0.637 0.237 25.331)

  // Border and Input Colors
  static const Color borderDark = Color(0xFF3D2A75);
  static const Color inputDark = Color(0xFF3D2A75);
  static const Color inputBackgroundDark = Color(0xFF3D2A75);
  static const Color switchBackgroundDark = Color(0xFF3D2A75);

  // Ring Color (focus/active states)
  static const Color ringDark = Color(0xFFFF6B35);

  // Chart Colors
  static const Color chart1Dark = Color(0xFFFF6B35);
  static const Color chart2Dark = Color(0xFF70D4AA); // oklch(0.696 0.17 162.48)
  static const Color chart3Dark = Color(0xFFD9B847); // oklch(0.769 0.188 70.08)
  static const Color chart4Dark = Color(0xFFB863D4); // oklch(0.627 0.265 303.9)
  static const Color chart5Dark = Color(
    0xFFD97A57,
  ); // oklch(0.645 0.246 16.439)

  // Sidebar Colors (Dark)
  static const Color sidebarDark = Color(0xFF1F1147);
  static const Color sidebarForegroundDark = Color(0xFFFBFBFB);
  static const Color sidebarPrimaryDark = Color(0xFFFF6B35);
  static const Color sidebarPrimaryForegroundDark = Color(0xFFFFFFFF);
  static const Color sidebarAccentDark = Color(0xFF3D2A75);
  static const Color sidebarAccentForegroundDark = Color(0xFFFBFBFB);
  static const Color sidebarBorderDark = Color(0xFF3D2A75);
  static const Color sidebarRingDark = Color(0xFFFF6B35);

  // ========== COMMON COLORS ==========

  /// Primary brand color (same for both themes)
  static const Color primary = Color(0xFFFF6B35);

  /// Secondary brand color (light theme)
  static const Color secondary = Color(0xFF1F1147);

  /// White color
  static const Color white = Color(0xFFFFFFFF);

  /// Black color
  static const Color black = Color(0xFF000000);

  /// Transparent color
  static const Color transparent = Colors.transparent;

  // ========== THEME-AWARE GETTERS ==========

  /// Get primary foreground color based on current theme
  /// Returns the appropriate color for the current brightness
  static Color primaryForeground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? primaryForegroundDark : primaryForegroundLight;
  }
}
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App gradient definitions
/// Common gradient styles used throughout the app
class AppGradients {
  AppGradients._();

  /// Primary gradient - Orange gradient
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,
      Color(0xFFFF8C61), // Lighter shade of primary
    ],
  );

  /// Secondary gradient - Purple gradient
  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondary,
      Color(0xFF2A1A5E), // Lighter shade of secondary
    ],
  );

  /// Accent gradient - Light accent for backgrounds
  static LinearGradient get accentLight => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.accentLight, AppColors.backgroundLight],
  );

  /// Accent gradient - Dark accent for backgrounds
  static LinearGradient get accentDark => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.accentDark, AppColors.backgroundDark],
  );

  /// Card gradient - Subtle gradient for cards (light)
  static LinearGradient get cardLight => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cardLight, AppColors.mutedLight.withValues(alpha: 0.3)],
  );

  /// Card gradient - Subtle gradient for cards (dark)
  static LinearGradient get cardDark => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cardDark, AppColors.mutedDark.withValues(alpha: 0.5)],
  );

  /// Primary to secondary gradient
  static const LinearGradient primaryToSecondary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.secondary],
  );

  /// Radial gradient - Primary
  static RadialGradient get radialPrimary => RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [
      AppColors.primary,
      AppColors.primary.withValues(alpha: 0.5),
      AppColors.transparent,
    ],
    stops: const [0.0, 0.6, 1.0],
  );

  /// Shimmer gradient - For loading states
  static LinearGradient get shimmerLight => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.mutedLight.withValues(alpha: 0.3),
      AppColors.mutedLight.withValues(alpha: 0.1),
      AppColors.mutedLight.withValues(alpha: 0.3),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  /// Shimmer gradient - For loading states (dark)
  static LinearGradient get shimmerDark => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.mutedDark.withValues(alpha: 0.5),
      AppColors.mutedDark.withValues(alpha: 0.3),
      AppColors.mutedDark.withValues(alpha: 0.5),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  /// Overlay gradient - Dark overlay for images
  static LinearGradient get darkOverlay => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.transparent, AppColors.black.withValues(alpha: 0.6)],
  );

  /// Overlay gradient - Light overlay for images
  static LinearGradient get lightOverlay => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.transparent, AppColors.white.withValues(alpha: 0.6)],
  );

  /// Sweep gradient - For circular progress or decorative elements
  static SweepGradient get sweepPrimary => SweepGradient(
    center: Alignment.center,
    colors: [AppColors.primary, AppColors.primaryLight, AppColors.primary],
    stops: const [0.0, 0.5, 1.0],
  );

  /// Glass morphism gradient - For glassmorphic effects
  static LinearGradient get glassMorphism => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.white.withValues(alpha: 0.1),
      AppColors.white.withValues(alpha: 0.05),
    ],
  );
}

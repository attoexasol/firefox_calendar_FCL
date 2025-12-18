import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App shadow definitions
/// Common shadow styles for elevation and depth
class AppShadows {
  AppShadows._();

  /// Small shadow - for subtle elevation
  static List<BoxShadow> get small => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Medium shadow - for cards and elevated components
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Large shadow - for modals and prominent elevation
  static List<BoxShadow> get large => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.15),
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Extra large shadow - for floating elements
  static List<BoxShadow> get extraLarge => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.2),
      offset: const Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.15),
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  /// Inner shadow effect (using border)
  static BoxDecoration get innerShadow => BoxDecoration(
    border: Border.all(color: AppColors.black.withValues(alpha: 0.05), width: 1),
  );

  /// Card shadow - default shadow for card components
  static List<BoxShadow> get card => medium;

  /// Button shadow - subtle shadow for buttons
  static List<BoxShadow> get button => small;

  /// Dialog shadow - prominent shadow for dialogs
  static List<BoxShadow> get dialog => large;

  /// Dropdown shadow - for dropdown menus and popovers
  static List<BoxShadow> get dropdown => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  /// Bottom sheet shadow - for bottom sheets
  static List<BoxShadow> get bottomSheet => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.25),
      offset: const Offset(0, -2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  /// No shadow
  static List<BoxShadow> get none => [];
}

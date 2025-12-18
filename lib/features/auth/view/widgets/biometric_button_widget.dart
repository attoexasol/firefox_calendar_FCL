
import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/auth/controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Biometric Button Widget
/// Converted from React biometric integrate code
/// Matches the exact React component: outline variant, icon size, responsive dimensions
/// 
/// React equivalent:
/// ```jsx
/// <Button 
///   onClick={handleBiometricLogin} 
///   variant="outline" 
///   size="icon"
///   className="h-9 w-9 sm:h-10 sm:w-10 flex-shrink-0"
/// >
///   <Fingerprint className="h-4 w-4 sm:h-5 sm:w-5" />
/// </Button>
/// ```
class BiometricButtonWidget extends GetView<LoginController> {
  final VoidCallback? onPressed;
  final bool? isLoading;
  final bool responsive;
  final double? size;
  final String tooltip;

  const BiometricButtonWidget({
    super.key,
    this.onPressed,
    this.isLoading,
    this.responsive = true,
    this.size,
    this.tooltip = 'Biometric Login',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Responsive sizing: h-9 w-9 sm:h-10 sm:w-10 (36px to 40px)
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 640;
    
    final buttonSize = size ?? (responsive 
        ? (isSmallScreen ? 36.0 : 40.0) 
        : 36.0);
    
    // Icon sizing: h-4 w-4 sm:h-5 sm:w-5 (16px to 20px)
    final iconSize = responsive 
        ? (isSmallScreen ? 16.0 : 20.0) 
        : 18.0;

    return Obx(() {
      final loading = isLoading ?? controller.isLoading.value;
      
      return Container(
        // flex-shrink-0 equivalent - prevents shrinking
        constraints: BoxConstraints(
          minWidth: buttonSize,
          minHeight: buttonSize,
          maxWidth: buttonSize,
          maxHeight: buttonSize,
        ),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: loading ? null : (onPressed ?? _handleBiometricLogin),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                // Outline variant styling
                border: Border.all(
                  color: loading 
                      ? (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5)
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                color: Colors.transparent, // outline variant = transparent background
              ),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: iconSize * 0.8,
                        height: iconSize * 0.8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark 
                                ? AppColors.foregroundDark 
                                : AppColors.foregroundLight,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.fingerprint, // Fingerprint equivalent
                        size: iconSize,
                        color: loading
                            ? (isDark 
                                ? AppColors.mutedForegroundDark 
                                : AppColors.mutedForegroundLight)
                            : (isDark 
                                ? AppColors.foregroundDark 
                                : AppColors.foregroundLight),
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Default biometric login handler
  void _handleBiometricLogin() {
    print('🔵 Biometric button pressed - calling handleBiometricLogin');
    controller.handleBiometricLogin();
  }
}

/// Alternative implementation using Material IconButton for consistency
/// This version uses Flutter's built-in IconButton for better accessibility
class BiometricIconButton extends GetView<LoginController> {
  final VoidCallback? onPressed;
  final bool? isLoading;
  final bool responsive;
  final String tooltip;

  const BiometricIconButton({
    super.key,
    this.onPressed,
    this.isLoading,
    this.responsive = true,
    this.tooltip = 'Biometric Login',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 640;
    
    final buttonSize = responsive 
        ? (isSmallScreen ? 36.0 : 40.0) 
        : 36.0;
    
    final iconSize = responsive 
        ? (isSmallScreen ? 16.0 : 20.0) 
        : 18.0;

    return Obx(() {
      final loading = isLoading ?? controller.isLoading.value;
      
      return Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: loading 
                ? (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: IconButton(
          onPressed: loading ? null : (onPressed ?? _handleBiometricLogin),
          tooltip: tooltip,
          icon: loading
              ? SizedBox(
                  width: iconSize * 0.8,
                  height: iconSize * 0.8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark 
                          ? AppColors.foregroundDark 
                          : AppColors.foregroundLight,
                    ),
                  ),
                )
              : Icon(
                  Icons.fingerprint,
                  size: iconSize,
                  color: isDark 
                      ? AppColors.foregroundDark 
                      : AppColors.foregroundLight,
                ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            minimumSize: Size(buttonSize, buttonSize),
            maximumSize: Size(buttonSize, buttonSize),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.transparent,
          ),
        ),
      );
    });
  }

  void _handleBiometricLogin() {
    print('🔵 Biometric icon button pressed - calling handleBiometricLogin');
    controller.handleBiometricLogin();
  }
}

/// Simplified version that exactly matches your existing login_buttons_widget pattern
class SimpleBiometricButton extends GetView<LoginController> {
  final double? width;
  final double? height;
  final double? iconSize;
  final VoidCallback? onPressed;

  const SimpleBiometricButton({
    super.key,
    this.width = 36,
    this.height = 36,
    this.iconSize = 18,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      child: IconButton(
        onPressed: controller.isLoading.value
            ? null
            : (onPressed ?? controller.handleBiometricLogin),
        icon: Icon(
          Icons.fingerprint,
          size: iconSize,
          color: isDark
              ? AppColors.foregroundDark
              : AppColors.foregroundLight,
        ),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          minimumSize: Size(width ?? 36, height ?? 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ));
  }
}
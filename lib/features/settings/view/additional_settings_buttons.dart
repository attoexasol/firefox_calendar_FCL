import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/settings/controller/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AdditionalSettingsButtons extends GetView<SettingsController> {
  const AdditionalSettingsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Security Section Card
        _buildSecuritySection(context, isDark),
        
        const SizedBox(height: 24),
        
        // Logout Button
        _buildLogoutButton(context, isDark),
      ],
    );
  }

  /// Build Security section - converted from React Card component
  Widget _buildSecuritySection(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header - matches React CardHeader with CardTitle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.fingerprint, // Fingerprint equivalent 
                  size: 20, // h-5 w-5 = 20px
                  color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                ),
                const SizedBox(width: 8), // gap-2 = 8px
                Text(
                  'Security',
                  style: AppTextStyles.h4.copyWith(
                    color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Card Content - matches React CardContent  
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildBiometricEnrollButton(context, isDark),
          ),
        ],
      ),
    );
  }

  /// Build Biometric Enroll Button - converted from React Button with outline variant
  Widget _buildBiometricEnrollButton(BuildContext context, bool isDark) {
    return Obx(() => SizedBox(
      width: double.infinity, // w-full equivalent
      child: OutlinedButton.icon(
        onPressed: controller.isLoading.value 
            ? null 
            : controller.enrollBiometric,
        icon: controller.isLoading.value
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.fingerprint, // Fingerprint equivalent
                size: 20, // h-5 w-5 = 20px
                color: isDark 
                    ? AppColors.foregroundDark 
                    : AppColors.foregroundLight,
              ),
        label: Text(
          'Enroll Biometric Login',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark 
                ? AppColors.foregroundDark 
                : AppColors.foregroundLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          backgroundColor: Colors.transparent, // outline variant = transparent background
          foregroundColor: isDark 
              ? AppColors.foregroundDark 
              : AppColors.foregroundLight,
        ),
      ),
    ));
  }

  /// Build Logout Button - converted from React Button with destructive variant
  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return Obx(() => SizedBox(
      width: double.infinity, // w-full equivalent
      child: ElevatedButton.icon(
        onPressed: controller.isLogoutLoading.value 
            ? null 
            : controller.handleLogout,
        icon: controller.isLogoutLoading.value
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.logout, // LogOut equivalent
                size: 20, // h-5 w-5 = 20px
                color: Colors.white,
              ),
        label: Text(
          'Logout',
          style: AppTextStyles.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444), // destructive = red color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          // Disabled state styling
          disabledBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    ));
  }
}

/// Standalone Security Card Widget 
/// For use in other parts of the app if needed
class SecurityCardWidget extends GetView<SettingsController> {
  const SecurityCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  size: 20,
                  color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Security',
                  style: AppTextStyles.h4.copyWith(
                    color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Obx(() => SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.isLoading.value 
                    ? null 
                    : controller.enrollBiometric,
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.fingerprint,
                        size: 20,
                        color: isDark 
                            ? AppColors.foregroundDark 
                            : AppColors.foregroundLight,
                      ),
                label: Text(
                  'Enroll Biometric Login',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark 
                        ? AppColors.foregroundDark 
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  backgroundColor: Colors.transparent,
                  foregroundColor: isDark 
                      ? AppColors.foregroundDark 
                      : AppColors.foregroundLight,
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

/// Standalone Logout Button Widget
/// For use in other parts of the app if needed
class LogoutButtonWidget extends GetView<SettingsController> {
  final String? text;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const LogoutButtonWidget({
    super.key,
    this.text,
    this.fullWidth = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: controller.isLogoutLoading.value 
            ? null 
            : controller.handleLogout,
        icon: controller.isLogoutLoading.value
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.logout,
                size: 20,
                color: Colors.white,
              ),
        label: Text(
          text ?? 'Logout',
          style: AppTextStyles.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444), // destructive red
          foregroundColor: Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          disabledBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    ));
  }
}
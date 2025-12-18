import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/settings/controller/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Profile Picture Change Button Widget
/// Converted from React Button with Camera icon and "Change Profile Picture" text
/// Follows the exact design from the React component
class ProfilePictureChangeButton extends GetView<SettingsController> {
  const ProfilePictureChangeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() => OutlinedButton.icon(
      onPressed: controller.isUploadingImage.value
          ? null
          : controller.selectProfilePicture,
      icon: controller.isUploadingImage.value
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                ),
              ),
            )
          : Icon(
              Icons.camera_alt,
              size: 16,
              color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            ),
      label: Text(
        controller.isUploadingImage.value
            ? 'Uploading...'
            : 'Change Profile Picture',
        style: AppTextStyles.labelMedium.copyWith(
          color: controller.isUploadingImage.value
              ? (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight)
              : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        foregroundColor: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        disabledBackgroundColor: isDark 
            ? AppColors.cardDark.withValues(alpha: 0.5) 
            : AppColors.cardLight.withValues(alpha: 0.5),
        disabledForegroundColor: isDark 
            ? AppColors.mutedForegroundDark 
            : AppColors.mutedForegroundLight,
      ),
    ));
  }
}

/// Enhanced Profile Picture Change Card Widget
/// Complete profile picture display and change functionality
/// Matches the exact layout from the screenshot
class ProfilePictureChangeCard extends GetView<SettingsController> {
  const ProfilePictureChangeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Profile Picture Circle - matches screenshot exactly
          Obx(() => Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5E7EB), // Light gray background like in screenshot
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Profile picture or initials
                controller.userProfilePicture.value.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          controller.userProfilePicture.value,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to initials if network image fails
                            return _buildInitialsAvatar();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildInitialsAvatar();
                          },
                        ),
                      )
                    : _buildInitialsAvatar(),
                
                // Loading overlay
                if (controller.isUploadingImage.value)
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
              ],
            ),
          )),

          const SizedBox(height: 16),

          // Change Picture Button - matches screenshot design exactly
          Obx(() => Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFD1D5DB),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: controller.isUploadingImage.value
                    ? null
                    : controller.selectProfilePicture,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.isUploadingImage.value)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? AppColors.foregroundDark : const Color(0xFF6B7280),
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: isDark ? AppColors.foregroundDark : const Color(0xFF6B7280),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isUploadingImage.value
                            ? 'Uploading...'
                            : 'Change Profile Picture',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: controller.isUploadingImage.value
                              ? (isDark ? AppColors.mutedForegroundDark : const Color(0xFF9CA3AF))
                              : (isDark ? AppColors.foregroundDark : const Color(0xFF374151)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// Build initials avatar - matches screenshot style
  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        controller.getUserInitials(),
        style: AppTextStyles.h1.copyWith(
          color: const Color(0xFF6B7280), // Gray text for initials
          fontWeight: FontWeight.w600,
          fontSize: 32,
        ),
      ),
    );
  }
}
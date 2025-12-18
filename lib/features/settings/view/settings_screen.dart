import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/auth/view/widgets/leave_application_widget.dart';
import 'package:firefox_calendar/features/auth/view/widgets/profile_picture_change_button_updated.dart';
import 'package:firefox_calendar/features/settings/controller/settings_controller.dart';
import 'package:firefox_calendar/features/settings/view/additional_settings_buttons.dart';
import 'package:firefox_calendar/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            const TopBar(title: 'Firefox Settings'),

            // Tab Navigation
            _buildTabNavigation(isDark),

            // Content
            Expanded(
              child: Obx(() {
                return controller.activeTab.value == 'profile'
                    ? _buildProfileContent(context, isDark)
                    : _buildLeaveContent(context, isDark);
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }

  /// Build tab navigation
  Widget _buildTabNavigation(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? AppColors.borderDark 
                : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile & Settings Tab
          Expanded(
            child: Obx(
              () => GestureDetector(
                onTap: () => controller.setActiveTab('profile'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: controller.activeTab.value == 'profile'
                            ? const Color(0xFFEF4444)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Profile & Settings',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: controller.activeTab.value == 'profile'
                          ? const Color(0xFFEF4444)
                          : (isDark 
                              ? AppColors.mutedForegroundDark 
                              : const Color(0xFF6B7280)),
                      fontWeight: controller.activeTab.value == 'profile'
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Leave Application Tab
          Expanded(
            child: Obx(
              () => GestureDetector(
                onTap: () => controller.setActiveTab('leave'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: controller.activeTab.value == 'leave'
                            ? const Color(0xFFEF4444)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Leave Application',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: controller.activeTab.value == 'leave'
                          ? const Color(0xFFEF4444)
                          : (isDark 
                              ? AppColors.mutedForegroundDark 
                              : const Color(0xFF6B7280)),
                      fontWeight: controller.activeTab.value == 'leave'
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build profile content
  Widget _buildProfileContent(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture Section
          const ProfilePictureChangeCard(),
          
          const SizedBox(height: 24),

          // Profile Information Section
          _buildProfileInformationSection(isDark),

          const SizedBox(height: 24),

          // Additional Settings Section
          _buildAdditionalSettingsSection(isDark),
        ],
      ),
    );
  }

  /// Build profile information section
  Widget _buildProfileInformationSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Profile Information',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark 
                  ? AppColors.foregroundDark 
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Email Field
          _buildProfileField(
            'Email',
            controller.userEmail.value,
            isDark,
          ),

          const SizedBox(height: 16),

          // Name Field
          _buildProfileField(
            'Name',
            controller.userName.value,
            isDark,
          ),

          const SizedBox(height: 16),

          // Edit Profile Button - navigates to separate screen (Requirement 4)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToEditProfile(),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), // Red color from screenshot
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() {
    Get.toNamed(AppRoutes.editProfile)?.then((result) {
      if (result == true) {
        controller.refreshUserData();
      }
    });
  }

  

  /// Build individual profile field
  Widget _buildProfileField(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark 
                ? AppColors.mutedForegroundDark 
                : const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : 'Not set',
          style: AppTextStyles.bodyLarge.copyWith(
            color: isDark 
                ? AppColors.foregroundDark 
                : const Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build additional settings section
  Widget _buildAdditionalSettingsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'App Settings',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark 
                  ? AppColors.foregroundDark 
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Additional Settings Buttons
          const AdditionalSettingsButtons(),
        ],
      ),
    );
  }

  /// Build leave content
  Widget _buildLeaveContent(BuildContext context, bool isDark) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          LeaveApplicationWidget(),
        ],
      ),
    );
  }
}
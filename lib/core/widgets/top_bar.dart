import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Top Bar
/// Converted from React TopBar.tsx with logout API integration
class TopBar extends GetView<DashboardController>
    implements PreferredSizeWidget {
  final String title;

  const TopBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Logo
              Container(
                height: 50,
                width: 150,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                padding: EdgeInsets.all(isDark ? 4 : 0),
                child: Image.asset(
                  "assets/images/firefox_logo.png",
                  //fit: BoxFit.contain, // logo distortion হবে না
                ),
              ),

              const SizedBox(width: 2),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h4.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              // Check-in/Check-out Button
              Obx(
                () => IconButton(
                  onPressed: controller.toggleCheckInOut,
                  icon: Icon(
                    controller.isCheckedIn.value
                        ? Icons.logout // Check out icon
                        : Icons.login, // Check in icon
                    size: 20,
                    color: controller.isCheckedIn.value
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                  ),
                  tooltip: controller.isCheckedIn.value
                      ? 'Check Out'
                      : 'Check In',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Logout Button with Loading State
              Obx(
                () => controller.isLogoutLoading.value
                    ? Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: controller.handleLogout,
                        icon: Icon(
                          Icons.logout,
                          size: 20,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                        ),
                        tooltip: 'Logout',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
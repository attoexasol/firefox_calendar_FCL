import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom Navigation Bar
/// Converted from React BottomNav.tsx
class BottomNav extends GetView<DashboardController> {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.calendar_today,
                  label: 'Calendar',
                  index: 0,
                  isActive: controller.currentNavIndex.value == 0,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.access_time,
                  label: 'Hours',
                  index: 1,
                  isActive: controller.currentNavIndex.value == 1,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 2,
                  isActive: controller.currentNavIndex.value == 2,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.attach_money,
                  label: 'Payroll',
                  index: 3,
                  isActive: controller.currentNavIndex.value == 3,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings,
                  label: 'Settings',
                  index: 4,
                  isActive: controller.currentNavIndex.value == 4,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required bool isDark,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Expanded(
      child: InkWell(
        onTap: () => controller.navigateTo(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/dashboard/controller/work_hours_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Work Hours Dashboard Cards Widget
/// 
/// Displays work hours summary in card format:
/// - Today: Total hours worked today
/// - This Week: Total hours worked in current week
/// - This Month: Total hours worked in current month
/// 
/// Features:
/// - Fetches all user hours from API
/// - Filters for logged-in user only
/// - Only shows approved records
/// - Calculates totals by summing total_hours
/// - Displays in clean card UI
class WorkHoursDashboardCards extends GetView<WorkHoursDashboardController> {
  const WorkHoursDashboardCards({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState(isDark);
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildErrorState(controller.errorMessage.value, isDark);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Work Hours Summary',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Cards Grid
          Row(
            children: [
              Expanded(
                child: _WorkHoursCard(
                  title: 'Today',
                  hours: controller.hoursToday.value,
                  icon: Icons.today,
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WorkHoursCard(
                  title: 'This Week',
                  hours: controller.hoursThisWeek.value,
                  icon: Icons.calendar_view_week,
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WorkHoursCard(
                  title: 'This Month',
                  hours: controller.hoursThisMonth.value,
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          // Refresh button
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.destructiveLight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.destructiveLight,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Error',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.destructiveLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => controller.refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primaryForegroundLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual Work Hours Card Widget
class _WorkHoursCard extends StatelessWidget {
  final String title;
  final double hours;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _WorkHoursCard({
    required this.title,
    required this.hours,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.black : AppColors.black)
                .withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hours Display
          Text(
            _formatHours(hours),
            style: AppTextStyles.h2.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Total hours',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.foregroundDark.withValues(alpha: 0.6)
                  : AppColors.foregroundLight.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    if (hours == hours.toInt()) {
      return '${hours.toInt()}';
    }
    return hours.toStringAsFixed(1);
  }
}


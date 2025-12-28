import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Hour Details Dialog
/// Displays work hour details (date, login time, logout time, total hours, status, user name)
/// Uses same navigation pattern as EventDetailsDialog
class HourDetailsDialog extends GetView<CalendarController> {
  const HourDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final workHour = controller.selectedWorkHour.value;

      if (workHour == null) return const SizedBox.shrink();

      // Calculate total hours
      final loginParts = workHour.loginTime.split(':');
      final logoutParts = workHour.logoutTime.split(':');
      final loginHour = int.parse(loginParts[0]);
      final loginMin = loginParts.length > 1 ? int.parse(loginParts[1]) : 0;
      final logoutHour = int.parse(logoutParts[0]);
      final logoutMin = logoutParts.length > 1 ? int.parse(logoutParts[1]) : 0;
      
      final loginMinutes = loginHour * 60 + loginMin;
      final logoutMinutes = logoutHour * 60 + logoutMin;
      final totalMinutes = logoutMinutes - loginMinutes;
      final totalHours = totalMinutes / 60.0;

      // Format date
      DateTime? workDate;
      try {
        workDate = DateTime.parse(workHour.date);
      } catch (e) {
        print('Error parsing work hour date: $e');
      }

      // Format time (09:00 AM format)
      String formatTime(String timeStr) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = parts[1];
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          return '$displayHour:$minute $period';
        }
        return timeStr;
      }

      return Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LEFT: Title + Subtitle
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Work Hours',
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Work hours details and information',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // RIGHT: Close button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: controller.closeWorkHourDetail,
                      icon: const Icon(Icons.close),
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildHourDetails(workHour, workDate, formatTime, totalHours, isDark),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.closeWorkHourDetail(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForegroundLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: AppTextStyles.buttonMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHourDetails(
    WorkHour workHour,
    DateTime? workDate,
    String Function(String) formatTime,
    double totalHours,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date
        _buildDetailRow(
          icon: Icons.calendar_today,
          label: 'Date',
          value: workDate != null
              ? _formatDate(workDate)
              : workHour.date,
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // Login Time
        _buildDetailRow(
          icon: Icons.login,
          label: 'Login Time',
          value: formatTime(workHour.loginTime),
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // Logout Time
        _buildDetailRow(
          icon: Icons.logout,
          label: 'Logout Time',
          value: formatTime(workHour.logoutTime),
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // Total Hours
        _buildDetailRow(
          icon: Icons.access_time,
          label: 'Total Hours',
          value: '${totalHours.toStringAsFixed(2)} hours',
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // Status
        Row(
          children: [
            Text(
              'Status: ',
              style: AppTextStyles.labelMedium.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: workHour.status.toLowerCase() == 'approved'
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                workHour.status.toLowerCase() == 'approved' ? 'Approved' : 'Pending',
                style: AppTextStyles.labelSmall.copyWith(
                  color: workHour.status.toLowerCase() == 'approved'
                      ? Colors.green.shade900
                      : Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // User Name/Email
        _buildDetailRow(
          icon: Icons.person,
          label: 'User',
          value: _getDisplayName(workHour.userEmail),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDisplayName(String userEmail) {
    if (userEmail.isEmpty) return 'User';
    
    // Try to extract name from email
    final parts = userEmail.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[0].substring(1)} ${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
    } else if (parts.isNotEmpty) {
      final name = parts[0];
      return name[0].toUpperCase() + name.substring(1);
    }
    return userEmail;
  }
}


import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// User Work Hours Details Modal
/// Shows detailed work hours for a specific user based on current calendar view
/// Adapts content for Day/Week/Month views
class UserWorkHoursModal extends GetView<CalendarController> {
  final String userEmail;
  final String viewType; // 'day', 'week', 'month'
  final DateTime selectedDate;
  final bool isDark;

  const UserWorkHoursModal({
    super.key,
    required this.userEmail,
    required this.viewType,
    required this.selectedDate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
            _buildHeader(context),
            // Content
            Expanded(
              child: Obx(() => _buildContent(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work Hours Details',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CalendarUtils.getDisplayName(userEmail),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isLoading = controller.isLoadingUserWorkHours.value;
    final error = controller.userWorkHoursError.value;
    final workHoursData = controller.userWorkHoursData.value;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.destructiveLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading work hours',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (workHoursData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 48,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              const SizedBox(height: 16),
              Text(
                'No work hours found',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No work hours recorded for this period',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Build content based on view type
    switch (viewType) {
      case 'day':
        return _buildDayView(workHoursData);
      case 'week':
        return _buildWeekView(workHoursData);
      case 'month':
        return _buildMonthView(workHoursData);
      default:
        return _buildDayView(workHoursData);
    }
  }

  Widget _buildDayView(List<Map<String, dynamic>> workHoursData) {
    final dateStr = CalendarUtils.formatDateToIso(selectedDate);
    final dayHours = workHoursData
        .where((entry) {
          final entryDate = entry['date']?.toString() ?? '';
          // Handle both ISO format (2025-12-29T00:00:00.000000Z) and simple format (2025-12-29)
          return entryDate.startsWith(dateStr);
        })
        .toList();

    double totalHours = 0.0;
    for (var entry in dayHours) {
      final hours = _parseHours(entry['total_hours']);
      totalHours += hours;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(
            title: 'Total Hours',
            value: _formatHours(totalHours),
            date: DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
          ),
          const SizedBox(height: 20),
          // Entries List
          if (dayHours.isEmpty)
            Center(
              child: Text(
                'No work hours for this day',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            )
          else
            ...dayHours.map((entry) => _buildHourEntryCard(entry)),
        ],
      ),
    );
  }

  Widget _buildWeekView(List<Map<String, dynamic>> workHoursData) {
    // Get week dates
    final weekDates = controller.getCurrentWeekDates();
    
    // Group by date
    final hoursByDate = <String, List<Map<String, dynamic>>>{};
    double weeklyTotal = 0.0;

    for (var entry in workHoursData) {
      final dateStr = entry['date']?.toString().split('T')[0] ?? '';
      if (dateStr.isNotEmpty) {
        hoursByDate.putIfAbsent(dateStr, () => []);
        hoursByDate[dateStr]!.add(entry);
        weeklyTotal += _parseHours(entry['total_hours']);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Summary
          _buildSummaryCard(
            title: 'Weekly Total',
            value: _formatHours(weeklyTotal),
            date: '${DateFormat('MMM d').format(weekDates.first)} - ${DateFormat('MMM d, yyyy').format(weekDates.last)}',
          ),
          const SizedBox(height: 20),
          // Daily Breakdown
          Text(
            'Daily Breakdown',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
          ),
          const SizedBox(height: 12),
          ...weekDates.map((date) {
            final dateStr = CalendarUtils.formatDateToIso(date);
            final dayHours = hoursByDate[dateStr] ?? [];
            double dayTotal = 0.0;
            for (var entry in dayHours) {
              dayTotal += _parseHours(entry['total_hours']);
            }

            return _buildDayCard(date, dayTotal, dayHours);
          }),
        ],
      ),
    );
  }

  Widget _buildMonthView(List<Map<String, dynamic>> workHoursData) {
    // Get month dates
    final monthDates = controller.getMonthDates();
    
    // Group by date
    final hoursByDate = <String, List<Map<String, dynamic>>>{};
    double monthlyTotal = 0.0;

    for (var entry in workHoursData) {
      final dateStr = entry['date']?.toString().split('T')[0] ?? '';
      if (dateStr.isNotEmpty) {
        hoursByDate.putIfAbsent(dateStr, () => []);
        hoursByDate[dateStr]!.add(entry);
        monthlyTotal += _parseHours(entry['total_hours']);
      }
    }

    // Filter to only dates in current month
    final monthDateStrings = monthDates
        .map((md) => CalendarUtils.formatDateToIso(md.date))
        .toSet();

    final monthHoursByDate = <String, List<Map<String, dynamic>>>{};
    for (var dateStr in hoursByDate.keys) {
      if (monthDateStrings.contains(dateStr)) {
        monthHoursByDate[dateStr] = hoursByDate[dateStr]!;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Summary
          _buildSummaryCard(
            title: 'Monthly Total',
            value: _formatHours(monthlyTotal),
            date: DateFormat('MMMM yyyy').format(selectedDate),
          ),
          const SizedBox(height: 20),
          // Days with hours
          Text(
            'Days with Work Hours',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
          ),
          const SizedBox(height: 12),
          if (monthHoursByDate.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No work hours for this month',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ),
            )
          else
            ...monthHoursByDate.entries.map((entry) {
              final date = DateTime.parse(entry.key);
              final dayHours = entry.value;
              double dayTotal = 0.0;
              for (var hourEntry in dayHours) {
                dayTotal += _parseHours(hourEntry['total_hours']);
              }
              return _buildDayCard(date, dayTotal, dayHours);
            }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.mutedDark.withValues(alpha: 0.3)
            : AppColors.mutedLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
            ],
          ),
          Text(
            date,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DateTime date, double totalHours, List<Map<String, dynamic>> entries) {
    final dateStr = CalendarUtils.formatDateToIso(date);
    final isToday = CalendarUtils.formatDateToIso(DateTime.now()) == dateStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isToday
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(date),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
              Text(
                _formatHours(totalHours),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...entries.map((entry) => _buildHourEntryCard(entry, isCompact: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildHourEntryCard(Map<String, dynamic> entry, {bool isCompact = false}) {
    final loginTime = entry['login_time']?.toString() ?? '';
    final logoutTime = entry['logout_time']?.toString() ?? '';
    final totalHours = _parseHours(entry['total_hours']);
    final status = entry['status']?.toString() ?? 'pending';

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.mutedDark.withValues(alpha: 0.2)
            : AppColors.mutedLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$loginTime - $logoutTime',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
                      ),
                    ),
                  ],
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 4),
                  _buildStatusChip(status),
                ],
              ],
            ),
          ),
          Text(
            _formatHours(totalHours),
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        statusText,
        style: AppTextStyles.labelSmall.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _parseHours(dynamic hoursValue) {
    if (hoursValue == null) return 0.0;
    if (hoursValue is double) return hoursValue;
    if (hoursValue is int) return hoursValue.toDouble();
    if (hoursValue is String) {
      return double.tryParse(hoursValue) ?? 0.0;
    }
    return 0.0;
  }

  String _formatHours(double hours) {
    if (hours == 0.0) return '0h';
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }
}


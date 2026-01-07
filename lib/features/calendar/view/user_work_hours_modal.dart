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
                  'Activities & Work Hours',
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

  Widget _buildDayView(List<Map<String, dynamic>> activitiesData) {
    final dateStr = CalendarUtils.formatDateToIso(selectedDate);
    final dayActivities = activitiesData
        .where((entry) {
          // Handle both 'work_date' (work hours) and 'date' (events) fields
          final entryDate = entry['work_date']?.toString() ?? entry['date']?.toString() ?? '';
          // Handle both ISO format (2025-12-29T00:00:00.000000Z) and simple format (2025-12-29)
          final datePart = entryDate.contains('T') ? entryDate.split('T')[0] : entryDate;
          return datePart == dateStr;
        })
        .toList();

    double totalHours = 0.0;
    for (var entry in dayActivities) {
      // Calculate hours from start/end times
      final hours = _calculateHours(entry);
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
          if (dayActivities.isEmpty)
            Center(
              child: Text(
                'No activities for this day',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            )
          else
            ...dayActivities.map((entry) => _buildActivityEntryCard(entry)),
        ],
      ),
    );
  }

  Widget _buildWeekView(List<Map<String, dynamic>> activitiesData) {
    // Get week dates - extract from controller ONCE in Obx, then pass as parameter
    // For now, calculate week dates from selectedDate to avoid Rx access
    final weekStart = _getStartOfWeek(selectedDate);
    final weekDates = List.generate(7, (index) => weekStart.add(Duration(days: index)));
    
    // Group by date
    final activitiesByDate = <String, List<Map<String, dynamic>>>{};
    double weeklyTotal = 0.0;

    for (var entry in activitiesData) {
      // Handle both 'work_date' (work hours) and 'date' (events) fields
      final entryDate = entry['work_date']?.toString() ?? entry['date']?.toString() ?? '';
      final dateStr = entryDate.contains('T') ? entryDate.split('T')[0] : entryDate;
      if (dateStr.isNotEmpty) {
        // Verify date is within the week range
        try {
          final entryDateTime = DateTime.parse(dateStr);
          final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          final weekEndDate = weekStartDate.add(const Duration(days: 6));
          final entryDateOnly = DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);
          
          if (entryDateOnly.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
              entryDateOnly.isBefore(weekEndDate.add(const Duration(days: 1)))) {
            activitiesByDate.putIfAbsent(dateStr, () => []);
            activitiesByDate[dateStr]!.add(entry);
            weeklyTotal += _calculateHours(entry);
          }
        } catch (e) {
          // Skip invalid dates
          continue;
        }
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
            final dayActivities = activitiesByDate[dateStr] ?? [];
            double dayTotal = 0.0;
            for (var entry in dayActivities) {
              dayTotal += _calculateHours(entry);
            }

            return _buildDayCard(date, dayTotal, dayActivities);
          }),
        ],
      ),
    );
  }

  Widget _buildMonthView(List<Map<String, dynamic>> activitiesData) {
    // Calculate month dates from selectedDate to avoid Rx access
    // Use year and month from selectedDate, ignore the day
    final year = selectedDate.year;
    final month = selectedDate.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final monthDates = List.generate(lastDay.day, (index) => DateTime(year, month, index + 1));
    
    // Group activities by date (all entries should already be in the target month from controller)
    final activitiesByDate = <String, List<Map<String, dynamic>>>{};
    double monthlyTotal = 0.0;

    for (var entry in activitiesData) {
      // Handle both 'work_date' (work hours) and 'date' (events) fields
      final entryDate = entry['work_date']?.toString() ?? entry['date']?.toString() ?? '';
      final dateStr = entryDate.contains('T') ? entryDate.split('T')[0] : entryDate;
      
      if (dateStr.isNotEmpty) {
        // Verify the date is in the target month (double-check for safety)
        try {
          final entryDateTime = DateTime.parse(dateStr);
          if (entryDateTime.year == year && entryDateTime.month == month) {
            activitiesByDate.putIfAbsent(dateStr, () => []);
            activitiesByDate[dateStr]!.add(entry);
            monthlyTotal += _calculateHours(entry);
          }
        } catch (e) {
          // Skip invalid dates
          continue;
        }
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
          // Days with activities
          Text(
            'Days with Activities',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
          ),
          const SizedBox(height: 12),
          // Show all days of the month that have activities
          // Sort entries by date for chronological display
          if (activitiesByDate.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No activities for this month',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ),
            )
          else
            ...() {
              // Sort entries by date
              final sortedEntries = activitiesByDate.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));
              
              // Map to widgets
              return sortedEntries.map((entry) {
                final date = DateTime.parse(entry.key);
                final dayActivities = entry.value;
                double dayTotal = 0.0;
                // Recalculate total to ensure accuracy
                for (var activityEntry in dayActivities) {
                  dayTotal += _calculateHours(activityEntry);
                }
                return _buildDayCard(date, dayTotal, dayActivities);
              }).toList();
            }(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              date,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMMM d').format(date),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
            ...entries.map((entry) => _buildActivityEntryCard(entry, isCompact: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityEntryCard(Map<String, dynamic> entry, {bool isCompact = false}) {
    final entryType = entry['type']?.toString() ?? 'work_hour';
    final isWorkHour = entryType == 'work_hour';
    final isEvent = entryType == 'event';
    
    // Get time strings - work hours use login_time/logout_time, events use start_time/end_time
    final startTimeStr = isWorkHour 
        ? (entry['login_time']?.toString() ?? entry['start_time']?.toString() ?? '')
        : (entry['start_time']?.toString() ?? '');
    final endTimeStr = isWorkHour
        ? (entry['logout_time']?.toString() ?? entry['end_time']?.toString() ?? '')
        : (entry['end_time']?.toString() ?? '');
    
    final totalHours = _calculateHours(entry);
    final status = entry['status']?.toString() ?? (isWorkHour ? 'approved' : 'confirmed');
    final title = entry['title']?.toString() ?? '';
    
    // Format time strings (remove seconds if present)
    final startTime = _formatTimeString(startTimeStr);
    final endTime = endTimeStr.isNotEmpty ? _formatTimeString(endTimeStr) : '--';

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
                      isEvent ? Icons.event : Icons.access_time,
                      size: 16,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : '$startTime - $endTime',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                          fontWeight: isEvent ? FontWeight.w500 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$startTime - $endTime',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
                if (!isCompact && isWorkHour) ...[
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

  /// Calculate hours from entry, using total_hours if available, otherwise from start/end times
  /// Handles both events (start_time/end_time) and work hours (login_time/logout_time)
  double _calculateHours(Map<String, dynamic> entry) {
    // First try to use total_hours field
    final totalHoursValue = entry['total_hours'];
    if (totalHoursValue != null) {
      final parsed = _parseHours(totalHoursValue);
      if (parsed > 0.0) {
        return parsed;
      }
    }
    
    // Determine entry type and get appropriate time fields
    final entryType = entry['type']?.toString() ?? 'work_hour';
    final isWorkHour = entryType == 'work_hour';
    
    // Get time strings - work hours use login_time/logout_time, events use start_time/end_time
    final startTimeStr = isWorkHour
        ? (entry['login_time']?.toString() ?? entry['start_time']?.toString() ?? '')
        : (entry['start_time']?.toString() ?? '');
    final endTimeStr = isWorkHour
        ? (entry['logout_time']?.toString() ?? entry['end_time']?.toString() ?? '')
        : (entry['end_time']?.toString() ?? '');
    
    if (startTimeStr.isEmpty || endTimeStr.isEmpty) {
      return 0.0;
    }
    
    try {
      // Parse time strings (format: "HH:MM:SS" or "HH:MM")
      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');
      
      if (startParts.length < 2 || endParts.length < 2) {
        return 0.0;
      }
      
      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);
      
      final startMinutes = startHour * 60 + startMin;
      final endMinutes = endHour * 60 + endMin;
      var totalMinutes = endMinutes - startMinutes;
      
      // Handle case where end time is next day
      if (totalMinutes < 0) {
        totalMinutes = (24 * 60) + totalMinutes;
      }
      
      return totalMinutes / 60.0;
    } catch (e) {
      return 0.0;
    }
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

  /// Get start of week (Monday) for a given date
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    // Monday is weekday 1, so subtract (weekday - 1) days
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Format time string to HH:MM format (remove seconds if present)
  String _formatTimeString(String timeStr) {
    if (timeStr.isEmpty) return '--';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  String _formatHours(double hours) {
    if (hours == 0.0) return '0h';
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }
}


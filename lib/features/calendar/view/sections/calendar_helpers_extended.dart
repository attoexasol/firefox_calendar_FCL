import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_utils.dart';
import 'package:flutter/material.dart';

/// Extended helper functions for calendar screen
class CalendarHelpers {
  /// Get color for user avatar (consistent color per user)
  static Color getUserColor(String userEmail) {
    // Generate consistent color based on user email
    final hash = userEmail.hashCode;
    final colors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF97316), // Orange
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEAB308), // Yellow
    ];
    return colors[hash.abs() % colors.length];
  }

  /// Get users by date for week view
  /// Includes users from both meetings and work hours
  /// This MUST match the calculation in CalendarWeekView.build() exactly
  static Map<String, List<String>> getUsersByDateForWeek(
    List<DateTime> weekDates,
    CalendarController controller,
  ) {
    final usersByDate = <String, List<String>>{};
    
    for (var date in weekDates) {
      final dateStr = CalendarUtils.formatDateToIso(date);
      // Get all meetings for this date from controller (includes work hours)
      // This MUST match CalendarWeekView.build() exactly
      final allDayMeetings = controller.meetings.where((m) => m.date == dateStr).toList();
      final filteredDayMeetings = controller.filterMeetings(allDayMeetings);
      
      // Get unique users for this specific date
      // This MUST match CalendarWeekView.build() exactly
      if (controller.scopeType.value == 'myself') {
        // In "Myself" view, only show current user if they have meetings or work hours
        final currentUserEmail = controller.userEmail.value;
        if (currentUserEmail.isNotEmpty) {
          // Check if user has any meetings or work hours on this date
          final hasMeetings = filteredDayMeetings.any((m) => 
            (m.creator == currentUserEmail || m.attendees.contains(currentUserEmail)) &&
            (controller.userId.value == 0 || m.userId == null || m.userId == controller.userId.value)
          );
          final hasWorkHours = controller.getWorkHoursForUser(currentUserEmail, dateStr).isNotEmpty;
          if (hasMeetings || hasWorkHours) {
            usersByDate[dateStr] = [currentUserEmail];
          } else {
            usersByDate[dateStr] = [];
          }
        } else {
          usersByDate[dateStr] = [];
        }
      } else {
        // In "Everyone" view, show all users who have events OR work hours on this date
        final users = CalendarUtils.getUsersFromMeetings(filteredDayMeetings);
        // Also add users from work hours
        final allUsers = <String>{...users};
        for (var meeting in filteredDayMeetings) {
          if (meeting.creator.isNotEmpty) {
            allUsers.add(meeting.creator);
          }
        }
        usersByDate[dateStr] = allUsers.toList()..sort();
      }
    }
    
    return usersByDate;
  }
}

/// Extension to format date as ISO string (YYYY-MM-DD)
extension DateFormatExtension on CalendarUtils {
  static String formatDateToIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// SliverPersistentHeaderDelegate for Week Grid Header
/// Sticky header with days/dates row + time column + user avatars
class WeekGridHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<DateTime> weekDates;
  final Map<String, List<String>> usersByDate;
  final double totalWidth;
  final bool isDark;
  final Function(DateTime) onDateClick;
  final DateTime? selectedWeekDate;
  final ScrollController horizontalScrollController;

  WeekGridHeaderDelegate({
    required this.weekDates,
    required this.usersByDate,
    required this.totalWidth,
    required this.isDark,
    required this.onDateClick,
    required this.horizontalScrollController,
    this.selectedWeekDate,
  });

  @override
  double get minExtent => 168.0; // Days row (~60 with padding) + User header (80) + borders/spacing (~28)

  @override
  double get maxExtent => 168.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Days/Dates Row - FIXED (does not scroll horizontally)
          // This row stays fixed while User Header Row and Time Grid scroll
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Constrain to viewport width - no horizontal scroll
                return Row(
                  children: weekDates.map((date) {
                    return _buildDayDateItem(date, isDark);
                  }).toList(),
                );
              },
            ),
          ),
          // User Header Row (Time + User Avatars)
          // This row scrolls horizontally with the time columns below
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: horizontalScrollController, // Shared scroll controller
              child: SizedBox(
                width: totalWidth,
                child: Row(
                  children: [
                    // Time Label Header
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                      ),
                      child: Text(
                        'Time',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // User Columns for each day
                    ...weekDates.expand((date) {
                      final dateStr = CalendarUtils.formatDateToIso(date);
                      final dayUsers = usersByDate[dateStr] ?? [];
                      return dayUsers.map((user) {
                        return Container(
                          width: 150,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight,
                            border: Border(
                              right: BorderSide(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // User Avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: CalendarHelpers.getUserColor(user),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  CalendarUtils.getUserInitials(user),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // User Name
                              Flexible(
                                child: Text(
                                  CalendarUtils.getDisplayName(user),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.foregroundDark
                                        : AppColors.foregroundLight,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(WeekGridHeaderDelegate oldDelegate) {
    return weekDates != oldDelegate.weekDates ||
        usersByDate != oldDelegate.usersByDate ||
        isDark != oldDelegate.isDark ||
        selectedWeekDate != oldDelegate.selectedWeekDate ||
        horizontalScrollController != oldDelegate.horizontalScrollController;
  }

  Widget _buildDayDateItem(DateTime date, bool isDark) {
    final today = DateTime.now();
    final dateStr = CalendarUtils.formatDateToIso(date);
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isFiltered =
        selectedWeekDate != null &&
        CalendarUtils.formatDateToIso(selectedWeekDate!) == dateStr;

    return Expanded(
      child: InkWell(
        onTap: () => onDateClick(date),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isFiltered
                ? AppColors.primary.withValues(alpha: 0.1)
                : isToday
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(
                    color: AppColors.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CalendarUtils.getWeekdayShort(date.weekday),
                style: AppTextStyles.labelSmall.copyWith(
                  color: isFiltered
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight),
                  fontWeight: isToday || isFiltered
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isFiltered
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight),
                  fontWeight: isToday || isFiltered
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SliverPersistentHeaderDelegate for Day Grid Header
/// Sticky header with time column + user avatars
class DayGridHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> users;
  final double totalWidth;
  final bool isDark;
  final ScrollController horizontalScrollController;

  DayGridHeaderDelegate({
    required this.users,
    required this.totalWidth,
    required this.isDark,
    required this.horizontalScrollController,
  });

  @override
  double get minExtent => 80.0;

  @override
  double get maxExtent => 80.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: horizontalScrollController, // Shared scroll controller
        child: SizedBox(
          width: totalWidth,
          child: Row(
            children: [
              // Time Label Header
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                ),
                child: Text(
                  'Time',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              // User Columns
              ...users.map((user) {
                return Container(
                  width: 150,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    border: Border(
                      right: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CalendarHelpers.getUserColor(user),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          CalendarUtils.getUserInitials(user),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // User Name
                      Flexible(
                        child: Text(
                          CalendarUtils.getDisplayName(user),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(DayGridHeaderDelegate oldDelegate) {
    return users != oldDelegate.users ||
        totalWidth != oldDelegate.totalWidth ||
        isDark != oldDelegate.isDark ||
        horizontalScrollController != oldDelegate.horizontalScrollController;
  }
}


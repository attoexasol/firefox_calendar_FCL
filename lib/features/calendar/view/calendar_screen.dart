import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:firefox_calendar/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Calendar Screen
/// Converted from React Calendar.tsx
/// Shows day/week/month views with meeting schedule
class CalendarScreen extends GetView<CalendarController> {
  const CalendarScreen({super.key});

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
            const TopBar(title: 'Calendar'),

            // Filtering Section
            _buildFilteringSection(context, isDark),

            // Calendar View
            Expanded(
              child: Obx(() {
                if (controller.viewType.value == 'week') {
                  return _buildWeekView(context, isDark);
                } else if (controller.viewType.value == 'day') {
                  return _buildDayView(context, isDark);
                } else {
                  return _buildMonthView(context, isDark);
                }
              }),
            ),
          ],
        ),
      ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Reset form for new event creation
      //     final createEventController = Get.find<CreateEventController>();
      //     createEventController.resetForm();

      //     // Navigate to create event screen
      //     Get.toNamed(AppRoutes.createEvent);
      //   },
      //   child: const Icon(Icons.add, size: 28),
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final createEventController = Get.find<CreateEventController>();
          createEventController.resetForm();
          Get.toNamed(AppRoutes.createEvent);
        },
        backgroundColor: const Color(0xFFFF6B35), // চাইলে পরিবর্তন করতে পারো
        elevation: 4,
        shape: const CircleBorder(), // 🔥 Force circle shape
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),

      bottomNavigationBar: const BottomNav(),
    );
  }

  /// Build filtering section
  Widget _buildFilteringSection(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // View Type Tabs
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Show calendar by',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        context,
                        'Day',
                        'day',
                        controller.viewType.value == 'day',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton(
                        context,
                        'Week',
                        'week',
                        controller.viewType.value == 'week',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton(
                        context,
                        'Month',
                        'month',
                        controller.viewType.value == 'month',
                        isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Scope Filter Tabs
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Show schedule for',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        context,
                        'Everyone',
                        'everyone',
                        controller.scopeType.value == 'everyone',
                        isDark,
                        isScope: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton(
                        context,
                        'Myself',
                        'myself',
                        controller.scopeType.value == 'myself',
                        isDark,
                        isScope: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Date Navigation
          Row(
            children: [
              // Previous Button
              IconButton(
                onPressed: controller.navigatePrevious,
                icon: const Icon(Icons.chevron_left, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.cardDark
                      : AppColors.cardLight,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Date Display
              Expanded(
                child: Obx(() {
                  String dateText;
                  if (controller.viewType.value == 'day') {
                    dateText = _formatDate(controller.currentDate.value, 'day');
                  } else if (controller.viewType.value == 'week') {
                    final weekDates = controller.getCurrentWeekDates();
                    dateText =
                        '${_formatDate(weekDates.first, 'short')} - ${_formatDate(weekDates.last, 'full')}';
                  } else {
                    dateText = _formatDate(
                      controller.currentDate.value,
                      'month',
                    );
                  }

                  return Container(
                    height: 36,
                    alignment: Alignment.center,
                    child: Text(
                      dateText,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),

              // Today Button
              TextButton(
                onPressed: controller.navigateToToday,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: isDark
                      ? AppColors.cardDark
                      : AppColors.cardLight,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  'Today',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Next Button
              IconButton(
                onPressed: controller.navigateNext,
                icon: const Icon(Icons.chevron_right, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.cardDark
                      : AppColors.cardLight,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build tab button
  Widget _buildTabButton(
    BuildContext context,
    String label,
    String value,
    bool isActive,
    bool isDark, {
    bool isScope = false,
  }) {
    return InkWell(
      onTap: () {
        if (isScope) {
          controller.setScopeType(value);
        } else {
          controller.setViewType(value);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isActive
                ? AppColors.primaryForegroundLight
                : (isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// Build week view
  Widget _buildWeekView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Week Date Filter Indicator
          Obx(() {
            if (controller.selectedWeekDate.value == null) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Showing events for ${_formatDate(controller.selectedWeekDate.value!, 'short')}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => controller.selectedWeekDate.value = null,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Week Days Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Obx(() {
              final weekDates = controller.getCurrentWeekDates();
              final today = DateTime.now();

              return Row(
                children: weekDates.map((date) {
                  final dateStr = date.toIso8601String().split('T')[0];
                  final isToday =
                      date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final isFiltered =
                      controller.selectedWeekDate.value != null &&
                      controller.selectedWeekDate.value!
                              .toIso8601String()
                              .split('T')[0] ==
                          dateStr;

                  return Expanded(
                    child: InkWell(
                      onTap: () => controller.handleWeekDateClick(date),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              _getWeekdayShort(date.weekday),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isFiltered || isToday
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight),
                                fontWeight: isFiltered || isToday
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isFiltered
                                    ? AppColors.primary
                                    : (isToday
                                          ? AppColors.primary.withValues(alpha: 0.2)
                                          : Colors.transparent),
                                borderRadius: BorderRadius.circular(16),
                                border: isFiltered
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isFiltered
                                      ? AppColors.white
                                      : (isToday
                                            ? AppColors.primary
                                            : (isDark
                                                  ? AppColors.foregroundDark
                                                  : AppColors.foregroundLight)),
                                  fontWeight: isFiltered || isToday
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ),

          const SizedBox(height: 8),

          // Week Schedule Grid
          Obx(() {
            final weekDates = controller.getCurrentWeekDates();
            final meetingsByDate = controller.getMeetingsByDate();

            // Get all meetings for the week
            final weekMeetings = <Meeting>[];
            for (var date in weekDates) {
              final dateStr = date.toIso8601String().split('T')[0];
              final dayMeetings = meetingsByDate[dateStr] ?? [];
              weekMeetings.addAll(dayMeetings);
            }

            final filteredMeetings = controller.filterMeetings(weekMeetings);
            final timeRange = controller.getTimeRange(filteredMeetings);

            return _buildTimelineGrid(
              context,
              weekDates,
              timeRange,
              meetingsByDate,
              isDark,
            );
          }),
        ],
      ),
    );
  }

  /// Build day view
  Widget _buildDayView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      child: Obx(() {
        final currentDate = controller.currentDate.value;
        final dateStr = currentDate.toIso8601String().split('T')[0];
        final meetingsByDate = controller.getMeetingsByDate();
        final dayMeetings = meetingsByDate[dateStr] ?? [];
        final filteredMeetings = controller.filterMeetings(dayMeetings);
        final timeRange = controller.getTimeRange(filteredMeetings);

        return _buildTimelineGrid(
          context,
          [currentDate],
          timeRange,
          meetingsByDate,
          isDark,
        );
      }),
    );
  }

  /// Build month view
  Widget _buildMonthView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Obx(() {
        final monthDates = controller.getMonthDates();
        final meetingsByDate = controller.getMeetingsByDate();
        final today = DateTime.now();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: monthDates.length + 7, // +7 for weekday headers
          itemBuilder: (context, index) {
            // Weekday headers
            if (index < 7) {
              return Container(
                alignment: Alignment.center,
                child: Text(
                  ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            // Date cells
            final dateIndex = index - 7;
            final monthDate = monthDates[dateIndex];
            final date = monthDate.date;
            final dateStr = date.toIso8601String().split('T')[0];
            final dayMeetings = controller.filterMeetings(
              meetingsByDate[dateStr] ?? [],
            );
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;

            return InkWell(
              onTap: () => controller.handleDayClick(date),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : (isDark ? AppColors.cardDark : AppColors.cardLight),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                    width: isToday ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: monthDate.isCurrentMonth
                            ? (isToday
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.foregroundDark
                                        : AppColors.foregroundLight))
                            : (isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight),
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (dayMeetings.isNotEmpty)
                      Expanded(
                        child: Column(
                          children: [
                            ...dayMeetings.take(2).map((meeting) {
                              final color = controller.getEventColor(
                                meeting,
                                isDark,
                              );
                              return Container(
                                height: 2,
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            }),
                            if (dayMeetings.length > 2)
                              Text(
                                '+${dayMeetings.length - 2}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 8,
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForegroundLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Build timeline grid (for day and week views)
  Widget _buildTimelineGrid(
    BuildContext context,
    List<DateTime> dates,
    TimeRange timeRange,
    Map<String, List<Meeting>> meetingsByDate,
    bool isDark,
  ) {
    final numSlots = timeRange.endHour - timeRange.startHour + 1;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width:
            dates.length * 150.0 +
            80, // 150px per date column + 80px for time labels
        child: Column(
          children: List.generate(numSlots, (index) {
            final hour = timeRange.startHour + index;
            final timeLabel = _formatHour(hour);

            return Container(
              height: 80,
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
                  // Time Label
                  Container(
                    width: 80,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      timeLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ),

                  // Date Columns
                  ...dates.map((date) {
                    final dateStr = date.toIso8601String().split('T')[0];
                    final dayMeetings = meetingsByDate[dateStr] ?? [];

                    // Find meetings in this time slot
                    final slotMeetings = controller
                        .filterMeetings(dayMeetings)
                        .where((meeting) {
                          final startParts = meeting.startTime.split(':');
                          final startHour = int.parse(startParts[0]);
                          return startHour == hour;
                        })
                        .toList();

                    return Container(
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: slotMeetings.map((meeting) {
                          final color = controller.getEventColor(
                            meeting,
                            isDark,
                          );
                          final textColor = controller.getEventTextColor(
                            meeting,
                            isDark,
                          );

                          return InkWell(
                            onTap: () => controller.openMeetingDetail(meeting),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meeting.title,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    meeting.startTime,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 10,
                                      color: textColor.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Format date based on type
  String _formatDate(DateTime date, String type) {
    switch (type) {
      case 'day':
        return '${_getWeekdayFull(date.weekday)}, ${_getMonthShort(date.month)} ${date.day}, ${date.year}';
      case 'short':
        return '${_getMonthShort(date.month)} ${date.day}';
      case 'full':
        return '${_getMonthShort(date.month)} ${date.day}, ${date.year}';
      case 'month':
        return '${_getMonthFull(date.month)} ${date.year}';
      default:
        return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Format hour for display
  String _formatHour(int hour) {
    if (hour > 12) {
      return '${hour - 12}:00 PM';
    } else if (hour == 12) {
      return '12:00 PM';
    } else if (hour == 0) {
      return '12:00 AM';
    } else {
      return '$hour:00 AM';
    }
  }

  /// Get weekday short name
  String _getWeekdayShort(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  /// Get weekday full name
  String _getWeekdayFull(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  /// Get month short name
  String _getMonthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Get month full name
  String _getMonthFull(int month) {
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
    return months[month - 1];
  }
}

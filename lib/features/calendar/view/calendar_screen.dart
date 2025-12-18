import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:firefox_calendar/features/calendar/view/event_details_dialog.dart';
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
      body: Stack(
        children: [
          // Main calendar content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                const TopBar(title: 'Calendar'),

                // Filtering Section
                _buildFilteringSection(context, isDark),

                // Calendar View
                Expanded(
                  child: Obx(() {
                    // Show loading state
                    if (controller.isLoadingEvents.value && controller.meetings.isEmpty) {
                      return _buildLoadingState(isDark);
                    }

                    // Show error state (only if no events exist)
                    if (controller.eventsError.value.isNotEmpty && 
                        controller.meetings.isEmpty &&
                        !controller.isLoadingEvents.value) {
                      return _buildErrorState(controller.eventsError.value, isDark);
                    }

                    // Show empty state (only if no events and no error)
                    if (controller.meetings.isEmpty && 
                        !controller.isLoadingEvents.value &&
                        controller.eventsError.value.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    // Show calendar views
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
          // Event Details Dialog listener
          _buildEventDetailsListener(),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final createEventController = Get.find<CreateEventController>();
          createEventController.resetForm();
          Get.toNamed(AppRoutes.createEvent);
        },
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 4,
        shape: const CircleBorder(),
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
      child: Obx(() {
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
        
        // Get unique users from all week meetings
        final users = _getUsersFromMeetings(filteredMeetings);
        
        return Column(
          children: [
            // Week Date Filter Indicator
            if (controller.selectedWeekDate.value != null)
              Container(
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
              ),

            // Week Days Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: weekDates.map((date) {
                  final today = DateTime.now();
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
                              _getWeekdayShort(date.weekday),
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
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Week Schedule with User Columns
            if (users.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No events scheduled for this week',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ),
              )
            else
              _buildWeekUserTimelineGrid(
                context,
                users,
                weekDates,
                meetingsByDate,
                timeRange,
                isDark,
              ),
          ],
        );
      }),
    );
  }

  /// Build week user timeline grid (similar to day view but for multiple days)
  Widget _buildWeekUserTimelineGrid(
    BuildContext context,
    List<String> users,
    List<DateTime> weekDates,
    Map<String, List<Meeting>> meetingsByDate,
    TimeRange timeRange,
    bool isDark,
  ) {
    final numSlots = timeRange.endHour - timeRange.startHour + 1;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: (weekDates.length * users.length * 150.0) + 80, // 150px per user column per day + 80px for time labels
        child: Column(
          children: [
            // Header Row with Time and User columns for each day
            Container(
              height: 80, // Fixed height for header
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
                    final dateStr = date.toIso8601String().split('T')[0];
                    return users.map((user) {
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
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // User Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getUserColor(user),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getUserInitials(user),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // User Name
                            Text(
                              _getDisplayName(user),
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
                          ],
                        ),
                      );
                    });
                  }),
                ],
              ),
            ),
            // Time Slots and Events
            ...List.generate(numSlots, (index) {
              final hour = timeRange.startHour + index;
              final timeLabel = _formatHour(hour);

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
                child: Row(
                  children: [
                    // Time Label
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                      ),
                      child: Text(
                        timeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ),
                    // User Columns for each day
                    ...weekDates.expand((date) {
                      final dateStr = date.toIso8601String().split('T')[0];
                      final dayMeetings = meetingsByDate[dateStr] ?? [];
                      final filteredDayMeetings = controller.filterMeetings(dayMeetings);
                      
                      return users.map((user) {
                        // Find meetings for this user on this date that overlap with this hour slot
                        final userMeetings = filteredDayMeetings.where((meeting) {
                          // Check if user is creator or attendee
                          final isUserMeeting = meeting.creator == user ||
                              meeting.attendees.contains(user);
                          if (!isUserMeeting) return false;

                          // Check if meeting overlaps with this hour
                          final startParts = meeting.startTime.split(':');
                          final endParts = meeting.endTime.split(':');
                          final startHour = int.parse(startParts[0]);
                          final startMin = int.parse(startParts[1]);
                          final endHour = int.parse(endParts[0]);
                          final endMin = int.parse(endParts[1]);
                          
                          // Meeting overlaps if it starts before or during this hour
                          // and ends after this hour starts
                          return (startHour < hour || (startHour == hour && startMin == 0)) &&
                                 (endHour > hour || (endHour == hour && endMin > 0));
                        }).toList();

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
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: userMeetings.where((meeting) {
                              // Only show event in the hour slot where it starts
                              final startParts = meeting.startTime.split(':');
                              final startHour = int.parse(startParts[0]);
                              return startHour == hour;
                            }).map((meeting) {
                              // Use meeting creator for color (user-wise color coding)
                              final userForColor = meeting.creator;
                              final color = _getEventColorForUser(meeting, userForColor, isDark);
                              final textColor = _getEventTextColorForUser(meeting, userForColor, isDark);

                              // Fixed size for all events (width and height)
                              return InkWell(
                                onTap: () => controller.openMeetingDetail(meeting),
                                child: Container(
                                  width: double.infinity, // Full width of parent
                                  height: 60, // Fixed height
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          meeting.title,
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
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
                      });
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Get weekday short name
  String _getWeekdayShort(int weekday) {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return weekdays[weekday - 1];
  }

  /// Get color for user avatar (consistent color per user)
  Color _getUserColor(String userEmail) {
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

  /// Get event color based on user (different color per user)
  Color _getEventColorForUser(Meeting meeting, String user, bool isDark) {
    // Check if meeting is in the past
    final meetingDateTime = DateTime.parse(
      '${meeting.date}T${meeting.endTime}',
    );
    final now = DateTime.now();
    final isPast = meetingDateTime.isBefore(now);

    if (isPast) {
      return isDark
          ? const Color(0xFF166534).withValues(alpha: 0.4)
          : const Color(0xFFBBF7D0);
    }

    // Get user color and apply it to the event (more vibrant for better visibility)
    final userColor = _getUserColor(user);
    return meeting.type == 'confirmed'
        ? userColor.withValues(alpha: 0.9) // More vibrant for confirmed events
        : userColor.withValues(alpha: 0.5); // Slightly more visible for tentative
  }

  /// Get text color for event based on user
  Color _getEventTextColorForUser(Meeting meeting, String user, bool isDark) {
    final meetingDateTime = DateTime.parse(
      '${meeting.date}T${meeting.endTime}',
    );
    final now = DateTime.now();
    final isPast = meetingDateTime.isBefore(now);

    if (isPast) {
      return isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534);
    }

    // Use white text for better contrast on colored backgrounds
    return meeting.type == 'confirmed'
        ? Colors.white
        : (isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87);
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

        // Get unique users from meetings
        final users = _getUsersFromMeetings(filteredMeetings);
        
        return _buildUserTimelineGrid(
          context,
          users,
          dateStr,
          filteredMeetings,
          timeRange,
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
              child: Row(
                children: [
                  // Time Label
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                    ),
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
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: slotMeetings.map((meeting) {
                          // Use meeting creator for color (user-wise)
                          final userForColor = meeting.creator;
                          final color = _getEventColorForUser(meeting, userForColor, isDark);
                          final textColor = _getEventTextColorForUser(meeting, userForColor, isDark);

                          return InkWell(
                            onTap: () => controller.openMeetingDetail(meeting),
                            child: Container(
                              width: double.infinity, // Full width of parent
                              height: 60, // Fixed height
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      meeting.title,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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

  /// Get unique users from meetings
  List<String> _getUsersFromMeetings(List<Meeting> meetings) {
    final userSet = <String>{};
    for (var meeting in meetings) {
      userSet.add(meeting.creator);
      userSet.addAll(meeting.attendees);
    }
    return userSet.toList()..sort();
  }

  /// Get user initials from email/name
  String _getUserInitials(String userEmail) {
    if (userEmail.isEmpty) return 'U';
    
    // Try to extract name from email or use email
    final parts = userEmail.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    } else if (parts.isNotEmpty) {
      final name = parts[0];
      if (name.length >= 2) {
        return name.substring(0, 2).toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return userEmail[0].toUpperCase();
  }

  /// Get display name from email
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

  /// Build user timeline grid (for day view with user columns)
  Widget _buildUserTimelineGrid(
    BuildContext context,
    List<String> users,
    String dateStr,
    List<Meeting> meetings,
    TimeRange timeRange,
    bool isDark,
  ) {
    final numSlots = timeRange.endHour - timeRange.startHour + 1;
    
    // If no users, show empty state
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No events scheduled for this day',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: users.length * 150.0 + 80, // 150px per user column + 80px for time labels
        child: Column(
          children: [
            // User Header Row
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
                  // User Columns Headers
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
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // User Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getUserColor(user),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _getUserInitials(user),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // User Name
                          Text(
                            _getDisplayName(user),
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
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Time Slots and Events
            ...List.generate(numSlots, (index) {
              final hour = timeRange.startHour + index;
              final timeLabel = _formatHour(hour);

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
                child: Row(
                  children: [
                    // Time Label
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                      ),
                      child: Text(
                        timeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ),
                    // User Columns
                    ...users.map((user) {
                      // Find meetings for this user that overlap with this hour slot
                      final userMeetings = meetings.where((meeting) {
                        // Check if user is creator or attendee
                        final isUserMeeting = meeting.creator == user ||
                            meeting.attendees.contains(user);
                        if (!isUserMeeting) return false;

                        // Check if meeting is on this date
                        if (meeting.date != dateStr) return false;

                        // Check if meeting overlaps with this hour
                        final startParts = meeting.startTime.split(':');
                        final endParts = meeting.endTime.split(':');
                        final startHour = int.parse(startParts[0]);
                        final startMin = int.parse(startParts[1]);
                        final endHour = int.parse(endParts[0]);
                        final endMin = int.parse(endParts[1]);
                        
                        // Meeting overlaps if it starts before or during this hour
                        // and ends after this hour starts
                        return (startHour < hour || (startHour == hour && startMin == 0)) &&
                               (endHour > hour || (endHour == hour && endMin > 0));
                      }).toList();

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
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: userMeetings.where((meeting) {
                            // Only show event in the hour slot where it starts
                            final startParts = meeting.startTime.split(':');
                            final startHour = int.parse(startParts[0]);
                            return startHour == hour;
                          }).map((meeting) {
                            // Use meeting creator for color (user-wise color coding)
                            final userForColor = meeting.creator;
                            final color = _getEventColorForUser(meeting, userForColor, isDark);
                            final textColor = _getEventTextColorForUser(meeting, userForColor, isDark);

                            // Fixed size for all events (width and height)
                            return InkWell(
                              onTap: () => controller.openMeetingDetail(meeting),
                              child: Container(
                                width: double.infinity, // Full width of parent
                                height: 60, // Fixed height
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        meeting.title,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }

  /// Build event details listener widget
  /// Shows dialog when selectedMeeting changes
  Widget _buildEventDetailsListener() {
    return _EventDetailsListener(controller: controller);
  }

  /// Build loading state
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading events...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Events',
              style: AppTextStyles.h4.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.fetchAllEvents(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForegroundLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Events Yet',
              style: AppTextStyles.h4.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first event to get started',
              style: AppTextStyles.bodyMedium.copyWith(
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
}

/// Widget that listens to selectedMeeting changes and shows dialog
class _EventDetailsListener extends StatefulWidget {
  final CalendarController controller;

  const _EventDetailsListener({required this.controller});

  @override
  State<_EventDetailsListener> createState() => _EventDetailsListenerState();
}

class _EventDetailsListenerState extends State<_EventDetailsListener> {
  Meeting? _lastShownMeeting;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meeting = widget.controller.selectedMeeting.value;
      
      // Show dialog when a new meeting is selected
      if (meeting != null && meeting != _lastShownMeeting) {
        _lastShownMeeting = meeting;
        
        // Show dialog after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.controller.selectedMeeting.value == meeting) {
            Get.dialog(
              const EventDetailsDialog(),
              barrierDismissible: true,
            ).then((_) {
              // Clean up when dialog is closed
              if (mounted && widget.controller.selectedMeeting.value == meeting) {
                widget.controller.closeMeetingDetail();
                _lastShownMeeting = null;
              }
            });
          }
        });
      } else if (meeting == null) {
        _lastShownMeeting = null;
      }
      
      return const SizedBox.shrink();
    });
  }
}

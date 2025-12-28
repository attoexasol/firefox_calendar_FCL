import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:firefox_calendar/features/calendar/view/cell_cards_modal.dart';
import 'package:firefox_calendar/features/calendar/view/event_details_dialog.dart';
import 'package:firefox_calendar/features/calendar/view/hour_details_dialog.dart';
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
          // Main calendar content with CustomScrollView
          SafeArea(
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

              // CustomScrollView with Slivers for sticky header behavior
              return CustomScrollView(
                slivers: [
                  // Top filters that scroll away
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const TopBar(title: 'Calendar'),
                        _buildShowCalendarBy(context, isDark),
                        _buildShowScheduleFor(context, isDark),
                        _buildDateNavigation(context, isDark),
                        // Days/Dates Row is ONLY in sticky SliverPersistentHeader (no duplication)
                      ],
                    ),
                  ),

                  // Sticky Calendar Grid Header (Time + User Avatars + Day Labels)
                  if (controller.viewType.value == 'week')
                    _buildWeekGridHeaderSliver(context, isDark)
                  else if (controller.viewType.value == 'day')
                    _buildDayGridHeaderSliver(context, isDark),

                  // Scrollable Calendar Body (Time Slots + Events)
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: Obx(() {
                    if (controller.viewType.value == 'week') {
                        return _buildWeekViewContent(context, isDark);
                    } else if (controller.viewType.value == 'day') {
                        return _buildDayViewContent(context, isDark);
                    } else {
                      return _buildMonthView(context, isDark);
                    }
                  }),
                ),
              ],
              );
            }),
          ),
          // Event Details Dialog listener
          _buildEventDetailsListener(),
          // Hour Details Dialog listener
          _buildHourDetailsListener(),
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

  /// Build week grid header as SliverPersistentHeader (sticky)
  Widget _buildWeekGridHeaderSliver(BuildContext context, bool isDark) {
    return Obx(() {
      final weekDates = controller.getCurrentWeekDates();
      final usersByDate = _getUsersByDateForWeek(weekDates);
      
      // Calculate total width
      final totalWidth = 80.0 + weekDates.fold<double>(
        0.0,
        (sum, date) {
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final dayUsers = usersByDate[dateStr] ?? [];
          return sum + (dayUsers.length * 150.0);
        },
      );

      return SliverPersistentHeader(
        pinned: true,
        delegate: _WeekGridHeaderDelegate(
          weekDates: weekDates,
          usersByDate: usersByDate,
          totalWidth: totalWidth,
          isDark: isDark,
          onDateClick: (date) => controller.handleWeekDateClick(date),
          selectedWeekDate: controller.selectedWeekDate.value,
        ),
      );
    });
  }

  /// Build day grid header as SliverPersistentHeader (sticky)
  Widget _buildDayGridHeaderSliver(BuildContext context, bool isDark) {
    return Obx(() {
      final currentDate = controller.currentDate.value;
      final dateStr = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      final meetingsByDate = controller.getMeetingsByDate();
      final dayMeetings = meetingsByDate[dateStr] ?? [];
      final filteredMeetings = controller.filterMeetings(dayMeetings);
      final users = _getUsersFromMeetings(filteredMeetings);
      
      final totalWidth = users.length * 150.0 + 80;

      return SliverPersistentHeader(
        pinned: true,
        delegate: _DayGridHeaderDelegate(
          users: users,
          totalWidth: totalWidth,
          isDark: isDark,
        ),
      );
    });
  }

  /// Build week view content (scrollable time slots)
  Widget _buildWeekViewContent(BuildContext context, bool isDark) {
    return Obx(() {
      final weekDates = controller.getCurrentWeekDates();
      final meetingsByDate = controller.getMeetingsByDate();
      final usersByDate = _getUsersByDateForWeek(weekDates);
      
      // Filter meetings by selected week date if any
      Map<String, List<Meeting>> updatedMeetingsByDate = {};
      if (controller.selectedWeekDate.value != null) {
        final selectedDateStr = '${controller.selectedWeekDate.value!.year}-${controller.selectedWeekDate.value!.month.toString().padLeft(2, '0')}-${controller.selectedWeekDate.value!.day.toString().padLeft(2, '0')}';
        updatedMeetingsByDate[selectedDateStr] = meetingsByDate[selectedDateStr] ?? [];
      } else {
        updatedMeetingsByDate = Map.from(meetingsByDate);
      }
      
      final allMeetings = updatedMeetingsByDate.values.expand((list) => list).toList();
      final filteredMeetings = controller.filterMeetings(allMeetings);
      final timeRange = controller.getTimeRange(filteredMeetings);

      return SingleChildScrollView(
        child: _buildWeekTimeGridContent(
          context,
          usersByDate,
          weekDates,
          updatedMeetingsByDate,
          timeRange,
          isDark,
        ),
      );
    });
  }

  /// Build day view content (scrollable time slots)
  Widget _buildDayViewContent(BuildContext context, bool isDark) {
    return Obx(() {
      final currentDate = controller.currentDate.value;
      final dateStr = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      final meetingsByDate = controller.getMeetingsByDate();
      final dayMeetings = meetingsByDate[dateStr] ?? [];
      final filteredMeetings = controller.filterMeetings(dayMeetings);
      final timeRange = controller.getTimeRange(filteredMeetings);
      final users = _getUsersFromMeetings(filteredMeetings);

      return SingleChildScrollView(
        child: _buildDayTimeGridContent(
          context,
          users,
          dateStr,
          filteredMeetings,
          timeRange,
          isDark,
        ),
      );
    });
  }

  /// Get users by date for week view
  Map<String, List<String>> _getUsersByDateForWeek(List<DateTime> weekDates) {
    final usersByDate = <String, List<String>>{};
    final meetingsByDate = controller.getMeetingsByDate();
    
    for (var date in weekDates) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayMeetings = meetingsByDate[dateStr] ?? [];
      final filteredDayMeetings = controller.filterMeetings(dayMeetings);
      final users = _getUsersFromMeetings(filteredDayMeetings);
      usersByDate[dateStr] = users;
    }
    
    return usersByDate;
  }

  /// Build week time grid content (time slots without header)
  Widget _buildWeekTimeGridContent(
    BuildContext context,
    Map<String, List<String>> usersByDate,
    List<DateTime> weekDates,
    Map<String, List<Meeting>> meetingsByDate,
    TimeRange timeRange,
    bool isDark,
  ) {
    final numSlots = timeRange.endHour - timeRange.startHour + 1;
    final totalWidth = 80.0 + weekDates.fold<double>(
      0.0,
      (sum, date) {
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final dayUsers = usersByDate[dateStr] ?? [];
        return sum + (dayUsers.length * 150.0);
      },
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: List.generate(numSlots, (index) {
            final hour = timeRange.startHour + index;
            final timeLabel = _formatHour(hour);

            return Container(
              constraints: const BoxConstraints(minHeight: 80),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Label
                  Container(
                    width: 80,
                    constraints: const BoxConstraints(minHeight: 80),
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
                    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final dayMeetings = meetingsByDate[dateStr] ?? [];
                    final filteredDayMeetings = controller.filterMeetings(dayMeetings);
                    final dayUsers = usersByDate[dateStr] ?? [];
                    
                    if (dayUsers.isEmpty) {
                      return <Widget>[];
                    }
                    
                    return dayUsers.map((user) {
                      // Find meetings for this user on this date that overlap with this hour slot
                      final userMeetings = filteredDayMeetings.where((meeting) {
                        if (controller.scopeType.value == 'myself') {
                          if (controller.userId.value > 0 && meeting.userId != null) {
                            if (meeting.userId != controller.userId.value) {
                              return false;
                            }
                          } else {
                            final isUserMeeting = meeting.creator == user ||
                                meeting.attendees.contains(user);
                            if (!isUserMeeting) return false;
                          }
                        } else {
                          final isUserMeeting = meeting.creator == user ||
                              meeting.attendees.contains(user);
                          if (!isUserMeeting) return false;
                        }

                        final startParts = meeting.startTime.split(':');
                        final endParts = meeting.endTime.split(':');
                        final startHour = int.parse(startParts[0]);
                        final startMin = startParts.length > 1 ? int.parse(startParts[1]) : 0;
                        final endHour = int.parse(endParts[0]);
                        final endMin = endParts.length > 1 ? int.parse(endParts[1]) : 0;
                        
                        final startMinutes = startHour * 60 + startMin;
                        final endMinutes = endHour * 60 + endMin;
                        final hourStartMinutes = hour * 60;
                        final hourEndMinutes = (hour + 1) * 60;
                        
                        return startMinutes < hourEndMinutes && endMinutes > hourStartMinutes;
                      }).toList();
                      
                      // Get work hours for this user and date
                      final userWorkHours = controller.getWorkHoursForUser(user, dateStr);
                      
                      final hourWorkHours = userWorkHours.where((workHour) {
                        final loginParts = workHour.loginTime.split(':');
                        final loginHour = int.parse(loginParts[0]);
                        return loginHour == hour;
                      }).toList();
                      
                      bool hasWorkHourInThisSlot = false;
                      for (var workHour in userWorkHours) {
                        final loginParts = workHour.loginTime.split(':');
                        final logoutParts = workHour.logoutTime.split(':');
                        final loginHour = int.parse(loginParts[0]);
                        final loginMin = loginParts.length > 1 ? int.parse(loginParts[1]) : 0;
                        final logoutHour = int.parse(logoutParts[0]);
                        final logoutMin = logoutParts.length > 1 ? int.parse(logoutParts[1]) : 0;
                        
                        final loginMinutes = loginHour * 60 + loginMin;
                        final logoutMinutes = logoutHour * 60 + logoutMin;
                        final hourStartMinutes = hour * 60;
                        final hourEndMinutes = (hour + 1) * 60;
                        
                        if (loginMinutes < hourEndMinutes && logoutMinutes > hourStartMinutes) {
                          hasWorkHourInThisSlot = true;
                          break;
                        }
                      }
                      
                      final hourEvents = userMeetings.where((meeting) {
                        final startParts = meeting.startTime.split(':');
                        final startHour = int.parse(startParts[0]);
                        return startHour == hour;
                      }).toList();

                      return Container(
                        width: 150,
                        constraints: const BoxConstraints(minHeight: 80),
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
                        child: _buildCellContent(
                          context: context,
                          meetings: hourEvents,
                          workHours: hourWorkHours,
                          dateStr: dateStr,
                          userEmail: user,
                          hour: hour,
                          isDark: isDark,
                          hasWorkHourBackground: hasWorkHourInThisSlot,
                        ),
                      );
                    });
                  }),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Build day time grid content (time slots without header)
  Widget _buildDayTimeGridContent(
    BuildContext context,
    List<String> users,
    String dateStr,
    List<Meeting> meetings,
    TimeRange timeRange,
    bool isDark,
  ) {
    final numSlots = timeRange.endHour - timeRange.startHour + 1;
    final totalWidth = users.length * 150.0 + 80;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: List.generate(numSlots, (index) {
            final hour = timeRange.startHour + index;
            final timeLabel = _formatHour(hour);

            return Container(
              constraints: const BoxConstraints(minHeight: 80),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Label
                  Container(
                    width: 80,
                    constraints: const BoxConstraints(minHeight: 80),
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
                    final userMeetings = meetings.where((meeting) {
                      if (controller.scopeType.value == 'myself') {
                        if (controller.userId.value > 0 && meeting.userId != null) {
                          if (meeting.userId != controller.userId.value) {
                            return false;
                          }
                        } else {
                          final isUserMeeting = meeting.creator == user ||
                              meeting.attendees.contains(user);
                          if (!isUserMeeting) return false;
                        }
                      } else {
                        final isUserMeeting = meeting.creator == user ||
                            meeting.attendees.contains(user);
                        if (!isUserMeeting) return false;
                      }

                      final startParts = meeting.startTime.split(':');
                      final endParts = meeting.endTime.split(':');
                      final startHour = int.parse(startParts[0]);
                      final startMin = startParts.length > 1 ? int.parse(startParts[1]) : 0;
                      final endHour = int.parse(endParts[0]);
                      final endMin = endParts.length > 1 ? int.parse(endParts[1]) : 0;
                      
                      final startMinutes = startHour * 60 + startMin;
                      final endMinutes = endHour * 60 + endMin;
                      final hourStartMinutes = hour * 60;
                      final hourEndMinutes = (hour + 1) * 60;
                      
                      return startMinutes < hourEndMinutes && endMinutes > hourStartMinutes;
                    }).toList();
                    
                    final userWorkHours = controller.getWorkHoursForUser(user, dateStr);
                    final hourWorkHours = userWorkHours.where((workHour) {
                      final loginParts = workHour.loginTime.split(':');
                      final loginHour = int.parse(loginParts[0]);
                      return loginHour == hour;
                    }).toList();
                    
                    bool hasWorkHourInThisSlot = false;
                    for (var workHour in userWorkHours) {
                      final loginParts = workHour.loginTime.split(':');
                      final logoutParts = workHour.logoutTime.split(':');
                      final loginHour = int.parse(loginParts[0]);
                      final loginMin = loginParts.length > 1 ? int.parse(loginParts[1]) : 0;
                      final logoutHour = int.parse(logoutParts[0]);
                      final logoutMin = logoutParts.length > 1 ? int.parse(logoutParts[1]) : 0;
                      
                      final loginMinutes = loginHour * 60 + loginMin;
                      final logoutMinutes = logoutHour * 60 + logoutMin;
                      final hourStartMinutes = hour * 60;
                      final hourEndMinutes = (hour + 1) * 60;
                      
                      if (loginMinutes < hourEndMinutes && logoutMinutes > hourStartMinutes) {
                        hasWorkHourInThisSlot = true;
                        break;
                      }
                    }
                    
                    final hourEvents = userMeetings.where((meeting) {
                      final startParts = meeting.startTime.split(':');
                      final startHour = int.parse(startParts[0]);
                      return startHour == hour;
                    }).toList();

                    return Container(
                      width: 150,
                      constraints: const BoxConstraints(minHeight: 80),
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
                      child: _buildCellContent(
                        context: context,
                        meetings: hourEvents,
                        workHours: hourWorkHours,
                        dateStr: dateStr,
                        userEmail: user,
                        hour: hour,
                        isDark: isDark,
                        hasWorkHourBackground: hasWorkHourInThisSlot,
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

  /// Build "Show calendar by" section (Day/Week/Month tabs)
  /// Scrolls away naturally when user scrolls
  Widget _buildShowCalendarBy(BuildContext context, bool isDark) {
    return Container(
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
      padding: const EdgeInsets.all(12),
      child: Column(
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
    );
  }

  /// Build "Show schedule for" section (Everyone/Myself tabs)
  /// Scrolls away naturally when user scrolls
  Widget _buildShowScheduleFor(BuildContext context, bool isDark) {
    return Container(
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
      padding: const EdgeInsets.all(12),
      child: Column(
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
    );
  }

  /// Build date navigation section (scrolls away)
  Widget _buildDateNavigation(BuildContext context, bool isDark) {
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
      child: Row(
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
    );
  }

  /// Build days/dates row in normal position (scrolls away)
  Widget _buildDaysDatesRowNormal(BuildContext context, bool isDark) {
    final weekDates = controller.getCurrentWeekDates();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Row(
        children: weekDates.map((date) {
          return _buildDayDateItem(date, isDark);
        }).toList(),
      ),
    );
  }

  /// Build days/dates row in sticky position (fixed at top when scrolling)
  Widget _buildDaysDatesRowSticky(BuildContext context, bool isDark) {
    final weekDates = controller.getCurrentWeekDates();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: weekDates.map((date) {
          return _buildDayDateItem(date, isDark);
        }).toList(),
      ),
    );
  }

  /// Build individual day/date item
  Widget _buildDayDateItem(DateTime date, bool isDark) {
    final today = DateTime.now();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
  /// Note: Vertical scrolling is handled by parent SingleChildScrollView
  /// This method only returns the week view content
  Widget _buildWeekView(BuildContext context, bool isDark) {
    return Obx(() {
        final weekDates = controller.getCurrentWeekDates();
        final meetingsByDate = controller.getMeetingsByDate();
        
        // Create a set of week date strings for fast lookup
        final weekDateStrings = weekDates.map((date) {
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }).toSet();
        
        // For week view, use ALL meetings from controller (already filtered by scope)
        // The API returns events for the week range, so we trust those dates
        // We'll filter to only show events that fall within the displayed week dates
        final weekStart = weekDates.first;
        final weekEnd = weekDates.last;
        
        // Debug: Print week dates and available meetings
        print('═══════════════════════════════════════════════════════════');
        print('📅 [CalendarScreen] Week view analysis:');
        print('   Week dates: ${weekDateStrings.join(", ")}');
        print('   Available meeting dates: ${meetingsByDate.keys.join(", ")}');
        print('   Total meetings in controller: ${controller.meetings.length}');
        
        // Get all meetings that match the week date strings OR fall within the week range
        // This handles both exact date matches and edge cases where API returns slightly different ranges
        final weekMeetings = <Meeting>[];
        
        for (var meeting in controller.meetings) {
          // First check: exact date string match (fast path)
          if (weekDateStrings.contains(meeting.date)) {
            weekMeetings.add(meeting);
            continue;
          }
          
          // Second check: parse date and check if within week range
          try {
            final meetingDateParts = meeting.date.split('-');
            if (meetingDateParts.length == 3) {
              final meetingDate = DateTime(
                int.parse(meetingDateParts[0]),
                int.parse(meetingDateParts[1]),
                int.parse(meetingDateParts[2]),
              );
              
              // Check if meeting date is within week range (inclusive)
              // Compare dates only (ignore time)
              final meetingDateOnly = DateTime(meetingDate.year, meetingDate.month, meetingDate.day);
              final weekStartOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
              final weekEndOnly = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
              
              // Meeting is included if its date is >= weekStart and <= weekEnd
              final isInRange = !meetingDateOnly.isBefore(weekStartOnly) && !meetingDateOnly.isAfter(weekEndOnly);
              
              if (isInRange) {
                weekMeetings.add(meeting);
                // Also add this date to weekDateStrings if it's not already there
                // This ensures the date column is shown even if it's outside calculated week
                if (!weekDateStrings.contains(meeting.date)) {
                  print('   ⚠️ Event date ${meeting.date} is outside calculated week but within API range');
                }
              }
            }
          } catch (e) {
            // If parsing fails, skip this meeting
            print('   ❌ Parse error for ${meeting.title} on ${meeting.date}: $e');
          }
        }
        
        print('   Total meetings in week: ${weekMeetings.length}');
        for (var meeting in weekMeetings) {
          print('      - ${meeting.title} on ${meeting.date}');
        }
        print('═══════════════════════════════════════════════════════════');
        
        // Group meetings by date for display
        final weekMeetingsByDate = <String, List<Meeting>>{};
        for (var meeting in weekMeetings) {
          if (!weekMeetingsByDate.containsKey(meeting.date)) {
            weekMeetingsByDate[meeting.date] = [];
          }
          weekMeetingsByDate[meeting.date]!.add(meeting);
        }
        
        // Merge with existing meetingsByDate to include all week meetings
        final updatedMeetingsByDate = Map<String, List<Meeting>>.from(meetingsByDate);
        weekMeetingsByDate.forEach((date, meetings) {
          updatedMeetingsByDate[date] = meetings;
        });
        
        final filteredMeetings = controller.filterMeetings(weekMeetings);
        final timeRange = controller.getTimeRange(filteredMeetings);
        
        // Get users per date (each day can have different users)
        // This matches the image where each day shows only users with events on that day
        final Map<String, List<String>> usersByDate = {};
        for (var date in weekDates) {
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          // Use updatedMeetingsByDate which includes the week-filtered events
          final dayMeetings = updatedMeetingsByDate[dateStr] ?? [];
          final filteredDayMeetings = controller.filterMeetings(dayMeetings);
          
          // Debug: Log users for this date
          if (dayMeetings.isNotEmpty) {
            print('   👥 [Week View] Date $dateStr: ${dayMeetings.length} meetings, filtering to ${filteredDayMeetings.length}');
          }
          
          // Get unique users for this specific date
          if (controller.scopeType.value == 'myself') {
            // In "Myself" view, only show current user
            final currentUserEmail = controller.userEmail.value;
            if (currentUserEmail.isNotEmpty && filteredDayMeetings.isNotEmpty) {
              usersByDate[dateStr] = [currentUserEmail];
              print('   ✅ [Week View] Date $dateStr: Added user $currentUserEmail (myself)');
            } else {
              usersByDate[dateStr] = [];
            }
          } else {
            // In "Everyone" view, show all users who have events on this date
            final users = _getUsersFromMeetings(filteredDayMeetings);
            usersByDate[dateStr] = users;
            if (users.isNotEmpty) {
              print('   ✅ [Week View] Date $dateStr: Added ${users.length} users: ${users.join(", ")}');
            }
          }
        }
        
        // FIXED HEADERS + SCROLLABLE CONTENT LAYOUT
        // Date Header (Week Days) stays fixed when scrolling
        // Grid header (Time + User profiles) stays fixed
        // Only time slots and events scroll
        return Column(
          children: [
            // FIXED: Week Date Filter Indicator (if shown)
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

            // Days/Dates row removed from here - now in sticky SliverPersistentHeader
            // Grid header (Time + User profiles) is also in sticky SliverPersistentHeader

            // SCROLLABLE: Week Schedule with User Columns (ONLY time slots, NO headers)
            Expanded(
              child: _buildWeekTimeGridContent(
                context,
                usersByDate,
                weekDates,
                updatedMeetingsByDate, // Use updated meetings that include week-filtered events
                timeRange,
                isDark,
              ),
            ),
          ],
        );
      });
  }

  /// Build week user timeline grid (similar to day view but for multiple days)
  /// Each day shows only users who have events on that specific day
  Widget _buildWeekUserTimelineGrid(
    BuildContext context,
    Map<String, List<String>> usersByDate,
    List<DateTime> weekDates,
    Map<String, List<Meeting>> meetingsByDate,
    TimeRange timeRange,
    bool isDark,
  ) {
    final numSlots = timeRange.endHour - timeRange.startHour + 1;
    
    // Calculate total width: sum of users per day + time column
    final totalWidth = 80.0 + weekDates.fold<double>(
      0.0,
      (sum, date) {
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final dayUsers = usersByDate[dateStr] ?? [];
        return sum + (dayUsers.length * 150.0);
      },
    );
    
    // FIXED HEADER + SCROLLABLE CONTENT LAYOUT
    // Header (Time + User profiles) stays fixed, time slots scroll
    return Column(
      children: [
        // FIXED: Header Row with Time and User columns for each day
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                  // User Columns for each day (only show users with events on that day)
                  ...weekDates.expand((date) {
                    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
          ),
        ),
        // SCROLLABLE: Time Slots and Events
        // Expanded provides bounded height for vertical scrolling
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...List.generate(numSlots, (index) {
                      final hour = timeRange.startHour + index;
                      final timeLabel = _formatHour(hour);

                      return Container(
                        constraints: const BoxConstraints(minHeight: 80),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time Label
                            Container(
                              width: 80,
                              constraints: const BoxConstraints(minHeight: 80),
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
                            // User Columns for each day (only show users with events on that day)
                            ...weekDates.expand((date) {
                      // Use consistent date format (YYYY-MM-DD)
                      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      // meetingsByDate parameter contains updatedMeetingsByDate passed from parent
                      final dayMeetings = meetingsByDate[dateStr] ?? [];
                      final filteredDayMeetings = controller.filterMeetings(dayMeetings);
                      final dayUsers = usersByDate[dateStr] ?? [];
                      
                      // Debug: Log meetings for this date
                      if (dayMeetings.isNotEmpty || dayUsers.isNotEmpty) {
                        print('   📅 [Week Grid] Date $dateStr: ${dayMeetings.length} meetings, ${filteredDayMeetings.length} filtered, ${dayUsers.length} users');
                        for (var meeting in dayMeetings) {
                          print('      - ${meeting.title}: ${meeting.startTime}-${meeting.endTime} (creator: ${meeting.creator})');
                        }
                      }
                      
                      // If no users for this date, return empty list (no columns)
                      if (dayUsers.isEmpty) {
                        return <Widget>[];
                      }
                      
                      return dayUsers.map((user) {
                        // Find meetings for this user on this date that overlap with this hour slot
                        final userMeetings = filteredDayMeetings.where((meeting) {
                          // In "Myself" view, all filtered meetings are already the user's events
                          // So we just need to check if the meeting matches this user column
                          if (controller.scopeType.value == 'myself') {
                            // In "Myself" view, match by userId first (more reliable)
                            if (controller.userId.value > 0 && meeting.userId != null) {
                              if (meeting.userId != controller.userId.value) {
                                return false;
                              }
                            } else {
                              // Fallback: match by creator/attendee email
                              final isUserMeeting = meeting.creator == user ||
                                  meeting.attendees.contains(user);
                              if (!isUserMeeting) return false;
                            }
                          } else {
                            // In "Everyone" view, match by creator/attendee
                            final isUserMeeting = meeting.creator == user ||
                                meeting.attendees.contains(user);
                            if (!isUserMeeting) return false;
                          }

                        // Check if meeting overlaps with this hour slot
                        // Convert times to minutes for accurate comparison
                        final startParts = meeting.startTime.split(':');
                        final endParts = meeting.endTime.split(':');
                        final startHour = int.parse(startParts[0]);
                        final startMin = startParts.length > 1 ? int.parse(startParts[1]) : 0;
                        final endHour = int.parse(endParts[0]);
                        final endMin = endParts.length > 1 ? int.parse(endParts[1]) : 0;
                        
                        // Convert to minutes for precise comparison
                        final startMinutes = startHour * 60 + startMin;
                        final endMinutes = endHour * 60 + endMin;
                        final hourStartMinutes = hour * 60;
                        final hourEndMinutes = (hour + 1) * 60;
                        
                        // Meeting overlaps hour if: starts before hour ends AND ends after hour starts
                        final overlaps = startMinutes < hourEndMinutes && endMinutes > hourStartMinutes;
                        
                        return overlaps;
                      }).toList();
                      
                      if (userMeetings.isNotEmpty) {
                        print('   📅 User $user has ${userMeetings.length} meetings in hour $hour');
                      }

                        return Container(
                          width: 150,
                          constraints: const BoxConstraints(
                            minHeight: 80,
                          ),
                          clipBehavior: Clip.hardEdge,
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
                          child: Builder(
                            builder: (context) {
                              // WORK HOURS OVERLAY: Get approved work hours for this user and date
                              final userWorkHours = controller.getWorkHoursForUser(user, dateStr);
                              
                              // Filter work hours that start in this hour slot (for card display)
                              final hourWorkHours = userWorkHours.where((workHour) {
                                final loginParts = workHour.loginTime.split(':');
                                final loginHour = int.parse(loginParts[0]);
                                return loginHour == hour;
                              }).toList();
                              
                              // Check if any work hour spans this hour slot (for background block)
                              bool hasWorkHourInThisSlot = false;
                              for (var workHour in userWorkHours) {
                                final loginParts = workHour.loginTime.split(':');
                                final logoutParts = workHour.logoutTime.split(':');
                                final loginHour = int.parse(loginParts[0]);
                                final loginMin = loginParts.length > 1 ? int.parse(loginParts[1]) : 0;
                                final logoutHour = int.parse(logoutParts[0]);
                                final logoutMin = logoutParts.length > 1 ? int.parse(logoutParts[1]) : 0;
                                
                                final loginMinutes = loginHour * 60 + loginMin;
                                final logoutMinutes = logoutHour * 60 + logoutMin;
                                final hourStartMinutes = hour * 60;
                                final hourEndMinutes = (hour + 1) * 60;
                                
                                if (loginMinutes < hourEndMinutes && logoutMinutes > hourStartMinutes) {
                                  hasWorkHourInThisSlot = true;
                                  break;
                                }
                              }
                              
                              // Filter events for this hour
                              final hourEvents = userMeetings.where((meeting) {
                                final startParts = meeting.startTime.split(':');
                                final startHour = int.parse(startParts[0]);
                                return startHour == hour;
                              }).toList();
                              
                              // Use helper method to build cell content - allows dynamic growth
                              return _buildCellContent(
                                context: context,
                                meetings: hourEvents,
                                workHours: hourWorkHours,
                                dateStr: dateStr,
                                userEmail: user,
                                hour: hour,
                                isDark: isDark,
                                hasWorkHourBackground: hasWorkHourInThisSlot,
                              );
                            },
                          ),
                        );
                      });
                    }).toList(),
                  ],
                ),
              );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

  /// Get event color based on event type (different color per event type)
  Color _getEventColorForUser(Meeting meeting, String user, bool isDark) {
    // Use the controller's event type-based color logic
    return controller.getEventColor(meeting, isDark);
  }

  /// Get text color for event based on event type
  Color _getEventTextColorForUser(Meeting meeting, String user, bool isDark) {
    // Use the controller's event type-based text color logic
    return controller.getEventTextColor(meeting, isDark);
  }

  /// Build calendar cell content with overflow handling
  /// Combines meetings and work hours, sorts by startTime, and handles overflow
  Widget _buildCellContent({
    required BuildContext context,
    required List<Meeting> meetings,
    required List<WorkHour> workHours,
    required String dateStr,
    required String userEmail,
    required int hour,
    required bool isDark,
    required bool hasWorkHourBackground,
  }) {
    // Combine all items and sort by startTime
    final allItems = <_CellItem>[];
    
    // Add meetings
    for (var meeting in meetings) {
      allItems.add(_CellItem(
        type: _CellItemType.meeting,
        meeting: meeting,
        startTime: meeting.startTime,
      ));
    }
    
    // Add work hours
    for (var workHour in workHours) {
      allItems.add(_CellItem(
        type: _CellItemType.workHour,
        workHour: workHour,
        startTime: workHour.loginTime,
      ));
    }
    
    // Sort by startTime
    allItems.sort((a, b) {
      final aParts = a.startTime.split(':');
      final bParts = b.startTime.split(':');
      final aHour = int.parse(aParts[0]);
      final aMin = aParts.length > 1 ? int.parse(aParts[1]) : 0;
      final bHour = int.parse(bParts[0]);
      final bMin = bParts.length > 1 ? int.parse(bParts[1]) : 0;
      
      if (aHour != bHour) return aHour.compareTo(bHour);
      return aMin.compareTo(bMin);
    });

    // Show all items - cells will grow to accommodate content
    // If more than 3 items, show first 3 and "+N more" indicator
    const maxVisibleItems = 3;
    final visibleItems = allItems.take(maxVisibleItems).toList();
    final remainingCount = allItems.length - visibleItems.length;
    final hasOverflow = remainingCount > 0;

                              return Stack(
                                children: [
        // WORK HOURS BACKGROUND BLOCK (if any work hour spans this hour)
        if (hasWorkHourBackground)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                    ? const Color(0xFF166534).withValues(alpha: 0.15)
                    : const Color(0xFFD1FAE5).withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  
        // CARDS FOREGROUND (content-driven Column - allows growth)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
            // Visible items - stack vertically with spacing
            ...visibleItems.map((item) {
              if (item.type == _CellItemType.meeting) {
                return _buildMeetingCard(
                  context,
                  item.meeting!,
                  controller,
                  isDark,
                );
              } else {
                return _buildWorkHourCard(
                  context,
                  item.workHour!,
                  controller,
                  isDark,
                );
              }
            }),
            
            // Overflow indicator
            if (hasOverflow)
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => CellCardsModal(
                      meetings: meetings,
                      workHours: workHours,
                      dateStr: dateStr,
                      userEmail: userEmail,
                      hour: hour,
                      isDark: isDark,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.mutedDark.withValues(alpha: 0.5)
                        : AppColors.mutedLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '+$remainingCount more',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Build meeting card widget
  Widget _buildMeetingCard(
    BuildContext context,
    Meeting meeting,
    CalendarController controller,
    bool isDark,
  ) {
    final userForColor = meeting.creator;
    final color = meeting.category == 'work_hour'
        ? controller.getWorkHourColorForUser(userForColor, isDark)
        : _getEventColorForUser(meeting, userForColor, isDark);
    final textColor = _getEventTextColorForUser(meeting, userForColor, isDark);

    return InkWell(
      onTap: () {
        if (meeting.category == 'work_hour') {
          controller.openWorkHourDetail(meeting);
        } else {
          controller.openMeetingDetail(meeting);
        }
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 28,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                meeting.startTime,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 8,
                  color: textColor.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build work hour card widget
  Widget _buildWorkHourCard(
    BuildContext context,
    WorkHour workHour,
    CalendarController controller,
    bool isDark,
  ) {
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

                                        String formatTime(String timeStr) {
                                          final parts = timeStr.split(':');
                                          if (parts.length >= 2) {
                                            final h = int.parse(parts[0]);
                                            final m = parts[1];
                                            final period = h >= 12 ? 'PM' : 'AM';
                                            final displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
                                            return '$displayHour:$m $period';
                                          }
                                          return timeStr;
                                        }

                                        final hourCardColor = isDark
                                            ? Colors.blue.withValues(alpha: 0.3)
                                            : Colors.blue.withValues(alpha: 0.2);
                                        final hourTextColor = isDark
                                            ? Colors.blue.shade200
                                            : Colors.blue.shade900;

                                        return InkWell(
                                          onTap: () => controller.openWorkHourDetail(workHour),
                                          child: Container(
                                            width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 28,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: hourCardColor,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.blue.withValues(alpha: 0.5)
                                                    : Colors.blue.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
              mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                  size: 10,
                                                        color: hourTextColor,
                                                      ),
                const SizedBox(width: 3),
                                                      Flexible(
                                                        child: Text(
                                                          '${formatTime(workHour.loginTime)} - ${formatTime(workHour.logoutTime)}',
                                                          style: AppTextStyles.labelSmall.copyWith(
                                                            color: hourTextColor,
                                                            fontWeight: FontWeight.w600,
                      fontSize: 9,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
            Flexible(
              child: Text(
                                                    '${totalHours.toStringAsFixed(1)}h',
                                                    style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 8,
                                                      color: hourTextColor.withValues(alpha: 0.9),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
          ],
        ),
      ),
    );
  }

  /// Build day view
  /// Note: Vertical scrolling is handled by parent SingleChildScrollView
  /// This method only returns the day view content
  Widget _buildDayView(BuildContext context, bool isDark) {
    return Obx(() {
        final currentDate = controller.currentDate.value;
        // Use consistent date format (YYYY-MM-DD)
        final dateStr = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
        final meetingsByDate = controller.getMeetingsByDate();
        final dayMeetings = meetingsByDate[dateStr] ?? [];
        
        print('📅 [CalendarScreen] Day view: date=$dateStr, meetings=${dayMeetings.length}');
        for (var meeting in dayMeetings) {
          print('   - ${meeting.title}: ${meeting.date} ${meeting.startTime}');
        }
        
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
      });
  }

  /// Build month view
  /// Note: Vertical scrolling is handled by parent SingleChildScrollView
  /// This method only returns the month view content
  Widget _buildMonthView(BuildContext context, bool isDark) {
    return Padding(
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
            // Use consistent date format (YYYY-MM-DD)
            final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
              constraints: const BoxConstraints(
                minHeight: 80,
              ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Label
                  Container(
                    width: 80,
                    constraints: const BoxConstraints(
                      minHeight: 80,
                    ),
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
                    // Use consistent date format (YYYY-MM-DD)
                  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
                      constraints: const BoxConstraints(
                        minHeight: 80,
                      ),
                      clipBehavior: Clip.hardEdge,
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
                      child: Builder(
                        builder: (context) {
                          // Get work hours for this date (for day view without user columns)
                          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          final userWorkHours = controller.getWorkHoursForUser('', dateStr); // Empty user for day view
                          
                          // Filter work hours that start in this hour slot
                          final hourWorkHours = userWorkHours.where((workHour) {
                            final loginParts = workHour.loginTime.split(':');
                            final loginHour = int.parse(loginParts[0]);
                            return loginHour == hour;
                          }).toList();
                          
                          // Check if any work hour spans this hour slot
                          bool hasWorkHourInThisSlot = false;
                          for (var workHour in userWorkHours) {
                            final loginParts = workHour.loginTime.split(':');
                            final logoutParts = workHour.logoutTime.split(':');
                            final loginHour = int.parse(loginParts[0]);
                            final loginMin = loginParts.length > 1 ? int.parse(loginParts[1]) : 0;
                            final logoutHour = int.parse(logoutParts[0]);
                            final logoutMin = logoutParts.length > 1 ? int.parse(logoutParts[1]) : 0;
                            
                            final loginMinutes = loginHour * 60 + loginMin;
                            final logoutMinutes = logoutHour * 60 + logoutMin;
                            final hourStartMinutes = hour * 60;
                            final hourEndMinutes = (hour + 1) * 60;
                            
                            if (loginMinutes < hourEndMinutes && logoutMinutes > hourStartMinutes) {
                              hasWorkHourInThisSlot = true;
                              break;
                            }
                          }
                          
                          // Use helper method to build cell content with overflow handling
                          // Wrap in ClipRect to prevent overflow from being visible
                          return ClipRect(
                            child: _buildCellContent(
                              context: context,
                              meetings: slotMeetings,
                              workHours: hourWorkHours,
                              dateStr: dateStr,
                              userEmail: '',
                              hour: hour,
                              isDark: isDark,
                              hasWorkHourBackground: hasWorkHourInThisSlot,
                            ),
                          );
                        },
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
  /// Format hour in 24-hour format with AM/PM indicators (HH:00 AM/PM)
  String _formatHour(int hour) {
    // Format as 24-hour with AM/PM: 00:00 AM to 23:00 PM
    final hourStr = hour.toString().padLeft(2, '0');
    
    // Determine AM/PM based on hour
    if (hour == 0) {
      return '00:00 AM'; // Midnight
    } else if (hour < 12) {
      return '$hourStr:00 AM'; // 01:00 AM to 11:00 AM
    } else if (hour == 12) {
      return '12:00 PM'; // Noon
    } else {
      return '$hourStr:00 PM'; // 13:00 PM to 23:00 PM
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
    
    // Debug logging
    print('═══════════════════════════════════════════════════════════');
    print('🎨 [CalendarScreen] Building user timeline grid:');
    print('   Date: $dateStr');
    print('   Users: ${users.length} (${users.join(", ")})');
    print('   Meetings: ${meetings.length}');
    for (var meeting in meetings) {
      print('      - ${meeting.title}: date=${meeting.date} time=${meeting.startTime}-${meeting.endTime} creator=${meeting.creator}');
    }
    print('   Time range: ${timeRange.startHour}:00 - ${timeRange.endHour}:00');
    print('═══════════════════════════════════════════════════════════');
    
    // If no users, show empty state
    if (users.isEmpty) {
      print('   ⚠️ No users found - showing empty state');
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
    
    if (meetings.isEmpty && users.isNotEmpty) {
      print('   ⚠️ No meetings found for ${users.length} users - showing empty grid');
    }

    // FIXED HEADER + SCROLLABLE CONTENT LAYOUT
    // Header (Time + User profiles) stays fixed, time slots scroll
    return Column(
      children: [
        // FIXED: User Header Row (Time + User profiles)
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
            child: SizedBox(
              width: users.length * 150.0 + 80,
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
          ),
        ),
        // SCROLLABLE: Time Slots and Events
        // Expanded provides bounded height for vertical scrolling
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: users.length * 150.0 + 80,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...List.generate(numSlots, (index) {
                      final hour = timeRange.startHour + index;
                      final timeLabel = _formatHour(hour);

                      return Container(
                        constraints: const BoxConstraints(
                          minHeight: 80,
                        ),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time Label
                            Container(
                              width: 80,
                              constraints: const BoxConstraints(
                                minHeight: 80,
                              ),
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
                        if (!isUserMeeting) {
                          return false; // Silent exclusion for user mismatch (too verbose)
                        }

                        // Check if meeting is on this date (exact match required)
                        if (meeting.date != dateStr) {
                          return false; // Silent exclusion for date mismatch (too verbose)
                        }

                        // Check if meeting overlaps with this hour slot
                        // Convert times to minutes for accurate comparison
                        final startParts = meeting.startTime.split(':');
                        final endParts = meeting.endTime.split(':');
                        final startHour = int.parse(startParts[0]);
                        final startMin = startParts.length > 1 ? int.parse(startParts[1]) : 0;
                        final endHour = int.parse(endParts[0]);
                        final endMin = endParts.length > 1 ? int.parse(endParts[1]) : 0;
                        
                        // Convert to minutes for precise comparison
                        final startMinutes = startHour * 60 + startMin;
                        final endMinutes = endHour * 60 + endMin;
                        final hourStartMinutes = hour * 60;
                        final hourEndMinutes = (hour + 1) * 60;
                        
                        // Meeting overlaps hour if: starts before hour ends AND ends after hour starts
                        // Example: 09:10-10:10 overlaps hour 9 (540-600) because 550 < 600 && 610 > 540
                        final overlaps = startMinutes < hourEndMinutes && endMinutes > hourStartMinutes;
                        
                        return overlaps;
                      }).toList();
                      
                      if (userMeetings.isNotEmpty) {
                        print('   📅 User $user has ${userMeetings.length} meetings in hour $hour');
                      }

                      return Container(
                        width: 150,
                        constraints: const BoxConstraints(
                          minHeight: 80,
                        ),
                        clipBehavior: Clip.hardEdge,
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
                        child: Builder(
                          builder: (context) {
                            // WORK HOURS OVERLAY: Get approved work hours for this user and date
                            final userWorkHours = controller.getWorkHoursForUser(user, dateStr);
                            
                            // Filter work hours that start in this hour slot (for card display)
                            final hourWorkHours = userWorkHours.where((workHour) {
                              final loginParts = workHour.loginTime.split(':');
                              final loginHour = int.parse(loginParts[0]);
                              return loginHour == hour;
                            }).toList();
                            
                            // Calculate work hour blocks that span this hour slot (for background)
                            final workHourBlocks = <Map<String, dynamic>>[];
                            bool hasWorkHourInThisSlot = false;
                            for (var workHour in userWorkHours) {
                              final loginParts = workHour.loginTime.split(':');
                              final logoutParts = workHour.logoutTime.split(':');
                              final loginHour = int.parse(loginParts[0]);
                              final loginMin = loginParts.length > 1 ? int.parse(loginParts[1]) : 0;
                              final logoutHour = int.parse(logoutParts[0]);
                              final logoutMin = logoutParts.length > 1 ? int.parse(logoutParts[1]) : 0;
                              
                              final loginMinutes = loginHour * 60 + loginMin;
                              final logoutMinutes = logoutHour * 60 + logoutMin;
                              final hourStartMinutes = hour * 60;
                              final hourEndMinutes = (hour + 1) * 60;
                              
                              if (loginMinutes < hourEndMinutes && logoutMinutes > hourStartMinutes) {
                                hasWorkHourInThisSlot = true;
                                
                                final blockStartMinutes = loginMinutes > hourStartMinutes ? loginMinutes : hourStartMinutes;
                                final blockEndMinutes = logoutMinutes < hourEndMinutes ? logoutMinutes : hourEndMinutes;
                                
                                final hourDuration = 60.0;
                                final topOffset = ((blockStartMinutes - hourStartMinutes) / hourDuration) * 80.0;
                                final blockHeight = ((blockEndMinutes - blockStartMinutes) / hourDuration) * 80.0;
                                
                                workHourBlocks.add({
                                  'top': topOffset,
                                  'height': blockHeight,
                                  'workHour': workHour,
                                });
                              }
                            }
                            
                            // Filter events for this hour
                            final hourEvents = userMeetings.where((meeting) {
                              final startParts = meeting.startTime.split(':');
                              final startHour = int.parse(startParts[0]);
                              return startHour == hour;
                            }).toList();
                            
                            // Use Stack for background work hour blocks + content-driven cards
                            return Stack(
                              children: [
                                // WORK HOURS BACKGROUND BLOCKS (spanning blocks)
                                ...workHourBlocks.map((block) {
                                  final workHour = block['workHour'] as WorkHour;
                                  final top = block['top'] as double;
                                  final height = block['height'] as double;
                                  final workHourColor = controller.getWorkHourColorForUser(workHour.userEmail, isDark);
                                  
                                  return Positioned(
                                    top: top,
                                    left: 0,
                                    right: 0,
                                    height: height,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: workHourColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }),
                                
                                // CARDS FOREGROUND (content-driven with overflow protection)
                                ClipRect(
                                  child: _buildCellContent(
                                    context: context,
                                    meetings: hourEvents,
                                    workHours: hourWorkHours,
                                    dateStr: dateStr,
                                    userEmail: user,
                                    hour: hour,
                                    isDark: isDark,
                                    hasWorkHourBackground: hasWorkHourInThisSlot,
                                                      ),
                                                    ),
                                                  ],
                            );
                          },
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
            ),
          ),
        ),
      ],
    );
  }

  /// Build event details listener widget
  /// Shows dialog when selectedMeeting changes
  Widget _buildEventDetailsListener() {
    return _EventDetailsListener(controller: controller);
  }

  /// Hour Details Dialog listener widget
  Widget _buildHourDetailsListener() {
    return _HourDetailsListener(controller: controller);
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

/// Helper class to combine meetings and work hours for sorting
class _CellItem {
  final _CellItemType type;
  final Meeting? meeting;
  final WorkHour? workHour;
  final String startTime;

  _CellItem({
    required this.type,
    this.meeting,
    this.workHour,
    required this.startTime,
  });
}

enum _CellItemType {
  meeting,
  workHour,
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

/// Hour Details Listener
/// Watches for selectedWorkHour changes and shows HourDetailsDialog
/// Uses same pattern as EventDetailsListener
class _HourDetailsListener extends StatefulWidget {
  final CalendarController controller;

  const _HourDetailsListener({required this.controller});

  @override
  State<_HourDetailsListener> createState() => _HourDetailsListenerState();
}

class _HourDetailsListenerState extends State<_HourDetailsListener> {
  WorkHour? _lastShownWorkHour;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final workHour = widget.controller.selectedWorkHour.value;
      
      // Show dialog when a new work hour is selected
      if (workHour != null && workHour != _lastShownWorkHour) {
        _lastShownWorkHour = workHour;
        
        // Show dialog after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.controller.selectedWorkHour.value == workHour) {
            Get.dialog(
              const HourDetailsDialog(),
              barrierDismissible: true,
            ).then((_) {
              // Clean up when dialog is closed
              if (mounted && widget.controller.selectedWorkHour.value == workHour) {
                widget.controller.closeWorkHourDetail();
                _lastShownWorkHour = null;
              }
            });
          }
        });
      } else if (workHour == null) {
        _lastShownWorkHour = null;
      }
      
      return const SizedBox.shrink();
    });
  }
}

/// SliverPersistentHeaderDelegate for Week Grid Header
/// Sticky header with days/dates row + time column + user avatars
class _WeekGridHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<DateTime> weekDates;
  final Map<String, List<String>> usersByDate;
  final double totalWidth;
  final bool isDark;
  final Function(DateTime) onDateClick;
  final DateTime? selectedWeekDate;

  _WeekGridHeaderDelegate({
    required this.weekDates,
    required this.usersByDate,
    required this.totalWidth,
    required this.isDark,
    required this.onDateClick,
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
          // Days/Dates Row
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
            child: Row(
              children: weekDates.map((date) {
                return _buildDayDateItem(date, isDark);
              }).toList(),
            ),
          ),
          // User Header Row (Time + User Avatars)
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
                      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_WeekGridHeaderDelegate oldDelegate) {
    return weekDates != oldDelegate.weekDates ||
        usersByDate != oldDelegate.usersByDate ||
        isDark != oldDelegate.isDark ||
        selectedWeekDate != oldDelegate.selectedWeekDate;
  }

  // Helper methods
  Color _getUserColor(String userEmail) {
    final hash = userEmail.hashCode;
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFFF97316),
      const Color(0xFF14B8A6),
      const Color(0xFF6366F1),
      const Color(0xFF84CC16),
      const Color(0xFFEAB308),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getUserInitials(String userEmail) {
    final parts = userEmail.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userEmail.substring(0, 2).toUpperCase();
  }

  String _getDisplayName(String userEmail) {
    final parts = userEmail.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return userEmail.split('@')[0];
  }

  Widget _buildDayDateItem(DateTime date, bool isDark) {
    final today = DateTime.now();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isFiltered =
        selectedWeekDate != null &&
        selectedWeekDate!.toIso8601String().split('T')[0] == dateStr;

    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

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
                weekdays[date.weekday - 1],
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
class _DayGridHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> users;
  final double totalWidth;
  final bool isDark;

  _DayGridHeaderDelegate({
    required this.users,
    required this.totalWidth,
    required this.isDark,
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
      ),
    );
  }

  @override
  bool shouldRebuild(_DayGridHeaderDelegate oldDelegate) {
    return users != oldDelegate.users ||
        isDark != oldDelegate.isDark;
  }

  // Helper methods
  Color _getUserColor(String userEmail) {
    final hash = userEmail.hashCode;
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFFF97316),
      const Color(0xFF14B8A6),
      const Color(0xFF6366F1),
      const Color(0xFF84CC16),
      const Color(0xFFEAB308),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getUserInitials(String userEmail) {
    final parts = userEmail.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userEmail.substring(0, 2).toUpperCase();
  }

  String _getDisplayName(String userEmail) {
    final parts = userEmail.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return userEmail.split('@')[0];
  }
}

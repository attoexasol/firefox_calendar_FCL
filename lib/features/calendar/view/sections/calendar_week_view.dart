import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_cell_content.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_helpers_extended.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Week view section for calendar
class CalendarWeekView extends GetView<CalendarController> {
  final bool isDark;
  const CalendarWeekView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final weekDates = controller.getCurrentWeekDates();
      final meetingsByDate = controller.getMeetingsByDate();
      
      // Create a set of week date strings for fast lookup
      final weekDateStrings = weekDates.map((date) {
        return CalendarUtils.formatDateToIso(date);
      }).toSet();
      
      // For week view, use ALL meetings from controller (already filtered by scope)
      // The API returns events for the week range, so we trust those dates
      // We'll filter to only show events that fall within the displayed week dates
      final weekStart = weekDates.first;
      final weekEnd = weekDates.last;
      
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
            }
          }
        } catch (e) {
          // If parsing fails, skip this meeting
        }
      }
      
      // Group meetings by date for display
      // Use all meetings from controller (includes work hours) grouped by date
      final updatedMeetingsByDate = <String, List<Meeting>>{};
      for (var date in weekDates) {
        final dateStr = CalendarUtils.formatDateToIso(date);
        // Get all meetings for this date from controller (includes work hours)
        final allDayMeetings = controller.meetings.where((m) => m.date == dateStr).toList();
        updatedMeetingsByDate[dateStr] = allDayMeetings;
      }
      
      final filteredMeetings = controller.filterMeetings(weekMeetings);
      final timeRange = controller.getTimeRange(filteredMeetings);
      
      // Get users per date (each day can have different users)
      // If selectedWeekDate is set, only show users for that selected date
      // Include users from both meetings AND work hours
      final Map<String, List<String>> usersByDate = {};
      
      // If a week date is selected, only process that date
      final datesToProcess = controller.selectedWeekDate.value != null
          ? [controller.selectedWeekDate.value!]
          : weekDates;
      
      for (var date in datesToProcess) {
        final dateStr = CalendarUtils.formatDateToIso(date);
        // Get all meetings for this date from controller (includes work hours)
        final allDayMeetings = controller.meetings.where((m) => m.date == dateStr).toList();
        final filteredDayMeetings = controller.filterMeetings(allDayMeetings);
        
        // Get unique users for this specific date
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
      
      // If selectedWeekDate is set, only show users for that date (set others to empty)
      if (controller.selectedWeekDate.value != null) {
        final selectedDateStr = CalendarUtils.formatDateToIso(controller.selectedWeekDate.value!);
        for (var date in weekDates) {
          final dateStr = CalendarUtils.formatDateToIso(date);
          if (dateStr != selectedDateStr) {
            usersByDate[dateStr] = [];
          }
        }
      }
      
      // SCROLLABLE: Week Schedule with User Columns (ONLY time slots, NO headers)
      // The parent SliverFillRemaining handles the scrolling, so we just return the scrollable content
      return _buildWeekTimeGridContent(
        context,
        usersByDate,
        weekDates,
        updatedMeetingsByDate,
        timeRange,
        isDark,
      );
    });
  }

  /// Build week time grid content (time slots without header)
  /// Structure: Fixed Time column + Paginated user columns (NO horizontal scroll)
  Widget _buildWeekTimeGridContent(
    BuildContext context,
    Map<String, List<String>> usersByDate,
    List<DateTime> weekDates,
    Map<String, List<Meeting>> meetingsByDate,
    TimeRange timeRange,
    bool isDark,
  ) {
    final numSlots = timeRange.endHour - timeRange.startHour + 1;

    return Obx(() {
      // Get paginated users by date
      final paginatedUsersByDate = controller.getPaginatedUsersByDate(usersByDate);

      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(numSlots, (index) {
            final hour = timeRange.startHour + index;
            final timeLabel = CalendarUtils.formatHour(hour);

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
                  // Fixed Time Label
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
                  // Paginated User Columns (NO horizontal scroll, fixed width)
                  // Structure: Fixed Prev button space + User columns + Fixed Next button space
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prev Button Space - ALWAYS RESERVED (50px) to match header
                        Container(
                          width: 50,
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
                        ),
                        // User Columns - Instant replacement, no animation
                        Expanded(
                          child: Obx(() {
                            // Direct instant replacement - no animation
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User Columns for each day (paginated)
                                ...weekDates.expand((date) {
                          final dateStr = CalendarUtils.formatDateToIso(date);
                          // Get all meetings for this date (includes work hours)
                          final allDayMeetings = controller.meetings.where((m) => m.date == dateStr).toList();
                          final filteredDayMeetings = controller.filterMeetings(allDayMeetings);
                          final dayUsers = paginatedUsersByDate[dateStr] ?? [];
                          
                          if (dayUsers.isEmpty) {
                            return <Widget>[];
                          }
                          
                          return dayUsers.map((user) {
                              // Find meetings for this user on this date that overlap with this hour slot
                              return Flexible(
                                child: Builder(
                                  builder: (context) {
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
                                      constraints: const BoxConstraints(minHeight: 80, minWidth: 120, maxWidth: 150),
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
                                      child: CalendarCellContent(
                                        meetings: hourEvents,
                                        workHours: hourWorkHours,
                                        dateStr: dateStr,
                                        userEmail: user,
                                        hour: hour,
                                        isDark: isDark,
                                        hasWorkHourBackground: hasWorkHourInThisSlot,
                                        controller: controller,
                                      ),
                                    );
                                  },
                                ),
                              );
                            });
                          }),
                              ],
                            );
                          }),
                        ),
                        // Next Button Space - ALWAYS RESERVED (50px) to match header
                        Container(
                          width: 50,
                          constraints: const BoxConstraints(minHeight: 80),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight,
                            border: Border(
                              left: BorderSide(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    });
  }
}

/// Week grid header sliver widget
class WeekGridHeaderSliver extends GetView<CalendarController> {
  final bool isDark;
  const WeekGridHeaderSliver({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final weekDates = controller.getCurrentWeekDates();
      final usersByDate = CalendarHelpers.getUsersByDateForWeek(weekDates, controller);

      return SliverPersistentHeader(
        pinned: true,
        delegate: WeekGridHeaderDelegate(
          weekDates: weekDates,
          usersByDate: usersByDate,
          isDark: isDark,
          onDateClick: (date) => controller.handleWeekDateClick(date),
          selectedWeekDate: controller.selectedWeekDate.value,
          controller: controller,
        ),
      );
    });
  }
}

/// Week view content wrapper
class WeekViewContent extends GetView<CalendarController> {
  final bool isDark;
  const WeekViewContent({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: CalendarWeekView(isDark: isDark),
    );
  }
}


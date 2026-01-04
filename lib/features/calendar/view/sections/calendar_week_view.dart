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
      // Extract Rx values once at the start of Obx
      final weekDates = controller.getCurrentWeekDates();
      final selectedWeekDate = controller.selectedWeekDate.value;
      final scopeType = controller.scopeType.value;
      final userEmail = controller.userEmail.value;
      final userId = controller.userId.value;
      final meetings = controller.meetings;
      final viewType = controller.viewType.value; // Extract viewType for filterMeetings
      
      // Create a set of week date strings for fast lookup
      final weekDateStrings = weekDates.map((date) {
        return CalendarUtils.formatDateToIso(date);
      }).toSet();
      
      // For week view, use ALL meetings from controller (already filtered by scope)
      // The API returns events for the week range, so we trust those dates
      // We'll filter to only show events that fall within the displayed week dates
      final weekStart = weekDates.first;
      final weekEnd = weekDates.last;
      
      // CRITICAL: Filter meetings to ONLY include those within the week range
      // This prevents date leakage from adjacent weeks/months
      final weekMeetings = <Meeting>[];
      final weekStartOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEndOnly = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
      
      print('🔍 [CalendarWeekView] Filtering meetings for week range: ${CalendarUtils.formatDateToIso(weekStart)} to ${CalendarUtils.formatDateToIso(weekEnd)}');
      print('   Week date strings: $weekDateStrings');
      
      for (var meeting in meetings) {
        // Skip if date is empty or invalid
        if (meeting.date.isEmpty) continue;
        
        // Fast path: exact date string match (only for dates in week)
        if (weekDateStrings.contains(meeting.date)) {
          weekMeetings.add(meeting);
          continue;
        }
        
        // Fallback: parse date and check if within week range
        try {
          final meetingDateParts = meeting.date.split('-');
          if (meetingDateParts.length != 3) continue;
          
          final meetingYear = int.tryParse(meetingDateParts[0]);
          final meetingMonth = int.tryParse(meetingDateParts[1]);
          final meetingDay = int.tryParse(meetingDateParts[2]);
          
          if (meetingYear == null || meetingMonth == null || meetingDay == null) continue;
          
          final meetingDateOnly = DateTime(meetingYear, meetingMonth, meetingDay);
          
          // Check if meeting date is within week range (inclusive boundaries)
          final isInRange = (meetingDateOnly.isAtSameMomentAs(weekStartOnly) ||
                            meetingDateOnly.isAtSameMomentAs(weekEndOnly) ||
                            (meetingDateOnly.isAfter(weekStartOnly) && meetingDateOnly.isBefore(weekEndOnly)));
          
          if (isInRange) {
            weekMeetings.add(meeting);
          } else {
            print('   ⚠️ Excluded: ${meeting.title} on ${meeting.date} (outside week range)');
          }
        } catch (e) {
          // If parsing fails, skip this meeting
          print('   ❌ Error parsing meeting date: ${meeting.date} - $e');
        }
      }
      
      print('✅ [CalendarWeekView] Filtered ${weekMeetings.length} meetings from ${meetings.length} total');
      
      // Group filtered week meetings by date for display
      // CRITICAL: Use weekMeetings (week-filtered) instead of all controller.meetings
      // This ensures only meetings within the week range are displayed
      final updatedMeetingsByDate = <String, List<Meeting>>{};
      for (var date in weekDates) {
        final dateStr = CalendarUtils.formatDateToIso(date);
        // Only include meetings that are in our filtered weekMeetings list
        updatedMeetingsByDate[dateStr] = weekMeetings.where((m) => m.date == dateStr).toList();
      }
      
      final filteredMeetings = controller.filterMeetings(
        weekMeetings,
        scopeTypeParam: scopeType,
        viewTypeParam: viewType,
        selectedWeekDateParam: selectedWeekDate,
        userIdParam: userId,
        userEmailParam: userEmail,
      );
      final timeRange = controller.getTimeRange(filteredMeetings);
      
      // Get users per date (each day can have different users)
      // If selectedWeekDate is set, only show users for that selected date
      // Include users from both meetings AND work hours
      final Map<String, List<String>> usersByDate = {};
      
      // If a week date is selected, only process that date
      final datesToProcess = selectedWeekDate != null
          ? [selectedWeekDate]
          : weekDates;
      
      for (var date in datesToProcess) {
        final dateStr = CalendarUtils.formatDateToIso(date);
        // Use filtered weekMeetings instead of all controller.meetings
        // This ensures we only show users for events within the week range
        final allDayMeetings = weekMeetings.where((m) => m.date == dateStr).toList();
        final filteredDayMeetings = controller.filterMeetings(
          allDayMeetings,
          scopeTypeParam: scopeType,
          viewTypeParam: viewType,
          selectedWeekDateParam: selectedWeekDate,
          userIdParam: userId,
          userEmailParam: userEmail,
        );
        
        // Get unique users for this specific date
        if (scopeType == 'myself') {
          // In "Myself" view, ALWAYS show current user column, even if they have no events
          // This ensures the weekly grid structure is identical to "Everyone" view
          if (userEmail.isNotEmpty) {
            // Always include current user - event data will populate if available
            usersByDate[dateStr] = [userEmail];
          } else {
            usersByDate[dateStr] = [];
          }
        } else {
          // In "Everyone" view, show all users who have events OR work hours on this date
          // filteredDayMeetings already includes work hours filtered by scope and date
          final users = CalendarUtils.getUsersFromMeetings(filteredDayMeetings);
          // Also add users from work hours (work hours are already in filteredDayMeetings)
          final allUsers = <String>{...users};
          for (var meeting in filteredDayMeetings) {
            // Include work hour creators (already filtered by scope and date)
            if (meeting.category == 'work_hour' && meeting.creator.isNotEmpty) {
              allUsers.add(meeting.creator);
            } else if (meeting.creator.isNotEmpty) {
              // Also include regular event creators
              allUsers.add(meeting.creator);
            }
          }
          // Only show users who have data (events or work hours) on this date
          usersByDate[dateStr] = allUsers.toList()..sort();
        }
      }
      
      // If selectedWeekDate is set, only show users for that date (set others to empty)
      if (selectedWeekDate != null) {
        final selectedDateStr = CalendarUtils.formatDateToIso(selectedWeekDate);
        for (var date in weekDates) {
          final dateStr = CalendarUtils.formatDateToIso(date);
          if (dateStr != selectedDateStr) {
            usersByDate[dateStr] = [];
          }
        }
      }
      
      // NOTE: Removed early empty state check for "Myself + Week"
      // The weekly grid should always be built with user columns, even when empty
      // Empty state messages will be shown inside the grid area, not as a replacement
      
      // SCROLLABLE: Week Schedule with User Columns (ONLY time slots, NO headers)
      // The parent SliverFillRemaining handles the scrolling, so we just return the scrollable content
      return _buildWeekTimeGridContent(
        context,
        usersByDate,
        weekDates,
        updatedMeetingsByDate,
        timeRange,
        isDark,
        scopeType,
        userId,
        viewType, // Pass viewType
        selectedWeekDate, // Pass selectedWeekDate
        userEmail, // Pass userEmail
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
    String scopeType,
    int userId,
    String viewType, // Add viewType parameter
    DateTime? selectedWeekDate, // Add selectedWeekDate parameter
    String userEmail, // Add userEmail parameter
  ) {
    final numSlots = timeRange.endHour - timeRange.startHour + 1;

    // Single Obx at this level - extract paginated users here
    return Obx(() {
      // Extract page value in Obx before calling method
      final currentPage = controller.currentUserPage.value;
      // Get paginated users by date with explicit page (no Rx access in method)
      final paginatedUsersByDate = controller.getPaginatedUsersByDateWithPage(usersByDate, currentPage);
      
      // Calculate if pagination should be shown (for alignment with header)
      // Get all unique users across all dates for pagination check
      final allUniqueUsers = <String>{};
      for (var users in usersByDate.values) {
        allUniqueUsers.addAll(users);
      }
      final sortedUsers = allUniqueUsers.toList()..sort();
      
      // Check if there are any users at all (empty state check)
      final hasAnyUsers = sortedUsers.isNotEmpty;
      
      // If no users, show empty state with proper height for SliverFillRemaining
      if (!hasAnyUsers) {
        return SizedBox.expand(
          child: Container(
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
          ),
        );
      }
      
      // Determine if pagination buttons should be shown
      // Hide in "Myself" view (only 1 user) or when users fit on one page
      final shouldShowPagination = scopeType == 'everyone' && 
                                  sortedUsers.length > CalendarController.usersPerPage;

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
                  // (Empty spaces to match header alignment, arrows only in header)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prev Button Space - Conditionally shown to match header
                        shouldShowPagination
                            ? Container(
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
                              )
                            : const SizedBox.shrink(),
                        // User Columns - Use paginatedUsersByDate from parent Obx (no nested Obx)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Columns for each day (paginated)
                              ...weekDates.expand((date) {
                                final dateStr = CalendarUtils.formatDateToIso(date);
                                // Use meetingsByDate which contains only filtered week meetings
                                final allDayMeetings = meetingsByDate[dateStr] ?? [];
                                final filteredDayMeetings = controller.filterMeetings(
                                  allDayMeetings,
                                  scopeTypeParam: scopeType,
                                  viewTypeParam: viewType,
                                  selectedWeekDateParam: selectedWeekDate,
                                  userIdParam: userId,
                                  userEmailParam: userEmail,
                                );
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
                                          if (scopeType == 'myself') {
                                            if (userId > 0 && meeting.userId != null) {
                                              if (meeting.userId != userId) {
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
                                        final userWorkHours = controller.getWorkHoursForUser(user, dateStr, filteredDayMeetings, userId);
                                        
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
                          ),
                        ),
                        // Next Button Space - Conditionally shown to match header
                        shouldShowPagination
                            ? Container(
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
                              )
                            : const SizedBox.shrink(),
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
      // Access Rx values within Obx and pass as parameters
      final selectedWeekDate = controller.selectedWeekDate.value;
      final scopeType = controller.scopeType.value;
      final userEmail = controller.userEmail.value;
      final userId = controller.userId.value;
      final meetings = controller.meetings; // Extract meetings from Obx context
      final viewType = controller.viewType.value; // Extract viewType from Obx context
      
      final usersByDate = CalendarHelpers.getUsersByDateForWeek(
        weekDates,
        controller,
        selectedWeekDate,
        scopeType,
        userEmail,
        userId,
        meetings, // Pass meetings list from Obx context
        viewType, // Pass viewType from Obx context
      );

      return SliverPersistentHeader(
        pinned: true,
        delegate: WeekGridHeaderDelegate(
          weekDates: weekDates,
          usersByDate: usersByDate,
          isDark: isDark,
          onDateClick: (date) => controller.handleWeekDateClick(date),
          selectedWeekDate: selectedWeekDate,
          controller: controller,
          currentUserPage: controller.currentUserPage.value, // Capture Rx value in Obx
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


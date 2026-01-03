import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_cell_content.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_helpers_extended.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Day view section for calendar
class CalendarDayView extends GetView<CalendarController> {
  final bool isDark;
  const CalendarDayView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentDate = controller.currentDate.value;
      final dateStr = CalendarUtils.formatDateToIso(currentDate);
      final currentMeetings = controller.meetings;
      final meetingsByDate = controller.getMeetingsByDate(currentMeetings);
      final dayMeetings = meetingsByDate[dateStr] ?? [];
      final currentScopeType = controller.scopeType.value;
      final currentViewType = controller.viewType.value;
      final currentSelectedWeekDate = controller.selectedWeekDate.value;
      final currentUserId = controller.userId.value;
      final currentUserEmail = controller.userEmail.value;
      final filteredMeetings = controller.filterMeetings(
        dayMeetings,
        scopeTypeParam: currentScopeType,
        viewTypeParam: currentViewType,
        selectedWeekDateParam: currentSelectedWeekDate,
        userIdParam: currentUserId,
        userEmailParam: currentUserEmail,
      );
      final timeRange = controller.getTimeRange(filteredMeetings);
      
      // Get users from meetings (already filtered by scope and date)
      // This includes both regular events and work hours that match the filter
      final usersFromMeetings = CalendarUtils.getUsersFromMeetings(filteredMeetings);
      
      // Also include users from work hours in filteredMeetings
      // Work hours are already included in filteredMeetings if they match date and scope
      final allUsers = <String>{...usersFromMeetings};
      for (var meeting in filteredMeetings) {
        // Include work hour creators (work hours are already filtered by scope and date)
        if (meeting.category == 'work_hour' && meeting.creator.isNotEmpty) {
          allUsers.add(meeting.creator);
        }
      }
      
      // Final list: only users who have events OR work hours on this date (respecting scope)
      final users = allUsers.toList()..sort();
      
      // Extract page value in Obx before calling method
      final currentPage = controller.currentUserPage.value;
      // Get paginated users with explicit page (no Rx access in method)
      final paginatedUsers = controller.getPaginatedUsersWithPage(users, currentPage);
      
      // Pass ALL users list to body for pagination logic, and paginated users for display
      // This ensures header and body stay in sync
      return _buildUserTimelineGrid(
        context,
        users, // Pass all users for pagination calculations
        paginatedUsers, // Pass paginated users for display
        dateStr,
        filteredMeetings,
        timeRange,
        isDark,
        currentUserId,
        currentScopeType,
      );
    });
  }

  /// Build user timeline grid (for day view with user columns)
  /// [allUsers] - Complete list of all users (for pagination calculations)
  /// [paginatedUsers] - Current page of users to display (already paginated)
  Widget _buildUserTimelineGrid(
    BuildContext context,
    List<String> allUsers,
    List<String> paginatedUsers,
    String dateStr,
    List<Meeting> meetings,
    TimeRange timeRange,
    bool isDark,
    int userId,
    String scopeType,
  ) {
    // CRITICAL: Always render 24 fixed time slots (0-23) regardless of events or users
    // This ensures the time grid is always visible, even when empty
    const int totalHours = 24;
    const int startHour = 0;
    const int endHour = 23;

    // SCROLLABLE CONTENT LAYOUT
    // Structure: Fixed Time column + Paginated user columns (NO horizontal scroll)
    // Always render all 24 hours, even when there are no users or events
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(totalHours, (index) {
            final hour = startHour + index;
            final timeLabel = CalendarUtils.formatHour(hour);

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
                  // Fixed Time Label
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
                  // Paginated User Columns (NO horizontal scroll, fixed width)
                  // Structure: Fixed Prev button space + User columns + Fixed Next button space
                  // (Empty spaces to match header alignment, arrows only in header)
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
                        // Use paginatedUsers passed from parent (already paginated)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // If no users, show empty message in event area
                              // Otherwise, show user columns
                              if (paginatedUsers.isEmpty)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'No events scheduled for this day',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppColors.mutedForegroundDark
                                            : AppColors.mutedForegroundLight,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              else
                                // User Columns - using paginated users (already paginated in parent)
                                ...paginatedUsers.map((user) {
                                  // Find meetings for this user that overlap with this hour slot
                                  return Flexible(
                                    child: Builder(
                                      builder: (context) {
                                        final userMeetings = meetings.where((meeting) {
                            // Check if user is creator or attendee
                            final isUserMeeting = meeting.creator == user ||
                                meeting.attendees.contains(user);
                            if (!isUserMeeting) {
                              return false;
                            }

                            // Check if meeting is on this date (exact match required)
                            if (meeting.date != dateStr) {
                              return false;
                            }

                            // Check if meeting overlaps with this hour slot
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
                            
                            final overlaps = startMinutes < hourEndMinutes && endMinutes > hourStartMinutes;
                            
                            return overlaps;
                          }).toList();
                          
                                return Container(
                                  width: 150,
                                  constraints: const BoxConstraints(
                                    minHeight: 80,
                                    minWidth: 120,
                                    maxWidth: 150,
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
                                      // Use meetings and userId from method parameters
                                      final userWorkHours = controller.getWorkHoursForUser(user, dateStr, meetings, userId);
                                      
                                      // Filter work hours that start in this hour slot (for card display)
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
                                      
                                      // Filter events for this hour
                                      final hourEvents = userMeetings.where((meeting) {
                                        final startParts = meeting.startTime.split(':');
                                        final startHour = int.parse(startParts[0]);
                                        return startHour == hour;
                                      }).toList();
                                      
                                      // Use helper method to build cell content with overflow handling
                                      return CalendarCellContent(
                                        meetings: hourEvents,
                                        workHours: hourWorkHours,
                                        dateStr: dateStr,
                                        userEmail: user,
                                        hour: hour,
                                        isDark: isDark,
                                        hasWorkHourBackground: hasWorkHourInThisSlot,
                                        controller: controller,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                              ],
                            ),
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
        ],
      ),
    );
  }
}

/// Day grid header sliver widget
class DayGridHeaderSliver extends GetView<CalendarController> {
  final bool isDark;
  const DayGridHeaderSliver({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentDate = controller.currentDate.value;
      final dateStr = CalendarUtils.formatDateToIso(currentDate);
      final currentMeetings = controller.meetings;
      final meetingsByDate = controller.getMeetingsByDate(currentMeetings);
      final dayMeetings = meetingsByDate[dateStr] ?? [];
      final currentScopeType = controller.scopeType.value;
      final currentViewType = controller.viewType.value;
      final currentSelectedWeekDate = controller.selectedWeekDate.value;
      final currentUserId = controller.userId.value;
      final currentUserEmail = controller.userEmail.value;
      final filteredMeetings = controller.filterMeetings(
        dayMeetings,
        scopeTypeParam: currentScopeType,
        viewTypeParam: currentViewType,
        selectedWeekDateParam: currentSelectedWeekDate,
        userIdParam: currentUserId,
        userEmailParam: currentUserEmail,
      );
      
      // Get users from meetings
      final usersFromMeetings = CalendarUtils.getUsersFromMeetings(filteredMeetings);
      // Also include users who have work hours on this date
      final allUsers = <String>{...usersFromMeetings};
      // Use currentMeetings from Obx context instead of accessing RxList directly
      for (var meeting in currentMeetings) {
        if (meeting.category == 'work_hour' && meeting.date == dateStr) {
          if (meeting.creator.isNotEmpty) {
            allUsers.add(meeting.creator);
          }
        }
      }
      final users = allUsers.toList()..sort();

      return SliverPersistentHeader(
        pinned: true,
        delegate: DayGridHeaderDelegate(
          users: users,
          isDark: isDark,
          controller: controller,
          currentUserPage: controller.currentUserPage.value, // Capture Rx value in Obx
        ),
      );
    });
  }
}

/// Day view content wrapper
class DayViewContent extends GetView<CalendarController> {
  final bool isDark;
  const DayViewContent({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: CalendarDayView(isDark: isDark),
    );
  }
}


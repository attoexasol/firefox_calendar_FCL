import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/cell_cards_modal.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_cards.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_helpers.dart';
import 'package:flutter/material.dart';

/// Calendar cell content widget with overflow handling
/// Combines meetings and work hours, sorts by startTime, and handles overflow
class CalendarCellContent extends StatelessWidget {
  final List<Meeting> meetings;
  final List<WorkHour> workHours;
  final String dateStr;
  final String userEmail;
  final int hour;
  final bool isDark;
  final bool hasWorkHourBackground;
  final CalendarController controller;

  const CalendarCellContent({
    super.key,
    required this.meetings,
    required this.workHours,
    required this.dateStr,
    required this.userEmail,
    required this.hour,
    required this.isDark,
    required this.hasWorkHourBackground,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Combine all items and sort by startTime
    final allItems = <CellItem>[];
    
    // Add meetings (exclude work_hour category - they're already in workHours list)
    for (var meeting in meetings) {
      // Skip meetings that are converted from work hours to avoid duplicates
      if (meeting.category != 'work_hour') {
        allItems.add(CellItem(
          type: CellItemType.meeting,
          meeting: meeting,
          startTime: meeting.startTime,
        ));
      }
    }
    
    // Add work hours
    for (var workHour in workHours) {
      allItems.add(CellItem(
        type: CellItemType.workHour,
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
              if (item.type == CellItemType.meeting) {
                return MeetingCard(
                  meeting: item.meeting!,
                  controller: controller,
                  isDark: isDark,
                );
              } else {
                return WorkHourCard(
                  workHour: item.workHour!,
                  controller: controller,
                  isDark: isDark,
                );
              }
            }),
            
            // Overflow indicator
            if (hasOverflow)
              InkWell(
                onTap: () {
                  // Filter out work_hour category meetings to avoid duplicates in modal
                  final filteredMeetings = meetings.where((m) => m.category != 'work_hour').toList();
                  showDialog(
                    context: context,
                    builder: (context) => CellCardsModal(
                      meetings: filteredMeetings,
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
}


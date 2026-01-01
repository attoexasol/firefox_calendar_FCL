import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/sections/hoverable_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Meeting card widget for calendar cells
class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final CalendarController controller;
  final bool isDark;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final userForColor = meeting.creator;
    final color = meeting.category == 'work_hour'
        ? controller.getWorkHourColorForUser(userForColor, isDark)
        : controller.getEventColor(meeting, isDark);
    final textColor = controller.getEventTextColor(meeting, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: HoverableCard(
        isDark: isDark,
        baseColor: color,
        onTap: () {
          if (meeting.category == 'work_hour') {
            controller.openWorkHourDetail(meeting);
          } else {
            controller.openMeetingDetail(meeting);
          }
        },
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: textColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  meeting.startTime,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Work hour card widget for calendar cells
class WorkHourCard extends StatelessWidget {
  final WorkHour workHour;
  final CalendarController controller;
  final bool isDark;

  const WorkHourCard({
    super.key,
    required this.workHour,
    required this.controller,
    required this.isDark,
  });

  String _formatTime(String timeStr) {
    // Handle time strings like "08:56:00" or "08:56"
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final h = int.parse(parts[0]);
      final m = parts[1];
      // Format as 24-hour: HH:mm (remove seconds if present)
      final hourStr = h.toString().padLeft(2, '0');
      return '$hourStr:$m';
    }
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
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

    final hourCardColor = isDark
        ? Colors.blue.withValues(alpha: 0.3)
        : Colors.blue.withValues(alpha: 0.2);
    final hourTextColor = isDark
        ? Colors.blue.shade200
        : Colors.blue.shade900;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: HoverableCard(
        isDark: isDark,
        baseColor: hourCardColor,
        onTap: () => controller.openWorkHourDetail(workHour),
        decoration: BoxDecoration(
          color: hourCardColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark
                ? Colors.blue.withValues(alpha: 0.5)
                : Colors.blue.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: hourTextColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${_formatTime(workHour.loginTime)} - ${_formatTime(workHour.logoutTime)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: hourTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  '${totalHours.toStringAsFixed(1)}h',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: hourTextColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


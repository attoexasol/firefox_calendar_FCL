import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Modal to show all events and work hours in a calendar cell
/// Used when there are too many items to display in the cell
class CellCardsModal extends StatelessWidget {
  final List<Meeting> meetings;
  final List<WorkHour> workHours;
  final String dateStr;
  final String userEmail;
  final int hour;
  final bool isDark;

  const CellCardsModal({
    super.key,
    required this.meetings,
    required this.workHours,
    required this.dateStr,
    required this.userEmail,
    required this.hour,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalendarController>();

    // Combine and sort all items by startTime
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

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Items',
                          style: AppTextStyles.h3.copyWith(
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatHour(hour)} - ${dateStr}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable list of items
            Flexible(
              child: allItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No items',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: allItems.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final item = allItems[index];
                        return _buildItemCard(
                          context,
                          item,
                          controller,
                          isDark,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    _CellItem item,
    CalendarController controller,
    bool isDark,
  ) {
    if (item.type == _CellItemType.meeting) {
      final meeting = item.meeting!;
      final userForColor = meeting.creator;
      final color = meeting.category == 'work_hour'
          ? controller.getWorkHourColorForUser(userForColor, isDark)
          : controller.getEventColor(meeting, isDark);
      final textColor = controller.getEventTextColor(meeting, isDark);

      return InkWell(
        onTap: () {
          Navigator.of(context).pop();
          if (meeting.category == 'work_hour') {
            controller.openWorkHourDetail(meeting);
          } else {
            controller.openMeetingDetail(meeting);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: textColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meeting.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${meeting.startTime} - ${meeting.endTime}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
              if (meeting.description != null && meeting.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  meeting.description!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      final workHour = item.workHour!;
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
          // Format as 24-hour: HH:mm
          final hourStr = h.toString().padLeft(2, '0');
          return '$hourStr:$m';
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
        onTap: () {
          Navigator.of(context).pop();
          controller.openWorkHourDetail(workHour);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hourCardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.blue.withValues(alpha: 0.5)
                  : Colors.blue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: hourTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Work Hours',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: hourTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${formatTime(workHour.loginTime)} - ${formatTime(workHour.logoutTime)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: hourTextColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${totalHours.toStringAsFixed(1)} hours',
                style: AppTextStyles.bodySmall.copyWith(
                  color: hourTextColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
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

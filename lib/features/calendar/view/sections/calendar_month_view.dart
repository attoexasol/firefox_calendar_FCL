import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Month view section for calendar
class CalendarMonthView extends GetView<CalendarController> {
  final bool isDark;
  const CalendarMonthView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
              // Weekday headers: S, M, T, W, T, F, S (index 0-6)
              const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              return Container(
                alignment: Alignment.center,
                child: Text(
                  weekdays[index],
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
            final dateStr = CalendarUtils.formatDateToIso(date);
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
}


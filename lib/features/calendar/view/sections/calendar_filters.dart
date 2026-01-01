import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_tab_button.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Show calendar by section (Day/Week/Month tabs)
class ShowCalendarBySection extends StatelessWidget {
  final bool isDark;
  final CalendarController controller;

  const ShowCalendarBySection({
    super.key,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: CalendarTabButton(
                    label: 'Day',
                    value: 'day',
                    isActive: controller.viewType.value == 'day',
                    isDark: isDark,
                    controller: controller,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CalendarTabButton(
                    label: 'Week',
                    value: 'week',
                    isActive: controller.viewType.value == 'week',
                    isDark: isDark,
                    controller: controller,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CalendarTabButton(
                    label: 'Month',
                    value: 'month',
                    isActive: controller.viewType.value == 'month',
                    isDark: isDark,
                    controller: controller,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Show schedule for section (Everyone/Myself tabs)
class ShowScheduleForSection extends StatelessWidget {
  final bool isDark;
  final CalendarController controller;

  const ShowScheduleForSection({
    super.key,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: CalendarTabButton(
                    label: 'Everyone',
                    value: 'everyone',
                    isActive: controller.scopeType.value == 'everyone',
                    isDark: isDark,
                    controller: controller,
                    isScope: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CalendarTabButton(
                    label: 'Myself',
                    value: 'myself',
                    isActive: controller.scopeType.value == 'myself',
                    isDark: isDark,
                    controller: controller,
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
}

/// Date navigation section
class DateNavigationSection extends StatelessWidget {
  final bool isDark;
  final CalendarController controller;

  const DateNavigationSection({
    super.key,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
                dateText = CalendarUtils.formatDate(
                  controller.currentDate.value,
                  'day',
                );
              } else if (controller.viewType.value == 'week') {
                final weekDates = controller.getCurrentWeekDates();
                dateText =
                    '${CalendarUtils.formatDate(weekDates.first, 'short')} - ${CalendarUtils.formatDate(weekDates.last, 'full')}';
              } else {
                dateText = CalendarUtils.formatDate(
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
}


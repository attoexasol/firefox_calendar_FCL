import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:flutter/material.dart';

/// Tab button widget for calendar filters
class CalendarTabButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;
  final bool isDark;
  final bool isScope;
  final CalendarController controller;

  const CalendarTabButton({
    super.key,
    required this.label,
    required this.value,
    required this.isActive,
    required this.isDark,
    required this.controller,
    this.isScope = false,
  });

  @override
  Widget build(BuildContext context) {
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
}


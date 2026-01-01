import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_day_view.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_filters.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_listeners.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_month_view.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_states.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_week_view.dart';
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
                return CalendarLoadingState(isDark: isDark);
              }

              // Show error state (only if no events exist)
              if (controller.eventsError.value.isNotEmpty && 
                  controller.meetings.isEmpty &&
                  !controller.isLoadingEvents.value) {
                return CalendarErrorState(
                  error: controller.eventsError.value,
                  isDark: isDark,
                  controller: controller,
                );
              }

              // Show empty state (only if no events and no error)
              if (controller.meetings.isEmpty && 
                  !controller.isLoadingEvents.value &&
                  controller.eventsError.value.isEmpty) {
                return CalendarEmptyState(isDark: isDark);
              }

              // CustomScrollView with Slivers for sticky header behavior
              return CustomScrollView(
                slivers: [
                  // Top filters that scroll away
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const TopBar(title: 'Calendar'),
                        ShowCalendarBySection(
                          isDark: isDark,
                          controller: controller,
                        ),
                        ShowScheduleForSection(
                          isDark: isDark,
                          controller: controller,
                        ),
                        DateNavigationSection(
                          isDark: isDark,
                          controller: controller,
                        ),
                      ],
                    ),
                  ),

                  // Sticky Calendar Grid Header (Time + User Avatars + Day Labels)
                  if (controller.viewType.value == 'week')
                    WeekGridHeaderSliver(isDark: isDark)
                  else if (controller.viewType.value == 'day')
                    DayGridHeaderSliver(isDark: isDark),

                  // Scrollable Calendar Body (Time Slots + Events)
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Obx(() {
                          if (controller.viewType.value == 'week') {
                            return CalendarWeekView(isDark: isDark);
                          } else if (controller.viewType.value == 'day') {
                            return CalendarDayView(isDark: isDark);
                          } else {
                            return CalendarMonthView(isDark: isDark);
                          }
                        });
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
          // Event Details Dialog listener
          EventDetailsListener(controller: controller),
          // Hour Details Dialog listener
          HourDetailsListener(controller: controller),
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
}

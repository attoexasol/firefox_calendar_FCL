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
    
    // Ensure user data is up-to-date when calendar screen is accessed
    // This handles account switching scenarios where userId/userEmail may have changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadUserData();
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Main calendar content with CustomScrollView
          SafeArea(
            child: _buildCalendarContent(isDark),
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

  /// Build calendar content with proper Obx scoping
  Widget _buildCalendarContent(bool isDark) {
    // Always show calendar layout with filters
    // Only show loading/error states if truly needed, but keep calendar structure
    return Obx(() {
      // Show loading state only during initial load (when no data exists yet)
      if (controller.isLoadingEvents.value && controller.meetings.isEmpty && controller.allMeetings.isEmpty) {
        return CalendarLoadingState(isDark: isDark);
      }

      // Show error state only if there's an error AND no data exists
      // But still show calendar layout if we have any data
      if (controller.eventsError.value.isNotEmpty && 
          controller.meetings.isEmpty &&
          controller.allMeetings.isEmpty &&
          !controller.isLoadingEvents.value) {
        return CalendarErrorState(
          error: controller.eventsError.value,
          isDark: isDark,
          controller: controller,
        );
      }

      // Always show calendar view - even when empty
      // The calendar views will handle showing empty states internally if needed
      return _buildCalendarView(isDark);
    });
  }

  /// Build calendar view with view type selection
  Widget _buildCalendarView(bool isDark) {
    return Obx(() {
      // Extract viewType once at the start
      final viewType = controller.viewType.value;
      
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
          if (viewType == 'week')
            WeekGridHeaderSliver(isDark: isDark)
          else if (viewType == 'day')
            DayGridHeaderSliver(isDark: isDark),

          // Scrollable Calendar Body (Time Slots + Events)
          SliverFillRemaining(
            hasScrollBody: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Small Obx for view type only (nested for pagination reactivity)
                return Obx(() {
                  final currentViewType = controller.viewType.value;
                  if (currentViewType == 'week') {
                    return CalendarWeekView(isDark: isDark);
                  } else if (currentViewType == 'day') {
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
    });
  }
}

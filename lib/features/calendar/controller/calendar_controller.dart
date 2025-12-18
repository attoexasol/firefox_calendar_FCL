
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:firefox_calendar/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Calendar Controller
/// Manages calendar state, view types, filtering, and meeting data
/// Converted from React Calendar.tsx
class CalendarController extends GetxController {
  // Storage
  final storage = GetStorage();

  // View types
  final RxString viewType = 'week'.obs; // 'day', 'week', 'month'
  final RxString scopeType = 'everyone'.obs; // 'everyone', 'myself'

  // Current date
  final Rx<DateTime> currentDate = DateTime.now().obs;

  // Selected date for week view filtering
  final Rx<DateTime?> selectedWeekDate = Rx<DateTime?>(null);

  // Calendar picker state
  final RxBool isCalendarOpen = false.obs;

  // Selected meeting for detail view
  final Rx<Meeting?> selectedMeeting = Rx<Meeting?>(null);

  // Create meeting modal state
  final RxBool showCreateMeeting = false.obs;

  // Meetings list (mock data - replace with API)
  final RxList<Meeting> meetings = <Meeting>[].obs;

  // User data
  final RxString userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadMockMeetings();
  }

  /// Load user data from storage
  void _loadUserData() {
    userEmail.value = storage.read('userEmail') ?? '';
  }

  /// Load mock meetings
  /// TODO: Replace with actual API call
  void _loadMockMeetings() {
    // Mock data - replace with actual API call
    final now = DateTime.now();

    meetings.value = [
      Meeting(
        id: '1',
        title: 'Team Standup',
        date: now.toIso8601String().split('T')[0],
        startTime: '10:00',
        endTime: '10:30',
        primaryEventType: 'Team Meeting',
        meetingType: 'team-meeting',
        type: 'confirmed',
        creator: userEmail.value,
        attendees: [userEmail.value],
        category: 'meeting',
      ),
      Meeting(
        id: '2',
        title: 'Client Meeting',
        date: DateTime(
          now.year,
          now.month,
          now.day + 1,
        ).toIso8601String().split('T')[0],
        startTime: '14:00',
        endTime: '15:00',
        primaryEventType: 'Client meeting',
        meetingType: 'client-meeting',
        type: 'confirmed',
        creator: userEmail.value,
        attendees: [userEmail.value],
        category: 'meeting',
      ),
      Meeting(
        id: '3',
        title: 'Training Session',
        date: DateTime(
          now.year,
          now.month,
          now.day + 2,
        ).toIso8601String().split('T')[0],
        startTime: '11:00',
        endTime: '12:00',
        primaryEventType: 'Training',
        meetingType: 'training',
        type: 'confirmed',
        creator: userEmail.value,
        attendees: [userEmail.value],
        category: 'meeting',
      ),
    ];
  }

  /// Change view type (day/week/month)
  void setViewType(String type) {
    viewType.value = type;
    selectedWeekDate.value = null; // Reset date filter when changing views
  }

  /// Change scope type (everyone/myself)
  void setScopeType(String type) {
    scopeType.value = type;
  }

  /// Navigate to previous period
  void navigatePrevious() {
    final newDate = DateTime(
      currentDate.value.year,
      currentDate.value.month,
      currentDate.value.day,
    );

    if (viewType.value == 'day') {
      currentDate.value = newDate.subtract(const Duration(days: 1));
    } else if (viewType.value == 'week') {
      currentDate.value = newDate.subtract(const Duration(days: 7));
      selectedWeekDate.value = null;
    } else {
      currentDate.value = DateTime(
        currentDate.value.year,
        currentDate.value.month - 1,
        currentDate.value.day,
      );
    }
  }

  /// Navigate to next period
  void navigateNext() {
    final newDate = DateTime(
      currentDate.value.year,
      currentDate.value.month,
      currentDate.value.day,
    );

    if (viewType.value == 'day') {
      currentDate.value = newDate.add(const Duration(days: 1));
    } else if (viewType.value == 'week') {
      currentDate.value = newDate.add(const Duration(days: 7));
      selectedWeekDate.value = null;
    } else {
      currentDate.value = DateTime(
        currentDate.value.year,
        currentDate.value.month + 1,
        currentDate.value.day,
      );
    }
  }

  /// Navigate to today
  void navigateToToday() {
    currentDate.value = DateTime.now();
    selectedWeekDate.value = null;
  }

  /// Set current date from calendar picker
  void setCurrentDate(DateTime date) {
    currentDate.value = date;
    isCalendarOpen.value = false;
  }

  /// Toggle calendar picker
  void toggleCalendarPicker() {
    isCalendarOpen.value = !isCalendarOpen.value;
  }

  /// Handle week date click (for filtering)
  void handleWeekDateClick(DateTime date) {
    if (selectedWeekDate.value != null &&
        selectedWeekDate.value!.toIso8601String().split('T')[0] ==
            date.toIso8601String().split('T')[0]) {
      // Deselect if clicking the same date
      selectedWeekDate.value = null;
    } else {
      // Select new date
      selectedWeekDate.value = date;
    }
  }

  /// Get current week dates (Monday to Sunday)
  List<DateTime> getCurrentWeekDates() {
    final currentDay = currentDate.value.weekday;
    final monday = currentDate.value.subtract(Duration(days: currentDay - 1));

    return List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });
  }

  /// Get month dates (with previous/next month padding)
  List<MonthDate> getMonthDates() {
    final year = currentDate.value.year;
    final month = currentDate.value.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startingDayOfWeek = firstDay.weekday;

    final dates = <MonthDate>[];

    // Add previous month's days
    for (int i = startingDayOfWeek - 1; i >= 1; i--) {
      final date = firstDay.subtract(Duration(days: i));
      dates.add(MonthDate(date: date, isCurrentMonth: false));
    }

    // Add current month's days
    for (int i = 1; i <= lastDay.day; i++) {
      dates.add(
        MonthDate(date: DateTime(year, month, i), isCurrentMonth: true),
      );
    }

    // Add next month's days to complete the grid
    final remainingDays = 42 - dates.length; // 6 weeks * 7 days
    for (int i = 1; i <= remainingDays; i++) {
      final date = DateTime(year, month + 1, i);
      dates.add(MonthDate(date: date, isCurrentMonth: false));
    }

    return dates;
  }

  /// Check if user is invited to meeting
  bool isUserInvited(Meeting meeting) {
    if (userEmail.value.isEmpty) return false;
    return meeting.attendees.contains(userEmail.value) ||
        meeting.creator == userEmail.value;
  }

  /// Filter meetings based on scope and date
  List<Meeting> filterMeetings(List<Meeting> meetings) {
    var filtered = meetings;

    // Apply scope filter
    if (scopeType.value == 'myself') {
      filtered = filtered.where((m) => isUserInvited(m)).toList();
    }

    // Apply week date filter (only in week view)
    if (viewType.value == 'week' && selectedWeekDate.value != null) {
      final dateStr = selectedWeekDate.value!.toIso8601String().split('T')[0];
      filtered = filtered.where((m) => m.date == dateStr).toList();
    }

    return filtered;
  }

  /// Get meetings by date
  Map<String, List<Meeting>> getMeetingsByDate() {
    final result = <String, List<Meeting>>{};

    for (var meeting in meetings) {
      if (!result.containsKey(meeting.date)) {
        result[meeting.date] = [];
      }
      result[meeting.date]!.add(meeting);
    }

    return result;
  }

  /// Get dynamic time range based on meetings
  TimeRange getTimeRange(List<Meeting> meetings) {
    const defaultStart = 9; // 9 AM
    const defaultEnd = 18; // 6 PM

    if (meetings.isEmpty) {
      return TimeRange(startHour: defaultStart, endHour: defaultEnd);
    }

    int earliestHour = defaultStart;
    int latestHour = defaultEnd;

    for (var meeting in meetings) {
      final startParts = meeting.startTime.split(':');
      final endParts = meeting.endTime.split(':');

      final startHour = int.parse(startParts[0]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      if (startHour < earliestHour) {
        earliestHour = startHour;
      }

      final effectiveEndHour = endMinute > 0 ? endHour + 1 : endHour;
      if (effectiveEndHour > latestHour) {
        latestHour = effectiveEndHour;
      }
    }

    earliestHour = earliestHour.clamp(0, 23);
    latestHour = latestHour.clamp(0, 23);

    return TimeRange(startHour: earliestHour, endHour: latestHour);
  }

  /// Get event color based on meeting type and status
  Color getEventColor(Meeting meeting, bool isDark) {
    // Check if meeting is in the past
    final meetingDateTime = DateTime.parse(
      '${meeting.date}T${meeting.endTime}',
    );
    final now = DateTime.now();
    final isPast = meetingDateTime.isBefore(now);
    final invited = isUserInvited(meeting);

    if (isPast) {
      return isDark
          ? const Color(0xFF166534).withValues(alpha: 0.4)
          : const Color(0xFFBBF7D0);
    }

    // Not invited - use gray colors
    if (!invited) {
      return meeting.type == 'confirmed'
          ? (isDark ? const Color(0xFF4B5563) : const Color(0xFF6B7280))
          : (isDark
                ? const Color(0xFF374151).withValues(alpha: 0.6)
                : const Color(0xFFD1D5DB));
    }

    // Determine color based on event type
    final eventType = meeting.primaryEventType ?? 'Meeting';

    switch (eventType) {
      case 'Team Meeting':
        return meeting.type == 'confirmed'
            ? const Color(0xFF2563EB)
            : (isDark
                  ? const Color(0xFF0C4A6E).withValues(alpha: 0.4)
                  : const Color(0xFFBAE6FD));
      case 'One-on-one':
        return meeting.type == 'confirmed'
            ? const Color(0xFF4F46E5)
            : (isDark
                  ? const Color(0xFF3730A3).withValues(alpha: 0.4)
                  : const Color(0xFFC7D2FE));
      case 'Client meeting':
        return meeting.type == 'confirmed'
            ? const Color(0xFF9333EA)
            : (isDark
                  ? const Color(0xFF6B21A8).withValues(alpha: 0.4)
                  : const Color(0xFFE9D5FF));
      case 'Training':
        return meeting.type == 'confirmed'
            ? const Color(0xFF16A34A)
            : (isDark
                  ? const Color(0xFF166534).withValues(alpha: 0.4)
                  : const Color(0xFFBBF7D0));
      case 'Personal Appointment':
        return meeting.type == 'confirmed'
            ? const Color(0xFFD97706)
            : (isDark
                  ? const Color(0xFF92400E).withValues(alpha: 0.4)
                  : const Color(0xFFFDE68A));
      case 'Annual Leave':
        return meeting.type == 'confirmed'
            ? const Color(0xFFDC2626)
            : (isDark
                  ? const Color(0xFF991B1B).withValues(alpha: 0.4)
                  : const Color(0xFFFECACA));
      case 'Personal Leave':
        return meeting.type == 'confirmed'
            ? const Color(0xFFEA580C)
            : (isDark
                  ? const Color(0xFF9A3412).withValues(alpha: 0.4)
                  : const Color(0xFFFED7AA));
      default:
        return meeting.type == 'confirmed'
            ? const Color(0xFF2563EB)
            : (isDark
                  ? const Color(0xFF0C4A6E).withValues(alpha: 0.4)
                  : const Color(0xFFBAE6FD));
    }
  }

  /// Get text color for event
  Color getEventTextColor(Meeting meeting, bool isDark) {
    final meetingDateTime = DateTime.parse(
      '${meeting.date}T${meeting.endTime}',
    );
    final now = DateTime.now();
    final isPast = meetingDateTime.isBefore(now);
    final invited = isUserInvited(meeting);

    if (isPast) {
      return isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534);
    }

    if (!invited) {
      return meeting.type == 'confirmed'
          ? Colors.white
          : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937));
    }

    return meeting.type == 'confirmed'
        ? Colors.white
        : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937));
  }

  /// Open create meeting modal
  // void openCreateMeetingModal() {
  //   showCreateMeeting.value = true;
  // }
  void openCreateMeetingModal() {
    // Reset form for new event creation
    final createEventController = Get.find<CreateEventController>();
    createEventController.resetForm();

    // Navigate to create event screen
    Get.toNamed(AppRoutes.createEvent);
  }

  /// Close create meeting modal
  void closeCreateMeetingModal() {
    showCreateMeeting.value = false;
  }

  /// Open meeting detail
  void openMeetingDetail(Meeting meeting) {
    selectedMeeting.value = meeting;
  }

  /// Close meeting detail
  void closeMeetingDetail() {
    selectedMeeting.value = null;
  }

  /// Handle day click in month view
  void handleDayClick(DateTime date) {
    currentDate.value = date;
    viewType.value = 'day';
  }
}

/// Meeting Model
/// Converted from React mockData.ts
class Meeting {
  final String id;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String? primaryEventType;
  final String? meetingType;
  final String type; // 'confirmed' or 'tentative'
  final String creator;
  final List<String> attendees;
  final String? category;
  final String? description;

  Meeting({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.primaryEventType,
    this.meetingType,
    required this.type,
    required this.creator,
    required this.attendees,
    this.category,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'primaryEventType': primaryEventType,
    'meetingType': meetingType,
    'type': type,
    'creator': creator,
    'attendees': attendees,
    'category': category,
    'description': description,
  };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    date: json['date'] ?? '',
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
    primaryEventType: json['primaryEventType'],
    meetingType: json['meetingType'],
    type: json['type'] ?? 'confirmed',
    creator: json['creator'] ?? '',
    attendees: List<String>.from(json['attendees'] ?? []),
    category: json['category'],
    description: json['description'],
  );
}

/// Month Date Model
class MonthDate {
  final DateTime date;
  final bool isCurrentMonth;

  MonthDate({required this.date, required this.isCurrentMonth});
}

/// Time Range Model
class TimeRange {
  final int startHour;
  final int endHour;

  TimeRange({required this.startHour, required this.endHour});
}

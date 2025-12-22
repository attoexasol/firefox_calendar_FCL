
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:firefox_calendar/routes/app_routes.dart';
import 'package:firefox_calendar/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Calendar Controller
/// Manages calendar state, view types, filtering, and meeting data
/// Converted from React Calendar.tsx
class CalendarController extends GetxController {
  // Storage
  final storage = GetStorage();
  final AuthService _authService = AuthService();

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
  final Rx<Map<String, dynamic>?> eventDetails = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoadingEventDetails = false.obs;
  final RxString eventDetailsError = ''.obs;

  // Create meeting modal state
  final RxBool showCreateMeeting = false.obs;

  // All meetings from API (unfiltered)
  final RxList<Meeting> allMeetings = <Meeting>[].obs;
  
  // Filtered meetings based on scope (everyone/myself)
  final RxList<Meeting> meetings = <Meeting>[].obs;

  // User data
  final RxString userEmail = ''.obs;
  final RxInt userId = 0.obs;

  // Events loading and error states
  final RxBool isLoadingEvents = false.obs;
  final RxString eventsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    fetchAllEvents(); // Fetch events from API on init
  }

  /// Load user data from storage
  void _loadUserData() {
    userEmail.value = storage.read('userEmail') ?? '';
    userId.value = storage.read('userId') ?? 0;
    print('👤 [CalendarController] Loaded user data:');
    print('   userId: ${userId.value}');
    print('   userEmail: ${userEmail.value}');
  }

  /// Format date to consistent YYYY-MM-DD string
  String _formatDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Fetch events from API
  /// Called on init and when refreshing events
  /// Supports day/week/month filtering based on viewType
  /// Uses different endpoints for "Everyone" vs "Myself"
  Future<void> fetchAllEvents() async {
    try {
      isLoadingEvents.value = true;
      eventsError.value = '';
      
      // Determine range based on view type
      String? range;
      if (viewType.value == 'day') {
        range = 'day';
      } else if (viewType.value == 'week') {
        range = 'week';
      } else if (viewType.value == 'month') {
        range = 'month';
      }

      // Format current date as YYYY-MM-DD
      final currentDateStr = _formatDateString(currentDate.value);

      print('═══════════════════════════════════════════════════════════');
      print('📅 [CalendarController] Fetching events...');
      print('   Scope: ${scopeType.value}');
      print('   View Type: ${viewType.value}');
      print('   Range: ${range ?? 'none'}');
      print('   Current Date: $currentDateStr');
      print('   User ID: ${userId.value}');
      print('═══════════════════════════════════════════════════════════');

      // Use different API endpoint based on scope
      Map<String, dynamic> result;
      if (scopeType.value == 'myself') {
        // Use /api/my/events for "Myself" scope
        result = await _authService.getMyEvents(
          range: range ?? 'week',
          currentDate: currentDateStr,
        );
      } else {
        // Use /api/all/events for "Everyone" scope
        result = await _authService.getAllEvents(
          range: range,
          currentDate: currentDateStr,
        );
      }

      isLoadingEvents.value = false;

      if (result['success'] == true && result['data'] != null) {
        final eventsData = result['data'];
        
        // Handle both single event object and list of events
        List<dynamic> eventsList;
        if (eventsData is List) {
          eventsList = eventsData;
        } else if (eventsData is Map) {
          // If it's a single event, wrap it in a list
          eventsList = [eventsData];
        } else {
          eventsList = [];
        }

        // Map API response to Meeting objects
        final mappedMeetings = eventsList.map((eventData) {
          return _mapEventToMeeting(eventData);
        }).where((meeting) => meeting != null).cast<Meeting>().toList();

        // Remove duplicates based on ID
        final uniqueMeetings = <String, Meeting>{};
        for (var meeting in mappedMeetings) {
          uniqueMeetings[meeting.id] = meeting;
        }

        // Store all meetings (for "Everyone" view)
        allMeetings.value = uniqueMeetings.values.toList();
        
        // Debug: Print all event dates
        print('📅 [CalendarController] All events dates:');
        for (var meeting in allMeetings) {
          print('   - ${meeting.title}: ${meeting.date} ${meeting.startTime} (userId: ${meeting.userId})');
        }
        
        // Apply scope filter to update displayed meetings
        _applyScopeFilter();
        
        print('✅ [CalendarController] Fetched ${allMeetings.length} events (${meetings.length} after filtering)');
        print('   Scope: ${scopeType.value}, View: ${viewType.value}, Date: ${_formatDateString(currentDate.value)}');
      } else {
        eventsError.value = result['message'] ?? 'Failed to fetch events';
        print('❌ [CalendarController] Failed to fetch events: ${result['message']}');
        
        // Clear all meetings on error
        allMeetings.value = [];
        meetings.value = [];
      }
    } catch (e) {
      isLoadingEvents.value = false;
      eventsError.value = 'An error occurred while fetching events';
      print('💥 [CalendarController] Error fetching events: $e');
      
      // Clear all meetings on error
      allMeetings.value = [];
      meetings.value = [];
    }
  }

  /// Map API event data to Meeting model
  Meeting? _mapEventToMeeting(Map<String, dynamic> eventData) {
    try {
      // Extract date and time
      final dateStr = eventData['date']?.toString() ?? '';
      final startTimeStr = eventData['start_time']?.toString() ?? '';
      final endTimeStr = eventData['end_time']?.toString() ?? '';

      print('🗓️ [CalendarController] Mapping event:');
      print('   Raw date: $dateStr');
      print('   Raw start_time: $startTimeStr');
      print('   Raw end_time: $endTimeStr');

      // Parse date
      String formattedDate = '';
      if (dateStr.isNotEmpty) {
        try {
          // Handle ISO format: "2025-12-20T00:00:00.000000Z" or "2025-12-20"
          String datePart = dateStr;
          if (dateStr.contains('T')) {
            datePart = dateStr.split('T')[0];
          }
          final date = DateTime.parse(datePart);
          formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          print('   ✅ Parsed date: $formattedDate');
        } catch (e) {
          print('   ⚠️ Date parse error: $e, using raw: $dateStr');
          formattedDate = dateStr;
        }
      } else {
        print('   ⚠️ Empty date string');
      }

      // Parse start time
      String formattedStartTime = '';
      if (startTimeStr.isNotEmpty) {
        try {
          if (startTimeStr.contains('T')) {
            final timePart = startTimeStr.split('T')[1].split(':');
            formattedStartTime = '${timePart[0]}:${timePart[1]}';
          } else {
            formattedStartTime = startTimeStr;
          }
        } catch (e) {
          formattedStartTime = startTimeStr;
        }
      }

      // Parse end time
      String formattedEndTime = '';
      if (endTimeStr.isNotEmpty) {
        try {
          if (endTimeStr.contains('T')) {
            final timePart = endTimeStr.split('T')[1].split(':');
            formattedEndTime = '${timePart[0]}:${timePart[1]}';
          } else {
            formattedEndTime = endTimeStr;
          }
        } catch (e) {
          formattedEndTime = endTimeStr;
        }
      }

      // Extract user information from API response
      final currentUserEmail = storage.read('userEmail') ?? '';
      final currentUserId = storage.read('userId') ?? 0;
      
      // Get creator info from API response
      String creatorEmail = currentUserEmail;
      int? eventUserId;
      
      print('   👤 Extracting user info from event data...');
      print('   Current user: userId=$currentUserId, email=$currentUserEmail');
      
      // Extract user ID from event data
      if (eventData['user'] != null && eventData['user'] is Map) {
        final userData = eventData['user'] as Map<String, dynamic>;
        eventUserId = userData['id'] is int 
            ? userData['id'] as int 
            : int.tryParse(userData['id']?.toString() ?? '');
        
        print('   Found user.id: $eventUserId');
        
        // Try to get email from user data, or construct from name
        if (userData['email'] != null) {
          creatorEmail = userData['email'].toString();
          print('   Found user.email: $creatorEmail');
        } else if (userData['first_name'] != null) {
          // Construct email-like identifier from name
          final firstName = userData['first_name'].toString().toLowerCase().replaceAll(' ', '');
          creatorEmail = '$firstName@user.com';
          print('   Constructed email from first_name: $creatorEmail');
        }
      } else if (eventData['created_by'] != null) {
        if (eventData['created_by'] is Map) {
          final createdByData = eventData['created_by'] as Map<String, dynamic>;
          eventUserId = createdByData['id'] is int 
              ? createdByData['id'] as int 
              : int.tryParse(createdByData['id']?.toString() ?? '');
          print('   Found created_by.id: $eventUserId');
        } else {
          eventUserId = eventData['created_by'] is int 
              ? eventData['created_by'] as int 
              : int.tryParse(eventData['created_by']?.toString() ?? '');
          print('   Found created_by (direct): $eventUserId');
        }
      } else if (eventData['user_id'] != null) {
        eventUserId = eventData['user_id'] is int 
            ? eventData['user_id'] as int 
            : int.tryParse(eventData['user_id']?.toString() ?? '');
        print('   Found user_id: $eventUserId');
      } else {
        print('   ⚠️ No user ID found in event data');
      }
      
      print('   Final eventUserId: $eventUserId, creatorEmail: $creatorEmail');

      // Extract event type name
      String? eventTypeName;
      if (eventData['event_type'] != null && eventData['event_type'] is Map) {
        final eventTypeData = eventData['event_type'] as Map<String, dynamic>;
        eventTypeName = eventTypeData['event_name']?.toString();
      }

      // Extract status
      final status = eventData['status']?.toString() ?? 
                    eventData['type']?.toString() ?? 
                    'confirmed';

      final meeting = Meeting(
        id: eventData['id']?.toString() ?? '',
        title: eventData['title']?.toString() ?? 'Untitled Event',
        date: formattedDate,
        startTime: formattedStartTime,
        endTime: formattedEndTime,
        primaryEventType: eventData['primaryEventType']?.toString() ?? 
                         eventTypeName,
        meetingType: eventData['meetingType']?.toString() ?? 
                    eventData['meeting_type']?.toString(),
        type: status,
        creator: creatorEmail,
        attendees: eventData['attendees'] != null 
            ? List<String>.from(eventData['attendees'])
            : [creatorEmail],
        category: eventData['category']?.toString() ?? 'meeting',
        description: eventData['description']?.toString(),
        userId: eventUserId, // Store user ID for filtering
      );

      print('   ✅ Mapped meeting: ${meeting.title} on ${meeting.date} at ${meeting.startTime}');
      print('      userId: ${meeting.userId}, creator: ${meeting.creator}, attendees: ${meeting.attendees}');
      return meeting;
    } catch (e, stackTrace) {
      print('⚠️ [CalendarController] Error mapping event: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Refresh events from API
  /// Called after creating/updating events to reload calendar data
  Future<void> refreshEvents() async {
    print('🔄 [CalendarController] Refreshing events...');
    // Reload user data in case it changed
    _loadUserData();
    // Fetch fresh events from API
    await fetchAllEvents();
  }

  /// Change view type (day/week/month)
  void setViewType(String type) {
    print('🔄 [CalendarController] View type changed: ${viewType.value} → $type');
    viewType.value = type;
    selectedWeekDate.value = null; // Reset date filter when changing views
    // Refresh events with new view type
    fetchAllEvents();
  }

  /// Change scope type (everyone/myself)
  void setScopeType(String type) {
    print('🔄 [CalendarController] Scope changed: ${scopeType.value} → $type');
    scopeType.value = type;
    // Fetch events based on scope (different API endpoints)
    fetchAllEvents(); // This will use the correct endpoint based on scope
  }

  /// Apply scope filter to meetings
  /// Everyone: Show all events
  /// Myself: Show only events where user is creator or attendee
  void _applyScopeFilter() {
    print('🔍 [CalendarController] Applying scope filter...');
    print('   Scope: ${scopeType.value}');
    print('   Total events: ${allMeetings.length}');
    print('   Current userId: ${userId.value}');
    print('   Current userEmail: ${userEmail.value}');
    
    if (scopeType.value == 'myself') {
      // Filter to show only user's events
      meetings.value = allMeetings.where((meeting) {
        final isInvited = isUserInvited(meeting);
        if (isInvited) {
          print('   ✅ Including: ${meeting.title} (userId: ${meeting.userId}, creator: ${meeting.creator})');
        } else {
          print('   ❌ Excluding: ${meeting.title} (userId: ${meeting.userId}, creator: ${meeting.creator})');
        }
        return isInvited;
      }).toList();
      print('   👤 Filtered to ${meetings.length} events for "Myself"');
    } else {
      // Show all events for "Everyone" view
      meetings.value = List.from(allMeetings);
      print('   👥 Showing all ${meetings.length} events for "Everyone"');
    }
  }

  /// Navigate to previous period
  void navigatePrevious() {
    final oldDate = _formatDateString(currentDate.value);
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
    
    final newDateStr = _formatDateString(currentDate.value);
    print('🔄 [CalendarController] Navigated PREVIOUS: $oldDate → $newDateStr');
    // Refresh events when date changes
    fetchAllEvents();
  }

  /// Navigate to next period
  void navigateNext() {
    final oldDate = _formatDateString(currentDate.value);
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
    
    final newDateStr = _formatDateString(currentDate.value);
    print('🔄 [CalendarController] Navigated NEXT: $oldDate → $newDateStr');
    // Refresh events when date changes
    fetchAllEvents();
  }

  /// Navigate to today
  void navigateToToday() {
    final oldDate = _formatDateString(currentDate.value);
    final now = DateTime.now();
    // Always set to today's date, resetting time to start of day
    currentDate.value = DateTime(now.year, now.month, now.day);
    selectedWeekDate.value = null;
    final newDateStr = _formatDateString(currentDate.value);
    print('🔄 [CalendarController] Navigated to TODAY: $oldDate → $newDateStr');
    // Refresh events when date changes
    fetchAllEvents();
  }

  /// Set current date from calendar picker
  void setCurrentDate(DateTime date) {
    final oldDate = _formatDateString(currentDate.value);
    currentDate.value = date;
    isCalendarOpen.value = false;
    final newDateStr = _formatDateString(currentDate.value);
    print('🔄 [CalendarController] Date changed via picker: $oldDate → $newDateStr');
    // Refresh events when date changes
    fetchAllEvents();
  }

  /// Toggle calendar picker
  void toggleCalendarPicker() {
    isCalendarOpen.value = !isCalendarOpen.value;
  }

  /// Handle week date click (for filtering)
  void handleWeekDateClick(DateTime date) {
    if (selectedWeekDate.value != null &&
        _formatDateString(selectedWeekDate.value!) == _formatDateString(date)) {
      // Deselect if clicking the same date
      selectedWeekDate.value = null;
    } else {
      // Select new date
      selectedWeekDate.value = date;
    }
  }

  /// Get current week dates (Monday to Sunday)
  /// For week view, this calculates the week containing the current date
  List<DateTime> getCurrentWeekDates() {
    final currentDay = currentDate.value.weekday;
    // Calculate Monday of the week (weekday 1 = Monday)
    final monday = currentDate.value.subtract(Duration(days: currentDay - 1));

    // Generate 7 days from Monday to Sunday
    final weekDates = List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });
    
    // Debug: Log week calculation
    if (viewType.value == 'week') {
      print('📅 [CalendarController] Week calculation:');
      print('   Current date: ${_formatDateString(currentDate.value)}');
      print('   Week range: ${_formatDateString(weekDates.first)} to ${_formatDateString(weekDates.last)}');
    }
    
    return weekDates;
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
  /// Checks both user ID (from API) and email (for compatibility)
  bool isUserInvited(Meeting meeting) {
    // Check by user ID (preferred method - works for both login types)
    if (userId.value > 0 && meeting.userId != null) {
      if (meeting.userId == userId.value) {
        return true;
      }
    }
    
    // Fallback to email check (for backward compatibility)
    if (userEmail.value.isNotEmpty) {
      return meeting.attendees.contains(userEmail.value) ||
          meeting.creator == userEmail.value;
    }
    
    return false;
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
      final selectedDate = selectedWeekDate.value!;
      // Use consistent date format (YYYY-MM-DD)
      final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      filtered = filtered.where((m) => m.date == dateStr).toList();
    }

    return filtered;
  }

  /// Get meetings by date
  Map<String, List<Meeting>> getMeetingsByDate() {
    final result = <String, List<Meeting>>{};

    print('📊 [CalendarController] Grouping ${meetings.length} meetings by date:');
    for (var meeting in meetings) {
      if (!result.containsKey(meeting.date)) {
        result[meeting.date] = [];
      }
      result[meeting.date]!.add(meeting);
      print('   - ${meeting.title}: date=${meeting.date}');
    }

    print('📊 [CalendarController] Meetings by date keys: ${result.keys.toList()}');
    return result;
  }

  /// Get dynamic time range based on meetings
  TimeRange getTimeRange(List<Meeting> meetings) {
    const defaultStart = 6; // 6 AM (as shown in screenshots)
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

    earliestHour = earliestHour.clamp(6, 23); // Minimum 6 AM
    latestHour = latestHour.clamp(6, 23);

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
    // Normalize event type name (case-insensitive, handle variations)
    final eventType = (meeting.primaryEventType ?? 'Meeting').trim();
    final normalizedType = eventType.toLowerCase();

    // Map event types to colors
    // Handle both form event types and API event type names
    Color getColorForType(String type) {
      switch (type) {
        case 'team meeting':
          return meeting.type == 'confirmed'
              ? const Color(0xFF2563EB) // Blue
              : (isDark
                    ? const Color(0xFF0C4A6E).withValues(alpha: 0.4)
                    : const Color(0xFFBAE6FD));
        case 'one-on-one':
        case 'one on one':
          return meeting.type == 'confirmed'
              ? const Color(0xFF4F46E5) // Indigo
              : (isDark
                    ? const Color(0xFF3730A3).withValues(alpha: 0.4)
                    : const Color(0xFFC7D2FE));
        case 'client meeting':
        case 'client':
          return meeting.type == 'confirmed'
              ? const Color(0xFF9333EA) // Purple
              : (isDark
                    ? const Color(0xFF6B21A8).withValues(alpha: 0.4)
                    : const Color(0xFFE9D5FF));
        case 'training':
          return meeting.type == 'confirmed'
              ? const Color(0xFF16A34A) // Green
              : (isDark
                    ? const Color(0xFF166534).withValues(alpha: 0.4)
                    : const Color(0xFFBBF7D0));
        case 'personal appointment':
        case 'appointment':
          return meeting.type == 'confirmed'
              ? const Color(0xFFD97706) // Amber
              : (isDark
                    ? const Color(0xFF92400E).withValues(alpha: 0.4)
                    : const Color(0xFFFDE68A));
        case 'annual leave':
        case 'leave':
          return meeting.type == 'confirmed'
              ? const Color(0xFFDC2626) // Red
              : (isDark
                    ? const Color(0xFF991B1B).withValues(alpha: 0.4)
                    : const Color(0xFFFECACA));
        case 'personal leave':
          return meeting.type == 'confirmed'
              ? const Color(0xFFEA580C) // Orange
              : (isDark
                    ? const Color(0xFF9A3412).withValues(alpha: 0.4)
                    : const Color(0xFFFED7AA));
        case 'conference':
        case 'meeting':
        default:
          // Default blue color for Conference, Meeting, or unknown types
          return meeting.type == 'confirmed'
              ? const Color(0xFF2563EB) // Blue
              : (isDark
                    ? const Color(0xFF0C4A6E).withValues(alpha: 0.4)
                    : const Color(0xFFBAE6FD));
      }
    }

    return getColorForType(normalizedType);
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

  /// Open meeting detail and fetch full details from API
  Future<void> openMeetingDetail(Meeting meeting) async {
    selectedMeeting.value = meeting;
    eventDetails.value = null;
    eventDetailsError.value = '';
    isLoadingEventDetails.value = true;

    try {
      // Extract event ID from meeting
      final eventId = int.tryParse(meeting.id);
      if (eventId == null) {
        isLoadingEventDetails.value = false;
        eventDetailsError.value = 'Invalid event ID';
        print('⚠️ [CalendarController] Invalid event ID: ${meeting.id}');
        return;
      }

      print('📅 [CalendarController] Fetching event details for ID: $eventId');

      // Fetch event details from API
      final result = await _authService.getSingleEvent(eventId: eventId);

      isLoadingEventDetails.value = false;

      if (result['success'] == true && result['data'] != null) {
        eventDetails.value = result['data'];
        print('✅ [CalendarController] Event details fetched successfully');
      } else {
        eventDetailsError.value = result['message'] ?? 'Failed to fetch event details';
        print('❌ [CalendarController] Failed to fetch event details: ${result['message']}');
      }
    } catch (e) {
      isLoadingEventDetails.value = false;
      eventDetailsError.value = 'An error occurred while fetching event details';
      print('💥 [CalendarController] Error fetching event details: $e');
    }
  }

  /// Close meeting detail
  void closeMeetingDetail() {
    selectedMeeting.value = null;
    eventDetails.value = null;
    eventDetailsError.value = '';
    isLoadingEventDetails.value = false;
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
  final int? userId; // User ID from API (for filtering "Myself" view)

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
    this.userId,
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
    userId: json['userId'] is int 
        ? json['userId'] as int 
        : int.tryParse(json['userId']?.toString() ?? ''),
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


import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:firefox_calendar/features/calendar/view/user_work_hours_modal.dart';
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
  final RxString viewType = 'month'.obs; // 'day', 'week', 'month' - Default to month
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

  // Selected work hour for detail view
  final Rx<WorkHour?> selectedWorkHour = Rx<WorkHour?>(null);

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

  // Work hours for calendar overlay (approved only)
  final RxList<WorkHour> workHours = <WorkHour>[].obs;
  final RxBool isLoadingWorkHours = false.obs;

  // User work hours details modal state
  final RxBool isLoadingUserWorkHours = false.obs;
  final RxString userWorkHoursError = ''.obs;
  final RxList<Map<String, dynamic>> userWorkHoursData = <Map<String, dynamic>>[].obs;

  // Scroll position tracking for sticky header behavior
  final RxDouble scrollOffset = 0.0.obs;
  final RxBool isDaysDatesRowSticky = false.obs;
  
  // Threshold for showing sticky header (in pixels)
  static const double stickyHeaderThreshold = 100.0;
  
  // Shared horizontal scroll controller for synchronizing header and content
  // NOTE: Kept for backward compatibility but not used with pagination
  final ScrollController horizontalScrollController = ScrollController();

  // User pagination state
  static const int usersPerPage = 2; // Number of users to show per page
  final RxInt currentUserPage = 0.obs; // Current page index (0-based)

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchAllEvents(); // Fetch events from API on init (will also fetch work hours)
  }

  @override
  void onClose() {
    horizontalScrollController.dispose();
    super.onClose();
  }

  /// Load user data from storage
  /// Called on init and when calendar screen is accessed to ensure current session data
  /// Public method to allow external calls (e.g., from CalendarScreen)
  void loadUserData() {
    final newUserEmail = storage.read('userEmail') ?? '';
    final newUserId = storage.read('userId') ?? 0;
    
    // Check if user changed before updating
    final userChanged = userEmail.value != newUserEmail || userId.value != newUserId;
    
    if (userChanged) {
      print('👤 [CalendarController] User data changed:');
      print('   Old: userId=${userId.value}, email=${userEmail.value}');
      print('   New: userId=$newUserId, email=$newUserEmail');
      
      // Clear calendar data when user changes to prevent cross-user data display
      print('🔄 [CalendarController] User changed, clearing calendar data...');
      allMeetings.clear();
      meetings.clear();
      workHours.clear();
      resetUserPage();
      
      // Update user data after clearing
      userEmail.value = newUserEmail;
      userId.value = newUserId;
    } else {
      print('👤 [CalendarController] User data unchanged:');
      print('   userId: ${userId.value}');
      print('   userEmail: ${userEmail.value}');
    }
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
        
        // Fetch and merge work hours BEFORE scope filtering
        // Work hours are now converted directly to Meeting objects in fetchWorkHours
        // and merged into allMeetings, so they go through the same filtering/grouping as events
        await fetchWorkHours();
        
        // Debug: Print all event dates
        print('📅 [CalendarController] All events dates:');
        for (var meeting in allMeetings) {
          print('   - ${meeting.title}: ${meeting.date} ${meeting.startTime} (userId: ${meeting.userId}, category: ${meeting.category ?? 'event'})');
        }
        
        // Apply scope filter to update displayed meetings (work hours included)
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
    loadUserData();
    // Fetch fresh events from API (will also fetch and merge work hours)
    await fetchAllEvents();
  }

  /// Refresh calendar data (both events and work hours)
  /// Called when work hours are created/updated to sync Calendar Screen
  Future<void> refreshCalendarData() async {
    print('🔄 [CalendarController] Refreshing calendar data...');
    await fetchAllEvents(); // Refresh events (which will also fetch and merge work hours)
    print('✅ [CalendarController] Calendar data refreshed successfully');
  }

  /// Fetch work hours from API for calendar overlay
  /// API returns user-wise grouped data: data = [{ user: {...}, hours: [...] }]
  /// Converts each approved work hour directly to Meeting with category='work_hour'
  /// Merges into allMeetings BEFORE scope filtering and date grouping
  Future<void> fetchWorkHours() async {
    try {
      isLoadingWorkHours.value = true;

      // Determine range based on view type (same as events)
      String? range;
      if (viewType.value == 'day') {
        range = 'day';
      } else if (viewType.value == 'week') {
        range = 'week';
      } else if (viewType.value == 'month') {
        range = 'month';
      }

      // Format current date as YYYY-MM-DD (same as events)
      final currentDateStr = _formatDateString(currentDate.value);

      print('═══════════════════════════════════════════════════════════');
      print('⏰ [CalendarController] Fetching work hours (user-wise grouped)...');
      print('   Range: ${range ?? 'none'}');
      print('   Current Date: $currentDateStr');
      print('   Scope: ${scopeType.value}');
      print('═══════════════════════════════════════════════════════════');

      // Fetch work hours from calendar endpoint
      final result = await _authService.getCalendarUserHours(
        range: range ?? 'week',
        currentDate: currentDateStr,
      );

      isLoadingWorkHours.value = false;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        
        // Handle new user-wise grouped structure: data = [{ user: {...}, hours: [...] }]
        List<dynamic> userHoursList;
        if (data is List) {
          userHoursList = data;
        } else if (data is Map) {
          userHoursList = [data];
        } else {
          userHoursList = [];
        }

        // Convert each user's approved work hours to Meeting objects
        final workHourMeetings = <Meeting>[];
        
        for (var userHoursData in userHoursList) {
          if (userHoursData is! Map<String, dynamic>) continue;
          
          // Extract user info
          final userData = userHoursData['user'] as Map<String, dynamic>?;
          if (userData == null) continue;
          
          final userId = userData['id'] is int 
              ? userData['id'] as int 
              : int.tryParse(userData['id']?.toString() ?? '') ?? 0;
          
          String userEmail = '';
          if (userData['email'] != null) {
            userEmail = userData['email'].toString();
          } else if (userData['first_name'] != null) {
            final firstName = userData['first_name'].toString().toLowerCase().replaceAll(' ', '');
            userEmail = '$firstName@user.com';
          }
          
          // Extract hours array
          final hoursList = userHoursData['hours'] as List<dynamic>?;
          if (hoursList == null || hoursList.isEmpty) continue;
          
          // Convert each approved work hour to Meeting
          for (var hourData in hoursList) {
            if (hourData is! Map<String, dynamic>) continue;
            
            // Only process approved work hours with both login_time and logout_time
            final status = hourData['status']?.toString().toLowerCase() ?? 'pending';
            if (status != 'approved') continue;
            
            if (hourData['login_time'] == null || hourData['logout_time'] == null) continue;
            
            // Convert work hour to Meeting
            final meeting = _convertWorkHourDataToMeeting(
              hourData: hourData,
              userId: userId,
              userEmail: userEmail,
            );
            
            if (meeting != null) {
              workHourMeetings.add(meeting);
            }
          }
        }

        // Store work hours for backward compatibility (used by getWorkHoursForUser)
        // Convert back to WorkHour objects for the old list
        workHours.value = workHourMeetings.map((meeting) {
          return _convertMeetingToWorkHour(meeting);
        }).where((hour) => hour != null).cast<WorkHour>().toList();

        print('✅ [CalendarController] Fetched ${workHourMeetings.length} approved work hours from ${userHoursList.length} users');
        
        // Remove existing work hour meetings (to avoid duplicates on re-merge)
        allMeetings.removeWhere((m) => m.id.startsWith('work_hour_'));
        
        // Merge work hours into allMeetings BEFORE filtering/grouping
        allMeetings.addAll(workHourMeetings);
        
        print('✅ [CalendarController] Merged ${workHourMeetings.length} work hours into allMeetings');
        print('   Total meetings (events + work hours): ${allMeetings.length}');
        
        // If events are already loaded, apply scope filter to update displayed meetings
        if (allMeetings.isNotEmpty) {
          _applyScopeFilter();
        }
      } else {
        print('⚠️ [CalendarController] Failed to fetch work hours: ${result['message']}');
        workHours.value = [];
        // Remove existing work hour meetings on error
        allMeetings.removeWhere((m) => m.id.startsWith('work_hour_'));
        if (allMeetings.isNotEmpty) {
          _applyScopeFilter();
        }
      }
    } catch (e) {
      isLoadingWorkHours.value = false;
      print('💥 [CalendarController] Error fetching work hours: $e');
      workHours.value = [];
      // Remove existing work hour meetings on error
      allMeetings.removeWhere((m) => m.id.startsWith('work_hour_'));
      if (allMeetings.isNotEmpty) {
        _applyScopeFilter();
      }
    }
  }

  /// Map API work hour data to WorkHour model
  WorkHour? _mapWorkHourFromApi(Map<String, dynamic> hourData) {
    try {
      // Parse date
      String formattedDate = '';
      if (hourData['work_date'] != null || hourData['date'] != null) {
        final dateStr = (hourData['work_date'] ?? hourData['date']).toString();
        try {
          String datePart = dateStr;
          if (dateStr.contains('T')) {
            datePart = dateStr.split('T')[0];
          }
          final date = DateTime.parse(datePart);
          formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          print('⚠️ [CalendarController] Error parsing work hour date: $e');
          return null;
        }
      } else {
        return null;
      }

      // Parse login_time (start time)
      String loginTime = '';
      if (hourData['login_time'] != null) {
        final loginTimeStr = hourData['login_time'].toString();
        if (loginTimeStr.contains('T')) {
          final timePart = loginTimeStr.split('T')[1].split(':');
          loginTime = '${timePart[0]}:${timePart[1]}';
        } else if (loginTimeStr.contains(' ')) {
          final timePart = loginTimeStr.split(' ')[1].split(':');
          loginTime = '${timePart[0]}:${timePart[1]}';
        } else {
          loginTime = loginTimeStr;
        }
      } else {
        return null; // Must have login time
      }

      // Parse logout_time (end time)
      String logoutTime = '';
      if (hourData['logout_time'] != null) {
        final logoutTimeStr = hourData['logout_time'].toString();
        if (logoutTimeStr.contains('T')) {
          final timePart = logoutTimeStr.split('T')[1].split(':');
          logoutTime = '${timePart[0]}:${timePart[1]}';
        } else if (logoutTimeStr.contains(' ')) {
          final timePart = logoutTimeStr.split(' ')[1].split(':');
          logoutTime = '${timePart[0]}:${timePart[1]}';
        } else {
          logoutTime = logoutTimeStr;
        }
      } else {
        return null; // Must have logout time
      }

      // Extract user information
      String userEmail = '';
      int? userId;
      
      if (hourData['user'] != null && hourData['user'] is Map) {
        final userData = hourData['user'] as Map<String, dynamic>;
        userId = userData['id'] is int 
            ? userData['id'] as int 
            : int.tryParse(userData['id']?.toString() ?? '');
        
        if (userData['email'] != null) {
          userEmail = userData['email'].toString();
        } else if (userData['first_name'] != null) {
          final firstName = userData['first_name'].toString().toLowerCase().replaceAll(' ', '');
          userEmail = '$firstName@user.com';
        }
      } else if (hourData['user_id'] != null) {
        userId = hourData['user_id'] is int 
            ? hourData['user_id'] as int 
            : int.tryParse(hourData['user_id']?.toString() ?? '');
      }

      // Extract status
      final status = hourData['status']?.toString() ?? 'pending';

      final workHour = WorkHour(
        id: hourData['id']?.toString() ?? '',
        date: formattedDate,
        loginTime: loginTime,
        logoutTime: logoutTime,
        userId: userId,
        userEmail: userEmail,
        status: status,
      );

      return workHour;
    } catch (e, stackTrace) {
      print('⚠️ [CalendarController] Error mapping work hour: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get work hours for a specific user and date
  /// Used for rendering work hours overlay in calendar grid
  /// Returns ONLY approved work hours with both login_time and logout_time
  /// Now extracts from filtered meetings (respects scope filter) for consistency
  /// 
  /// NOTE: This method should only be called from within Obx widgets.
  /// Pass meetings and userId as parameters to avoid accessing Rx values directly.
  /// 
  /// CRITICAL: Matches ONLY by the user whose column we're rendering (userEmail),
  /// NOT by the currently logged-in user (currentUserId). This prevents work hours
  /// from appearing under multiple user profiles when multiple accounts are logged in.
  List<WorkHour> getWorkHoursForUser(String userEmail, String dateStr, List<Meeting> meetingsList, int currentUserId) {
    // Extract work hours from filtered meetings (respects scope: everyone/myself)
    // This ensures work hours match the same filtering as events
    final workHourMeetings = meetingsList.where((meeting) {
      // Only work hours
      if (meeting.category != 'work_hour') return false;
      // Match by date
      if (meeting.date != dateStr) return false;
      // CRITICAL FIX: Match ONLY by the user whose column we're rendering (userEmail)
      // Do NOT use currentUserId (logged-in user) as it causes work hours to appear
      // under multiple profiles when multiple accounts are logged in on the same device
      // Each work hour belongs to exactly one user (the creator)
      return meeting.creator == userEmail;
    }).toList();
    
    // Convert meetings back to WorkHour objects for backward compatibility
    return workHourMeetings
        .map((meeting) => _convertMeetingToWorkHour(meeting))
        .where((hour) => hour != null)
        .cast<WorkHour>()
        .toList();
  }
  
  /// Legacy method - kept for backward compatibility but marked as deprecated
  /// Use getWorkHoursForUser with explicit parameters instead
  @Deprecated('Use getWorkHoursForUser with explicit meetings and userId parameters')
  List<WorkHour> getWorkHoursForUserLegacy(String userEmail, String dateStr) {
    return getWorkHoursForUser(userEmail, dateStr, meetings, userId.value);
  }

  /// Convert approved WorkHour objects to Meeting objects
  /// Merges them into allMeetings so they can be rendered using existing Meeting logic
  /// Uses category = 'work_hour' to differentiate from regular events
  void _mergeWorkHoursAsMeetings() {
    if (workHours.isEmpty) {
      // No work hours to merge
      return;
    }
    
    // Convert work hours to meetings
    final workHourMeetings = workHours.map((workHour) {
      return _convertWorkHourToMeeting(workHour);
    }).where((meeting) => meeting != null).cast<Meeting>().toList();
    
    if (workHourMeetings.isEmpty) {
      return;
    }
    
    // Remove existing work hour meetings (to avoid duplicates on re-merge)
    allMeetings.removeWhere((m) => m.id.startsWith('work_hour_'));
    
    // Add all work hour meetings
    allMeetings.addAll(workHourMeetings);
    
    print('✅ [CalendarController] Merged ${workHourMeetings.length} work hours as meetings');
    print('   Total meetings (events + work hours): ${allMeetings.length}');
  }

  /// Convert raw API work hour data directly to Meeting object
  /// Used when parsing new user-wise grouped API response
  /// Returns Meeting with category='work_hour' for approved hours only
  Meeting? _convertWorkHourDataToMeeting({
    required Map<String, dynamic> hourData,
    required int userId,
    required String userEmail,
  }) {
    try {
      // Only process approved work hours
      final status = hourData['status']?.toString().toLowerCase() ?? 'pending';
      if (status != 'approved') return null;
      
      // Parse date
      String formattedDate = '';
      if (hourData['date'] != null) {
        final dateStr = hourData['date'].toString();
        try {
          String datePart = dateStr;
          if (dateStr.contains('T')) {
            datePart = dateStr.split('T')[0];
          }
          final date = DateTime.parse(datePart);
          formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          print('⚠️ [CalendarController] Error parsing work hour date: $e');
          return null;
        }
      } else {
        return null;
      }

      // Parse login_time (start time)
      String loginTime = '';
      if (hourData['login_time'] != null) {
        final loginTimeStr = hourData['login_time'].toString();
        if (loginTimeStr.contains('T')) {
          final timePart = loginTimeStr.split('T')[1].split(':');
          loginTime = '${timePart[0]}:${timePart[1]}';
        } else if (loginTimeStr.contains(' ')) {
          final timePart = loginTimeStr.split(' ')[1].split(':');
          loginTime = '${timePart[0]}:${timePart[1]}';
        } else {
          loginTime = loginTimeStr;
        }
      } else {
        return null; // Must have login time
      }

      // Parse logout_time (end time)
      String logoutTime = '';
      if (hourData['logout_time'] != null) {
        final logoutTimeStr = hourData['logout_time'].toString();
        if (logoutTimeStr.contains('T')) {
          final timePart = logoutTimeStr.split('T')[1].split(':');
          logoutTime = '${timePart[0]}:${timePart[1]}';
        } else if (logoutTimeStr.contains(' ')) {
          final timePart = logoutTimeStr.split(' ')[1].split(':');
          logoutTime = '${timePart[0]}:${timePart[1]}';
        } else {
          logoutTime = logoutTimeStr;
        }
      } else {
        return null; // Must have logout time
      }

      // Format time for display (HH:MM format)
      String formatTime(String timeStr) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
        return timeStr;
      }

      // Use work hour ID with prefix to avoid conflicts with event IDs
      final hourId = hourData['id']?.toString() ?? '';
      if (hourId.isEmpty) return null;
      final meetingId = 'work_hour_$hourId';
      
      // Create title showing time range (e.g., "Work Hours 07:00 – 10:00")
      final formattedStart = formatTime(loginTime);
      final formattedEnd = formatTime(logoutTime);
      final title = 'Work Hours $formattedStart – $formattedEnd';

      return Meeting(
        id: meetingId,
        title: title,
        date: formattedDate,
        startTime: formatTime(loginTime),
        endTime: formatTime(logoutTime),
        primaryEventType: null,
        meetingType: null,
        type: 'confirmed', // Work hours are always confirmed/approved
        creator: userEmail,
        attendees: [userEmail],
        category: 'work_hour', // Use 'work_hour' to differentiate from regular events
        description: 'Work hours entry',
        userId: userId,
      );
    } catch (e) {
      print('⚠️ [CalendarController] Error converting work hour data to meeting: $e');
      return null;
    }
  }

  /// Convert a WorkHour object to a Meeting object
  /// Uses category = 'work_hour' to differentiate from regular events
  Meeting? _convertWorkHourToMeeting(WorkHour workHour) {
    try {
      // Calculate total hours for title
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

      // Format time for display (HH:MM format)
      String formatTime(String timeStr) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
        return timeStr;
      }

      // Use work hour ID with prefix to avoid conflicts with event IDs
      final meetingId = 'work_hour_${workHour.id}';
      
      // Create title showing time range (e.g., "Work Hours 07:00 – 10:00")
      final formattedStart = formatTime(workHour.loginTime);
      final formattedEnd = formatTime(workHour.logoutTime);
      final title = 'Work Hours $formattedStart – $formattedEnd';

      return Meeting(
        id: meetingId,
        title: title,
        date: workHour.date,
        startTime: formatTime(workHour.loginTime),
        endTime: formatTime(workHour.logoutTime),
        primaryEventType: null,
        meetingType: null,
        type: 'confirmed', // Work hours are always confirmed/approved
        creator: workHour.userEmail,
        attendees: [workHour.userEmail],
        category: 'work_hour', // Use 'work_hour' to differentiate from regular events
        description: 'Work hours entry',
        userId: workHour.userId,
      );
    } catch (e) {
      print('⚠️ [CalendarController] Error converting work hour to meeting: $e');
      return null;
    }
  }

  /// Convert a Meeting object (with category='work_hour') back to WorkHour object
  /// Used for backward compatibility with getWorkHoursForUser method
  WorkHour? _convertMeetingToWorkHour(Meeting meeting) {
    if (meeting.category != 'work_hour') return null;
    
    try {
      // Extract work hour ID from meeting ID (format: 'work_hour_123')
      final hourId = meeting.id.replaceFirst('work_hour_', '');
      if (hourId.isEmpty) return null;
      
      return WorkHour(
        id: hourId,
        date: meeting.date,
        loginTime: meeting.startTime,
        logoutTime: meeting.endTime,
        userId: meeting.userId,
        userEmail: meeting.creator,
        status: 'approved', // All work hours in calendar are approved
      );
    } catch (e) {
      print('⚠️ [CalendarController] Error converting meeting to work hour: $e');
      return null;
    }
  }

  /// Get distinct background color for work hour blocks per user
  /// Returns a soft, light color that's visually distinct per user
  /// Colors are lighter than event cards to keep events visually dominant
  Color getWorkHourColorForUser(String userEmail, bool isDark) {
    // Generate a consistent color based on user email hash
    final hash = userEmail.hashCode;
    final colors = [
      // Soft pastel colors for light mode, darker muted colors for dark mode
      isDark ? const Color(0xFF1E3A2E) : const Color(0xFFE0F2E9), // Soft green
      isDark ? const Color(0xFF2E1E3A) : const Color(0xFFF2E0F5), // Soft purple
      isDark ? const Color(0xFF3A2E1E) : const Color(0xFFF5F2E0), // Soft yellow
      isDark ? const Color(0xFF1E2E3A) : const Color(0xFFE0E8F2), // Soft blue
      isDark ? const Color(0xFF3A1E2E) : const Color(0xFFF2E0E8), // Soft pink
      isDark ? const Color(0xFF2E3A1E) : const Color(0xFFE8F2E0), // Soft lime
      isDark ? const Color(0xFF1E3A3A) : const Color(0xFFE0F2F2), // Soft cyan
      isDark ? const Color(0xFF3A1E1E) : const Color(0xFFF2E0E0), // Soft red
    ];
    
    // Use hash to select a consistent color for this user
    final colorIndex = hash.abs() % colors.length;
    final baseColor = colors[colorIndex];
    
    // Apply opacity to make it lighter (background layer)
    return baseColor.withValues(alpha: isDark ? 0.2 : 0.4);
  }

  /// Change view type (day/week/month)
  void setViewType(String type) {
    print('🔄 [CalendarController] View type changed: ${viewType.value} → $type');
    viewType.value = type;
    selectedWeekDate.value = null; // Reset date filter when changing views
    resetUserPage(); // Reset pagination when changing views
    // Refresh events with new view type
    fetchAllEvents();
    // Also refresh work hours
    fetchWorkHours();
  }

  /// Change scope type (everyone/myself)
  void setScopeType(String type) {
    print('🔄 [CalendarController] Scope changed: ${scopeType.value} → $type');
    scopeType.value = type;
    resetUserPage(); // Reset pagination when changing scope
    // Fetch events based on scope (different API endpoints)
    fetchAllEvents(); // This will use the correct endpoint based on scope
    // Also refresh work hours
    fetchWorkHours();
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
    resetUserPage(); // Reset pagination when date changes
    // Refresh events when date changes
    fetchAllEvents();
    // Also refresh work hours
    fetchWorkHours();
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
    resetUserPage(); // Reset pagination when date changes
    // Refresh events when date changes
    fetchAllEvents();
    // Also refresh work hours
    fetchWorkHours();
  }

  /// Navigate to today
  /// Jumps to today's date and applies the active filter (Day/Week/Month)
  /// Refreshes calendar data to show only users with data for today/today's week/month
  void navigateToToday() {
    final oldDate = _formatDateString(currentDate.value);
    final now = DateTime.now();
    
    // Always set to today's date, resetting time to start of day
    currentDate.value = DateTime(now.year, now.month, now.day);
    
    // Clear any week date selection
    selectedWeekDate.value = null;
    
    // Reset pagination when navigating to today
    resetUserPage();
    
    final newDateStr = _formatDateString(currentDate.value);
    
    print('═══════════════════════════════════════════════════════════');
    print('🔄 [CalendarController] Navigated to TODAY');
    print('   Old date: $oldDate');
    print('   New date: $newDateStr');
    print('   View type: ${viewType.value}');
    print('   Scope: ${scopeType.value}');
    
    // Log date range based on view type
    // Note: getCurrentWeekDates() and getMonthDates() access Rx values
    // They should only be called from within Obx widgets, not from controller methods
    // Removed calls to these methods from here to prevent GetX warnings
    final currentViewType = viewType.value;
    if (currentViewType == 'day') {
      print('   Range: Day view - showing only $newDateStr');
    } else if (currentViewType == 'week') {
      // Don't call getCurrentWeekDates() here - it accesses Rx values
      // The UI will call it from within Obx
      print('   Range: Week view');
    } else if (currentViewType == 'month') {
      // Don't call getMonthDates() here - it accesses Rx values
      // The UI will call it from within Obx
      print('   Range: Month view');
    }
    print('═══════════════════════════════════════════════════════════');
    
    // Refresh events and work hours based on current view type and today's date
    // fetchAllEvents() will automatically call fetchWorkHours() internally
    fetchAllEvents();
  }

  /// Set current date from calendar picker
  void setCurrentDate(DateTime date) {
    final oldDate = _formatDateString(currentDate.value);
    currentDate.value = date;
    isCalendarOpen.value = false;
    resetUserPage(); // Reset pagination when date changes
    final newDateStr = _formatDateString(currentDate.value);
    print('🔄 [CalendarController] Date changed via picker: $oldDate → $newDateStr');
    // Refresh events when date changes
    fetchAllEvents();
    // Also refresh work hours
    fetchWorkHours();
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
    // Reset pagination when week date selection changes
    resetUserPage();
  }

  /// Get current week dates (Monday to Sunday)
  /// For week view, this calculates the week containing the current date
  /// NOTE: This method accesses Rx values (currentDate.value) and should only be called from within Obx widgets
  List<DateTime> getCurrentWeekDates() {
    final currentDay = currentDate.value.weekday;
    // Calculate Monday of the week (weekday 1 = Monday)
    final monday = currentDate.value.subtract(Duration(days: currentDay - 1));

    // Generate 7 days from Monday to Sunday
    final weekDates = List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });
    
    // Removed debug logging that accessed viewType.value to prevent GetX warnings
    // Debug logging should be done in the calling context if needed
    
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
  /// NOTE: This method should only be called from within Obx widgets.
  /// All parameters are REQUIRED to prevent Rx value access outside Obx.
  List<Meeting> filterMeetings(
    List<Meeting> meetings, {
    required String scopeTypeParam,
    required String viewTypeParam,
    DateTime? selectedWeekDateParam,
    required int userIdParam,
    required String userEmailParam,
  }) {
    var filtered = meetings;

    // Use passed parameters only (NO fallback to Rx values to prevent GetX errors)
    final currentScopeType = scopeTypeParam;
    final currentViewType = viewTypeParam;
    final currentSelectedWeekDate = selectedWeekDateParam;
    final currentUserId = userIdParam;
    final currentUserEmail = userEmailParam;

    // Apply scope filter
    if (currentScopeType == 'myself') {
      filtered = filtered.where((m) {
        // Check by user ID (preferred method)
        if (currentUserId > 0 && m.userId != null) {
          if (m.userId == currentUserId) {
            return true;
          }
        }
        // Fallback to email check
        if (currentUserEmail.isNotEmpty) {
          return m.attendees.contains(currentUserEmail) || m.creator == currentUserEmail;
        }
        return false;
      }).toList();
    }

    // Apply week date filter (only in week view)
    if (currentViewType == 'week' && currentSelectedWeekDate != null) {
      final selectedDate = currentSelectedWeekDate;
      // Use consistent date format (YYYY-MM-DD)
      final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      filtered = filtered.where((m) => m.date == dateStr).toList();
    }

    return filtered;
  }

  /// Get meetings by date
  /// NOTE: This method should only be called from within Obx widgets.
  /// Pass meetings list as parameter to avoid accessing RxList directly.
  /// REQUIRED: meetingsList parameter must always be provided to prevent Rx access.
  Map<String, List<Meeting>> getMeetingsByDate(List<Meeting> meetingsList) {
    final result = <String, List<Meeting>>{};
    
    // Use passed list (no fallback to prevent Rx access outside Obx)
    final meetingsToProcess = meetingsList;

    print('📊 [CalendarController] Grouping ${meetingsToProcess.length} meetings by date:');
    for (var meeting in meetingsToProcess) {
      if (!result.containsKey(meeting.date)) {
        result[meeting.date] = [];
      }
      result[meeting.date]!.add(meeting);
      print('   - ${meeting.title}: date=${meeting.date}');
    }

    print('📊 [CalendarController] Meetings by date keys: ${result.keys.toList()}');
    return result;
  }

  /// Get time range - always returns full 24 hours (00:00 to 23:00)
  TimeRange getTimeRange(List<Meeting> meetings) {
    // Always return full 24-hour range
    return TimeRange(startHour: 0, endHour: 23);
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

  /// Open work hour detail (similar to openMeetingDetail)
  /// Uses same navigation pattern as events
  /// Can be called with either a WorkHour object or a Meeting object with category='work_hour'
  void openWorkHourDetail(dynamic workHourOrMeeting) {
    if (workHourOrMeeting is WorkHour) {
      selectedWorkHour.value = workHourOrMeeting;
      print('⏰ [CalendarController] Opening work hour detail for ID: ${workHourOrMeeting.id}');
    } else if (workHourOrMeeting is Meeting && workHourOrMeeting.category == 'work_hour') {
      // Extract work hour ID from meeting ID (format: 'work_hour_123')
      final workHourIdStr = workHourOrMeeting.id.replaceFirst('work_hour_', '');
      final workHourId = int.tryParse(workHourIdStr);
      if (workHourId != null) {
        WorkHour? workHour;
        try {
          workHour = workHours.firstWhere((wh) => wh.id == workHourId);
        } catch (e) {
          workHour = null;
        }
        if (workHour != null) {
          selectedWorkHour.value = workHour;
          print('⏰ [CalendarController] Opening work hour detail for ID: ${workHour.id} (from meeting)');
        } else {
          print('⚠️ [CalendarController] Work hour not found for ID: $workHourId');
        }
      }
    }
  }

  /// Close work hour detail
  void closeWorkHourDetail() {
    selectedWorkHour.value = null;
  }

  /// Handle day click in month view
  void handleDayClick(DateTime date) {
    currentDate.value = date;
    viewType.value = 'day';
  }

  // ============================================================================
  // USER PAGINATION METHODS
  // ============================================================================

  /// Get paginated users from a list
  /// Returns a subset of users for the current page
  /// NOTE: This method accesses Rx values and should only be called from within Obx widgets.
  /// For better control, use getPaginatedUsersWithPage instead.
  List<String> getPaginatedUsers(List<String> allUsers) {
    return getPaginatedUsersWithPage(allUsers, currentUserPage.value);
  }

  /// Get paginated users from a list with explicit page number
  /// Returns a subset of users for the specified page
  /// This method does NOT access Rx values, making it safe to call from anywhere.
  List<String> getPaginatedUsersWithPage(List<String> allUsers, int page) {
    if (allUsers.isEmpty) return [];
    
    final startIndex = page * usersPerPage;
    final endIndex = (startIndex + usersPerPage).clamp(0, allUsers.length);
    
    if (startIndex >= allUsers.length) {
      // If current page is beyond available users, return empty list
      // (Don't modify Rx value here - let the caller handle page reset)
      return [];
    }
    
    return allUsers.sublist(startIndex, endIndex);
  }

  /// Get paginated users by date for week view
  /// Returns a map of date -> paginated users for that date
  /// NOTE: This method accesses Rx values and should only be called from within Obx widgets.
  /// For better control, use getPaginatedUsersByDateWithPage instead.
  Map<String, List<String>> getPaginatedUsersByDate(Map<String, List<String>> usersByDate) {
    return getPaginatedUsersByDateWithPage(usersByDate, currentUserPage.value);
  }

  /// Get paginated users by date for week view with explicit page number
  /// Returns a map of date -> paginated users for that date
  /// This method does NOT access Rx values, making it safe to call from anywhere.
  Map<String, List<String>> getPaginatedUsersByDateWithPage(Map<String, List<String>> usersByDate, int page) {
    final paginatedMap = <String, List<String>>{};
    
    // Collect all unique users across all dates
    final allUniqueUsers = <String>{};
    for (var users in usersByDate.values) {
      allUniqueUsers.addAll(users);
    }
    final sortedUsers = allUniqueUsers.toList()..sort();
    
    // Get paginated users with explicit page
    final paginatedUsers = getPaginatedUsersWithPage(sortedUsers, page);
    
    // Filter usersByDate to only include paginated users
    for (var entry in usersByDate.entries) {
      final dateStr = entry.key;
      final dayUsers = entry.value;
      final filteredUsers = dayUsers.where((user) => paginatedUsers.contains(user)).toList();
      if (filteredUsers.isNotEmpty) {
        paginatedMap[dateStr] = filteredUsers;
      }
    }
    
    return paginatedMap;
  }

  /// Navigate to next page of users
  void nextUserPage(List<String> allUsers) {
    final totalPages = ((allUsers.length - 1) / usersPerPage).floor() + 1;
    if (currentUserPage.value < totalPages - 1) {
      currentUserPage.value++;
      print('📄 [CalendarController] Next page: ${currentUserPage.value + 1}/$totalPages');
    }
  }

  /// Navigate to previous page of users
  void previousUserPage() {
    if (currentUserPage.value > 0) {
      currentUserPage.value--;
      print('📄 [CalendarController] Previous page: ${currentUserPage.value + 1}');
    }
  }

  /// Check if can navigate to next page
  /// NOTE: This method accesses Rx values and should only be called from within Obx widgets.
  /// For better control, use canGoToNextPageWithPage instead.
  bool canGoToNextPage(List<String> allUsers) {
    return canGoToNextPageWithPage(allUsers, currentUserPage.value);
  }

  /// Check if can navigate to next page with explicit page number
  /// This method does NOT access Rx values, making it safe to call from anywhere.
  bool canGoToNextPageWithPage(List<String> allUsers, int page) {
    if (allUsers.isEmpty) return false;
    final totalPages = ((allUsers.length - 1) / usersPerPage).floor() + 1;
    return page < totalPages - 1;
  }

  /// Check if can navigate to previous page
  /// NOTE: This method accesses Rx values and should only be called from within Obx widgets.
  /// For better control, use canGoToPreviousPageWithPage instead.
  bool canGoToPreviousPage() {
    return canGoToPreviousPageWithPage(currentUserPage.value);
  }

  /// Check if can navigate to previous page with explicit page number
  /// This method does NOT access Rx values, making it safe to call from anywhere.
  bool canGoToPreviousPageWithPage(int page) {
    return page > 0;
  }

  /// Reset pagination to first page
  /// Called when view type, scope, or date changes
  void resetUserPage() {
    currentUserPage.value = 0;
  }

  /// Fetch work hours for a specific user based on current view type
  /// Used for user work hours details modal
  Future<void> fetchUserWorkHours({
    required String userEmail,
    required String viewType,
    required DateTime selectedDate,
  }) async {
    try {
      isLoadingUserWorkHours.value = true;
      userWorkHoursError.value = '';

      // Determine range based on view type
      String range;
      if (viewType == 'day') {
        range = 'day';
      } else if (viewType == 'week') {
        range = 'week';
      } else if (viewType == 'month') {
        range = 'month';
      } else {
        range = 'week';
      }

      // Format current date as YYYY-MM-DD
      final currentDateStr = _formatDateString(selectedDate);

      print('═══════════════════════════════════════════════════════════');
      print('🔵 [CalendarController] Fetching user work hours...');
      print('   User: $userEmail');
      print('   Range: $range');
      print('   Current Date: $currentDateStr');
      print('═══════════════════════════════════════════════════════════');

      // Fetch work hours from API
      final result = await _authService.getUserHours(
        range: range,
        currentDate: currentDateStr,
      );

      isLoadingUserWorkHours.value = false;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        List<Map<String, dynamic>> allHours = [];

        if (data is List) {
          allHours = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          allHours = [Map<String, dynamic>.from(data)];
        }

        // Filter to only the clicked user's work hours (not the logged-in user)
        // The API returns a flat list of work hours entries
        // Match by email pattern (construct from first_name if needed)
        // This matches the logic used in calendar work hours display
        final userHours = allHours.where((entry) {
          // Try to match by email pattern (construct from first_name if needed)
          // This matches the logic used in calendar work hours
          if (entry['user'] != null && entry['user'] is Map) {
            final userData = entry['user'] as Map<String, dynamic>;
            final entryEmail = userData['email']?.toString() ?? '';
            
            // Direct email match
            if (entryEmail.isNotEmpty && entryEmail == userEmail) {
              return true;
            }
            
            // Try to construct email from first_name if email not available
            if (entryEmail.isEmpty && userData['first_name'] != null) {
              final firstName = userData['first_name'].toString().toLowerCase().replaceAll(' ', '');
              final constructedEmail = '$firstName@user.com';
              if (constructedEmail == userEmail) {
                return true;
              }
            }
          }
          
          // Fallback: check user_id if we can match it (but we only have email)
          // For now, we rely on email matching above
          return false;
        }).toList();

        userWorkHoursData.value = userHours;
        print('✅ [CalendarController] Fetched ${userHours.length} work hours for $userEmail');
      } else {
        userWorkHoursError.value = result['message'] ?? 'Failed to fetch work hours';
        userWorkHoursData.value = [];
        print('❌ [CalendarController] Failed to fetch user work hours: ${result['message']}');
      }
    } catch (e) {
      isLoadingUserWorkHours.value = false;
      userWorkHoursError.value = 'An error occurred: $e';
      userWorkHoursData.value = [];
      print('💥 [CalendarController] Error fetching user work hours: $e');
    }
  }

  /// Show user work hours modal
  /// Opens modal with work hours details for the specified user
  void showUserWorkHoursModal({
    required String userEmail,
    required String viewType,
    required DateTime selectedDate,
    required bool isDark,
  }) {
    // Fetch work hours first
    fetchUserWorkHours(
      userEmail: userEmail,
      viewType: viewType,
      selectedDate: selectedDate,
    ).then((_) {
      // Show modal after data is loaded
      Get.dialog(
        UserWorkHoursModal(
          userEmail: userEmail,
          viewType: viewType,
          selectedDate: selectedDate,
          isDark: isDark,
        ),
        barrierDismissible: true,
      );
    });
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

/// Work Hour Model for Calendar Overlay
/// Represents approved work hours to display as background blocks
class WorkHour {
  final String id;
  final String date; // YYYY-MM-DD format
  final String loginTime; // HH:MM format (start time)
  final String logoutTime; // HH:MM format (end time)
  final int? userId; // User ID from API
  final String userEmail; // User email for matching
  final String status; // 'approved', 'pending', 'rejected'

  WorkHour({
    required this.id,
    required this.date,
    required this.loginTime,
    required this.logoutTime,
    this.userId,
    required this.userEmail,
    required this.status,
  });
}

import 'package:firefox_calendar/services/auth_service.dart';
import 'package:firefox_calendar/features/hours/controller/hours_controller.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


/// Dashboard Controller
/// 
/// RESPONSIBILITY: Summary View (Read-Only)
/// =========================================
/// - Fetches backend summary (POST /api/dashboard/summary)
/// - Displays aggregated totals from backend
/// - NO approval/pending badges (summary only)
/// - NO frontend calculations
/// - NO status inference
/// - Accepts backend summary as source of truth
/// 
/// DIFFERENCE FROM HOURS SCREEN:
/// - Dashboard = Summary totals (backend-calculated, read-only)
/// - Hours Screen = Detailed entries (with status badges, per-entry view)
/// - Dashboard totals may differ from Hours screen totals (this is expected)
/// - Dashboard shows aggregated summary, Hours shows individual entries
/// 
/// Manages dashboard state, user data, metrics, and events
class DashboardController extends GetxController {
  // Storage and services
  final storage = GetStorage();
  final AuthService _authService = AuthService();

  // User data (observable)
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userProfilePicture = ''.obs;

  // Loading states
  final RxBool isLogoutLoading = false.obs;
  final RxBool isStartTimeLoading = false.obs;
  final RxBool isEndTimeLoading = false.obs;

  // Start/End time state
  final RxString startTime = ''.obs; // Format: "2025-12-17 09:00:00"
  final RxString endTime = ''.obs; // Format: "2025-12-17 18:00:00"
  final RxString workDate = ''.obs; // Format: "2025-12-17"
  final RxString activeSessionId = ''.obs; // Store the ID of the active session

  // Metrics (observable) - Read-only values from API
  // Backend API Response Format:
  // {
  //   "status": true,
  //   "data": {
  //     "hours_today": number,                → hoursToday (displayed as "Hours Today")
  //     "hours_this_week": number,           → hoursThisWeek (displayed as "Hours This Week")
  //     "event_this_week": number,            → eventsThisWeek (displayed as "Events This Week")
  //     "leave_application_this_week": number → leaveThisWeek (displayed as "Leave This Week")
  //   }
  // }
  // All values come from API - no hard-coded defaults
  final RxString hoursToday = '0'.obs;        // Maps from backend: hours_today
  final RxString hoursThisWeek = '0'.obs;     // Maps from backend: hours_this_week
  final RxString eventsThisWeek = '0'.obs;    // Maps from backend: event_this_week
  final RxString leaveThisWeek = '0'.obs;     // Maps from backend: leave_application_this_week
  
  // Loading state for dashboard summary
  final RxBool isLoadingSummary = false.obs;

  // Next event
  final Rx<Meeting?> nextMeeting = Rx<Meeting?>(null);
  final RxString countdown = ''.obs;

  // Modals state
  final RxBool showCreateMeeting = false.obs;
  final RxBool showManualTimeEntry = false.obs;

  // Navigation index
  final RxInt currentNavIndex = 2.obs; // Dashboard is index 2

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadStartEndTimeStatus();
    _loadMockMeetings();
    _startCountdownTimer();
    // Fetch dashboard summary from API (approved hours only)
    fetchDashboardSummary();
  }

  /// Load user data from storage
  void _loadUserData() {
    userName.value = storage.read('userName') ?? 'User';
    userEmail.value = storage.read('userEmail') ?? '';
    userPhone.value = storage.read('userPhone') ?? '';
    userProfilePicture.value = storage.read('userProfilePicture') ?? '';
  }

  /// Load start/end time status from local storage
  void _loadStartEndTimeStatus() {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    workDate.value = todayStr;
    
    final timeData = storage.read('workTime_${userEmail.value}_$todayStr');
    
    if (timeData != null) {
      startTime.value = timeData['startTime'] ?? '';
      endTime.value = timeData['endTime'] ?? '';
      activeSessionId.value = timeData['sessionId'] ?? '';
      final storedStatus = timeData['status'] ?? '';
      
      // Check if there's an active (pending) session for today
      if (startTime.value.isNotEmpty && 
          endTime.value.isEmpty && 
          (storedStatus == 'pending' || storedStatus.isEmpty)) {
        // Active pending session exists
        print('📅 [DashboardController] Pending entry found for today: ${startTime.value}');
        print('   Entry ID: ${activeSessionId.value}');
        print('   Status: $storedStatus');
      }
    }
  }

  /// Check if a pending work-hours entry exists for today
  /// CRITICAL: Prevents duplicate entries by checking both state and storage
  /// Returns true if:
  /// - A pending entry exists in storage for today (status="pending" AND logout_time is empty/null)
  /// - OR state indicates active session (startTime set, endTime empty, activeSessionId exists)
  /// 
  /// This ensures:
  /// - START can only create ONE entry per day
  /// - END can only update existing pending entry
  /// - No duplicates are created even if state is cleared
  bool get hasPendingEntryToday {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    // CRITICAL: Check storage first - this is the source of truth
    // Even if state is cleared, storage will have the entry
    final timeData = storage.read('workTime_${userEmail.value}_$todayStr');
    if (timeData != null) {
      final storedStartTime = timeData['startTime'] ?? '';
      final storedEndTime = timeData['endTime'] ?? '';
      final storedSessionId = timeData['sessionId'] ?? '';
      final storedStatus = timeData['status'] ?? '';
      final storedDate = timeData['date'] ?? '';
      
      // Check if this is for today
      if (storedDate == todayStr) {
        // A pending entry exists if:
        // 1. Has startTime (entry was created)
        // 2. Has sessionId (entry ID exists)
        // 3. endTime is empty/null (not completed)
        // 4. Status is "pending" or empty (defaults to pending)
        final isPending = storedStartTime.isNotEmpty &&
                         storedSessionId.isNotEmpty &&
                         (storedEndTime.isEmpty || storedEndTime == null) &&
                         (storedStatus == 'pending' || storedStatus.isEmpty);
        
        if (isPending) {
          // Sync state from storage if state is empty
          if (startTime.value.isEmpty || activeSessionId.value.isEmpty) {
            startTime.value = storedStartTime;
            activeSessionId.value = storedSessionId;
            workDate.value = storedDate;
            endTime.value = '';
          }
          return true;
        }
      }
    }
    
    // Fallback: Check state if storage check didn't find anything
    // This handles the case where entry was just created but not yet saved to storage
    if (workDate.value == todayStr) {
      final hasActiveSession = startTime.value.isNotEmpty && 
                              endTime.value.isEmpty && 
                              activeSessionId.value.isNotEmpty;
      return hasActiveSession;
    }
    
    return false;
  }

  /// Handle START button click
  /// CRITICAL FIX: Prevents duplicate entries by enforcing strict checks
  /// Rules:
  /// - START must call CREATE API only once per day
  /// - Check if a pending work-hours entry already exists for today (in storage OR state)
  /// - If pending entry exists, DO NOTHING and prevent duplicate creation
  /// - If no pending entry exists:
  ///   - Call CREATE user hours API (ONLY ONCE per day)
  ///   - Send title = "Work Day", date = today, login_time = current datetime
  ///   - status must always be "pending"
  /// - Save the returned entry ID in controller state and local storage
  /// - Only ONE pending entry allowed per day
  Future<void> setStartTime() async {
    // Prevent multiple simultaneous calls
    if (isStartTimeLoading.value) {
      print('⚠️ [DashboardController] START already in progress, ignoring duplicate call');
      return;
    }

    // CRITICAL: Check if a pending entry already exists for today
    // This check uses storage as source of truth to prevent duplicates
    // Even if state is cleared, storage will have the entry
    if (hasPendingEntryToday) {
      print('⚠️ [DashboardController] Pending entry already exists for today - PREVENTING DUPLICATE');
      print('   Entry ID: ${activeSessionId.value}');
      print('   Start Time: ${startTime.value}');
      print('   ⛔ CREATE API will NOT be called - duplicate prevented');
      
      Get.snackbar(
        'Warning',
        'A pending work session already exists for today. Please end the current session first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      isStartTimeLoading.value = true;

      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final currentDateTime = now.toIso8601String().split('.')[0]; // Format: "2025-12-17T09:00:00"
      final loginTime = currentDateTime.replaceAll('T', ' '); // Format: "2025-12-17 09:00:00"

      print('🟢 [DashboardController] Creating new work hours entry');
      print('   Title: Work Day');
      print('   Date: $todayStr');
      print('   Login Time: $loginTime');
      print('   Status: pending');

      // Call CREATE user hours API
      // Send: title = "Work Day", date = today, login_time = current datetime
      // CRITICAL: Status is ALWAYS "pending" - frontend NEVER sets "approved"
      // Backend will auto-approve when both login_time and logout_time are set
      final result = await _authService.createUserHours(
        title: 'Work Day',
        date: todayStr,
        loginTime: loginTime,
        logoutTime: null, // Not sent at this stage (set later via UPDATE)
        totalHours: null, // Backend calculates this
        status: 'pending', // ALWAYS pending - backend handles approval
      );

      if (result['success'] == true) {
        // Extract entry ID from response and save in controller state
        final sessionData = result['data'];
        if (sessionData != null && sessionData['id'] != null) {
          activeSessionId.value = sessionData['id'].toString();
          print('✅ [DashboardController] Entry ID saved: ${activeSessionId.value}');
        }

        // Update local state
        startTime.value = loginTime;
        workDate.value = todayStr;
        endTime.value = ''; // Clear end time for new session

        // Save entry ID and session data to local storage
        await storage.write('workTime_${userEmail.value}_$todayStr', {
          'startTime': loginTime,
          'endTime': '',
          'date': todayStr,
          'sessionId': activeSessionId.value,
          'status': 'pending', // Status must always be "pending"
        });
        
        print('✅ [DashboardController] Session data saved to local storage');

        // Reflect backend response in UI
        final responseData = result['data'];
        final entryStatus = responseData != null ? (responseData['status'] ?? 'pending') : 'pending';
        
        Get.snackbar(
          'Success',
          result['message'] ?? 'Start time recorded: ${loginTime.split(' ')[1]}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
        
        print('✅ [DashboardController] Backend response reflected in UI');
        print('   Entry Status: $entryStatus');
        
        // Refresh dashboard summary after creating work hours entry
        // This ensures summary reflects latest approved hours totals
        await refreshDashboardSummary();
        
        // ============================================================
        // AUTO-REFRESH HOURS SCREEN
        // ============================================================
        // After successful START API call, refresh Hours screen data
        // This ensures Hours screen UI updates immediately without manual refresh
        // Uses GetX controller access to trigger HoursController refresh
        try {
          if (Get.isRegistered<HoursController>()) {
            final hoursController = Get.find<HoursController>();
            print('🔄 [DashboardController] Refreshing Hours screen after START...');
            await hoursController.refreshWorkLogs();
            print('✅ [DashboardController] Hours screen refreshed successfully');
          } else {
            print('⚠️ [DashboardController] HoursController not registered yet - will refresh when Hours screen opens');
          }
        } catch (e) {
          print('⚠️ [DashboardController] Could not refresh Hours screen: $e');
          // Non-critical error - Hours screen will refresh when opened
        }
        
        // ============================================================
        // AUTO-REFRESH CALENDAR SCREEN & START REAL-TIME TRACKING
        // ============================================================
        // After successful START API call, refresh Calendar screen data
        // This ensures Calendar screen UI updates immediately without manual refresh
        // Uses GetX controller access to trigger CalendarController refresh
        // Also starts real-time work tracking highlighting
        try {
          if (Get.isRegistered<CalendarController>()) {
            final calendarController = Get.find<CalendarController>();
            print('🔄 [DashboardController] Refreshing Calendar screen after START...');
            await calendarController.refreshCalendarData();
            
            // Start real-time work tracking in calendar
            calendarController.startWorkSession(now);
            print('🟢 [DashboardController] Real-time work tracking started in calendar');
            
            print('✅ [DashboardController] Calendar screen refreshed successfully');
          } else {
            print('⚠️ [DashboardController] CalendarController not registered yet - will refresh when Calendar screen opens');
          }
        } catch (e) {
          print('⚠️ [DashboardController] Could not refresh Calendar screen: $e');
          // Non-critical error - Calendar screen will refresh when opened
        }
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to record start time',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error setting start time: $e');
      Get.snackbar(
        'Error',
        'Failed to set start time: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isStartTimeLoading.value = false;
    }
  }

  /// Handle END button click
  /// CRITICAL FIX: END must NEVER call CREATE API - only UPDATE
  /// Rules:
  /// - END button should only work if a pending work-hours entry exists
  /// - On END button click:
  ///   - Call UPDATE user hours API (NEVER CREATE)
  ///   - Send the SAME pending entry ID and logout_time = current datetime
  ///   - DO NOT call create API again - this prevents duplicates
  ///   - Update the same row in backend
  /// - After successful update:
  ///   - Keep status as "pending"
  ///   - Clear local "active session" state (allows new START next day)
  ///   - Disable END button
  /// - Only ONE pending entry allowed per day
  Future<void> setEndTime() async {
    // Prevent multiple simultaneous calls
    if (isEndTimeLoading.value) {
      print('⚠️ [DashboardController] END already in progress, ignoring duplicate call');
      return;
    }

    // CRITICAL: END button should only work if a pending work-hours entry exists
    // This prevents calling UPDATE on non-existent entries
    if (!hasPendingEntryToday) {
      print('⚠️ [DashboardController] No pending entry found - END cannot proceed');
      Get.snackbar(
        'Warning',
        'No pending work session found for today. Please start a session first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // CRITICAL: Must have active session ID to update
    // Without ID, we cannot update - this prevents errors
    if (activeSessionId.value.isEmpty) {
      print('❌ [DashboardController] No active session ID found - cannot update');
      Get.snackbar(
        'Error',
        'No active session ID found. Cannot update entry.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      isEndTimeLoading.value = true;

      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final currentDateTime = now.toIso8601String().split('.')[0]; // Format: "2025-12-17T18:00:00"
      final logoutTime = currentDateTime.replaceAll('T', ' '); // Format: "2025-12-17 18:00:00"

      print('🔴 [DashboardController] Updating work hours entry');
      print('   Entry ID: ${activeSessionId.value}');
      print('   Logout Time: $logoutTime');
      print('   Status: pending (remains pending)');
      print('   ⚠️ CRITICAL: Calling UPDATE API (NOT CREATE) to prevent duplicates');

      // CRITICAL: Call UPDATE user hours API (NEVER CREATE)
      // Send the SAME pending entry ID and logout_time = current datetime
      // DO NOT call create API again - this prevents duplicate rows
      // Update the same row in backend
      // 
      // AUTO-APPROVAL NOTE:
      // - After logout_time is set, backend will auto-approve this entry
      // - Auto-approval happens in dashboard summary API or scheduled job
      // - Frontend NEVER sets "approved" status - backend handles this
      final result = await _authService.updateUserHours(
        id: activeSessionId.value, // Same pending entry ID from START
        logoutTime: logoutTime, // Current datetime
        // Do NOT send title, date, loginTime, or status
        // - title/date/loginTime: unchanged
        // - status: backend handles approval automatically
        // This ensures we update the existing entry, not create a new one
      );

      if (result['success'] == true) {
        // Extract updated data from response
        final responseData = result['data'];
        final entryStatus = responseData != null ? (responseData['status'] ?? 'pending') : 'pending';
        final entryId = responseData != null ? (responseData['id']?.toString() ?? '') : '';
        
        print('✅ [DashboardController] Entry updated successfully');
        print('   Entry ID: $entryId');
        print('   Status: $entryStatus (remains pending)');
        print('   Logout Time: $logoutTime');

        // Update local state with logout time
        endTime.value = logoutTime;

        // Update local storage with logout time
        // Keep status as "pending" (as per requirements)
        await storage.write('workTime_${userEmail.value}_$todayStr', {
          'startTime': startTime.value,
          'endTime': logoutTime,
          'date': todayStr,
          'sessionId': activeSessionId.value,
          'status': 'pending', // Status remains "pending" after update
        });

        // Clear local "active session" state
        // This disables the END button and allows a new START
        // Note: We keep the data in storage for history, but clear the "active" state
        startTime.value = '';
        endTime.value = '';
        activeSessionId.value = '';
        workDate.value = '';

        print('✅ [DashboardController] Active session state cleared');
        print('   END button will now be disabled');

        // Refresh dashboard summary after updating work hours entry
        // This ensures summary reflects latest approved hours totals
        await refreshDashboardSummary();
        
        // ============================================================
        // AUTO-REFRESH HOURS SCREEN
        // ============================================================
        // After successful END API call, refresh Hours screen data
        // This ensures Hours screen UI updates immediately without manual refresh
        // Uses GetX controller access to trigger HoursController refresh
        try {
          if (Get.isRegistered<HoursController>()) {
            final hoursController = Get.find<HoursController>();
            print('🔄 [DashboardController] Refreshing Hours screen after END...');
            await hoursController.refreshWorkLogs();
            print('✅ [DashboardController] Hours screen refreshed successfully');
          } else {
            print('⚠️ [DashboardController] HoursController not registered yet - will refresh when Hours screen opens');
          }
        } catch (e) {
          print('⚠️ [DashboardController] Could not refresh Hours screen: $e');
          // Non-critical error - Hours screen will refresh when opened
        }
        
        // ============================================================
        // AUTO-REFRESH CALENDAR SCREEN & STOP REAL-TIME TRACKING
        // ============================================================
        // After successful END API call, refresh Calendar screen data
        // This ensures Calendar screen UI updates immediately without manual refresh
        // Uses GetX controller access to trigger CalendarController refresh
        // Also stops real-time work tracking highlighting (fixes the highlight)
        try {
          if (Get.isRegistered<CalendarController>()) {
            final calendarController = Get.find<CalendarController>();
            print('🔄 [DashboardController] Refreshing Calendar screen after END...');
            await calendarController.refreshCalendarData();
            
            // Stop real-time work tracking in calendar (fixes the highlight)
            calendarController.stopWorkSession(now);
            print('🔴 [DashboardController] Real-time work tracking stopped in calendar');
            
            print('✅ [DashboardController] Calendar screen refreshed successfully');
          } else {
            print('⚠️ [DashboardController] CalendarController not registered yet - will refresh when Calendar screen opens');
          }
        } catch (e) {
          print('⚠️ [DashboardController] Could not refresh Calendar screen: $e');
          // Non-critical error - Calendar screen will refresh when opened
        }

        Get.snackbar(
          'Success',
          result['message'] ?? 'Work hours completed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to update end time',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error setting end time: $e');
      Get.snackbar(
        'Error',
        'Failed to set end time: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isEndTimeLoading.value = false;
    }
  }

  /// Enhanced logout with API call
  Future<void> handleLogout() async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Set loading state
      isLogoutLoading.value = true;

      // Call logout API
      final result = await _authService.logoutUser();

      if (result['success'] == true) {
        // Clear user session data
        await _authService.clearUserSession();

        // Show success message
        Get.snackbar(
          'Success',
          result['message'] ?? 'Logout successful',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );

        // Navigate to login
        Get.offAllNamed('/login');
      } else {
        // API call failed but still logout locally
        await _authService.clearUserSession();

        Get.snackbar(
          'Warning',
          '${result['message']} - Logged out locally',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 3),
        );

        // Navigate to login
        Get.offAllNamed('/login');
      }
    } catch (e) {
      print('Error during logout: $e');
      
      // Even if API fails, logout locally
      await _authService.clearUserSession();
      
      Get.snackbar(
        'Error',
        'Logout failed but logged out locally',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      );

      // Navigate to login
      Get.offAllNamed('/login');
    } finally {
      isLogoutLoading.value = false;
    }
  }

  /// Load mock meetings (replace with actual API call)
  void _loadMockMeetings() {
    // Mock data - replace with actual API call
    final mockMeetings = [
      Meeting(
        id: '1',
        title: 'Team Standup',
        date: DateTime.now().add(const Duration(hours: 2)).toIso8601String().split('T')[0],
        startTime: '10:00',
        endTime: '10:30',
        primaryEventType: 'Meeting',
        meetingType: 'team-meeting',
      ),
      Meeting(
        id: '2',
        title: 'Client Meeting',
        date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
        startTime: '14:00',
        endTime: '15:00',
        primaryEventType: 'Meeting',
        meetingType: 'client-meeting',
      ),
    ];

    // Find next upcoming meeting
    final now = DateTime.now();
    final upcoming = mockMeetings.where((m) {
      final meetingDateTime = DateTime.parse('${m.date}T${m.startTime}:00');
      return meetingDateTime.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.parse('${a.date}T${a.startTime}:00');
        final dateB = DateTime.parse('${b.date}T${b.startTime}:00');
        return dateA.compareTo(dateB);
      });

    if (upcoming.isNotEmpty) {
      nextMeeting.value = upcoming.first;
    }
  }

  /// Start countdown timer for next meeting
  void _startCountdownTimer() {
    // Update countdown every second
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (nextMeeting.value == null) return;

      final now = DateTime.now();
      final meetingTime = DateTime.parse(
        '${nextMeeting.value!.date}T${nextMeeting.value!.startTime}:00',
      );
      final diff = meetingTime.difference(now);

      if (diff.isNegative) {
        countdown.value = 'Event started';
        return;
      }

      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;

      if (days > 0) {
        countdown.value = '${days}d ${hours}h ${minutes}m';
      } else if (hours > 0) {
        countdown.value = '${hours}h ${minutes}m ${seconds}s';
      } else {
        countdown.value = '${minutes}m ${seconds}s';
      }
    });
  }

  /// Navigate to different pages
  void navigateTo(int index) {
    currentNavIndex.value = index;
    
    switch (index) {
      case 0:
        Get.toNamed('/calendar');
        break;
      case 1:
        Get.toNamed('/hours');
        break;
      case 2:
        Get.toNamed('/dashboard');
        break;
      case 3:
        Get.toNamed('/payroll');
        break;
      case 4:
        Get.toNamed('/settings');
        break;
    }
  }

  /// Open create meeting modal
  void openCreateMeetingModal() {
    showCreateMeeting.value = true;
  }

  /// Close create meeting modal
  void closeCreateMeetingModal() {
    showCreateMeeting.value = false;
  }

  /// Open manual time entry modal
  void openManualTimeEntryModal() {
    showManualTimeEntry.value = true;
  }

  /// Close manual time entry modal
  void closeManualTimeEntryModal() {
    showManualTimeEntry.value = false;
  }

  /// Reusable method to create complete work hours entry
  /// Can be used by Dashboard buttons and Hours screen
  /// Creates entry with title, date, login_time, logout_time, and status "pending"
  Future<Map<String, dynamic>> createCompleteWorkHoursEntry({
    required String title,
    required String date,
    required String loginTime,
    required String logoutTime,
  }) async {
    print('═══════════════════════════════════════════════════════════');
    print('📝 [DashboardController] Creating complete work hours entry');
    print('   Title: $title');
    print('   Date: $date');
    print('   Login Time: $loginTime');
    print('   Logout Time: $logoutTime');
    print('   Status: pending');
    print('═══════════════════════════════════════════════════════════');

    final result = await _authService.createUserHours(
      title: title,
      date: date,
      loginTime: loginTime,
      logoutTime: logoutTime,
      totalHours: null, // Backend will calculate
      status: 'pending', // Status remains "pending" after creation
    );

    if (result['success'] == true) {
      final sessionData = result['data'];
      if (sessionData != null) {
        print('✅ [DashboardController] Complete entry created successfully');
        print('   Entry ID: ${sessionData['id']}');
        print('   Status: ${sessionData['status'] ?? 'pending'}');
        print('═══════════════════════════════════════════════════════════');
      }
    }

    return result;
  }

  // =========================================================
  // DASHBOARD SUMMARY API INTEGRATION
  // =========================================================

  /// Fetch dashboard summary from API
  /// 
  /// Backend API: POST /api/dashboard/summary
  /// 
  /// Backend Response Format:
  /// {
  ///   "status": true,
  ///   "data": {
  ///     "hours_today": number,                // Maps to "Hours Today"
  ///     "hours_this_week": number,            // Maps to "Hours This Week"
  ///     "event_this_week": number,            // Maps to "Events This Week"
  ///     "leave_application_this_week": number // Maps to "Leave This Week"
  ///   }
  /// }
  /// 
  /// =========================================================
  /// CRITICAL: SEPARATION OF RESPONSIBILITIES
  /// =========================================================
  /// 
  /// DASHBOARD SCREEN (This Controller):
  /// - Purpose: Summary view only (read-only)
  /// - Data Source: Backend summary API (POST /api/dashboard/summary)
  /// - Display: Aggregated totals from backend
  /// - NO approval/pending badges (summary only)
  /// - NO frontend calculations
  /// - NO status inference
  /// - Accepts backend summary as source of truth
  /// 
  /// HOURS SCREEN (HoursController):
  /// - Purpose: Detailed per-day breakdown
  /// - Data Source: Backend detailed API (GET /api/all/user_hours)
  /// - Display: Individual entries with status badges
  /// - Shows approved/pending badges (detailed view)
  /// - Shows delete buttons for pending entries
  /// - Per-entry status display
  /// 
  /// WHY TOTALS MAY DIFFER:
  /// - Dashboard shows backend-calculated summary (may include auto-approval logic)
  /// - Hours screen shows individual entries (may include pending entries)
  /// - Backend summary calculation may differ from frontend sum of entries
  /// - This is EXPECTED and ACCEPTABLE - backend summary is source of truth
  /// - Do NOT try to match totals - they serve different purposes
  /// 
  /// IMPORTANT RULES:
  /// - Frontend must ONLY read and display data (read-only)
  /// - NO calculations on frontend - trust backend values
  /// - NO approval logic inference on frontend
  /// - Default to 0 if any field is missing
  /// - Parse response safely with null checks
  /// - Map backend fields correctly to UI labels:
  ///   - hours_today → hoursToday → "Hours Today"
  ///   - hours_this_week → hoursThisWeek → "Hours This Week"
  ///   - event_this_week → eventsThisWeek → "Events This Week"
  ///   - leave_application_this_week → leaveThisWeek → "Leave This Week"
  Future<void> fetchDashboardSummary() async {
    if (isLoadingSummary.value) return;

    try {
      isLoadingSummary.value = true;
      print('🔄 [DashboardController] Fetching dashboard summary from API');
      print('   📋 Backend Response Format:');
      print('      - hours_today → "Hours Today"');
      print('      - hours_this_week → "Hours This Week"');
      print('      - event_this_week → "Events This Week"');
      print('      - leave_application_this_week → "Leave This Week"');
      print('   ⚠️ IMPORTANT: Read-only display - no calculations on frontend');

      // Call API to get dashboard summary
      final result = await _authService.getDashboardSummary();

      if (result['success'] == true) {
        final summaryData = result['data'] as Map<String, dynamic>?;
        
        if (summaryData != null) {
          // CRITICAL: Parse response safely with null checks
          // CRITICAL: Do NOT recalculate - use backend values directly
          // CRITICAL: Default to 0 if any field is missing
          // CRITICAL: No approval logic inference - backend summary is source of truth
          
          // Map: hours_today → hoursToday → "Hours Today"
          // Backend calculates this - we only display it
          final hoursTodayValue = summaryData['hours_today'];
          hoursToday.value = _formatHours(hoursTodayValue);
          
          // Map: hours_this_week → hoursThisWeek → "Hours This Week"
          // Backend calculates this - we only display it
          final hoursThisWeekValue = summaryData['hours_this_week'];
          hoursThisWeek.value = _formatHours(hoursThisWeekValue);
          
          // Map: event_this_week → eventsThisWeek → "Events This Week"
          // Backend calculates this - we only display it
          final eventThisWeekValue = summaryData['event_this_week'];
          eventsThisWeek.value = (eventThisWeekValue ?? 0).toString();
          
          // Map: leave_application_this_week → leaveThisWeek → "Leave This Week"
          // Backend calculates this - we only display it
          final leaveApplicationThisWeekValue = summaryData['leave_application_this_week'];
          leaveThisWeek.value = (leaveApplicationThisWeekValue ?? 0).toString();

          print('✅ [DashboardController] Dashboard summary updated (READ-ONLY):');
          print('   hours_today: $hoursTodayValue → Hours Today: ${hoursToday.value}');
          print('   hours_this_week: $hoursThisWeekValue → Hours This Week: ${hoursThisWeek.value}');
          print('   event_this_week: $eventThisWeekValue → Events This Week: ${eventsThisWeek.value}');
          print('   leave_application_this_week: $leaveApplicationThisWeekValue → Leave This Week: ${leaveThisWeek.value}');
          print('   ⚠️ NOTE: Dashboard totals may differ from Hours screen - this is expected');
          print('   ⚠️ Dashboard = summary (backend-calculated), Hours = detailed (per-entry)');
        } else {
          print('⚠️ [DashboardController] No summary data in API response - using defaults (0)');
          // Reset to defaults if no data
          hoursToday.value = '0';
          hoursThisWeek.value = '0';
          eventsThisWeek.value = '0';
          leaveThisWeek.value = '0';
        }
      } else {
        print('❌ [DashboardController] Failed to fetch dashboard summary: ${result['message']}');
        print('   Using default values (0)');
        // Reset to defaults on error
        hoursToday.value = '0';
        hoursThisWeek.value = '0';
        eventsThisWeek.value = '0';
        leaveThisWeek.value = '0';
      }
    } catch (e) {
      print('❌ [DashboardController] Error fetching dashboard summary: $e');
      // Reset to defaults on error
      hoursToday.value = '0';
      hoursThisWeek.value = '0';
      eventsThisWeek.value = '0';
      leaveThisWeek.value = '0';
    } finally {
      isLoadingSummary.value = false;
    }
  }

  /// Format hours value for display
  /// Handles both double and int types
  /// Shows whole numbers without decimals (e.g., 5 instead of 5.0)
  /// Shows one decimal place only if needed (e.g., 7.5)
  String _formatHours(dynamic value) {
    if (value == null) return '0';
    
    double? hoursValue;
    
    if (value is double) {
      hoursValue = value;
    } else if (value is int) {
      hoursValue = value.toDouble();
    } else if (value is String) {
      hoursValue = double.tryParse(value);
    }
    
    if (hoursValue == null) return '0';
    
    // If it's a whole number, display without decimals (e.g., 5 instead of 5.0)
    if (hoursValue == hoursValue.roundToDouble()) {
      return hoursValue.toInt().toString();
    }
    
    // Otherwise, show one decimal place (e.g., 7.5)
    return hoursValue.toStringAsFixed(1);
  }

  /// Refresh dashboard summary
  /// Call this method after creating/updating/deleting work hours
  /// to refresh the summary with latest approved hours totals
  Future<void> refreshDashboardSummary() async {
    await fetchDashboardSummary();
  }
}

/// Meeting model
class Meeting {
  final String id;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String? primaryEventType;
  final String? meetingType;

  Meeting({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.primaryEventType,
    this.meetingType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'primaryEventType': primaryEventType,
    'meetingType': meetingType,
  };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    date: json['date'] ?? '',
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
    primaryEventType: json['primaryEventType'],
    meetingType: json['meetingType'],
  );
}
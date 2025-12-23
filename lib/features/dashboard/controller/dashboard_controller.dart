import 'package:firefox_calendar/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


/// Dashboard Controller
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

  // Metrics (observable)
  final RxString hoursToday = '7.5'.obs;
  final RxString hoursThisWeek = '37.5'.obs;
  final RxString eventsThisWeek = '8'.obs;
  final RxString leaveThisWeek = '2'.obs;

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
      final currentDateTime = '${now.toIso8601String().split('.')[0]}'; // Format: "2025-12-17T09:00:00"
      final loginTime = currentDateTime.replaceAll('T', ' '); // Format: "2025-12-17 09:00:00"

      print('🟢 [DashboardController] Creating new work hours entry');
      print('   Title: Work Day');
      print('   Date: $todayStr');
      print('   Login Time: $loginTime');
      print('   Status: pending');

      // Call CREATE user hours API
      // Send: title = "Work Day", date = today, login_time = current datetime
      // status must always be "pending"
      final result = await _authService.createUserHours(
        title: 'Work Day',
        date: todayStr,
        loginTime: loginTime,
        logoutTime: null, // Not sent at this stage
        totalHours: null, // Not sent at this stage
        status: 'pending', // Status must always be "pending"
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
      final currentDateTime = '${now.toIso8601String().split('.')[0]}'; // Format: "2025-12-17T18:00:00"
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
      final result = await _authService.updateUserHours(
        id: activeSessionId.value, // Same pending entry ID from START
        logoutTime: logoutTime, // Current datetime
        // Do NOT send title, date, loginTime, or status - only update logout_time
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
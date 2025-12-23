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

  /// Load start/end time status
  void _loadStartEndTimeStatus() {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    workDate.value = todayStr;
    
    final timeData = storage.read('workTime_${userEmail.value}_$todayStr');
    
    if (timeData != null) {
      startTime.value = timeData['startTime'] ?? '';
      endTime.value = timeData['endTime'] ?? '';
      activeSessionId.value = timeData['sessionId'] ?? '';
      
      // Check if there's an active (pending) session for today
      if (startTime.value.isNotEmpty && endTime.value.isEmpty) {
        // Active session exists
        print('📅 [DashboardController] Active session found for today: ${startTime.value}');
      }
    }
  }

  /// Handle start time (login time) - Creates a new work session via API
  Future<void> setStartTime() async {
    if (isStartTimeLoading.value) return;

    try {
      isStartTimeLoading.value = true;

      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final currentDateTime = '${now.toIso8601String().split('.')[0]}'; // Format: "2025-12-17T09:00:00"
      final loginTime = currentDateTime.replaceAll('T', ' '); // Format: "2025-12-17 09:00:00"

      // Check if there's already an active session for today
      if (startTime.value.isNotEmpty && endTime.value.isEmpty) {
        Get.snackbar(
          'Warning',
          'An active work session already exists for today. Please end the current session first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Call API to create user hours with only login_time and status "pending"
      final result = await _authService.createUserHours(
        title: 'Work Day',
        date: todayStr,
        loginTime: loginTime,
        logoutTime: null, // Not sent at this stage
        totalHours: null, // Not sent at this stage
        status: 'pending', // Set status as "pending" by default
      );

      if (result['success'] == true) {
        // Extract session ID from response if available
        final sessionData = result['data'];
        if (sessionData != null && sessionData['id'] != null) {
          activeSessionId.value = sessionData['id'].toString();
        }

        // Update local state
        startTime.value = loginTime;
        workDate.value = todayStr;
        endTime.value = ''; // Clear end time for new session

        // Save to local storage
        await storage.write('workTime_${userEmail.value}_$todayStr', {
          'startTime': loginTime,
          'endTime': '',
          'date': todayStr,
          'sessionId': activeSessionId.value,
          'status': 'pending',
        });

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

  /// Handle end time (logout time) - Updates the active work session via API
  Future<void> setEndTime() async {
    if (isEndTimeLoading.value) return;

    try {
      isEndTimeLoading.value = true;

      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final currentDateTime = '${now.toIso8601String().split('.')[0]}'; // Format: "2025-12-17T18:00:00"
      final logoutTime = currentDateTime.replaceAll('T', ' '); // Format: "2025-12-17 18:00:00"

      // Check if there's an active session (start time exists but no end time)
      if (startTime.value.isEmpty || endTime.value.isNotEmpty) {
        Get.snackbar(
          'Warning',
          'No active work session found for today. Please start a session first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Verify the session is for today
      if (workDate.value != todayStr) {
        Get.snackbar(
          'Warning',
          'Active session is for a different date. Please start a new session for today.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Create complete work hours entry with all fields (title, date, login_time, logout_time)
      // Status remains "pending" even when complete
      final result = await createCompleteWorkHoursEntry(
        title: 'Work Day',
        date: todayStr,
        loginTime: startTime.value,
        logoutTime: logoutTime,
      );

      if (result['success'] == true) {
        // Extract session ID from response if available
        final sessionData = result['data'];
        if (sessionData != null && sessionData['id'] != null) {
          activeSessionId.value = sessionData['id'].toString();
        }

        // Update local state
        endTime.value = logoutTime;

        // Save to local storage
        await storage.write('workTime_${userEmail.value}_$todayStr', {
          'startTime': startTime.value,
          'endTime': logoutTime,
          'date': todayStr,
          'sessionId': activeSessionId.value,
          'status': 'pending', // Status remains "pending"
        });

        // Reflect backend response in UI
        final responseData = result['data'];
        final entryStatus = responseData != null ? (responseData['status'] ?? 'pending') : 'pending';
        final entryId = responseData != null ? (responseData['id']?.toString() ?? '') : '';
        
        if (entryId.isNotEmpty) {
          activeSessionId.value = entryId;
        }

        Get.snackbar(
          'Success',
          result['message'] ?? 'Complete work hours entry created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 3),
        );
        
        print('✅ [DashboardController] Backend response reflected in UI');
        print('   Entry ID: $entryId');
        print('   Status: $entryStatus');
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
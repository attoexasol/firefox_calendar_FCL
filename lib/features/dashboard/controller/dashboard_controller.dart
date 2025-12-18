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

  // Check-in state
  final RxBool isCheckedIn = false.obs;
  final RxString todayCheckInTime = ''.obs;
  final RxString todayCheckOutTime = ''.obs;

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
    _loadCheckInStatus();
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

  /// Load check-in status
  void _loadCheckInStatus() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final checkInData = storage.read('checkIn_$userEmail.value_$today');
    
    if (checkInData != null) {
      todayCheckInTime.value = checkInData['checkInTime'] ?? '';
      todayCheckOutTime.value = checkInData['checkOutTime'] ?? '';
      isCheckedIn.value = todayCheckInTime.value.isNotEmpty && 
                          todayCheckOutTime.value.isEmpty;
    }
  }

  /// Handle check-in/check-out
  Future<void> toggleCheckInOut() async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (!isCheckedIn.value) {
      // Check in
      todayCheckInTime.value = currentTime;
      isCheckedIn.value = true;
      
      await storage.write('checkIn_${userEmail.value}_$today', {
        'checkInTime': currentTime,
        'checkOutTime': '',
      });

      Get.snackbar(
        'Success',
        'Checked in at $currentTime',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 2),
      );
    } else {
      // Check out
      todayCheckOutTime.value = currentTime;
      isCheckedIn.value = false;
      
      await storage.write('checkIn_${userEmail.value}_$today', {
        'checkInTime': todayCheckInTime.value,
        'checkOutTime': currentTime,
      });

      Get.snackbar(
        'Success',
        'Checked out at $currentTime',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        duration: const Duration(seconds: 2),
      );
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
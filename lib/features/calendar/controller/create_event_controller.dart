import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Create Event Controller
/// Manages event creation and editing state
/// Converted from React CreateMeetingModal component
class CreateEventController extends GetxController {
  // Storage
  final storage = GetStorage();

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  // Observable variables
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final RxString startTime = ''.obs;
  final RxString endTime = ''.obs;
  final RxString eventType = ''.obs;
  final RxString status = 'confirmed'.obs; // 'confirmed' or 'tentative'
  final RxBool isLoading = false.obs;
  final RxBool showDatePicker = false.obs;

  // Editing mode
  final RxBool isEditMode = false.obs;
  final RxString editingEventId = ''.obs;

  // User data
  final RxString userEmail = ''.obs;

  // Event type categories (from React EVENT_CATEGORIES)
  static const List<String> eventCategories = [
    'Team Meeting',
    'One-on-one',
    'Client meeting',
    'Training',
    'Personal Appointment',
    'Annual Leave',
    'Personal Leave',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Load user data from storage
  void _loadUserData() {
    userEmail.value = storage.read('userEmail') ?? '';
  }

  /// Initialize form with event data for editing
  void initializeEditMode(Map<String, dynamic> eventData) {
    isEditMode.value = true;
    editingEventId.value = eventData['id'] ?? '';
    titleController.text = eventData['title'] ?? '';

    // Parse date
    if (eventData['date'] != null) {
      try {
        selectedDate.value = DateTime.parse(eventData['date']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    startTime.value = eventData['startTime'] ?? '';
    endTime.value = eventData['endTime'] ?? '';
    status.value = eventData['type'] ?? 'confirmed';
    eventType.value = eventData['primaryEventType'] ?? '';
    descriptionController.text = eventData['description'] ?? '';
  }

  /// Reset form to create new event
  void resetForm() {
    isEditMode.value = false;
    editingEventId.value = '';
    titleController.clear();
    descriptionController.clear();
    selectedDate.value = null;
    startTime.value = '';
    endTime.value = '';
    eventType.value = '';
    status.value = 'confirmed';
  }

  /// Validate form inputs
  bool validateForm() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter event title',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    if (selectedDate.value == null) {
      Get.snackbar(
        'Validation Error',
        'Please select a date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    if (startTime.value.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select start time',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    if (endTime.value.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select end time',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    // Validate time range
    final startParts = startTime.value.split(':');
    final endParts = endTime.value.split(':');

    if (startParts.length != 2 || endParts.length != 2) {
      Get.snackbar(
        'Validation Error',
        'Invalid time format',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    final startHour = int.tryParse(startParts[0]) ?? 0;
    final startMin = int.tryParse(startParts[1]) ?? 0;
    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMin = int.tryParse(endParts[1]) ?? 0;

    final startMinutes = startHour * 60 + startMin;
    final endMinutes = endHour * 60 + endMin;

    if (startMinutes >= endMinutes) {
      Get.snackbar(
        'Validation Error',
        'End time must be after start time',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    return true;
  }

  /// Handle event creation or update
  Future<void> handleSubmit() async {
    if (!validateForm()) return;

    isLoading.value = true;

    try {
      // Determine category based on event type (from React logic)
      final isLeaveType =
          eventType.value == 'Annual Leave' ||
          eventType.value == 'Personal Leave';
      final category = isLeaveType ? 'leave' : 'meeting';

      // Map event type to meeting type (from React logic)
      String meetingType = 'other';
      if (eventType.value == 'Team Meeting') {
        meetingType = 'team-meeting';
      } else if (eventType.value == 'One-on-one') {
        meetingType = 'one-on-one';
      } else if (eventType.value == 'Client meeting') {
        meetingType = 'client-meeting';
      } else if (eventType.value == 'Training') {
        meetingType = 'training';
      }

      final eventData = {
        'title': titleController.text.trim(),
        'date': selectedDate.value!.toIso8601String().split('T')[0],
        'startTime': startTime.value,
        'endTime': endTime.value,
        'type': status.value,
        'category': category,
        'meetingType': meetingType,
        'primaryEventType': eventType.value.isNotEmpty ? eventType.value : null,
        'description': descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
        'creator': userEmail.value,
        'attendees': [userEmail.value],
      };

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      if (isEditMode.value) {
        // Update existing event
        // TODO: Replace with actual API call
        print('✅ Event updated: $eventData');

        Get.snackbar(
          'Success',
          'Event updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      } else {
        // Create new event
        // TODO: Replace with actual API call
        print('✅ Event created: $eventData');

        Get.snackbar(
          'Success',
          'Event created successfully and will appear in all calendar views',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      }

      isLoading.value = false;

      // Navigate back to previous screen
      Get.back();

      // Reset form for next use
      resetForm();
    } catch (e) {
      isLoading.value = false;

      Get.snackbar(
        'Error',
        'Failed to ${isEditMode.value ? 'update' : 'create'} event',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );

      print('Error creating/updating event: $e');
    }
  }

  /// Handle date selection
  void handleDateSelect(DateTime? date) {
    selectedDate.value = date;
    showDatePicker.value = false;
  }

  /// Toggle date picker visibility
  void toggleDatePicker() {
    showDatePicker.value = !showDatePicker.value;
  }

  /// Set start time
  void setStartTime(String time) {
    startTime.value = time;
  }

  /// Set end time
  void setEndTime(String time) {
    endTime.value = time;
  }

  /// Set event type
  void setEventType(String type) {
    eventType.value = type;
  }

  /// Set status
  void setStatus(String newStatus) {
    status.value = newStatus;
  }

  /// Format date for display (from React formatDate)
  String formatDate(DateTime? date) {
    if (date == null) return 'Pick a date';

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, $month ${date.day}, ${date.year}';
  }

  /// Format time for display (from React formatTime)
  String formatTime(String time) {
    if (time.isEmpty) return '';

    final parts = time.split(':');
    if (parts.length != 2) return time;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;

    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHours = hours % 12 == 0 ? 12 : hours % 12;

    return '$displayHours:${minutes.toString().padLeft(2, '0')} $period';
  }

  /// Navigate back/cancel
  void handleCancel() {
    Get.back();
    resetForm();
  }
}

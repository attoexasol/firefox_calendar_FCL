import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Create Event Controller
/// Manages event creation and editing state
/// Converted from React CreateMeetingModal component
class CreateEventController extends GetxController {
  // Storage
  final storage = GetStorage();
  final AuthService _authService = AuthService();

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

  /// Map event type string to event_type_id
  /// NOTE: Currently using ID 1 for all types as per API example
  /// TODO: Update this mapping based on actual API event type IDs
  /// The API may require fetching valid event types from an endpoint
  int? getEventTypeId(String eventType) {
    // Using ID 1 for all event types as shown in the API example
    // This may need to be adjusted based on actual API requirements
    // If the API provides an endpoint to fetch event types, use that instead
    return 1;
    
    // Original mapping (commented out - API rejected these IDs)
    // const eventTypeMap = {
    //   'Team Meeting': 1,
    //   'One-on-one': 2,
    //   'Client meeting': 3,
    //   'Training': 4,
    //   'Personal Appointment': 5,
    //   'Annual Leave': 6,
    //   'Personal Leave': 7,
    // };
    // return eventTypeMap[eventType];
  }

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

    // Validate event type
    if (eventType.value.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select event type',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    // Validate event type ID mapping
    final eventTypeId = getEventTypeId(eventType.value);
    if (eventTypeId == null) {
      Get.snackbar(
        'Validation Error',
        'Invalid event type selected',
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
    // Prevent duplicate submissions
    if (isLoading.value) {
      print('⚠️ [CreateEventController] Submission already in progress');
      return;
    }

    if (!validateForm()) return;

    isLoading.value = true;

    try {
      // Get event type ID
      final eventTypeId = getEventTypeId(eventType.value);
      if (eventTypeId == null) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Invalid event type selected',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
        return;
      }

      // Format date (YYYY-MM-DD)
      final dateStr = selectedDate.value!.toIso8601String().split('T')[0];

      // Format start_time and end_time (YYYY-MM-DD HH:MM:SS)
      final startDateTime = '${dateStr} ${startTime.value}:00';
      final endDateTime = '${dateStr} ${endTime.value}:00';

      print('📅 [CreateEventController] Creating event...');
      print('   Title: ${titleController.text.trim()}');
      print('   Date: $dateStr');
      print('   Start Time: $startDateTime');
      print('   End Time: $endDateTime');
      print('   Event Type ID: $eventTypeId');
      print('   Description: ${descriptionController.text.trim()}');

      if (isEditMode.value) {
        // Update existing event
        // TODO: Implement update event API when available
        isLoading.value = false;
        Get.snackbar(
          'Info',
          'Event update functionality coming soon',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade900,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Create new event via API
      final result = await _authService.createEvent(
        title: titleController.text.trim(),
        date: dateStr,
        startTime: startDateTime,
        endTime: endDateTime,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
        eventTypeId: eventTypeId,
      );

      isLoading.value = false;

      if (result['success'] == true) {
        print('✅ [CreateEventController] Event created successfully');

        // Show success message
        Get.snackbar(
          'Success',
          'Event created successfully and will appear in all calendar views',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );

        // Refresh calendar events
        try {
          final calendarController = Get.find<CalendarController>();
          calendarController.refreshEvents();
        } catch (e) {
          print('⚠️ [CreateEventController] Could not refresh calendar: $e');
        }

        // Navigate back to previous screen
        Get.back();

        // Reset form for next use
        resetForm();
      } else {
        // Show error message
        final errorMessage = result['message'] ?? 'Failed to create event. Please try again.';
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
        print('❌ [CreateEventController] Event creation failed: $errorMessage');
      }
    } catch (e) {
      isLoading.value = false;

      Get.snackbar(
        'Error',
        'Failed to create event. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      );

      print('💥 [CreateEventController] Error creating event: $e');
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

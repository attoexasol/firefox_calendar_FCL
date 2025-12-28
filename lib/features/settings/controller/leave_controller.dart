import 'package:firefox_calendar/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Leave Controller
/// Manages leave application form state and submission
class LeaveController extends GetxController {
  // =========================================================
  // DEPENDENCIES
  // =========================================================
  final AuthService _authService = AuthService();
  final GetStorage _storage = GetStorage();

  // =========================================================
  // REACTIVE PROPERTIES
  // =========================================================
  
  // Form fields
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString reason = ''.obs;
  
  // State
  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;

  // =========================================================
  // METHODS
  // =========================================================

  /// Set start date
  void setStartDate(DateTime? date) {
    startDate.value = date;
    errorMessage.value = '';
  }

  /// Set end date
  void setEndDate(DateTime? date) {
    endDate.value = date;
    errorMessage.value = '';
  }

  /// Set reason
  void setReason(String text) {
    reason.value = text;
    errorMessage.value = '';
  }

  /// Clear reason placeholder
  void clearReasonPlaceholder() {
    if (reason.value == 'Please provide a reason for your leave request...') {
      reason.value = '';
    }
  }

  /// Validate form before submission
  bool _validateForm() {
    errorMessage.value = '';

    if (startDate.value == null) {
      errorMessage.value = 'Please select a start date';
      return false;
    }

    if (endDate.value == null) {
      errorMessage.value = 'Please select an end date';
      return false;
    }

    if (startDate.value!.isAfter(endDate.value!)) {
      errorMessage.value = 'Start date must be before or equal to end date';
      return false;
    }

    if (reason.value.trim().isEmpty || 
        reason.value == 'Please provide a reason for your leave request...') {
      errorMessage.value = 'Please provide a reason for your leave request';
      return false;
    }

    return true;
  }

  /// Format date to YYYY-MM-DD HH:mm:ss format
  String _formatDateTime(DateTime date, String time) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day $time';
  }

  /// Submit leave application
  Future<void> submitLeaveApplication() async {
    try {
      // Validate form
      if (!_validateForm()) {
        Get.snackbar(
          'Validation Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      isSubmitting.value = true;
      errorMessage.value = '';

      // Get API token from storage
      final apiToken = _storage.read('apiToken') ?? '';
      
      if (apiToken.isEmpty) {
        errorMessage.value = 'Authentication token not found. Please log in again.';
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
        isSubmitting.value = false;
        return;
      }

      // Format dates with time
      final startTime = _formatDateTime(startDate.value!, '09:00:00');
      final endTime = _formatDateTime(endDate.value!, '18:00:00');

      print('📝 [LeaveController] Submitting leave application...');
      print('   Start Time: $startTime');
      print('   End Time: $endTime');
      print('   Reason: ${reason.value}');

      // Call API
      final result = await _authService.createLeaveApplication(
        apiToken: apiToken,
        startTime: startTime,
        endTime: endTime,
        reason: reason.value.trim(),
      );

      if (result['success'] == true) {
        // Success - clear form and show success message
        _clearForm();
        
        Get.snackbar(
          'Success',
          result['message'] ?? 'Leave request submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 3),
        );

        print('✅ [LeaveController] Leave application submitted successfully');
      } else {
        // Failure - show error message
        errorMessage.value = result['message'] ?? 'Failed to submit leave request. Please try again.';
        
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );

        print('❌ [LeaveController] Leave application failed: ${result['message']}');
      }
    } catch (e) {
      print('💥 [LeaveController] Leave application error: $e');
      errorMessage.value = 'An error occurred. Please try again.';
      
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Clear form fields
  void _clearForm() {
    startDate.value = null;
    endDate.value = null;
    reason.value = '';
    errorMessage.value = '';
  }

  /// Format date for display (DD/MM/YYYY)
  String formatDateForDisplay(DateTime? date) {
    if (date == null) return 'dd----yyyy';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}


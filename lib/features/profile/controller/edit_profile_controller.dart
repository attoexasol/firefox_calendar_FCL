import 'package:firefox_calendar/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Edit Profile Controller
/// Uses centralized AuthService for profile update API operations
/// Follows established project patterns with GetX state management
/// Updated for separate screen navigation instead of dialog
class EditProfileController extends GetxController {
  // =========================================================
  // DEPENDENCIES
  // =========================================================
  final AuthService _authService = AuthService();
  final storage = GetStorage();

  // =========================================================
  // FORM CONTROLLERS
  // =========================================================
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();

  // =========================================================
  // REACTIVE PROPERTIES
  // =========================================================
  final RxString firstNameError = ''.obs;
  final RxString lastNameError = ''.obs;
  final RxString emailError = ''.obs;
  final RxString generalError = ''.obs;
  final RxBool isLoading = false.obs;

  // =========================================================
  // COMPUTED PROPERTIES
  // =========================================================

  /// Check if form has been modified
  RxBool get isFormValid {
    final currentFirstName = firstNameController.text.trim();
    final currentLastName = lastNameController.text.trim();
    final currentEmail = emailController.text.trim();

    final originalFirstName = storage.read('firstName') ?? '';
    final originalLastName = storage.read('lastName') ?? '';
    final originalEmail = storage.read('userEmail') ?? '';

    final isValid = currentFirstName.isNotEmpty &&
        currentLastName.isNotEmpty &&
        currentEmail.isNotEmpty &&
        firstNameError.value.isEmpty &&
        lastNameError.value.isEmpty &&
        emailError.value.isEmpty &&
        (currentFirstName != originalFirstName ||
         currentLastName != originalLastName ||
         currentEmail != originalEmail);

    return isValid.obs;
  }

  // =========================================================
  // LIFECYCLE METHODS
  // =========================================================

  @override
  void onInit() {
    super.onInit();
    print('🔧 EditProfileController initialized');
    _loadUserData();
    _setupValidation();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  // =========================================================
  // INITIALIZATION METHODS
  // =========================================================

  /// Load current user data into form
  void _loadUserData() {
    final userData = _authService.getCurrentUserData();
    
    firstNameController.text = userData['firstName'] ?? '';
    lastNameController.text = userData['lastName'] ?? '';
    emailController.text = userData['userEmail'] ?? '';
    
    print('📋 [EditProfileController] User data loaded');
  }

  /// Setup form validation listeners
  void _setupValidation() {
    firstNameController.addListener(_validateFirstName);
    lastNameController.addListener(_validateLastName);
    emailController.addListener(_validateEmail);
  }

  // =========================================================
  // VALIDATION METHODS
  // =========================================================

  /// Validate first name
  void _validateFirstName() {
    final firstName = firstNameController.text.trim();
    
    if (firstName.isEmpty) {
      firstNameError.value = 'First name is required';
    } else if (firstName.length < 2) {
      firstNameError.value = 'First name must be at least 2 characters';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(firstName)) {
      firstNameError.value = 'First name can only contain letters and spaces';
    } else {
      firstNameError.value = '';
    }
    
    update();
  }

  /// Validate last name
  void _validateLastName() {
    final lastName = lastNameController.text.trim();
    
    if (lastName.isEmpty) {
      lastNameError.value = 'Last name is required';
    } else if (lastName.length < 2) {
      lastNameError.value = 'Last name must be at least 2 characters';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(lastName)) {
      lastNameError.value = 'Last name can only contain letters and spaces';
    } else {
      lastNameError.value = '';
    }
    
    update();
  }

  /// Validate email
  void _validateEmail() {
    final email = emailController.text.trim();
    
    if (email.isEmpty) {
      emailError.value = 'Email is required';
    } else if (!GetUtils.isEmail(email)) {
      emailError.value = 'Please enter a valid email address';
    } else {
      emailError.value = '';
    }
    
    update();
  }

  /// Validate entire form
  bool _validateForm() {
    _validateFirstName();
    _validateLastName();
    _validateEmail();

    return firstNameError.value.isEmpty &&
           lastNameError.value.isEmpty &&
           emailError.value.isEmpty &&
           firstNameController.text.trim().isNotEmpty &&
           lastNameController.text.trim().isNotEmpty &&
           emailController.text.trim().isNotEmpty;
  }

  // =========================================================
  // ACTION METHODS
  // =========================================================

  /// Reset form to original values
  void resetForm() {
    _loadUserData();
    _clearErrors();
    
    Get.snackbar(
      'Form Reset',
      'Form has been reset to original values',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  /// Handle cancel action - navigate back to settings
  void handleCancel() {
    Get.back(); // Navigate back to settings screen
  }


// Future<void> handleSave() async {
//   final result = await _authService.updateUserProfile(...);

//   if (result['success'] == true) {
//     Get.snackbar('Success', 'Profile updated');
//     Get.back(result: true); // 🔥 IMPORTANT
//   }
// }



  /// Handle save action
  Future<void> handleSave() async {
    print('💾 [EditProfileController] handleSave called');
    
    // Validate form first
    if (!_validateForm()) {
      generalError.value = 'Please fix the errors above';
      return;
    }

    // Check if any changes were made
    if (!isFormValid.value) {
      generalError.value = 'No changes detected';
      return;
    }

    isLoading.value = true;
    _clearErrors();

    try {
      // Call API to update profile
      final result = await _authService.updateUserProfile(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (result['success'] == true) {
        // Show success message
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );

        // Navigate back to settings screen after successful update
        Get.back(); // This will return to settings screen
      } else {
        generalError.value = result['message'] ?? 'Update failed';

        Get.snackbar(
          'Error',
          generalError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    } catch (e) {
      generalError.value = 'Something went wrong';

      Get.snackbar(
        'Error',
        generalError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================
  // UTILITY METHODS
  // =========================================================

  /// Clear all error messages
  void _clearErrors() {
    firstNameError.value = '';
    lastNameError.value = '';
    emailError.value = '';
    generalError.value = '';
  }
}
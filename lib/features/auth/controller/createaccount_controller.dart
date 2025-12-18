
import 'package:firefox_calendar/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CreateAccountController extends GetxController {
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
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // =========================================================
  // REACTIVE PROPERTIES
  // =========================================================
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxString emailError = ''.obs;
  final RxString firstNameError = ''.obs;
  final RxString lastNameError = ''.obs;
  final RxString registrationError = ''.obs;
  final RxBool isLoading = false.obs;

  // Password validation states
  final RxBool hasMinLength = false.obs;
  final RxBool hasUppercase = false.obs;
  final RxBool hasLowercase = false.obs;
  final RxBool hasNumber = false.obs;
  final RxBool hasSpecialChar = false.obs;

  // =========================================================
  // LIFECYCLE METHODS
  // =========================================================

  @override
  void onInit() {
    super.onInit();
    print('🔧 [CreateAccountController] initialized');
    _clearErrors();

    // Listen to password changes for validation
    passwordController.addListener(_validatePassword);
    
    // Listen to name changes
    firstNameController.addListener(_validateFirstName);
    lastNameController.addListener(_validateLastName);
    
    // Listen to email changes
    emailController.addListener(_validateEmail);
  }

  @override
  void onClose() {
    // Remove listeners before disposing
    passwordController.removeListener(_validatePassword);
    firstNameController.removeListener(_validateFirstName);
    lastNameController.removeListener(_validateLastName);
    emailController.removeListener(_validateEmail);
    
    // Dispose all text editing controllers
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    
    super.onClose();
  }



  // =========================================================
  // VISIBILITY TOGGLE METHODS
  // =========================================================

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // =========================================================
  // VALIDATION METHODS
  // =========================================================

  /// Clear all error messages
  void _clearErrors() {
    emailError.value = '';
    firstNameError.value = '';
    lastNameError.value = '';
    registrationError.value = '';
  }

  /// Validate first name
  void _validateFirstName() {
    final firstName = firstNameController.text.trim();
    if (firstName.isEmpty) {
      firstNameError.value = '';
    } else if (firstName.length < 2) {
      firstNameError.value = 'First name must be at least 2 characters';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(firstName)) {
      firstNameError.value = 'First name can only contain letters and spaces';
    } else {
      firstNameError.value = '';
    }
  }

  /// Validate last name
  void _validateLastName() {
    final lastName = lastNameController.text.trim();
    if (lastName.isEmpty) {
      lastNameError.value = '';
    } else if (lastName.length < 2) {
      lastNameError.value = 'Last name must be at least 2 characters';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(lastName)) {
      lastNameError.value = 'Last name can only contain letters and spaces';
    } else {
      lastNameError.value = '';
    }
  }

  /// Validate email
  void _validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      emailError.value = '';
    } else if (!GetUtils.isEmail(email)) {
      emailError.value = 'Please enter a valid email address';
    } else {
      emailError.value = '';
    }
  }

  /// Validate password strength
  void _validatePassword() {
    final password = passwordController.text;
    
    // Length check
    hasMinLength.value = password.length >= 8;
    
    // Uppercase check
    hasUppercase.value = password.contains(RegExp(r'[A-Z]'));
    
    // Lowercase check
    hasLowercase.value = password.contains(RegExp(r'[a-z]'));
    
    // Number check
    hasNumber.value = password.contains(RegExp(r'[0-9]'));
    
    // Special character check
    hasSpecialChar.value = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  /// Check if password meets all requirements
  bool get isPasswordValid =>
      hasMinLength.value &&
      hasUppercase.value &&
      hasLowercase.value &&
      hasNumber.value &&
      hasSpecialChar.value;

  /// Check if passwords match
  bool get passwordsMatch =>
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      passwordController.text == confirmPasswordController.text;

  /// Validate form inputs
  bool _validateForm() {
    bool isValid = true;

    // Validate first name
    final firstName = firstNameController.text.trim();
    if (firstName.isEmpty) {
      firstNameError.value = 'First name is required';
      isValid = false;
    } else if (firstName.length < 2) {
      firstNameError.value = 'First name must be at least 2 characters';
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(firstName)) {
      firstNameError.value = 'First name can only contain letters and spaces';
      isValid = false;
    } else {
      firstNameError.value = '';
    }

    // Validate last name
    final lastName = lastNameController.text.trim();
    if (lastName.isEmpty) {
      lastNameError.value = 'Last name is required';
      isValid = false;
    } else if (lastName.length < 2) {
      lastNameError.value = 'Last name must be at least 2 characters';
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(lastName)) {
      lastNameError.value = 'Last name can only contain letters and spaces';
      isValid = false;
    } else {
      lastNameError.value = '';
    }

    // Validate email
    final email = emailController.text.trim();
    if (email.isEmpty) {
      emailError.value = 'Email is required';
      isValid = false;
    } else if (!GetUtils.isEmail(email)) {
      emailError.value = 'Please enter a valid email address';
      isValid = false;
    } else {
      emailError.value = '';
    }

    // Validate password
    if (!isPasswordValid) {
      registrationError.value = 'Password does not meet all requirements';
      isValid = false;
    }

    // Check if passwords match
    if (!passwordsMatch) {
      registrationError.value = 'Passwords do not match';
      isValid = false;
    }

    update();
    return isValid;
  }

  /// Check if form is valid for button state
  bool get canCreateAccount =>
      firstNameController.text.trim().isNotEmpty &&
      lastNameController.text.trim().isNotEmpty &&
      emailController.text.trim().isNotEmpty &&
      firstNameError.value.isEmpty &&
      lastNameError.value.isEmpty &&
      emailError.value.isEmpty &&
      isPasswordValid &&
      passwordsMatch;

  // =========================================================
  // REGISTRATION HANDLER
  // =========================================================

  /// Handle create account using AuthService
  Future<void> handleCreateAccount() async {
    if (isLoading.value) return;

    registrationError.value = '';

    if (!_validateForm()) return;

    isLoading.value = true;
    update();

    try {
      final result = await _authService.registerUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (result['success'] == true) {
        // Unfocus keyboard first
        FocusManager.instance.primaryFocus?.unfocus();
        
        // Show success message
        Get.snackbar(
          'Success',
          'Account created successfully. Please login.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );

        // Small delay to let UI settle before navigation
        await Future.delayed(const Duration(milliseconds: 200));

        // Navigate to login - GetX will handle controller cleanup
        Get.offAllNamed('/login');
      } else {
        _handleRegistrationError(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _handleRegistrationError('Network error');
    } finally {
      // Only update if controller is still active
      if (!isClosed) {
        isLoading.value = false;
        update();
      }
    }
  }


  /// Handle registration error
  void _handleRegistrationError(String message) {
    print('❌ [CreateAccountController] Registration error: $message');
    
    // Set specific error messages based on response
    if (message.toLowerCase().contains('email')) {
      if (message.toLowerCase().contains('already') || 
          message.toLowerCase().contains('exist')) {
        emailError.value = 'This email is already registered';
      } else {
        emailError.value = 'Invalid email format';
      }
    } else {
      registrationError.value = message;
    }

    // Show error snackbar
    Get.snackbar(
      'Registration Failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: const Duration(seconds: 4),
    );
    
    update();
  }

  /// Clear form data (used for manual reset)
  void clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _clearErrors();
  }

  // =========================================================
  // NAVIGATION METHODS
  // =========================================================

  /// Navigate back to login
  void navigateToLogin() {
    Get.back();
  }
}
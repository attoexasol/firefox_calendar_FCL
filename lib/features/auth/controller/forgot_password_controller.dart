import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ForgotPasswordController extends GetxController {

  final storage = GetStorage();
  
  /// Email input controller
  final TextEditingController emailController = TextEditingController();
  
  /// New password input controller
  final TextEditingController newPasswordController = TextEditingController();
  
  /// Confirm password input controller
  final TextEditingController confirmPasswordController = TextEditingController();
  
  /// Loading state
  final RxBool isLoading = false.obs;
  
  /// Email error state
  final RxString emailError = ''.obs;
  
  /// Show OTP popup state
  final RxBool showOTP = false.obs;
  
  /// OTP verified state
  final RxBool otpVerified = false.obs;
  
  /// Show new password visibility
  final RxBool showNewPassword = false.obs;
  
  /// Show confirm password visibility  
  final RxBool showConfirmPassword = false.obs;
  
  /// Password validation states
  final RxBool hasMinLength = false.obs;
  final RxBool hasUppercase = false.obs;
  final RxBool hasLowercase = false.obs;
  final RxBool hasNumber = false.obs;
  final RxBool hasSpecialChar = false.obs;
  
  /// Passwords match state
  final RxBool passwordsMatch = true.obs;
  
  /// Can save password state
  final RxBool canSavePassword = false.obs;

  // =========================================================
  // LIFECYCLE METHODS
  // =========================================================
  
  @override
  void onInit() {
    super.onInit();
    print('🔧 UpdateForgotPasswordController initialized');
    _initializeController();
    _setupPasswordListeners();
  }

  @override
  void onClose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Initialize controller with passed email if available
  void _initializeController() {
    // Get email from arguments if passed from previous screen
    final email = Get.arguments?['email'] ?? '';
    if (email.isNotEmpty) {
      emailController.text = email;
      validateEmail(email);
    }
  }

  /// Setup password validation listeners
  void _setupPasswordListeners() {
    // Listen to new password changes
    newPasswordController.addListener(() {
      _validatePassword(newPasswordController.text);
      _checkPasswordsMatch();
      _updateCanSaveState();
    });
    
    // Listen to confirm password changes
    confirmPasswordController.addListener(() {
      _checkPasswordsMatch();
      _updateCanSaveState();
    });
  }

  // =========================================================
  // EMAIL VALIDATION
  // =========================================================

  /// Validate email format and domain restriction
  bool validateEmail(String email) {
    if (email.isEmpty) {
      emailError.value = 'Email is required';
      return false;
    }

    // Check for @firefoxtraining.com.au domain requirement
    if (!email.endsWith('@firefoxtraining.com.au')) {
      emailError.value = 'Email must be @firefoxtraining.com.au';
      return false;
    }

    emailError.value = '';
    return true;
  }

  // =========================================================
  // PASSWORD VALIDATION
  // =========================================================

  /// Validate password against all requirements
  void _validatePassword(String password) {
    hasMinLength.value = password.length >= 8;
    hasUppercase.value = password.contains(RegExp(r'[A-Z]'));
    hasLowercase.value = password.contains(RegExp(r'[a-z]'));
    hasNumber.value = password.contains(RegExp(r'[0-9]'));
    hasSpecialChar.value = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  /// Check if passwords match
  void _checkPasswordsMatch() {
    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;
    
    if (confirmPass.isNotEmpty) {
      passwordsMatch.value = newPass == confirmPass;
    } else {
      passwordsMatch.value = true; // Don't show error until user types
    }
  }

  /// Check if all password requirements are met
  bool _isPasswordValid() {
    return hasMinLength.value &&
           hasUppercase.value &&
           hasLowercase.value &&
           hasNumber.value &&
           hasSpecialChar.value;
  }

  /// Update the can save state based on all conditions
  void _updateCanSaveState() {
    canSavePassword.value = otpVerified.value &&
                          _isPasswordValid() &&
                          passwordsMatch.value &&
                          confirmPasswordController.text.isNotEmpty;
  }

  // =========================================================
  // EMAIL VERIFICATION FLOW
  // =========================================================

  /// Handle email verification - send OTP
  Future<void> handleVerifyEmail() async {
    print('📧 Handling email verification');
    
    final email = emailController.text.trim();
    if (!validateEmail(email)) {
      return;
    }

    isLoading.value = true;

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // TODO: Replace with actual API call
      final success = await _sendOTP(email);
      
      if (success) {
        print('✅ OTP sent to $email');
        showOTP.value = true;
        
        Get.snackbar(
          'OTP Sent',
          'Verification code sent to your email',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to send OTP. Please try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('💥 Send OTP error: $e');
      Get.snackbar(
        'Error',
        'An error occurred. Please try again later.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Mock send OTP API call
  Future<bool> _sendOTP(String email) async {
    // Simulate successful OTP send for valid emails
    return email.endsWith('@firefoxtraining.com.au');
  }

  // =========================================================
  // OTP VERIFICATION FLOW
  // =========================================================

  /// Handle OTP verification
  Future<void> handleOTPVerify(String otp) async {
    print('🔐 Handling OTP verification: $otp');
    
    // Mock OTP verification (in real app, verify with backend)
    if (otp == '123456' || otp.length == 6) {
      otpVerified.value = true;
      showOTP.value = false;
      _updateCanSaveState();
      
      Get.snackbar(
        'Success',
        'OTP verified successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Invalid OTP',
        'Please enter the correct verification code',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Close OTP popup
  void closeOTPPopup() {
    showOTP.value = false;
  }

  // =========================================================
  // PASSWORD RESET FLOW
  // =========================================================

  /// Handle password save
  Future<void> handleSavePassword() async {
    print('💾 Handling password save');
    
    if (!_isPasswordValid()) {
      Get.snackbar(
        'Invalid Password',
        'Password does not meet all requirements',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (!passwordsMatch.value) {
      Get.snackbar(
        'Password Mismatch',
        'Passwords do not match',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    isLoading.value = true;

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // TODO: Replace with actual API call
      final success = await _resetPassword(
        emailController.text,
        newPasswordController.text,
      );
      
      if (success) {
        print('✅ Password updated successfully');
        
        Get.snackbar(
          'Success',
          'Password updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        );
        
        // Navigate back to login after success
        Future.delayed(const Duration(milliseconds: 1500), () {
          navigateToLogin();
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to update password',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('💥 Reset password error: $e');
      Get.snackbar(
        'Error',
        'An error occurred. Please try again later.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Mock reset password API call
  /// TODO: Replace with actual API implementation
  Future<bool> _resetPassword(String email, String newPassword) async {
    // Simulate successful password reset
    return true;
  }

  // =========================================================
  // UI INTERACTION METHODS
  // =========================================================

  /// Toggle new password visibility
  void toggleNewPasswordVisibility() {
    showNewPassword.value = !showNewPassword.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  // =========================================================
  // NAVIGATION METHODS
  // =========================================================

  /// Navigate back to login screen
  void navigateToLogin() {
    print('🔙 Navigating back to login');
    Get.offAllNamed('/login');
  }

  /// Navigate back to previous screen
  void navigateBack() {
    Get.back();
  }
}
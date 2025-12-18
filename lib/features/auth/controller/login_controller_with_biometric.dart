import 'package:firefox_calendar/features/auth/view/widgets/biometric_prompt.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


class LoginController extends GetxController {
  // Text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observable variables
  final RxBool isPasswordVisible = false.obs;
  final RxString emailError = ''.obs;
  final RxString loginError = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool showBiometricPrompt = false.obs; // NEW: For biometric prompt

  // Storage
  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // Clear any previous errors
    emailError.value = '';
    loginError.value = '';
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Validate email format and domain
  bool validateEmail(String email) {
    if (email.isEmpty) {
      emailError.value = '';
      return false;
    }

    if (!email.endsWith('@gmail.com')) {
      emailError.value = 'Email must be @gmail.com';
      return false;
    }

    emailError.value = '';
    return true;
  }

  /// Handle email change
  void onEmailChanged(String value) {
    if (value.isNotEmpty) {
      validateEmail(value);
    } else {
      emailError.value = '';
    }
    loginError.value = '';
  }

  /// Handle login
  Future<void> handleLogin() async {
    loginError.value = '';

    // Validate email
    if (!validateEmail(emailController.text)) {
      return;
    }

    // Check if password is empty
    if (passwordController.text.isEmpty) {
      loginError.value = 'Password is required';
      return;
    }

    isLoading.value = true;

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock authentication logic
    // TODO: Replace with actual API call
    if (_mockLogin(emailController.text, passwordController.text)) {
      // Save user session
      await storage.write('isLoggedIn', true);
      await storage.write('userEmail', emailController.text);

      isLoading.value = false;

      // NEW: Check if biometric is enabled
      final biometricEnabled = storage.read('biometricEnabled') ?? false;

      if (!biometricEnabled) {
        // Show biometric prompt using GetX dialog
        _showBiometricPromptDialog();
      } else {
        // Navigate directly to dashboard
        Get.offAllNamed('/dashboard');
      }
    } else {
      isLoading.value = false;
      loginError.value = 'Invalid email or password';
    }
  }

  /// NEW: Show biometric prompt dialog
  void _showBiometricPromptDialog() {
    Get.dialog(
      BiometricPrompt(
        isOpen: true,
        onEnable: _enableBiometric,
        onDismiss: _dismissBiometricPrompt,
      ),
      barrierDismissible: false, // Prevent dismissal by tapping outside
    );
  }

  /// NEW: Enable biometric authentication
  Future<void> _enableBiometric() async {
    // TODO: Integrate with local_auth package for actual biometric enrollment
    // For now, just save the preference

    await storage.write('biometricEnabled', true);

    // Close dialog
    Get.back();

    // Show success message
    Get.snackbar(
      'Success',
      'Biometric login enabled successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 2),
    );

    // Navigate to dashboard
    Get.offAllNamed('/dashboard');
  }

  /// NEW: Dismiss biometric prompt
  void _dismissBiometricPrompt() {
    // Close dialog
    Get.back();

    // Navigate to dashboard
    Get.offAllNamed('/dashboard');
  }

  /// Handle biometric login
  Future<void> handleBiometricLogin() async {
    loginError.value = '';
    isLoading.value = true;

    // Simulate biometric authentication
    await Future.delayed(const Duration(milliseconds: 800));

    // Check if biometric is enabled
    final biometricEnabled = storage.read('biometricEnabled') ?? false;

    if (!biometricEnabled) {
      isLoading.value = false;
      loginError.value = 'Biometric login not enabled';
      return;
    }

    // TODO: Implement actual biometric authentication using local_auth
    // For now, use mock credentials
    emailController.text = 'user@gmail.com';
    passwordController.text = 'Password123!';

    if (_mockLogin('user@gmail.com', 'Password123!')) {
      // Save user session
      await storage.write('isLoggedIn', true);
      await storage.write('userEmail', 'user@gmail.com');

      isLoading.value = false;

      // Navigate to dashboard (no biometric prompt shown for biometric login)
      Get.offAllNamed('/dashboard');
    } else {
      isLoading.value = false;
      loginError.value = 'Biometric authentication failed';
    }
  }

  /// Mock login logic
  /// TODO: Replace with actual API authentication
  bool _mockLogin(String email, String password) {
    // Simple mock validation
    // In production, this should call an API endpoint
    return email == 'user@gmail.com' && password == 'Password123!';
  }

  /// Navigate to create account
  void navigateToCreateAccount() {
    Get.toNamed('/register');
  }

  /// Navigate to forgot password
  void navigateToForgotPassword() {
    Get.toNamed('/forgot-password');
  }

  /// Navigate to contact
  void navigateToContact() {
    // TODO: Add contact route if not exists
    Get.snackbar(
      'Contact',
      'Contact page coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Open social media
  void openSocial() {
    // TODO: Implement URL launcher
    Get.snackbar(
      'Social',
      'Opening social media...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Open website
  void openWebsite() {
    // TODO: Implement URL launcher for https://firefoxtraining.com.au
    Get.snackbar(
      'Website',
      'Opening website...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
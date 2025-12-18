import 'package:firefox_calendar/features/auth/view/widgets/biometric_prompt.dart';
import 'package:firefox_calendar/services/auth_service.dart';
import 'package:firefox_calendar/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


/// Enhanced Login Controller
/// Uses centralized AuthService for all API operations
/// Improved session management, biometric integration, and login persistence
class LoginController extends GetxController {
  // =========================================================
  // DEPENDENCIES
  // =========================================================
  final AuthService _authService = AuthService();
  final storage = GetStorage();
  final BiometricService _biometricService = BiometricService();

  // =========================================================
  // FORM CONTROLLERS
  // =========================================================
  final emailController = TextEditingController(text: "aman22@gmail.com");
  final passwordController = TextEditingController(text: "Aman22@@");

  // =========================================================
  // REACTIVE PROPERTIES
  // =========================================================
  final RxBool isPasswordVisible = false.obs;
  final RxString emailError = ''.obs;
  final RxString loginError = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isBiometricLoading = false.obs;

  // =========================================================
  // LIFECYCLE METHODS
  // =========================================================

  @override
  void onInit() {
    super.onInit();
    emailError.value = '';
    loginError.value = '';
    _initializeController();
    print('✅ Enhanced LoginController initialized with AuthService');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // =========================================================
  // INITIALIZATION METHODS
  // =========================================================

  /// Initialize controller with session checking
  void _initializeController() {
    // Check if user has valid session
    _checkExistingSession();
    
    // Load saved email if available
    final savedEmail = storage.read('lastLoginEmail') ?? '';
    if (savedEmail.isNotEmpty && emailController.text.isEmpty) {
      emailController.text = savedEmail;
    }
  }

  /// Check for existing valid session
  void _checkExistingSession() {
    if (_authService.isLoggedIn()) {
      final userData = _authService.getCurrentUserData();
      final userEmail = userData['userEmail'] ?? '';
      
      print('✅ Valid session found, redirecting to dashboard for: $userEmail');
      // Auto-redirect to dashboard if valid session exists
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/dashboard');
      });
    }
  }

  // =========================================================
  // EMAIL / PASSWORD VALIDATION
  // =========================================================

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  bool validateEmail(String email) {
    if (email.isEmpty) {
      emailError.value = '';
      return false;
    }

    // Updated to accept any valid email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      emailError.value = 'Please enter a valid email address';
      return false;
    }

    emailError.value = '';
    return true;
  }

  void onEmailChanged(String value) {
    if (value.isNotEmpty) {
      validateEmail(value);
    } else {
      emailError.value = '';
    }
    loginError.value = '';
  }

  // =========================================================
  // ENHANCED LOGIN HANDLER
  // =========================================================

  Future<void> handleLogin() async {
    print('🔵 [LoginController] handleLogin called');
    loginError.value = '';
    emailError.value = '';

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      emailError.value = 'Email is required';
      return;
    }

    if (!validateEmail(email)) return;

    if (password.isEmpty) {
      loginError.value = 'Password is required';
      return;
    }

    isLoading.value = true;

    try {
      // Use centralized API service
      final result = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        print('✅ [LoginController] Login successful for $email');

        // Save last login email for convenience
        await storage.write('lastLoginEmail', email);

        isLoading.value = false;

        // Check and handle biometric setup
        await _handleBiometricSetup();
      } else {
        isLoading.value = false;
        loginError.value = result['message'] ?? 'Login failed';
        print('❌ [LoginController] Login failed: ${result['message']}');
      }
    } catch (e) {
      print('💥 [LoginController] Login error: $e');
      isLoading.value = false;
      loginError.value = 'An error occurred. Please try again.';
    }
  }

  /// Navigate to dashboard
  void _navigateToDashboard() {
    print('🚀 [LoginController] Navigating to dashboard');
    Get.offAllNamed('/dashboard');
  }

  // =========================================================
  // ENHANCED BIOMETRIC SETUP AND LOGIN
  // =========================================================

  /// Handle biometric setup flow
  Future<void> _handleBiometricSetup() async {
    final biometricEnabled = storage.read('biometricEnabled') ?? false;

    if (!biometricEnabled) {
      bool isAvailable = false;

      // Check biometric availability (not on web)
      if (!kIsWeb) {
        try {
          isAvailable = await _biometricService.isBiometricAvailable();
          print('🔐 [LoginController] Biometric available: $isAvailable');
        } catch (e) {
          print('⚠️ [LoginController] Error checking biometric availability: $e');
          isAvailable = false;
        }
      } else {
        print("⌨️ [LoginController] Biometrics not supported on Web");
      }

      if (isAvailable) {
        _showBiometricPromptDialog();
      } else {
        _navigateToDashboard();
      }
    } else {
      _navigateToDashboard();
    }
  }

  /// Show biometric setup prompt
  void _showBiometricPromptDialog() {
    Get.dialog(
      BiometricPrompt(
        isOpen: true,
        onEnable: _enableBiometric,
        onDismiss: _dismissBiometricPrompt,
      ),
      barrierDismissible: false,
    );
  }

  /// Enable biometric authentication
  Future<void> _enableBiometric() async {
    try {
      Get.back(); // Close prompt

      if (kIsWeb) {
        print("⌨️ [LoginController] Cannot enable biometric on Web");
        _navigateToDashboard();
        return;
      }

      final authenticated = await _biometricService.authenticateToEnable();

      if (authenticated) {
        await storage.write('biometricEnabled', true);
        await storage.write('biometricSetupDate', DateTime.now().toIso8601String());

        Get.snackbar(
          'Success',
          'Biometric login enabled successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Setup Failed',
          'Biometric authentication setup was cancelled or failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 2),
        );
      }

      _navigateToDashboard();
    } catch (e) {
      print("💥 [LoginController] Error enabling biometric: $e");
      Get.snackbar(
        'Error',
        'Failed to enable biometric authentication',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
      _navigateToDashboard();
    }
  }

  /// Dismiss biometric prompt
  void _dismissBiometricPrompt() {
    Get.back();
    _navigateToDashboard();
  }

  Future<void> handleBiometricLogin() async {
    print('🔵 [LoginController] handleBiometricLogin called');
    loginError.value = '';
    isBiometricLoading.value = true;

    try {
      // ❌ Web is not supported
      if (kIsWeb) {
        isBiometricLoading.value = false;
        loginError.value = 'Biometric authentication is not supported on Web';
        return;
      }

      // ✅ Check if device supports biometrics
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        isBiometricLoading.value = false;
        loginError.value = 'Biometric authentication not available on this device';
        return;
      }

      // ✅ Show biometric popup (Fingerprint / Face ID)
      final authenticated = await _biometricService.authenticateForLogin();

      if (!authenticated) {
        isBiometricLoading.value = false;
        loginError.value = 'Biometric authentication failed or was cancelled';
        return;
      }

      // ✅ FORCE enable biometric after first success
      await storage.write('biometricEnabled', true);
      await storage.write('lastBiometricLogin', DateTime.now().toIso8601String());

      // ✅ Auto-create / restore session using stored credentials
      final savedEmail = storage.read('userEmail') ?? storage.read('lastLoginEmail') ?? '';
      
      if (savedEmail.isEmpty) {
        isBiometricLoading.value = false;
        loginError.value = 'No saved credentials found. Please login with username and password first.';
        return;
      }

      // ✅ Preserve existing user data (userId, apiToken, etc.) from previous login
      // Only update session-related fields
      final existingUserId = storage.read('userId');
      final existingApiToken = storage.read('apiToken');
      final existingFirstName = storage.read('firstName');
      final existingLastName = storage.read('lastName');
      final existingUserName = storage.read('userName');
      final existingProfilePicture = storage.read('userProfilePicture');
      
      print('🔍 [LoginController] Biometric login - Checking stored data:');
      print('   userId: $existingUserId');
      print('   apiToken: ${existingApiToken != null && existingApiToken.toString().isNotEmpty ? "exists" : "missing"}');
      print('   email: $savedEmail');
      
      // Set session data
      await storage.write('isLoggedIn', true);
      await storage.write('userEmail', savedEmail);
      final sessionExpiry = DateTime.now().add(const Duration(days: 30));
      await storage.write('sessionExpiry', sessionExpiry.toIso8601String());
      await storage.write('loginTimestamp', DateTime.now().toIso8601String());
      
      // ✅ Preserve user ID and other user data if they exist
      if (existingUserId != null && existingUserId != 0) {
        await storage.write('userId', existingUserId);
        print('✅ [LoginController] Preserved userId: $existingUserId');
      } else {
        // If userId is missing, we need to fetch it from the API
        // But we need the password for that, which we don't store
        // So we'll show an error and ask user to login with username/password
        print('⚠️ [LoginController] No userId found in storage. User may need to login with username/password first.');
        
        // Check if we have an API token - if yes, we might be able to fetch user profile
        if (existingApiToken != null && existingApiToken.toString().isNotEmpty) {
          print('ℹ️ [LoginController] API token found, but userId is missing. User should login with username/password to restore full session.');
        } else {
          isBiometricLoading.value = false;
          loginError.value = 'Session expired. Please login with username and password to restore your profile.';
          return;
        }
      }
      
      // Preserve API token if it exists
      if (existingApiToken != null && existingApiToken.toString().isNotEmpty) {
        await storage.write('apiToken', existingApiToken);
        print('✅ [LoginController] Preserved apiToken');
      }
      
      // Preserve user profile data if it exists
      if (existingFirstName != null) await storage.write('firstName', existingFirstName);
      if (existingLastName != null) await storage.write('lastName', existingLastName);
      if (existingUserName != null) await storage.write('userName', existingUserName);
      if (existingProfilePicture != null) await storage.write('userProfilePicture', existingProfilePicture);

      // Verify userId is stored after biometric login
      final storedUserId = storage.read('userId');
      print('✅ [LoginController] Biometric login complete. Stored userId: $storedUserId');
      
      if (storedUserId == null || storedUserId == 0) {
        print('⚠️ [LoginController] WARNING: userId is still missing after biometric login!');
      }

      isBiometricLoading.value = false;

      Get.snackbar(
        'Success',
        'Biometric login successful',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 1),
      );

      // ✅ ✅ ✅ FINAL DASHBOARD NAVIGATION
      _navigateToDashboard();

    } catch (e) {
      print('💥 [LoginController] Biometric login error: $e');
      isBiometricLoading.value = false;
      loginError.value = 'Biometric authentication error. Please try again.';
    }
  }

  // =========================================================
  // UTILITY METHODS
  // =========================================================

  /// Get session info for debugging
  Map<String, dynamic> getSessionInfo() {
    return _authService.getCurrentUserData();
  }

  /// Logout with session cleanup
  Future<void> logout() async {
    await _authService.logoutUser();
    Get.offAllNamed('/login');
  }

  // =========================================================
  // NAVIGATION METHODS
  // =========================================================

  void navigateToCreateAccount() => Get.toNamed('/register');
  void navigateToForgotPassword() => Get.toNamed('/forgot-password');
  void navigateToContact() => Get.snackbar('Contact', 'Coming soon');
  void openSocial() => Get.snackbar('Social', 'Opening social media...');
  void openWebsite() => Get.snackbar('Website', 'Opening website...');
}
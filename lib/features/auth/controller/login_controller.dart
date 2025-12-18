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
    // emailController.dispose();
    // passwordController.dispose();
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

      // Step 1: Check if biometric is enabled
      final isBiometricEnable = storage.read('is_biometric_enable') ?? false;
      print('🔍 [LoginController] is_biometric_enable: $isBiometricEnable');

      if (!isBiometricEnable) {
        isBiometricLoading.value = false;
        loginError.value = 'Biometric login is not enabled. Please enable it from Settings.';
        return;
      }

      // Step 2: Check if biometric API token is available
      // Try biometric_api_token first (from enrollment), fallback to current apiToken
      var biometricApiToken = storage.read('biometric_api_token') ?? '';
      if (biometricApiToken.isEmpty) {
        // Fallback to current session apiToken
        biometricApiToken = storage.read('apiToken') ?? '';
      }
      print('🔍 [LoginController] biometric_api_token: ${biometricApiToken.isNotEmpty ? "exists" : "missing"}');

      if (biometricApiToken.isEmpty) {
        isBiometricLoading.value = false;
        loginError.value = 'Biometric token not found. Please enable biometric login from Settings.';
        return;
      }

      // Step 3: Check if biometric_token is available (from previous login)
      final biometricToken = storage.read('biometric_token') ?? '';
      print('🔍 [LoginController] biometric_token: ${biometricToken.isNotEmpty ? "exists" : "missing"}');

      if (biometricToken.isEmpty) {
        isBiometricLoading.value = false;
        loginError.value = 'Biometric token not found. Please login with username and password first.';
        return;
      }

      // Step 4: Check if device supports biometrics
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        isBiometricLoading.value = false;
        loginError.value = 'Biometric authentication not available on this device';
        return;
      }

      // Step 5: Show biometric popup (Fingerprint / Face ID)
      print('🔐 [LoginController] Requesting device-level biometric authentication...');
      final authenticated = await _biometricService.authenticateForLogin();

      if (!authenticated) {
        isBiometricLoading.value = false;
        loginError.value = 'Biometric authentication failed or was cancelled';
        return;
      }

      print('✅ [LoginController] Device biometric authenticated, calling biometric login API...');

      // Step 6: Call biometric login API
      final loginResult = await _authService.biometricLogin(
        apiToken: biometricApiToken,
        biometricToken: biometricToken,
      );

      if (loginResult['success'] != true) {
        isBiometricLoading.value = false;
        loginError.value = loginResult['message'] ?? 'Biometric login failed. Please try again.';
        print('❌ [LoginController] Biometric login API failed: ${loginResult['message']}');
        return;
      }

      // Step 7: Biometric login successful - user data is already stored by AuthService
      print('✅ [LoginController] Biometric login API successful');
      
      // Update last biometric login timestamp
      await storage.write('lastBiometricLogin', DateTime.now().toIso8601String());

      // Verify user data was stored correctly
      final storedUserId = storage.read('userId');
      final storedApiToken = storage.read('apiToken');
      final storedEmail = storage.read('userEmail');
      
      print('✅ [LoginController] Biometric login complete:');
      print('   userId: $storedUserId');
      print('   apiToken: ${storedApiToken != null && storedApiToken.toString().isNotEmpty ? "exists" : "missing"}');
      print('   email: $storedEmail');

      if (storedUserId == null || storedUserId == 0) {
        print('⚠️ [LoginController] WARNING: userId is missing after biometric login!');
        isBiometricLoading.value = false;
        loginError.value = 'User data not found. Please login with username and password.';
        return;
      }

      isBiometricLoading.value = false;

      // Show success message
      Get.snackbar(
        'Success',
        'Biometric login successful',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 1),
      );

      // Navigate to dashboard
      print('🚀 [LoginController] Navigating to dashboard after biometric login');
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
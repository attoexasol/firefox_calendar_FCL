import 'dart:convert';
import 'package:firefox_calendar/services/auth_service.dart';
import 'package:firefox_calendar/services/biometric_service.dart';
import 'package:firefox_calendar/features/settings/view/biometric_enrollment_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

/// Settings Controller
/// Converted from React UserSettings.tsx
/// Manages user settings, profile, notifications, and theme preferences
class SettingsController extends GetxController {
  // =========================================================
  // DEPENDENCIES
  // =========================================================
  final storage = GetStorage();
  final BiometricService _biometricService = BiometricService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  // =========================================================
  // API CONSTANTS
  // =========================================================
  static const String baseUrl = 'https://firefoxcalander.attoexasolutions.com/api';
  static const String profilePictureEndpoint = '$baseUrl/user/update_profile_photo';

  // =========================================================
  // REACTIVE PROPERTIES
  // =========================================================
  
  // User data
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userProfilePicture = ''.obs;
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final RxBool isAdmin = false.obs;

  // Active tab
  final RxString activeTab = 'profile'.obs;

  // Edit mode
  final RxBool isEditMode = false.obs;
  
  // Form controllers for edit mode
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  
  // Update profile loading and error states
  final RxBool isUpdatingProfile = false.obs;
  final RxString profileUpdateError = ''.obs;

  // Notification settings
  final RxMap<String, bool> notifications = <String, bool>{
    'meetingReminder': true,
    'scheduleUpdate': true,
    'lineManagerAction': false,
    'paymentUpdate': true,
  }.obs;

  // Theme settings
  final RxBool isDarkMode = false.obs;
  final RxBool biometricEnabled = false.obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isLogoutLoading = false.obs;

  // =========================================================
  // LIFECYCLE METHODS
  // =========================================================

  @override
  void onInit() {
    super.onInit();
    print('🔧 SettingsController initialized');
    _loadUserData();
    _loadSettings();
  }


  // =========================================================
  // DATA LOADING METHODS
  // =========================================================

  /// Load user data from storage
  void _loadUserData() {
    firstName.value = storage.read('firstName') ?? '';
    lastName.value = storage.read('lastName') ?? '';
    userName.value = storage.read('userName') ?? 'User';
    userEmail.value = storage.read('userEmail') ?? '';
    userPhone.value = storage.read('userPhone') ?? '';
    userProfilePicture.value = storage.read('userProfilePicture') ?? '';
    
    // Initialize form controllers with current values
    firstNameController.text = firstName.value;
    lastNameController.text = lastName.value;
    phoneController.text = userPhone.value;
    
    // Mock admin check - replace with actual logic
    isAdmin.value = userEmail.value == 'admin@gmail.com';
  }

  /// Refresh user data from storage (called after profile update)
  void refreshUserData() {
    firstName.value = storage.read('firstName') ?? '';
    lastName.value = storage.read('lastName') ?? '';
    userName.value = storage.read('userName') ?? 'User';
    userEmail.value = storage.read('userEmail') ?? '';
    userPhone.value = storage.read('userPhone') ?? '';
    userProfilePicture.value = storage.read('userProfilePicture') ?? '';
    
    // Update form controllers
    firstNameController.text = firstName.value;
    lastNameController.text = lastName.value;
    phoneController.text = userPhone.value;
    
    print('👤 User data refreshed in Settings');
  }

  // =========================================================
  // EDIT PROFILE METHODS
  // =========================================================

  /// Enable edit mode
  void enableEditMode() {
    isEditMode.value = true;
    profileUpdateError.value = '';
    // Pre-fill controllers with current values
    firstNameController.text = firstName.value;
    lastNameController.text = lastName.value;
    phoneController.text = userPhone.value;
  }

  /// Disable edit mode
  void disableEditMode() {
    isEditMode.value = false;
    profileUpdateError.value = '';
    // Reset controllers to current values
    firstNameController.text = firstName.value;
    lastNameController.text = lastName.value;
    phoneController.text = userPhone.value;
  }

  /// Update user profile
  Future<void> updateProfile() async {
    try {
      isUpdatingProfile.value = true;
      profileUpdateError.value = '';

      // Validate form
      if (firstNameController.text.trim().isEmpty) {
        profileUpdateError.value = 'First name is required';
        isUpdatingProfile.value = false;
        return;
      }

      if (lastNameController.text.trim().isEmpty) {
        profileUpdateError.value = 'Last name is required';
        isUpdatingProfile.value = false;
        return;
      }

      print('📝 [SettingsController] Updating profile...');
      print('   First Name: ${firstNameController.text.trim()}');
      print('   Last Name: ${lastNameController.text.trim()}');
      print('   Email: ${userEmail.value}');

      // Call update profile API
      final result = await _authService.updateUserProfile(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: userEmail.value, // Email is read-only, use current value
      );

      if (result['success'] == true) {
        // Refresh user data from storage (AuthService updates it)
        refreshUserData();
        
        // Exit edit mode
        isEditMode.value = false;
        
        // Show success message
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
        
        print('✅ [SettingsController] Profile updated successfully');
      } else {
        profileUpdateError.value = result['message'] ?? 'Failed to update profile. Please try again.';
        Get.snackbar(
          'Error',
          profileUpdateError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
        print('❌ [SettingsController] Profile update failed: ${result['message']}');
      }
    } catch (e) {
      print('💥 [SettingsController] Profile update error: $e');
      profileUpdateError.value = 'An error occurred. Please try again.';
      Get.snackbar(
        'Error',
        profileUpdateError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  /// Load settings from storage
  void _loadSettings() {
    // Load notification settings
    final savedNotifications = storage.read('notificationSettings');
    if (savedNotifications != null) {
      notifications.value = Map<String, bool>.from(savedNotifications);
    }

    // Load theme setting
    isDarkMode.value = Get.isDarkMode;
    
    // Load biometric setting
    biometricEnabled.value = storage.read('biometricEnabled') ?? false;
  }

  // =========================================================
  // UI METHODS
  // =========================================================

  /// Set active tab
  void setActiveTab(String tab) {
    activeTab.value = tab;
  }

  /// Toggle notification setting
  Future<void> toggleNotification(String key) async {
    notifications[key] = !(notifications[key] ?? false);
    await storage.write('notificationSettings', notifications);
    
    Get.snackbar(
      'Settings',
      'Notification preference updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  /// Toggle theme
  void toggleTheme() {
    Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
    isDarkMode.value = Get.isDarkMode;
    
    Get.snackbar(
      'Theme',
      'Theme changed successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  /// Open edit profile dialog
  void openEditProfile() {
    // Import is handled in the settings screen file to avoid circular dependencies
    Get.dialog(
      _buildEditProfileDialog(),
      barrierDismissible: false,
    ).then((_) {
      // Refresh user data after dialog closes
      refreshUserData();
    });
  }

  /// Build edit profile dialog (placeholder - will be replaced by proper dialog)
  Widget _buildEditProfileDialog() {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: const Text('Edit Profile dialog will be implemented here'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Close'),
        ),
      ],
    );
  }


  Future<void> selectProfilePicture() async {
  try {
    isUploadingImage.value = true;

    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    final result = await _authService.updateProfilePicture(image: image);

    if (result['success'] == true) {
      final String imageUrl = result['imageUrl'];

      // ✅ cache-busted URL
      final refreshedUrl = '$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      userProfilePicture.value = refreshedUrl;
      await storage.write('userProfilePicture', refreshedUrl);

      Get.snackbar(
        'Success',
        'Profile picture updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Upload failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to update profile picture',
      snackPosition: SnackPosition.BOTTOM,
    );
  } finally {
    isUploadingImage.value = false;
  }
}


  /// Upload profile picture to API (available for direct API calls if needed)
  Future<Map<String, dynamic>> uploadProfilePictureToAPI(XFile image) async {
    try {
      // Get stored user ID and API token
      final userId = storage.read('userId') ?? 0;
      final apiToken = storage.read('apiToken') ?? '';
      
      if (userId == 0) {
        return {
          'success': false,
          'message': 'User ID not found. Please log in again.',
        };
      }
      
      if (apiToken.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      print('🔵 Uploading profile picture to API...');
      print('🔵 User ID: $userId');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(profilePictureEndpoint));
      
      // Add headers with authentication
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiToken',
      });

      // Add user ID field (as per API specification)
      request.fields['user_id'] = userId.toString();

      // Add image file with the correct field name
      if (kIsWeb) {
        // For web, read bytes directly
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            bytes,
            filename: 'profile_picture.jpg',
          ),
        );
      } else {
        // For mobile, use file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            image.path,
          ),
        );
      }

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('🔵 Profile picture upload response status: ${response.statusCode}');
      print('🔵 Profile picture upload response body: $responseBody');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        
        if (responseData['status'] == true) {
          print('✅ Profile picture upload successful');
          
          // Extract the profile image URL from the response
          final profileImageUrl = responseData['data']?['profile_image'];
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Profile picture updated successfully',
            'imageUrl': profileImageUrl,
          };
        } else {
          print('❌ Profile picture upload failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Upload failed',
          };
        }
      } else {
        print('❌ Profile picture upload failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Upload failed. Please try again.',
        };
      }
    } catch (e) {
      print('💥 Profile picture upload network error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Show image source selection dialog
  Future<ImageSource?> _showImageSourceDialog() async {
    return await Get.dialog<ImageSource>(
      AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BIOMETRIC METHODS
  // =========================================================

  /// Handle biometric enrollment
  /// Shows dialog asking for username and password first
  Future<void> enrollBiometric() async {
    try {
      if (kIsWeb) {
        Get.snackbar(
          'Not Supported',
          'Biometric authentication is not supported on Web',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Check if biometric is available
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        Get.snackbar(
          'Not Available',
          'Biometric authentication not available on this device',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Show dialog asking for username and password
      await _showBiometricEnrollmentDialog();
    } catch (e) {
      print('Error enrolling biometric: $e');
      Get.snackbar(
        'Error',
        'Failed to enroll biometric authentication',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Show biometric enrollment dialog with username/password fields
  Future<void> _showBiometricEnrollmentDialog() async {
    await Get.dialog(
      BiometricEnrollmentDialog(
        onEnable: (email, password) async {
          await _verifyCredentialsAndEnableBiometric(email, password);
        },
      ),
      barrierDismissible: false,
    );
  }

  /// Verify credentials and enable biometric authentication
  Future<void> _verifyCredentialsAndEnableBiometric(
    String email,
    String password,
  ) async {
    try {
      isLoading.value = true;

      print('🔐 [SettingsController] Verifying credentials for biometric enrollment...');

      // Step 1: Verify credentials by attempting login
      final loginResult = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (loginResult['success'] != true) {
        // Credentials are invalid
        Get.back(); // Close dialog
        Get.snackbar(
          'Authentication Failed',
          loginResult['message'] ?? 'Invalid email or password. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
        isLoading.value = false;
        return;
      }

      // Step 2: Extract API token from login response
      final loginData = loginResult['data'];
      final apiToken = loginData?['api_token'] ?? '';
      
      if (apiToken.isEmpty) {
        Get.back(); // Close dialog
        Get.snackbar(
          'Error',
          'Failed to get API token. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
        isLoading.value = false;
        return;
      }

      print('✅ [SettingsController] Credentials verified, API token received');
      print('🔑 [SettingsController] API Token: ${apiToken.substring(0, 20)}...');

      // Step 3: Store is_biometric_enable flag and API token in local storage
      await storage.write('is_biometric_enable', true);
      await storage.write('biometric_api_token', apiToken);
      await storage.write('biometricEnabled', true);
      await storage.write('biometricSetupDate', DateTime.now().toIso8601String());
      
      print('✅ [SettingsController] Biometric flags and API token stored in local storage');

      // Step 4: Authenticate using biometric (fingerprint/face ID) on device level
      print('🔐 [SettingsController] Requesting device-level biometric authentication...');
      final authenticated = await _biometricService.authenticateToEnable();

      if (authenticated) {
        // Step 5: Device-level biometric authentication successful, now register with API
        print('✅ [SettingsController] Device biometric authenticated, registering with API...');
        
        final registerResult = await _authService.registerBiometric(
          apiToken: apiToken,
        );

        if (registerResult['success'] == true) {
          // Extract and store the new biometric_token from API response
          final registerData = registerResult['data'];
          final newBiometricToken = registerData?['biometric_token'] ?? '';
          
          if (newBiometricToken.isNotEmpty) {
            await storage.write('biometric_token', newBiometricToken);
            print('✅ [SettingsController] New biometric_token stored: ${newBiometricToken.substring(0, 20)}...');
          } else {
            print('⚠️ [SettingsController] WARNING: No biometric_token in register response');
          }
          
          // Biometric enrollment and registration successful
          biometricEnabled.value = true;
          
          Get.back(); // Close dialog

          Get.snackbar(
            'Success',
            'Biometric login enrolled and registered successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2),
          );

          print('✅ [SettingsController] Biometric enrollment and API registration completed successfully');
        } else {
          // API registration failed, but device biometric is enabled
          print('⚠️ [SettingsController] Device biometric enabled but API registration failed');
          
          Get.back(); // Close dialog
          
          Get.snackbar(
            'Partial Success',
            'Biometric enabled on device, but server registration failed. ${registerResult['message'] ?? ''}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade900,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        // Biometric authentication failed or cancelled
        // Clear the flags since enrollment didn't complete
        await storage.remove('is_biometric_enable');
        await storage.remove('biometric_api_token');
        await storage.write('biometricEnabled', false);
        
        Get.back(); // Close dialog
        Get.snackbar(
          'Failed',
          'Biometric enrollment failed or was cancelled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 2),
        );
        
        print('❌ [SettingsController] Biometric authentication failed or cancelled');
      }
    } catch (e) {
      print('💥 [SettingsController] Error during biometric enrollment: $e');
      
      // Clear flags on error
      await storage.remove('is_biometric_enable');
      await storage.remove('biometric_api_token');
      await storage.write('biometricEnabled', false);
      
      Get.back(); // Close dialog
      Get.snackbar(
        'Error',
        'Failed to enroll biometric authentication. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================
  // AUTHENTICATION METHODS
  // =========================================================

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

  // =========================================================
  // UTILITY METHODS
  // =========================================================

  /// Get user initials for avatar
  String getUserInitials() {
    if (userName.value.isEmpty) return 'U';

    final parts = userName.value.trim().split(' ');
    if (parts.isEmpty) return 'U';

    return parts
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join('')
        .toUpperCase();
  }

  /// Get notification setting display text
  String getNotificationDisplayText(String key) {
    switch (key) {
      case 'meetingReminder':
        return 'Meeting Reminder';
      case 'scheduleUpdate':
        return 'Schedule Update';
      case 'lineManagerAction':
        return 'Line Manager Action';
      case 'paymentUpdate':
        return 'Payment Update';
      default:
        return key;
    }
  }

  /// Get notification setting description
  String getNotificationDescription(String key) {
    switch (key) {
      case 'meetingReminder':
        return 'Get notified before meetings start';
      case 'scheduleUpdate':
        return 'Receive updates when schedules change';
      case 'lineManagerAction':
        return 'Notifications from your line manager';
      case 'paymentUpdate':
        return 'Updates about payment status';
      default:
        return '';
    }
  }
}
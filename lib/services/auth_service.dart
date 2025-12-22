import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// User API Service
/// Centralized service for all user-related API operations
/// Handles registration, login, logout, profile updates, and profile picture uploads
class AuthService {
  // =========================================================
  // CONSTANTS
  // =========================================================
  static const String baseUrl = 'https://firefoxcalander.attoexasolutions.com/api';
  
  // API Endpoints
  static const String registrationEndpoint = '$baseUrl/user/registration';
  static const String loginEndpoint = '$baseUrl/user/login';
  static const String logoutEndpoint = '$baseUrl/user/logout';
  static const String updateProfileEndpoint = '$baseUrl/user/update';
  static const String updateProfilePhotoEndpoint = '$baseUrl/user/update_profile_photo';
  static const String biometricRegisterEndpoint = '$baseUrl/user/biometric_register';
  static const String biometricLoginEndpoint = '$baseUrl/user/biometric_login';
  static const String createEventEndpoint = '$baseUrl/create/events';
  static const String getSingleEventEndpoint = '$baseUrl/single/events';
  static const String getAllEventsEndpoint = '$baseUrl/all/events';
  static const String getMyEventsEndpoint = '$baseUrl/my/events';
  
  // =========================================================
  // DEPENDENCIES
  // =========================================================
  final GetStorage _storage = GetStorage();

  
  /// Register new user account
  /// Parameters: firstName, lastName, email, password
  /// Returns: Map with success status, message, and user data
  Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    try {
      print('ðŸ”µ [AuthService] Starting user registration...');
      
      final requestData = {
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim(),
      'password': password,
      'if_biometric_enable': 1, // ✅ MUST be int
      'is_notification_allowed': 1,
      'is_meeting_notify': 1,
      'is_scheduled_update_notify': 1,
      'is_line_manager_action': 1,
      'is_payment_update': 1,
      'is_user_home': 'light',
    };

      print('ðŸ”µ [AuthService] Registration request data: $requestData');

      final response = await http.post(
        Uri.parse(registrationEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      return _handleResponse(response, 'Registration');
    } catch (e) {
      print('ðŸ’¥ [AuthService] Registration error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }


  /// Login user with email and password
  /// Parameters: email, password
  /// Returns: Map with success status, message, and user data
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      print('ðŸ”µ [AuthService] Starting user login...');
      
      final requestData = {
        'email': email.trim(),
        'password': password,
      };

      print('ðŸ”µ [AuthService] Login request for email: $email');

      final response = await http.post(
        Uri.parse(loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      final result = _handleResponse(response, 'Login');
      
      // Store user data if login successful
      if (result['success'] == true && result['data'] != null) {
        await _storeUserData(result['data']);
      }
      
      return result;
    } catch (e) {
      print('ðŸ’¥ [AuthService] Login error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  
  /// Update user profile information
  /// Parameters: firstName, lastName, email
  /// Returns: Map with success status, message, and updated user data
  Future<Map<String, dynamic>> updateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      print('ðŸ”µ [AuthService] Starting profile update...');
      
      final userId = _storage.read('userId') ?? 0;
      final apiToken = _storage.read('apiToken') ?? '';
      
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

      final requestData = {
        'user_id': userId,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim(),
      };

      print('ðŸ”µ [AuthService] Profile update request: $requestData');

      final response = await http.post(
        Uri.parse(updateProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: json.encode(requestData),
      );

      final result = _handleResponse(response, 'Profile Update');
      
      // Update local storage if successful
      if (result['success'] == true && result['data'] != null) {
        await _updateLocalUserData(result['data']);
      }
      
      return result;
    } catch (e) {
      print('ðŸ’¥ [AuthService] Profile update error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // =========================================================
  // UPDATE PROFILE PICTURE
  // =========================================================
  
  /// Update user profile picture
  /// Parameters: XFile image from image picker
  /// Returns: Map with success status, message, and image URL
  Future<Map<String, dynamic>> updateProfilePicture({
    required XFile image,
  }) async {
    try {
      print('ðŸ”µ [AuthService] Starting profile picture update...');
      
      final userId = _storage.read('userId') ?? 0;
      final apiToken = _storage.read('apiToken') ?? '';
      
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

      print('ðŸ”µ [AuthService] Creating multipart request for user ID: $userId');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(updateProfilePhotoEndpoint));
      
      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiToken',
      });

      // Add user ID field
      request.fields['user_id'] = userId.toString();

      // Add image file
      if (kIsWeb) {
        // For web platform
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image', // âœ… Correct field name as per API spec
            bytes,
            filename: 'profile_picture.jpg',
          ),
        );
      } else {
        // For mobile platforms
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image', // âœ… Correct field name as per API spec
            image.path,
          ),
        );
      }

      // Send request
      print('ðŸ”µ [AuthService] Sending profile picture upload request...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('ðŸ”µ [AuthService] Profile picture response status: ${response.statusCode}');
      print('ðŸ”µ [AuthService] Profile picture response body: $responseBody');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        
        if (responseData['status'] == true) {
          print('âœ… [AuthService] Profile picture upload successful');
          
          // Extract image URL from response
          final profileImageUrl = responseData['data']?['profile_image'];
          
          // Update local storage
          if (profileImageUrl != null) {
            await _storage.write('userProfilePicture', profileImageUrl);
          }
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Profile picture updated successfully',
            'imageUrl': profileImageUrl,
            'data': responseData['data'],
          };
        } else {
          print('âŒ [AuthService] Profile picture upload failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Upload failed',
          };
        }
      } else {
        print('âŒ [AuthService] Profile picture upload failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Upload failed. Please try again.',
        };
      }
    } catch (e) {
      print('ðŸ’¥ [AuthService] Profile picture upload error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> logoutUser() async {
    print('═══════════════════════════════════════════════════════════');
    print('🔵 [API CALL] User Logout');
    print('═══════════════════════════════════════════════════════════');

    final apiToken = _storage.read('apiToken') ?? '';

    try {
      if (apiToken.isNotEmpty) {
        final requestData = {
          'api_token': apiToken,
        };

        // Log request details
        print('📍 URL: $logoutEndpoint');
        print('🔷 METHOD: POST');
        print('📤 REQUEST HEADERS:');
        print('   Content-Type: application/json');
        print('   Accept: application/json');
        print('📤 REQUEST BODY:');
        print('   ${json.encode(requestData)}');

        final response = await http.post(
          Uri.parse(logoutEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(requestData),
        );

        // Log response details
        print('📥 RESPONSE STATUS: ${response.statusCode}');
        print('📥 RESPONSE BODY:');
        print('   ${response.body}');
        print('═══════════════════════════════════════════════════════════');
      }
    } catch (e) {
      print('⚠️ [API ERROR] Logout API error: $e');
      print('═══════════════════════════════════════════════════════════');
      // Ignore API failure
    } finally {
      // 🔥 ALWAYS clear local session
      await clearUserSession();
    }

    return {
      'success': true,
      'message': 'Logged out successfully',
    };
  }

  // =========================================================
  // BIOMETRIC REGISTER API
  // =========================================================

  /// Register biometric authentication with the server
  /// Parameters: apiToken
  /// Returns: Map with success status and message
  Future<Map<String, dynamic>> registerBiometric({
    required String apiToken,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════════');
      print('🔵 [API CALL] Register Biometric');
      print('═══════════════════════════════════════════════════════════');
      
      final requestData = {
        'api_token': apiToken,
      };

      // Log request details
      print('📍 URL: $biometricRegisterEndpoint');
      print('🔷 METHOD: POST');
      print('📤 REQUEST HEADERS:');
      print('   Content-Type: application/json');
      print('   Accept: application/json');
      print('📤 REQUEST BODY:');
      print('   ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse(biometricRegisterEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      // Log response details
      print('📥 RESPONSE STATUS: ${response.statusCode}');
      print('📥 RESPONSE BODY:');
      print('   ${response.body}');
      print('═══════════════════════════════════════════════════════════');

      return _handleResponse(response, 'Biometric Register');
    } catch (e) {
      print('❌ [API ERROR] Biometric register failed: $e');
      print('═══════════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // =========================================================
  // BIOMETRIC LOGIN API
  // =========================================================

  /// Login using biometric authentication
  /// Parameters: apiToken, biometricToken
  /// Returns: Map with success status, message, and user data
  Future<Map<String, dynamic>> biometricLogin({
    required String apiToken,
    required String biometricToken,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════════');
      print('🔵 [API CALL] Biometric Login');
      print('═══════════════════════════════════════════════════════════');
      
      final requestData = {
        'api_token': apiToken,
        'biometric_token': biometricToken,
      };

      // Log request details
      print('📍 URL: $biometricLoginEndpoint');
      print('🔷 METHOD: POST');
      print('📤 REQUEST HEADERS:');
      print('   Content-Type: application/json');
      print('   Accept: application/json');
      print('📤 REQUEST BODY:');
      print('   ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse(biometricLoginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      // Log response details
      print('📥 RESPONSE STATUS: ${response.statusCode}');
      print('📥 RESPONSE BODY:');
      print('   ${response.body}');
      print('═══════════════════════════════════════════════════════════');

      final result = _handleResponse(response, 'Biometric Login');
      
      // Store user data if login successful
      if (result['success'] == true && result['data'] != null) {
        await _storeUserData(result['data']);
      }
      
      return result;
    } catch (e) {
      print('❌ [API ERROR] Biometric login failed: $e');
      print('═══════════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // =========================================================
  // CREATE EVENT API
  // =========================================================

  /// Create a new event
  /// Parameters: title, date, startTime, endTime, description, eventTypeId
  /// Returns: Map with success status, message, and event data
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    required String startTime,
    required String endTime,
    String? description,
    required int eventTypeId,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════════');
      print('🔵 [API CALL] Create Event');
      print('═══════════════════════════════════════════════════════════');
      
      final apiToken = _storage.read('apiToken') ?? '';
      
      if (apiToken.isEmpty) {
        print('❌ [API ERROR] API token not found');
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final requestData = {
        'api_token': apiToken,
        'title': title.trim(),
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'event_type_id': eventTypeId,
      };

      // Add description if provided
      if (description != null && description.trim().isNotEmpty) {
        requestData['description'] = description.trim();
      }

      // Log request details
      print('📍 URL: $createEventEndpoint');
      print('🔷 METHOD: POST');
      print('📤 REQUEST HEADERS:');
      print('   Content-Type: application/json');
      print('   Accept: application/json');
      print('📤 REQUEST BODY:');
      print('   ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse(createEventEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      // Log response details
      print('📥 RESPONSE STATUS: ${response.statusCode}');
      print('📥 RESPONSE BODY:');
      print('   ${response.body}');
      print('═══════════════════════════════════════════════════════════');

      return _handleResponse(response, 'Create Event');
    } catch (e) {
      print('❌ [API ERROR] Create event failed: $e');
      print('═══════════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // =========================================================
  // GET SINGLE EVENT API
  // =========================================================

  /// Get single by ID
  /// Parameters: eventId
  /// Returns: Map with success status, message, and event data
  Future<Map<String, dynamic>> getSingleEvent({
    required int eventId,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════════');
      print('🔵 [API CALL] Get Single Event');
      print('═══════════════════════════════════════════════════════════');
      
      final apiToken = _storage.read('apiToken') ?? '';
      
      if (apiToken.isEmpty) {
        print('❌ [API ERROR] API token not found');
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final requestData = {
        'id': eventId,
      };

      // Log request details
      print('📍 URL: $getSingleEventEndpoint');
      print('🔷 METHOD: POST');
      print('📤 REQUEST HEADERS:');
      print('   Content-Type: application/json');
      print('   Accept: application/json');
      print('📤 REQUEST BODY:');
      print('   ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse(getSingleEventEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      // Log response details
      print('📥 RESPONSE STATUS: ${response.statusCode}');
      print('📥 RESPONSE BODY:');
      print('   ${response.body}');
      print('═══════════════════════════════════════════════════════════');

      return _handleResponse(response, 'Get Single Event');
    } catch (e) {
      print('❌ [API ERROR] Get single event failed: $e');
      print('═══════════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // =========================================================
  // GET ALL EVENTS API
  // =========================================================

  /// Get all events for the logged-in user
  /// Parameters: Optional range (day/week/month), currentDate (YYYY-MM-DD), event_type_id, sub_type_name, sub_type_description
  /// Returns: Map with success status, message, and list of events
  Future<Map<String, dynamic>> getAllEvents({
    String? range,
    String? currentDate,
    int? eventTypeId,
    String? subTypeName,
    String? subTypeDescription,
  }) async {
    try {
      final apiToken = _storage.read('apiToken') ?? '';
      
      if (apiToken.isEmpty) {
        print('❌ [API ERROR] Get All Events: API token not found');
        print('═══════════════════════════════════════════════════════════');
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final queryParams = <String, dynamic>{
        'api_token': apiToken,
      };

      // Add date/range parameters if provided (for day/week/month filtering)
      if (range != null && range.isNotEmpty) {
        queryParams['range'] = range;
      }
      if (currentDate != null && currentDate.isNotEmpty) {
        queryParams['current_date'] = currentDate;
      }

      // Add optional event type parameters if provided
      if (eventTypeId != null) {
        queryParams['event_type_id'] = eventTypeId;
      }
      if (subTypeName != null && subTypeName.isNotEmpty) {
        queryParams['sub_type_name'] = subTypeName;
      }
      if (subTypeDescription != null && subTypeDescription.isNotEmpty) {
        queryParams['sub_type_description'] = subTypeDescription;
      }

      // Build URL with query parameters (GET request)
      final uri = Uri.parse(getAllEventsEndpoint).replace(
        queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())),
      );

      // Log request details
      print('═══════════════════════════════════════════════════════════');
      print('🔵 [API CALL] Get All Events');
      print('═══════════════════════════════════════════════════════════');
      print('📍 URL: $uri');
      print('🔷 METHOD: GET');
      print('📤 REQUEST HEADERS:');
      print('   Content-Type: application/json');
      print('   Accept: application/json');
      print('📤 QUERY PARAMETERS:');
      queryParams.forEach((key, value) {
        if (key == 'api_token') {
          print('   $key: ${value.toString().substring(0, 20)}...');
        } else {
          print('   $key: $value');
        }
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Log response details
      print('📥 RESPONSE STATUS: ${response.statusCode}');
      print('📥 RESPONSE BODY:');
      print('   ${response.body}');
      print('═══════════════════════════════════════════════════════════');

      return _handleResponse(response, 'Get All Events');
    } catch (e) {
      print('❌ [API ERROR] Get All Events failed: $e');
      print('═══════════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // =========================================================
  // GET MY EVENTS API
  // =========================================================

  /// Get current user's events
  /// Parameters: range (day/week/month), currentDate (YYYY-MM-DD)
  /// Returns: Map with success status, message, meta, and list of events
  Future<Map<String, dynamic>> getMyEvents({
    required String range,
    required String currentDate,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════════');
      print('🔵 [API CALL] Get My Events');
      print('═══════════════════════════════════════════════════════════');
      
      final apiToken = _storage.read('apiToken') ?? '';
      
      if (apiToken.isEmpty) {
        print('❌ [API ERROR] API token not found');
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      // Build URL with query parameters (GET request)
      final queryParams = {
        'api_token': apiToken,
        'range': range,
        'current_date': currentDate,
      };

      final uri = Uri.parse(getMyEventsEndpoint).replace(
        queryParameters: queryParams,
      );

      // Log request details
      print('📍 URL: $uri');
      print('🔷 METHOD: GET');
      print('📤 REQUEST HEADERS:');
      print('   Content-Type: application/json');
      print('   Accept: application/json');
      print('📤 QUERY PARAMETERS:');
      queryParams.forEach((key, value) {
        if (key == 'api_token') {
          print('   $key: ${value.toString().substring(0, 20)}...');
        } else {
          print('   $key: $value');
        }
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Log response details
      print('📥 RESPONSE STATUS: ${response.statusCode}');
      print('📥 RESPONSE BODY:');
      print('   ${response.body}');
      print('═══════════════════════════════════════════════════════════');

      return _handleResponse(response, 'Get My Events');
    } catch (e) {
      print('❌ [API ERROR] Get my events failed: $e');
      print('═══════════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // =========================================================
  // HELPER METHODS
  // =========================================================
  
  /// Handle HTTP response and extract relevant data
  Map<String, dynamic> _handleResponse(http.Response response, String operation) {
    print('ðŸ”µ [AuthService] $operation response status: ${response.statusCode}');
    print('ðŸ”µ [AuthService] $operation response body: ${response.body}');

    try {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? '$operation successful',
            'data': responseData['data'],
            'meta': responseData['meta'], // Include meta for my/events endpoint
          };
        } else {
          print('âŒ [AuthService] $operation failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? '$operation failed',
            'data': responseData['data'],
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Invalid credentials. Please check your email and password.',
        };
      } else {
        // Try to extract error message from response
        try {
          final responseData = json.decode(response.body);
          return {
            'success': false,
            'message': responseData['message'] ?? '$operation failed. Please try again.',
          };
        } catch (e) {
          return {
            'success': false,
            'message': '$operation failed. Please try again.',
          };
        }
      }
    } catch (e) {
      print('ðŸ’¥ [AuthService] Error parsing $operation response: $e');
      return {
        'success': false,
        'message': 'Invalid response format. Please try again.',
        'error': e.toString(),
      };
    }
  }
  
  /// Store user data in local storage after successful login/registration
  Future<void> _storeUserData(Map<String, dynamic> userData) async {
    try {
      print('ðŸ’¾ [AuthService] Storing user data in local storage...');
      
      // Store basic user info
      if (userData['id'] != null) await _storage.write('userId', userData['id']);
      if (userData['first_name'] != null) await _storage.write('firstName', userData['first_name']);
      if (userData['last_name'] != null) await _storage.write('lastName', userData['last_name']);
      if (userData['email'] != null) await _storage.write('userEmail', userData['email']);
      
      // Store full name
      final fullName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
      await _storage.write('userName', fullName);
      
      // Store API token
      if (userData['api_token'] != null) {
        await _storage.write('apiToken', userData['api_token']);
        print('✅ [AuthService] API token stored successfully');
      } else {
        print('⚠️ [AuthService] WARNING: api_token not found in response data');
      }
      
      // Store biometric token (for biometric login API)
      if (userData['biometric_token'] != null) {
        await _storage.write('biometric_token', userData['biometric_token']);
        print('✅ [AuthService] Biometric token stored successfully');
      }
      
      // Store profile image
      if (userData['profile_image'] != null) {
        await _storage.write('userProfilePicture', userData['profile_image']);
      } else if (userData['profile_photo'] != null) {
        await _storage.write('userProfilePicture', userData['profile_photo']);
      }
      
      // Store theme preference
      if (userData['is_user_home'] != null) await _storage.write('userTheme', userData['is_user_home']);
      
      // Set login status
      await _storage.write('isLoggedIn', true);
      
      // Set session expiry (30 days from now)
      final sessionExpiry = DateTime.now().add(const Duration(days: 30));
      await _storage.write('sessionExpiry', sessionExpiry.toIso8601String());
      await _storage.write('loginTimestamp', DateTime.now().toIso8601String());
      
      // Verify token was stored correctly
      final storedToken = _storage.read('apiToken');
      if (storedToken != null && storedToken.toString().isNotEmpty) {
        print('✅ [AuthService] Token verification: apiToken stored and verified');
      } else {
        print('⚠️ [AuthService] WARNING: Token verification failed - apiToken is missing or empty');
      }
      
      print('âœ… [AuthService] User data stored successfully');
    } catch (e) {
      print('âŒ [AuthService] Error storing user data: $e');
    }
  }
  
  /// Update local user data after profile update
  Future<void> _updateLocalUserData(Map<String, dynamic> userData) async {
    try {
      print('ðŸ’¾ [AuthService] Updating local user data...');
      
      if (userData['first_name'] != null) await _storage.write('firstName', userData['first_name']);
      if (userData['last_name'] != null) await _storage.write('lastName', userData['last_name']);
      if (userData['email'] != null) await _storage.write('userEmail', userData['email']);
      
      // Update full name
      final fullName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
      await _storage.write('userName', fullName);
      
      // Update API token if provided
      if (userData['api_token'] != null) await _storage.write('apiToken', userData['api_token']);
      
      print('âœ… [AuthService] Local user data updated successfully');
    } catch (e) {
      print('âŒ [AuthService] Error updating local user data: $e');
    }
  }
  
  /// Clear all user session data
  Future<void> clearUserSession() async {
    try {
      print('ðŸ—‘ï¸ [AuthService] Clearing user session data...');
      
      // Clear authentication data
      await _storage.remove('isLoggedIn');
      await _storage.remove('apiToken');
      await _storage.remove('userId');
      
      // Clear user profile data
      await _storage.remove('userEmail');
      await _storage.remove('userName');
      await _storage.remove('firstName');
      await _storage.remove('lastName');
      await _storage.remove('userPhone');
      await _storage.remove('userProfilePicture');
      
      // Clear session data
      await _storage.remove('sessionExpiry');
      await _storage.remove('lastLoginEmail');
      await _storage.remove('loginTimestamp');
      
      // Keep notification and biometric preferences
      // await _storage.remove('notificationSettings');
      // await _storage.remove('biometricEnabled');
      
      print('âœ… [AuthService] User session cleared successfully');
    } catch (e) {
      print('âŒ [AuthService] Error clearing session: $e');
    }
  }
  
  // =========================================================
  // UTILITY METHODS
  // =========================================================
  
  /// Check if user is currently logged in
  bool isLoggedIn() {
    final loggedIn = _storage.read('isLoggedIn') ?? false;
    final apiToken = _storage.read('apiToken') ?? '';
    final sessionExpiry = _storage.read('sessionExpiry');
    
    if (!loggedIn || apiToken.isEmpty) {
      return false;
    }
    
    // Check session expiry
    if (sessionExpiry != null) {
      try {
        final expiryDate = DateTime.parse(sessionExpiry);
        if (DateTime.now().isAfter(expiryDate)) {
          print('ðŸ• [AuthService] Session expired');
          return false;
        }
      } catch (e) {
        print('âŒ [AuthService] Error parsing session expiry: $e');
        return false;
      }
    }
    
    return true;
  }
  
  /// Get current user data from storage
  Map<String, dynamic> getCurrentUserData() {
    return {
      'userId': _storage.read('userId'),
      'firstName': _storage.read('firstName'),
      'lastName': _storage.read('lastName'),
      'userName': _storage.read('userName'),
      'userEmail': _storage.read('userEmail'),
      'userProfilePicture': _storage.read('userProfilePicture'),
      'apiToken': _storage.read('apiToken'),
      'isLoggedIn': _storage.read('isLoggedIn') ?? false,
      'sessionExpiry': _storage.read('sessionExpiry'),
      'loginTimestamp': _storage.read('loginTimestamp'),
    };
  }
}
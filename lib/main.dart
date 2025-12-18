import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


import 'app/routes/app_pages.dart';
import 'app/bindings/initial_binding.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage for local storage
  await GetStorage.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Check if user is already logged in and determine initial route
  String _getInitialRoute() {
    final storage = GetStorage();
    final isLoggedIn = storage.read('isLoggedIn') ?? false;
    final userEmail = storage.read('userEmail') ?? '';

    print('🔍 Session check: isLoggedIn=$isLoggedIn, userEmail=$userEmail');

    // If user is logged in and has valid session, go to dashboard
    if (isLoggedIn && userEmail.isNotEmpty) {
      print('✅ User has valid session, redirecting to dashboard');
      return '/dashboard';
    }

    print('❌ No valid session, showing login screen');
    return AppPages.initial; // This should be '/login'
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // App Configuration
      title: 'Firefox Workplace Calendar',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Use system theme by default
      // Enhanced Routing Configuration with Session Persistence
      initialRoute:
          _getInitialRoute(), // Dynamic initial route based on login status
      getPages: AppPages.routes,
      initialBinding: InitialBinding(),

      // Transitions
      defaultTransition: AppPages.defaultTransition,
      transitionDuration: AppPages.defaultTransitionDuration,

      // Enhanced Unknown Route Handler
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Page not found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/login'),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      ),

      // Enhanced Builder for additional configurations
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling beyond certain limits
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
            ),
          ),
          child: child!,
        );
      },

      // Enable navigation observers for debugging (optional)
      navigatorObservers: [
        GetObserver(), // Built-in GetX observer
      ],

      // Add error handling for routes
      onGenerateRoute: (settings) {
        print('🔄 Navigating to: ${settings.name}');
        return null; // Let GetX handle it
      },
    );
  }
}

/// Session Manager Utility Class
/// Handles session persistence and validation
class SessionManager {
  static final GetStorage _storage = GetStorage();

  /// Check if user has valid session
  static bool get isLoggedIn {
    final isLoggedIn = _storage.read('isLoggedIn') ?? false;
    final userEmail = _storage.read('userEmail') ?? '';
    final sessionExpiry = _storage.read('sessionExpiry');

    // Check if session is expired
    if (sessionExpiry != null) {
      final expiryDate = DateTime.parse(sessionExpiry);
      if (DateTime.now().isAfter(expiryDate)) {
        print('🕐 Session expired, clearing storage');
        clearSession();
        return false;
      }
    }

    return isLoggedIn && userEmail.isNotEmpty;
  }

  /// Save login session
  static Future<void> saveSession({
    required String email,
    String? userName,
    bool biometricEnabled = false,
    Duration? sessionDuration,
  }) async {
    final expiry = DateTime.now().add(
      sessionDuration ?? const Duration(days: 30),
    );

    await _storage.write('isLoggedIn', true);
    await _storage.write('userEmail', email);
    await _storage.write('sessionExpiry', expiry.toIso8601String());

    if (userName != null) {
      await _storage.write('userName', userName);
    }

    if (biometricEnabled) {
      await _storage.write('biometricEnabled', true);
    }

    print('✅ Session saved for $email, expires: $expiry');
  }

  /// Clear login session
  static Future<void> clearSession() async {
    await _storage.remove('isLoggedIn');
    await _storage.remove('userEmail');
    await _storage.remove('userName');
    await _storage.remove('sessionExpiry');
    // Keep biometric preference

    print('🗑️ Session cleared');
  }

  /// Get user session data
  static Map<String, dynamic> getSessionData() {
    return {
      'isLoggedIn': _storage.read('isLoggedIn') ?? false,
      'userEmail': _storage.read('userEmail') ?? '',
      'userName': _storage.read('userName') ?? '',
      'biometricEnabled': _storage.read('biometricEnabled') ?? false,
      'sessionExpiry': _storage.read('sessionExpiry'),
    };
  }

  /// Extend session expiry
  static Future<void> extendSession({Duration? extension}) async {
    if (!isLoggedIn) return;

    final newExpiry = DateTime.now().add(extension ?? const Duration(days: 30));
    await _storage.write('sessionExpiry', newExpiry.toIso8601String());

    print('⏰ Session extended until: $newExpiry');
  }
}

import 'package:firefox_calendar/features/auth/view/create_account_screens.dart';
import 'package:firefox_calendar/features/auth/view/forget_password_screen.dart';
import 'package:firefox_calendar/features/auth/view/login_screen.dart';
import 'package:firefox_calendar/features/calendar/view/calendar_screen.dart';
import 'package:firefox_calendar/features/calendar/view/create_event_screen.dart';
import 'package:firefox_calendar/features/dashboard/view/dashbord_screen.dart';
import 'package:firefox_calendar/features/hours/view/hours_screen.dart';
import 'package:firefox_calendar/features/payroll/view/payroll_screen_updated.dart';
import 'package:firefox_calendar/features/profile/controller/edit_profile_controller.dart';
import 'package:firefox_calendar/features/profile/view/edit_profile_screen.dart';
import 'package:firefox_calendar/features/settings/view/settings_screen.dart';
import 'package:firefox_calendar/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// App page configurations with bindings and transitions
class AppPages {
  AppPages._();

  /// Initial route
  static const String initial = AppRoutes.login;

  /// All app pages with their bindings and transitions
  static final routes = <GetPage>[
    // // ========== AUTH PAGES ==========
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.register,
      page: () => const CreateAccountScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ========== MAIN PAGES ==========
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Calendar Page - Now fully implemented
    GetPage(
      name: AppRoutes.calendar,
      page: () => const CalendarScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Create Event Page
    GetPage(
      name: AppRoutes.createEvent,
      page: () => const CreateEventScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Hours Page - Converted from React with tabs functionality
    GetPage(
      name: AppRoutes.hours,
      page: () => const HoursScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Payroll Page - Converted from React with admin/employee views
    GetPage(
      name: AppRoutes.payroll,
      page: () => const PayrollScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Settings Page - Converted from React with profile and leave sections
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // // Edit Profile Page - Separate screen for editing profile information
    // GetPage(
    //   name: AppRoutes.editProfile,
    //   page: () => const EditProfileScreen(),
    //   binding: BindingsBuilder(() {
    //     Get.put(EditProfileController());
    //   }),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<EditProfileController>(() => EditProfileController());
      }),
    ),

  ];

  /// Default page transition
  static const Transition defaultTransition = Transition.rightToLeft;

  /// Default transition duration
  static const Duration defaultTransitionDuration = Duration(milliseconds: 300);
}

/// Placeholder screen for routes not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
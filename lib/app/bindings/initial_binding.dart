import 'package:firefox_calendar/features/auth/controller/createaccount_controller.dart';
import 'package:firefox_calendar/features/auth/controller/forgot_password_controller.dart';
import 'package:firefox_calendar/features/auth/controller/login_controller.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/controller/create_event_controller.dart';
import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:firefox_calendar/features/hours/controller/hours_controller.dart';
import 'package:firefox_calendar/features/payroll/controller/payroll_controller.dart';
import 'package:firefox_calendar/features/profile/controller/edit_profile_controller.dart';
import 'package:firefox_calendar/features/settings/controller/settings_controller.dart';
import 'package:get/get.dart';


/// Initial binding for global dependencies
/// Controllers initialized here are available throughout the app lifecycle
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateAccountController>(
      () => CreateAccountController(),
      fenix: true,
    );

    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    
    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController(), fenix: true);
    
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<CalendarController>(() => CalendarController(), fenix: true);
    Get.lazyPut<CreateEventController>(
      () => CreateEventController(),
      fenix: true,
    );

    Get.lazyPut<HoursController>(
      () => HoursController(),
      fenix: true,
    );

    Get.lazyPut<PayrollController>(
      () => PayrollController(),
      fenix: true,
    );
  
    Get.lazyPut<SettingsController>(
      () => SettingsController(),
      fenix: true,
    );

    // Edit Profile Controller for separate edit profile screen
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(),
      fenix: true,
    );
  }
}
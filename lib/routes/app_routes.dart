/// App route definitions
/// All application routes are defined here
class AppRoutes {
  AppRoutes._();

  // ========== AUTH ROUTES ==========
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  // ========== MAIN ROUTES ==========
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String calendar = '/calendar';
  static const String hours = '/hours';
  static const String payroll = '/payroll';
  static const String createEvent = '/create-event';

  // ========== PROFILE ROUTES ==========
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  // ========== OTHER ROUTES ==========
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String help = '/help';
  static const String about = '/about';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String privacyPolicy = '/privacy-policy';

  // Add more routes as needed following the same pattern
}

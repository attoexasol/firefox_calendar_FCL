import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/auth/controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Updated Login Screen with New Biometric Button Widget
/// Integrates the converted React biometric button component
class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is already registered via InitialBinding with fenix: true
    // Using Get.find() through GetView's controller getter
    print('📷 LoginScreen build called');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Theme Toggle
            _buildTopBar(context),

            // Center Section - Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 448,
                    ), // max-w-md
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Logo and Title
                        _buildHeader(context),

                        const SizedBox(height: 32),

                        // Form Section
                        _buildForm(context),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer Bar
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  /// Top bar with theme toggle
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {
              // Toggle theme
              Get.changeThemeMode(
                Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
            },
            icon: Icon(
              Get.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              size: 20,
            ),
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          ),
        ],
      ),
    );
  }

  /// Header with logo and title
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          height: 100,
          width: 250,
          decoration: BoxDecoration(
            color: isDark ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          padding: EdgeInsets.all(isDark ? 8 : 0),
          child: Image.asset(
            "assets/images/firefox_logo.png",
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 20),

        // App Title
        Text(
          'Firefox Workplace Calendar',
          style: AppTextStyles.h2.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Form section with inputs and buttons
  Widget _buildForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email',
              style: AppTextStyles.labelMedium.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: controller.onEmailChanged,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  errorText: controller.emailError.value.isEmpty
                      ? null
                      : controller.emailError.value,
                  errorStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.destructiveLight,
                  ),
                ),
                style: AppTextStyles.input.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Password Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password',
              style: AppTextStyles.labelMedium.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => TextField(
                controller: controller.passwordController,
                obscureText: !controller.isPasswordVisible.value,
                onSubmitted: (_) {
                  print('🔵 Password field submitted - calling handleLogin');
                  controller.handleLogin();
                },
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                  ),
                ),
                style: AppTextStyles.input.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.navigateToForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Login Error Message
        Obx(
          () => controller.loginError.value.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    controller.loginError.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.destructiveLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 8),

        // Login and Biometric Buttons Row
        _buildLoginButtonsRow(isDark),

        const SizedBox(height: 12),

        // Create Account Button
        Obx(
          () => ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : controller.navigateToCreateAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.secondaryDark
                  : AppColors.secondaryLight,
              foregroundColor: isDark
                  ? AppColors.secondaryForegroundDark
                  : AppColors.secondaryForegroundLight,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Create an Account',
              style: AppTextStyles.buttonMedium.copyWith(
                color: isDark
                    ? AppColors.secondaryForegroundDark
                    : AppColors.secondaryForegroundLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build login buttons row with new biometric button widget
  Widget _buildLoginButtonsRow(bool isDark) {
    return Obx(
      () => Row(
        children: [
          // Main Login Button
          Expanded(
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      print('🔵 Login button pressed');
                      controller.handleLogin();
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: controller.isLoading.value
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryForegroundLight,
                        ),
                      ),
                    )
                  : Text(
                      'Login',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.primaryForegroundLight,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // NEW: Biometric Button using our converted React component
          _buildBiometricButton(isDark),
        ],
      ),
    );
  }

  Widget _buildBiometricButton(bool isDark) {
    // Responsive sizing: h-9 w-9 sm:h-10 sm:w-10 (36px to 40px)
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isSmallScreen = screenWidth <= 640;
    final buttonSize = isSmallScreen ? 36.0 : 40.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0; // h-4 w-4 sm:h-5 sm:w-5

    return Obx(() => SizedBox(
      // flex-shrink-0 equivalent - fixed dimensions
      width: buttonSize,
      height: buttonSize,
      child: Tooltip(
        message: 'Biometric Login',
        child: InkWell(
          onTap: controller.isLoading.value ? null : () {
            print('🔵 Biometric button pressed - React style');
            controller.handleBiometricLogin();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              // variant="outline" - border with transparent background
              border: Border.all(
                color: controller.isLoading.value 
                    ? (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              color: Colors.transparent, // outline variant
            ),
            child: Center(
              child: controller.isLoading.value
                  ? SizedBox(
                      width: iconSize * 0.8,
                      height: iconSize * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark 
                              ? AppColors.foregroundDark 
                              : AppColors.foregroundLight,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.fingerprint, // <Fingerprint /> equivalent
                      size: iconSize,
                      color: isDark 
                          ? AppColors.foregroundDark 
                          : AppColors.foregroundLight,
                    ),
            ),
          ),
        ),
      ),
    ));
  }

  /// Footer with action buttons
  Widget _buildFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFooterButton(
            context: context,
            icon: Icons.share,
            label: 'Social',
            onTap: controller.openSocial,
            textColor: textColor,
          ),
          const SizedBox(width: 48),
          _buildFooterButton(
            context: context,
            icon: Icons.language,
            label: 'Website',
            onTap: controller.openWebsite,
            textColor: textColor,
          ),
          const SizedBox(width: 48),
          _buildFooterButton(
            context: context,
            icon: Icons.message,
            label: 'Contact',
            onTap: controller.navigateToContact,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  /// Footer button widget
  Widget _buildFooterButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
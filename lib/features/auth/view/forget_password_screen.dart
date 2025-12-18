
import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/auth/controller/forgot_password_controller.dart';
import 'package:firefox_calendar/features/auth/view/otp_pop_up.dart';
import 'package:firefox_calendar/features/auth/view/widgets/password_rules_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



/// Update Forgot Password Screen
/// Converted from React ForgotPassword component
/// Manages complete forgot password flow: email verification, OTP, and password reset
/// Matches the exact design and functionality from the React component
class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is already registered via InitialBinding with fenix: true
    print('🔄 UpdateForgotPasswordScreen build called');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back Button
            _buildTopBar(context),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                    child: Obx(() {
                      return controller.otpVerified.value
                          ? _buildPasswordResetSection(context)
                          : _buildEmailVerificationSection(context);
                    }),
                  ),
                ),
              ),
            ),

            // OTP Popup
            Obx(() {
              return controller.showOTP.value
                  ? _buildOTPPopup()
                  : const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  /// Build top bar with back button (matches React component)
  Widget _buildTopBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: controller.navigateBack,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: isDark 
                    ? AppColors.foregroundDark 
                    : AppColors.foregroundLight,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Title
          Text(
            'Forgot Password',
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark 
                  ? AppColors.foregroundDark 
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build email verification section (initial step)
  Widget _buildEmailVerificationSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Label
        Text(
          'Email',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark 
                ? AppColors.foregroundDark 
                : AppColors.foregroundLight,
          ),
        ),
        
        const SizedBox(height: 8),

        // Email TextField
        Obx(() => TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            if (value.isNotEmpty) {
              controller.validateEmail(value);
            }
          },
          onSubmitted: (_) => controller.handleVerifyEmail(),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: isDark 
                  ? AppColors.mutedForegroundDark 
                  : AppColors.mutedForegroundLight,
            ),
            filled: true,
            fillColor: isDark 
                ? AppColors.inputBackgroundDark 
                : AppColors.inputBackgroundLight,
            errorText: controller.emailError.value.isEmpty 
                ? null 
                : controller.emailError.value,
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: Colors.red.shade600,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: controller.emailError.value.isNotEmpty
                    ? Colors.red.shade500
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: controller.emailError.value.isNotEmpty
                    ? Colors.red.shade500
                    : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: Colors.red.shade500),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: Colors.red.shade500, width: 2),
            ),
          ),
        )),

        const SizedBox(height: 24),

        // Send OTP Button
        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (controller.emailController.text.isNotEmpty && 
                       controller.emailError.value.isEmpty &&
                       !controller.isLoading.value)
                ? controller.handleVerifyEmail
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground(context),
              disabledBackgroundColor: isDark 
                  ? AppColors.mutedDark 
                  : AppColors.mutedLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Send OTP',
                    style: AppTextStyles.labelMedium.copyWith(
                     color: AppColors.primaryForeground(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        )),
      ],
    );
  }

  /// Build password reset section (after OTP verification)
  Widget _buildPasswordResetSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New Password Field
        _buildPasswordField(
          context: context,
          label: 'New Password',
          controller: controller.newPasswordController,
          obscureText: !controller.showNewPassword.value,
          onToggleVisibility: controller.toggleNewPasswordVisibility,
          isDark: isDark,
        ),

        const SizedBox(height: 24),

        // Confirm Password Field
        _buildPasswordField(
          context: context,
          label: 'Confirm Password',
          controller: controller.confirmPasswordController,
          obscureText: !controller.showConfirmPassword.value,
          onToggleVisibility: controller.toggleConfirmPasswordVisibility,
          isDark: isDark,
          showMatchError: true,
        ),

        const SizedBox(height: 24),

        // Password Requirements Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.grey.shade900 
                : Colors.grey.shade50,
            border: Border.all(
              color: isDark 
                  ? AppColors.borderDark 
                  : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password Requirements:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark 
                      ? AppColors.foregroundDark 
                      : AppColors.foregroundLight,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Password Rules Widget
              Obx(() => PasswordRulesWidget(
                hasMinLength: controller.hasMinLength.value,
                hasUppercase: controller.hasUppercase.value,
                hasLowercase: controller.hasLowercase.value,
                hasNumber: controller.hasNumber.value,
                hasSpecialChar: controller.hasSpecialChar.value,
              )),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Save Password Button
        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (controller.canSavePassword.value && 
                       !controller.isLoading.value)
                ? controller.handleSavePassword
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
             foregroundColor: AppColors.primaryForeground(context),
              disabledBackgroundColor: isDark 
                  ? AppColors.mutedDark 
                  : AppColors.mutedLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Password',
                    style: AppTextStyles.labelMedium.copyWith(
                     color: AppColors.primaryForeground(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        )),
      ],
    );
  }

  /// Build password field with visibility toggle
  Widget _buildPasswordField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isDark,
    bool showMatchError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark 
                ? AppColors.foregroundDark 
                : AppColors.foregroundLight,
          ),
        ),
        
        const SizedBox(height: 8),

        // Password field with eye toggle
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark 
                ? AppColors.inputBackgroundDark 
                : AppColors.inputBackgroundLight,
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: isDark 
                    ? AppColors.mutedForegroundDark 
                    : AppColors.mutedForegroundLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),

        // Password match error (only for confirm password)
        if (showMatchError)
          Obx(() {
            final confirmText = this.controller.confirmPasswordController.text;
            final newText = this.controller.newPasswordController.text;
            final showError = confirmText.isNotEmpty && 
                            newText != confirmText;
            
            return showError
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Passwords do not match',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }),
      ],
    );
  }

  /// Build OTP popup overlay
  Widget _buildOTPPopup() {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: OTPPopup(
            email: controller.emailController.text,
            onVerify: controller.handleOTPVerify,
            onClose: controller.closeOTPPopup,
          ),
        ),
      ),
    );
  }
}
import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/features/profile/controller/edit_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Edit Profile Screen
/// Separate screen for editing user profile information
/// Follows the established project patterns and design system
/// This satisfies requirement 4 for separate screen navigation
class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Controller is already registered via InitialBinding and route binding with fenix: true

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
          ),
          onPressed: () => controller.handleCancel(),
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.h4.copyWith(
            color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Reset button in app bar
          TextButton(
            onPressed: controller.resetForm,
            child: Text(
              'Reset',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.orange.shade600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildForm(isDark),
              ),
            ),
            
            // Bottom buttons
            _buildBottomButtons(isDark),
          ],
        ),
      ),
    );
  }

  /// Build form content
  Widget _buildForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page description
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.blue.shade900.withValues(alpha: 0.3)
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark 
                  ? Colors.blue.shade700
                  : Colors.blue.shade200
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline, 
                color: Colors.blue.shade600, 
                size: 20
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Update your profile information below. All changes will be saved to your account.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // First Name Field
        _buildInputField(
          label: 'First Name',
          controller: controller.firstNameController,
          errorText: controller.firstNameError,
          isDark: isDark,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

        // Last Name Field
        _buildInputField(
          label: 'Last Name',
          controller: controller.lastNameController,
          errorText: controller.lastNameError,
          isDark: isDark,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

        // Email Field
        _buildInputField(
          label: 'Email Address',
          controller: controller.emailController,
          errorText: controller.emailError,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 20),

        // Form validation status
        Obx(() => controller.isFormValid.value
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, 
                         color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changes detected and ready to save.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink()),

        // General error display
        Obx(() => controller.generalError.value.isNotEmpty
            ? Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, 
                         color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.generalError.value,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  /// Build input field
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required RxString errorText,
    required bool isDark,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark 
                ? AppColors.foregroundDark 
                : AppColors.foregroundLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            errorText: errorText.value.isEmpty ? null : errorText.value,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, 
              vertical: 12
            ),
          ),
        )),
      ],
    );
  }

  /// Build bottom buttons
  Widget _buildBottomButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: TextButton(
              onPressed: controller.handleCancel,
              child: Text(
                'Cancel',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Save Button
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            )),
          ),
        ],
      ),
    );
  }
}
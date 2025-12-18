
import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/auth/controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Login Buttons Widget
/// Converted from React attach_login code
/// Contains main login button and biometric login button
class LoginButtonsWidget extends GetView<LoginController> {
  const LoginButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(top: 8), // pt-2 equivalent
      child: Column(
        children: [
          // Login and Biometric Buttons Row
          Obx(
            () => Row(
              children: [
                // Main Login Button (flex-1 equivalent)
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                            print('🔵 Login button pressed');
                            controller.handleLogin();
                          },
                    style: ElevatedButton.styleFrom(
                      // h-9 sm:h-10 equivalent (36-40px height)
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primaryForegroundLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: 16,
                            width: 16,
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
                              fontSize: 14, // text-sm equivalent
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 8), // gap-2 equivalent

                // Biometric Button (outline variant, size icon)
                Container(
                  // h-9 w-9 sm:h-10 sm:w-10 equivalent (36-40px)
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                  ),
                  child: IconButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                            print('🔵 Biometric button pressed');
                            controller.handleBiometricLogin();
                          },
                    icon: Icon(
                      Icons.fingerprint, // Fingerprint equivalent
                      // h-4 w-4 sm:h-5 sm:w-5 equivalent (16-20px)
                      size: 18,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add responsive spacing (space-y-2 sm:space-y-3 equivalent)
          SizedBox(
            height: MediaQuery.of(context).size.width > 640 ? 12 : 8,
          ),
        ],
      ),
    );
  }
}

import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BiometricPrompt extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onEnable;
  final VoidCallback onDismiss;

  const BiometricPrompt({
    super.key,
    required this.isOpen,
    required this.onEnable,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448), // sm:max-w-md
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Fingerprint Icon
              Column(
                children: [
                  // Fingerprint Icon Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.1,
                      ), // bg-primary/10
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 48, // h-12 w-12
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 16), // mb-4
                  // Dialog Title
                  Text(
                    'Enable Biometric Login?',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Dialog Description
                  Text(
                    'Use your fingerprint or face ID for faster and more secure access to your account.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 16), // mt-4
              // Action Buttons
              Row(
                children: [
                  // Later Button (outline variant)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Text(
                        'Later',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12), // gap-3
                  // Enable Button (primary)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onEnable,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Enable',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.primaryForegroundLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

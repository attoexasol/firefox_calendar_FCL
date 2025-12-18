import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class PasswordRulesWidget extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;

  const PasswordRulesWidget({
    super.key,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRuleItem(
          context,
          'At least 8 characters',
          hasMinLength,
          isDark,
        ),
        const SizedBox(height: 8),
        _buildRuleItem(
          context,
          'One uppercase letter',
          hasUppercase,
          isDark,
        ),
        const SizedBox(height: 8),
        _buildRuleItem(
          context,
          'One lowercase letter',
          hasLowercase,
          isDark,
        ),
        const SizedBox(height: 8),
        _buildRuleItem(
          context,
          'One number',
          hasNumber,
          isDark,
        ),
        const SizedBox(height: 8),
        _buildRuleItem(
          context,
          'One special character',
          hasSpecialChar,
          isDark,
        ),
      ],
    );
  }

  Widget _buildRuleItem(
    BuildContext context,
    String text,
    bool isValid,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: isValid
              ? Colors.green.shade600
              : (isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: isValid
                ? Colors.green.shade600
                : (isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight),
          ),
        ),
      ],
    );
  }
}
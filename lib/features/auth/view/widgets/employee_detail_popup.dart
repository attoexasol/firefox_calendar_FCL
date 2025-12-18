import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/payroll/controller/payroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Employee Detail Popup
/// Converted from React EmployeeDetailPopup component
/// Shows detailed employee information in a modal dialog
class EmployeeDetailPopup extends GetView<PayrollController> {
  final Employee employee;
  final bool isOpen;
  final VoidCallback onClose;

  const EmployeeDetailPopup({
    super.key,
    required this.employee,
    required this.isOpen,
    required this.onClose,
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
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isDark),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildContent(isDark),
              ),
            ),

            // Footer
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  /// Build header with title and close button
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Employee Details',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content
  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee Basic Info
        _buildEmployeeInfo(isDark),

        const SizedBox(height: 20),

        // Hours Section
        _buildHoursSection(isDark),

        const SizedBox(height: 20),

        // Leave Section
        _buildLeaveSection(isDark),

        const SizedBox(height: 20),

        // Payment Section
        _buildPaymentSection(isDark),
      ],
    );
  }

  /// Build employee basic information
  Widget _buildEmployeeInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: AppTextStyles.labelMedium.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // Name
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Name: ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              Expanded(
                child: Text(
                  employee.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Email
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                size: 16,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Email: ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              Expanded(
                child: Text(
                  employee.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ID
          Row(
            children: [
              Icon(
                Icons.badge_outlined,
                size: 16,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              Text(
                employee.id,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build hours section
  Widget _buildHoursSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Work Hours',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Hours Today',
                  '${employee.hoursToday}h',
                  Colors.blue.shade600,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Hours This Week',
                  '${employee.hoursWeek}h',
                  Colors.green.shade600,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build leave section
  Widget _buildLeaveSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.umbrella,
                size: 20,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Leave Information',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Leave taken this week
          _buildStatItem(
            'Leave Taken This Week',
            '${employee.leaveTakenThisWeek} days',
            Colors.red.shade600,
            isDark,
            fullWidth: true,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Annual Leave',
                  '${employee.annualLeaveAccrued} days',
                  Colors.teal.shade600,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Personal Leave',
                  '${employee.personalLeaveAccrued} days',
                  Colors.purple.shade600,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildStatItem(
            'Days in Lieu Accrued',
            '${employee.daysInLeaveAccrued} days',
            Colors.indigo.shade600,
            isDark,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  /// Build payment section
  Widget _buildPaymentSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 20,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Information',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Amount',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              Text(
                '\$${employee.paymentAmount.toStringAsFixed(0)}',
                style: AppTextStyles.h3.copyWith(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Payment status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Status',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: controller.getStatusBackgroundColor(
                    employee.paymentStatus,
                    isDark,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  controller.getStatusText(employee.paymentStatus),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: controller.getStatusTextColor(
                      employee.paymentStatus,
                      isDark,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    bool isDark, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.h4.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build footer with action buttons
  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Close',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement send email functionality
                Get.snackbar(
                  'Email',
                  'Sending email to ${employee.email}...',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.blue.shade100,
                  colorText: Colors.blue.shade900,
                  duration: const Duration(seconds: 2),
                );
              },
              icon: const Icon(Icons.email_outlined, size: 16),
              label: Text(
                'Send Email',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primaryForegroundLight,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
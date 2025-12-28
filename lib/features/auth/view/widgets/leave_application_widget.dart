import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/settings/controller/leave_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Leave Application Widget
/// Converted from React LeaveApplication component
/// Complete implementation matching the provided screenshots
class LeaveApplicationWidget extends GetView<LeaveController> {
  const LeaveApplicationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave Balance Card
          _buildLeaveBalanceCard(isDark),

          const SizedBox(height: 16),

          // Apply for Leave Form
          _buildApplyLeaveForm(isDark),

          const SizedBox(height: 16),

          // Leave History
          _buildLeaveHistory(isDark),
        ],
      ),
    );
  }

  /// Build leave balance card matching the screenshot
  Widget _buildLeaveBalanceCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave Balance',
            style: AppTextStyles.h4.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Balance metrics in 2x2 grid
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Total Allocated',
                  '20 days',
                  isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceItem(
                  'Remaining',
                  '15 days',
                  Colors.green.shade600,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Used',
                  '5 days',
                  Colors.blue.shade600,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceItem(
                  'Pending',
                  '0 requests',
                  Colors.orange.shade600,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build balance item
  Widget _buildBalanceItem(String label, String value, Color valueColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Build apply for leave form matching the screenshot
  Widget _buildApplyLeaveForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply for Leave',
            style: AppTextStyles.h4.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Date fields row
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Start Date *',
                  isDark,
                  isStartDate: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  'End Date *',
                  isDark,
                  isStartDate: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reason field
          _buildReasonField(isDark),

          // Error message
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.errorMessage.value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.red,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 20),

          // Submit button
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () => controller.submitLeaveApplication(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight, // Orange/red color from screenshot
                foregroundColor: AppColors.primaryForegroundLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                elevation: 0,
                disabledBackgroundColor: AppColors.primaryLight.withValues(alpha: 0.6),
              ),
              child: controller.isSubmitting.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Submitting...',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primaryForegroundLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Submit Leave Request',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primaryForegroundLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          )),
        ],
      ),
    );
  }

  /// Build date input field
  Widget _buildDateField(String label, bool isDark, {required bool isStartDate}) {
    return Obx(() {
      final date = isStartDate ? controller.startDate.value : controller.endDate.value;
      final displayText = controller.formatDateForDisplay(date);
      
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
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.inputBackgroundDark
                  : AppColors.inputBackgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: InkWell(
              onTap: () => _handleDateFieldTap(isStartDate),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  displayText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: displayText == 'dd----yyyy'
                        ? (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight)
                        : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Build reason text area field
  Widget _buildReasonField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason *',
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.inputBackgroundDark
                : AppColors.inputBackgroundLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Obx(() {
            final reasonText = controller.reason.value;
            final isPlaceholder = reasonText.isEmpty || 
                reasonText == 'Please provide a reason for your leave request...';
            
            return TextField(
              controller: TextEditingController(text: isPlaceholder ? '' : reasonText),
              onTap: () {
                if (isPlaceholder) {
                  controller.setReason('');
                }
              },
              onChanged: (value) => controller.setReason(value),
              maxLines: 4,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isPlaceholder
                    ? (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight)
                    : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                hintText: 'Please provide a reason for your leave request...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: isDark 
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Build leave history section matching the screenshot
  Widget _buildLeaveHistory(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave History',
            style: AppTextStyles.h4.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          // Empty state matching the screenshot
          Center(
            child: Text(
              'No leave requests found',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Handle date field tap
  void _handleDateFieldTap(bool isStartDate) {
    final currentDate = isStartDate ? controller.startDate.value : controller.endDate.value;
    final initialDate = currentDate ?? DateTime.now();
    
    // Show date picker
    showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        if (isStartDate) {
          controller.setStartDate(date);
        } else {
          controller.setEndDate(date);
        }
      }
    });
  }
}
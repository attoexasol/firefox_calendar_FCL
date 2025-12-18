import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/auth/view/widgets/employee_detail_popup.dart';
import 'package:firefox_calendar/features/payroll/controller/payroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';



/// Payroll Screen
/// Converted from React Payroll.tsx
/// Shows different views based on user role (admin vs employee)
class PayrollScreen extends GetView<PayrollController> {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Top Bar
                const TopBar(title: 'Payroll'),

                // Content - Show different views based on user role
                Expanded(
                  child: Obx(() {
                    return controller.isAdmin.value
                        ? _buildAdminView(context, isDark)
                        : _buildEmployeeView(context, isDark);
                  }),
                ),
              ],
            ),

            // Employee Detail Popup Overlay
            Obx(() => controller.showEmployeeDetail.value &&
                    controller.selectedEmployee.value != null
                ? EmployeeDetailPopup(
                    employee: controller.selectedEmployee.value!,
                    isOpen: controller.showEmployeeDetail.value,
                    onClose: controller.closeEmployeeDetail,
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }

  /// Build admin view with summary metrics and employee list
  Widget _buildAdminView(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Top Actions - Export Buttons
        _buildTopActions(isDark),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Section
                _buildInfoSection(isDark),

                const SizedBox(height: 16),

                // Summary Metrics
                _buildSummaryMetrics(isDark),

                const SizedBox(height: 24),

                // Employee Overview
                Text(
                  'Employee Overview',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // Employee Cards
                _buildEmployeeList(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build employee view with personal payment summary
  Widget _buildEmployeeView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final employee = controller.getCurrentEmployee();
        if (employee == null) {
          return Center(
            child: Text(
              'Employee data not found',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Payment Summary
            _buildPersonalSummary(employee, isDark),

            const SizedBox(height: 16),

            // Work Hours Grid
            _buildWorkHoursGrid(employee, isDark),

            const SizedBox(height: 16),

            // Payment History
            _buildPaymentHistory(isDark),
          ],
        );
      }),
    );
  }

  /// Build top actions with export buttons
  Widget _buildTopActions(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Obx(
            () => OutlinedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.handleExport('csv'),
              icon: const Icon(Icons.file_present, size: 16),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => OutlinedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.handleExport('pdf'),
              icon: const Icon(Icons.file_download, size: 16),
              label: const Text('Export PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build info section
  Widget _buildInfoSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            //? Colors.blue.shade950.withValues(alpha: 0.2)
            ? Colors.blue.shade900.withValues(alpha: 0.2)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.blue.shade800
              : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: isDark
                ? Colors.blue.shade400
                : Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payroll information is entered manually or via imported data (admin controlled).',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? Colors.blue.shade200
                    : Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build summary metrics grid
  Widget _buildSummaryMetrics(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Obx(() => _buildSummaryMetricCard(
          icon: Icons.access_time,
          iconColor: Colors.blue.shade600,
          label: 'Total Hours Today',
          value: controller.totalHoursToday.value,
          isDark: isDark,
        )),
        Obx(() => _buildSummaryMetricCard(
          icon: Icons.access_time_rounded,
          iconColor: Colors.green.shade600,
          label: 'Total Hours This Week',
          value: controller.totalHoursThisWeek.value,
          isDark: isDark,
        )),
        Obx(() => _buildSummaryMetricCard(
          icon: Icons.attach_money,
          iconColor: Colors.orange.shade600,
          label: 'Payments Due',
          value: '\$${controller.paymentsDue.value}',
          isDark: isDark,
        )),
        Obx(() => _buildSummaryMetricCard(
          icon: Icons.attach_money,
          iconColor: Colors.green.shade600,
          label: 'Payments Completed',
          value: '\$${controller.paymentsCompleted.value}',
          isDark: isDark,
        )),
        Obx(() => _buildSummaryMetricCard(
          icon: Icons.umbrella,
          iconColor: Colors.red.shade600,
          label: 'Leaves This Week',
          value: controller.leavesThisWeek.value,
          isDark: isDark,
        )),
        Obx(() => _buildSummaryMetricCard(
          icon: Icons.people,
          iconColor: Colors.teal.shade600,
          label: 'Current Availability',
          value: controller.currentAvailability.value,
          isDark: isDark,
        )),
        Obx(() => _buildSummaryMetricCard(
          icon: Icons.calendar_today,
          iconColor: Colors.purple.shade600,
          label: 'Meetings This Week',
          value: controller.meetingsThisWeek.value,
          isDark: isDark,
        )),
      ],
    );
  }

  /// Build individual summary metric card
  Widget _buildSummaryMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build employee list
  Widget _buildEmployeeList(bool isDark) {
    return Obx(() {
      return Column(
        children: controller.employees.map((employee) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEmployeeCard(employee, isDark),
          );
        }).toList(),
      );
    });
  }

  /// Build individual employee card
  Widget _buildEmployeeCard(Employee employee, bool isDark) {
    return InkWell(
      onTap: () => controller.openEmployeeDetail(employee),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            // Header with name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.email,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Payment Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: controller.getStatusBackgroundColor(
                      employee.paymentStatus,
                      isDark,
                    ),
                    borderRadius: BorderRadius.circular(12),
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

            const SizedBox(height: 12),

            // Hours and Leave Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      Text(
                        '${employee.hoursToday}h',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      Text(
                        '${employee.hoursWeek}h',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annual Leave',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      Text(
                        '${employee.annualLeaveAccrued} days',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Payment Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                  ),
                  child: Text(
                    '\$${employee.paymentAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build personal payment summary for employee view
  Widget _buildPersonalSummary(Employee employee, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            'My Payment Summary',
            style: AppTextStyles.h4.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Summary Items
          _buildSummaryItem('Name', employee.name, isDark),
          _buildSummaryItem('Email', employee.email, isDark),
          _buildSummaryItem(
            'Payment Status',
            controller.getStatusText(employee.paymentStatus),
            isDark,
            isStatus: true,
            status: employee.paymentStatus,
          ),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              Text(
                '\$${employee.paymentAmount.toStringAsFixed(0)}',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build summary item
  Widget _buildSummaryItem(
    String label,
    String value,
    bool isDark, {
    bool isStatus = false,
    String? status,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            isStatus && status != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.getStatusBackgroundColor(status, isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: controller.getStatusTextColor(status, isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// Build work hours grid for employee view
  Widget _buildWorkHoursGrid(Employee employee, bool isDark) {
    
    final hoursData = [
  {
    'icon': SvgPicture.asset('assets/images/Icon.svg'),
    'color': Colors.blue.shade600,
    'value': '${employee.hoursToday}h',
    'label': 'Hours Today',
  },
  {
    'icon': SvgPicture.asset('assets/images/Icon (1).svg'),
    'color': Colors.green.shade600,
    'value': '${employee.hoursWeek}h',
    'label': 'Hours This Week',
  },
  {
    'icon': SvgPicture.asset('assets/images/Icon (2).svg'),
    'color': Colors.red.shade600,
    'value': '${employee.leaveTakenThisWeek}',
    'label': 'Leave Taken This Week',
  },
  {
    'icon': SvgPicture.asset('assets/images/Icon (3).svg'),
    'color': Colors.teal.shade600,
    'value': '${employee.annualLeaveAccrued}',
    'label': 'Annual Leave Accrued',
  },
  {
    'icon': SvgPicture.asset('assets/images/Icon (4).svg'),
    'color': Colors.purple.shade600,
    'value': '${employee.personalLeaveAccrued}',
    'label': 'Personal Leave Accrued',
  },
  {
    'icon': SvgPicture.asset('assets/images/Icon (5).svg'),
    'color': Colors.orange.shade600,
    'value': '${employee.daysInLeaveAccrued}',
    'label': 'Days in Lieu Accrued',
  },
];


    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: hoursData.map((data) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
    
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: data['icon'] as Widget,   // <-- SVG widget here
              ),
              const SizedBox(height: 8),
              Text(
                data['value'] as String,
                style: AppTextStyles.h2.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                data['label'] as String,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

          ),
        );
      }).toList(),
    );
  }

  /// Build payment history for employee view
  Widget _buildPaymentHistory(bool isDark) {
    final paymentHistory = controller.getPaymentHistory();

    return Container(
      padding: const EdgeInsets.all(16),
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
            'Payment History',
            style: AppTextStyles.h4.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          ...paymentHistory.map((payment) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.weekEnding,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${payment.hours} hours',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${payment.amount.toStringAsFixed(0)}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: controller.getStatusBackgroundColor(payment.status, isDark),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          controller.getStatusText(payment.status),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: controller.getStatusTextColor(payment.status, isDark),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
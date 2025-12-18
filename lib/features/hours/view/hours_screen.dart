
import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/hours/controller/hours_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Hours Screen - Updated to match React Hours component and screenshot
/// Features: Day/Week/Month tabs, Summary card, Work logs list
class HoursScreen extends GetView<HoursController> {
  const HoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            const TopBar(title: 'Work Hours'),

            // View by Tabs Section
            _buildViewByTabs(context, isDark),

            // Date Navigation Section
            _buildDateNavigation(context, isDark),

            // Summary Card + Work Logs
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Summary Card
                    _buildSummaryCard(isDark),
                    
                    const SizedBox(height: 16),

                    // Work Logs List
                    Expanded(child: _buildWorkLogsList(isDark)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }

  /// Build View by Tabs (Day, Week, Month)
  Widget _buildViewByTabs(BuildContext context, bool isDark) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'View by',
            style: AppTextStyles.labelMedium.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Row(
              children: [
                _buildTabButton('Day', 'day', isDark),
                const SizedBox(width: 8),
                _buildTabButton('Week', 'week', isDark),
                const SizedBox(width: 8),
                _buildTabButton('Month', 'month', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual tab button
  Widget _buildTabButton(String label, String value, bool isDark) {
    final isActive = controller.activeTab.value == value;
    
    return Expanded(
      child: InkWell(
        onTap: () => controller.setActiveTab(value),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive
                  ? AppColors.primaryForegroundLight
                  : (isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  /// Build Date Navigation Section
  Widget _buildDateNavigation(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Previous Button
          IconButton(
            onPressed: controller.navigateToPreviousWeek,
            icon: const Icon(Icons.chevron_left, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.cardDark
                  : AppColors.cardLight,
              side: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
            ),
          ),

          // Date Range
          Expanded(
            child: Obx(() => Text(
              controller.getCurrentWeekRange(),
              style: AppTextStyles.labelMedium.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )),
          ),

          // Today Button
          TextButton(
            onPressed: controller.navigateToToday,
            style: TextButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.cardDark
                  : AppColors.cardLight,
              side: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Today',
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foregroundLight,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Next Button
          IconButton(
            onPressed: controller.navigateToNextWeek,
            icon: const Icon(Icons.chevron_right, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.cardDark
                  : AppColors.cardLight,
              side: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Summary Card - matches React component
  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Total Hours
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Hours',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  '${controller.totalHours.toStringAsFixed(0)}h',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ),
          
          // Entries
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Entries',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Obx(() => Text(
                controller.totalEntries.toString(),
                style: AppTextStyles.h2.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Work Logs List - matches React component structure
  Widget _buildWorkLogsList(bool isDark) {
    return Obx(() {
      final filteredLogs = controller.getFilteredWorkLogs();
      
      if (filteredLogs.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              'No work logs found for this period',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: filteredLogs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final log = filteredLogs[index];
          return _buildWorkLogCard(log, isDark);
        },
      );
    });
  }

  /// Build individual Work Log Card - matches React component structure
  Widget _buildWorkLogCard(WorkLog log, bool isDark) {
    final statusColor = controller.getStatusColor(log.status);
    
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
        children: [
          // Header Row - Work Type and Status Badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.workType,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.formatWorkLogDate(log.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${log.status[0].toUpperCase()}${log.status.substring(1)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hours and Logged At Row
          Row(
            children: [
              // Hours
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${log.hours}h',
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
              
              // Logged At
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Logged At',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    controller.formatWorkLogTime(log.timestamp),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
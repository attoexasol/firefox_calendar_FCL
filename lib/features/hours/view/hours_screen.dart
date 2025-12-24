
import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/hours/controller/hours_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Hours Screen - Detailed per-entry breakdown
/// 
/// RESPONSIBILITY: Detailed View (with Status Badges)
/// ===================================================
/// - Shows individual work hour entries
/// - Displays approved/pending status badges
/// - Shows delete buttons for pending entries
/// - Per-entry status display
/// - Detailed per-day breakdown
/// 
/// DIFFERENCE FROM DASHBOARD:
/// - Dashboard = Summary totals (backend-calculated, read-only)
/// - Hours Screen = Detailed entries (with status badges, per-entry view)
/// - Dashboard totals may differ from Hours screen totals (this is expected)
/// - Dashboard shows aggregated summary, Hours shows individual entries
/// 
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

          // Date Range - Shows different format based on active tab
          Expanded(
            child: Obx(() {
              String dateRangeText;
              switch (controller.activeTab.value) {
                case 'day':
                  final date = controller.currentDate.value;
                  dateRangeText = '${date.month}/${date.day}/${date.year}';
                  break;
                case 'week':
                  dateRangeText = controller.getCurrentWeekRange();
                  break;
                case 'month':
                  final date = controller.currentDate.value;
                  final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'];
                  dateRangeText = '${monthNames[date.month - 1]} ${date.year}';
                  break;
                default:
                  dateRangeText = '';
              }
              
              return Text(
                dateRangeText,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              );
            }),
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

  /// Build Work Logs List - Card-based layout
  /// Displays entries grouped by day/week/month based on selected range
  /// Controller handles filtering & grouping
  Widget _buildWorkLogsList(bool isDark) {
    return Obx(() {
      // Get filtered work logs based on active tab (day/week/month)
      // Controller handles filtering & grouping
      final filteredLogs = controller.getFilteredWorkLogs();
      
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      if (filteredLogs.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              'No work hour entries found for this period',
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

  /// Build individual Work Hour Entry Card
  /// Shows: title, date, logged time, total hours, status badge
  /// Rules:
  /// - status == "pending": Show orange Pending badge, Show Delete button
  /// - status == "approved": Show green Approved badge, Hide Delete button, Entry is read-only
  Widget _buildWorkLogCard(WorkLog log, bool isDark) {
    // Normalize status (trim whitespace, lowercase) - status comes directly from API
    final normalizedStatus = (log.status ?? '').trim().toLowerCase();
    final isApproved = normalizedStatus == 'approved';
    final isPending = normalizedStatus == 'pending';
    
    // Explicit badge colors based on status
    // Pending: Orange badge
    // Approved: Green badge
    final badgeColor = isPending 
        ? Colors.orange 
        : isApproved 
            ? Colors.green 
            : Colors.grey; // Fallback for other statuses
    
    // Format status text for badge
    final statusText = isPending 
        ? 'Pending' 
        : isApproved 
            ? 'Approved' 
            : (log.status.isNotEmpty 
                ? log.status[0].toUpperCase() + log.status.substring(1).toLowerCase()
                : 'Unknown');
    
    // Make approved entries visually distinct with green styling
    // Pending entries use default styling
    final cardBackgroundColor = isApproved
        ? (isDark 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.05))
        : (isDark ? AppColors.cardDark : AppColors.cardLight);
    
    final borderColor = isApproved
        ? badgeColor.withValues(alpha: 0.5)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);
    
    final borderWidth = isApproved ? 2.0 : 1.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: isApproved
                ? badgeColor.withValues(alpha: 0.15)
                : (isDark 
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1)),
            blurRadius: isApproved ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Date
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
                          style: AppTextStyles.bodyMedium.copyWith(
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
              // Rules: Pending = Orange badge, Approved = Green badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isApproved ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: isApproved ? 0.6 : 0.4),
                    width: isApproved ? 2.0 : 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isApproved)
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: badgeColor,
                      )
                    else if (isPending)
                      Icon(
                        Icons.pending,
                        size: 14,
                        color: badgeColor,
                      ),
                    if (isApproved || isPending) const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark 
                ? AppColors.borderDark 
                : AppColors.borderLight,
          ),

          const SizedBox(height: 16),

          // Bottom Row: Logged Time and Total Hours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logged Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logged Time',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : const Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                        ),
                        const SizedBox(width: 6),
                        // Display login time and logout time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (log.loginTime != null)
                              Text(
                                _formatTime(log.loginTime!),
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isDark
                                      ? AppColors.foregroundDark
                                      : AppColors.foregroundLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (log.logoutTime != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'to ${_formatTime(log.logoutTime!)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : const Color(0xFF6B7280),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (log.loginTime == null && log.logoutTime == null)
                              Text(
                                'No time logged',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : const Color(0xFF6B7280),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Total Hours
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Hours',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${log.hours.toStringAsFixed(1)}h',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Delete Button - ONLY for pending entries
          // Rules: 
          // - status == "pending": Show Delete button
          // - status == "approved": Hide Delete button (read-only)
          // Status comes directly from API response
          if (isPending) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark 
                  ? AppColors.borderDark 
                  : AppColors.borderLight,
            ),
            const SizedBox(height: 12),
            // Delete Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => controller.deleteWorkLog(id: log.id),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Entry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Format time for display (09:00 AM format)
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}

import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/hours/controller/hours_controller.dart';
import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
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
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                const TopBar(title: 'Work Hours'),

                // Timer Controls Section (Hours Screen ONLY)
                _buildTimerControls(context, isDark),

                // View by Tabs Section
                _buildViewByTabs(context, isDark),

                // Date Navigation Section
                _buildDateNavigation(context, isDark),

                // Summary Card + Events + Work Logs (unified scroll)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomScrollView(
                      slivers: [
                        // Summary Card (fixed at top)
                        SliverToBoxAdapter(
                          child: _buildSummaryCard(isDark),
                        ),
                        
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 16),
                        ),

                        // Calendar Events Section (scrollable)
                        Obx(() => _buildCalendarEventsSliver(isDark)),

                        // Work Logs List (scrollable)
                        _buildWorkLogsSliver(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Start Timer Modal Overlay
          Obx(() {
            if (controller.showStartTimerModal.value) {
              return _buildStartTimerModal(context, isDark);
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }

  /// Build Start Timer Modal
  Widget _buildStartTimerModal(BuildContext context, bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start Timer',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.closeStartTimerModal,
                      icon: const Icon(Icons.close),
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Work Type Dropdown
                Text(
                  'Work Type *',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  // Get static work type options
                  final options = HoursController.workTypeOptions;
                  
                  // Build dropdown items from static options
                  // UI shows label, but value stores ENUM
                  final dropdownItems = options.map((option) {
                    final label = option['label'] ?? '';
                    final value = option['value'] ?? '';
                    if (label.isEmpty || value.isEmpty) return null;
                    return DropdownMenuItem<String>(
                      value: value, // Store ENUM value (e.g., "client_meeting")
                      child: Text(label), // Display label (e.g., "Client Meeting")
                    );
                  }).whereType<DropdownMenuItem<String>>().toList();
                  
                  // Get current selected value (ENUM value)
                  final selectedValue = controller.selectedWorkType.value.isEmpty
                      ? null
                      : controller.selectedWorkType.value;
                  
                  return DropdownButtonFormField<String>(
                    value: selectedValue, // Controlled value from state (ENUM value)
                    decoration: InputDecoration(
                      hintText: 'Select work type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    items: dropdownItems,
                    onChanged: (String? value) {
                      // Update state when dropdown changes (controlled component)
                      // value is the ENUM (e.g., "client_meeting")
                      if (value != null && value.isNotEmpty) {
                        controller.selectedWorkType.value = value;
                        controller.descriptionError.value = ''; // Clear description error when work type changes
                      }
                    },
                  );
                }),
                const SizedBox(height: 16),

                // Description Field
                Obx(() {
                  final isRequired = controller.isDescriptionRequired(
                    controller.selectedWorkType.value,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description${isRequired ? ' *' : ''}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        return TextField(
                          controller: controller.descriptionController,
                          onChanged: (value) {
                            controller.descriptionText.value = value;
                            controller.descriptionError.value = '';
                          },
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            errorText: controller.descriptionError.value.isEmpty
                                ? null
                                : controller.descriptionError.value,
                          ),
                        );
                      }),
                    ],
                  );
                }),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.closeStartTimerModal,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        final isValid = controller.selectedWorkType.value.isNotEmpty &&
                            (!controller.isDescriptionRequired(
                              controller.selectedWorkType.value,
                            ) ||
                                controller.descriptionText.value.trim().isNotEmpty);
                        return ElevatedButton(
                          onPressed: isValid && !controller.isLoading.value
                              ? controller.startTimerWithDetails
                              : null,
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Start Timer'),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build Timer Controls Section (Hours Screen ONLY)
  /// Shows Start/End timer buttons and active timer state
  Widget _buildTimerControls(BuildContext context, bool isDark) {
    return Obx(() {
      final activeSession = controller.getActiveSession();
      final hasActiveSession = activeSession != null;
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasActiveSession
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Timer Status Info (if running)
            if (hasActiveSession) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Timer Running',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (activeSession!.workType.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Work Type: ${controller.getWorkTypeLabel(activeSession.workType)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (activeSession.description != null && activeSession.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Description: ${activeSession.description}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // End Timer Button
              ElevatedButton.icon(
                onPressed: () => _handleEndTimer(context, activeSession, isDark),
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('End Timer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ] else ...[
              // Start Timer Button (when no active session)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.openStartTimerModal(),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Start Timer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForegroundLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Handle End Timer with confirmation dialog
  Future<void> _handleEndTimer(BuildContext context, WorkLog activeSession, bool isDark) async {
    // Calculate duration
    final now = DateTime.now();
    final startTime = activeSession.loginTime ?? now;
    final duration = now.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationText = '${hours}h ${minutes}m';

    // Show confirmation dialog with details
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('End Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeSession.workType.isNotEmpty) ...[
              _buildDialogRow('Work Type', controller.getWorkTypeLabel(activeSession.workType), isDark),
              const SizedBox(height: 8),
            ],
            if (activeSession.description != null && activeSession.description!.isNotEmpty) ...[
              _buildDialogRow('Description', activeSession.description!, isDark),
              const SizedBox(height: 8),
            ],
            _buildDialogRow('Duration', durationText, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Timer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Call End Timer from DashboardController (existing logic)
      try {
        if (Get.isRegistered<DashboardController>()) {
          final dashboardController = Get.find<DashboardController>();
          await dashboardController.setEndTime();
          // Refresh work logs
          await controller.refreshWorkLogs();
        }
      } catch (e) {
        print('⚠️ [HoursScreen] Could not end timer: $e');
        Get.snackbar(
          'Error',
          'Failed to end timer',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    }
  }

  /// Build dialog row for confirmation
  Widget _buildDialogRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: AppTextStyles.labelMedium.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
          ),
        ),
      ],
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

  /// Build Work Logs Sliver - Card-based layout
  /// Displays entries grouped by day/week/month based on selected range
  /// Controller handles filtering & grouping
  Widget _buildWorkLogsSliver(bool isDark) {
    return Obx(() {
      // Get filtered work logs based on active tab (day/week/month)
      // Controller handles filtering & grouping
      final filteredLogs = controller.getFilteredWorkLogs();
      
      if (controller.isLoading.value) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
      
      if (filteredLogs.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index > 0) {
              return Column(
                children: [
                  const SizedBox(height: 12),
                  _buildWorkLogCard(filteredLogs[index], isDark),
                ],
              );
            }
            return _buildWorkLogCard(filteredLogs[index], isDark);
          },
          childCount: filteredLogs.length,
        ),
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
                    // Date and Work Type
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        if (log.workType.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 14,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                controller.getWorkTypeLabel(log.workType),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : const Color(0xFF6B7280),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
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

          // Description (if available)
          if (log.description != null && log.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark 
                  ? AppColors.borderDark 
                  : AppColors.borderLight,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.description!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
              ],
            ),
          ] else if (log.description == null || log.description!.isEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark 
                  ? AppColors.borderDark 
                  : AppColors.borderLight,
            ),
            const SizedBox(height: 12),
            Text(
              'Description: —',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : const Color(0xFF6B7280),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

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

  // ============================================================
  // CALENDAR EVENTS SECTION
  // ============================================================

  /// Build Calendar Events Sliver
  /// Shows informational event cards above work hour cards
  /// Returns a Sliver widget for unified scrolling
  Widget _buildCalendarEventsSliver(bool isDark) {
    // Show loading state if events are loading
    if (controller.isLoadingEvents.value) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    // Show error state (optional - can be silent)
    if (controller.eventsError.value.isNotEmpty) {
      // Silently handle error - don't show error message to avoid cluttering UI
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final filteredEvents = controller.getFilteredCalendarEvents();
    
    // Don't show section if no events
    if (filteredEvents.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // First item: Section Header
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Calendar Events',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          } else if (index <= filteredEvents.length) {
            // Event cards (index 1 to length)
            final eventIndex = index - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: eventIndex < filteredEvents.length - 1 ? 12 : 8,
              ),
              child: _buildEventCard(filteredEvents[eventIndex], isDark),
            );
          } else {
            // Last item: Separator after all events
            return Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark 
                      ? AppColors.borderDark 
                      : AppColors.borderLight,
                ),
                const SizedBox(height: 16),
              ],
            );
          }
        },
        childCount: filteredEvents.length + 2, // +1 for header, +1 for separator
      ),
    );
  }

  /// Build individual Event Card
  /// Read-only informational card, visually distinct from work hour cards
  Widget _buildEventCard(CalendarEvent event, bool isDark) {
    // Lighter background and different styling to differentiate from work hour cards
    final cardBackgroundColor = isDark
        ? AppColors.cardDark.withValues(alpha: 0.6)
        : AppColors.cardLight.withValues(alpha: 0.6);
    
    final borderColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.5)
        : AppColors.borderLight.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Icon (different from work hour icon)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Event Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                Text(
                  event.title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Event Type (if available)
                if (event.eventTypeName != null && event.eventTypeName!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.eventTypeName!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Time Range
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.getTimeRange(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : const Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
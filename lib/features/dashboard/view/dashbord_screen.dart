import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/widgets/bottom_nav.dart';
import 'package:firefox_calendar/core/widgets/top_bar.dart';
import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Complete Dashboard Screen
/// Fully converted from React Dashboard with all components
/// Integrates: Welcome Card, Metrics Grid, Next Event Card, Quick Actions
class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: const TopBar(title: 'Dashboard'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================
              _buildWelcomeCard(isDark),

              const SizedBox(height: 16),

              _buildNextEventCard(),

              const SizedBox(height: 16),

              _buildQuickActionCards(),

              const SizedBox(height: 16), // Space for bottom nav

              // Show loading state while fetching dashboard summary
              Obx(
                () => controller.isLoadingSummary.value
                    ? _buildLoadingMetricsGrid(isDark)
                    : _buildMetricsGrid(isDark),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35), // Orange from Figma (0%)
            Color(0xFF1F1147), // Deep purple from Figma (100%)
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF6B35).withValues(alpha: 0.3), // soft orange shadow
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // Avatar with white border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.2),
                width: 4,
              ),
            ),
            child: Obx(
              () => CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                backgroundImage: controller.userProfilePicture.value.isNotEmpty
                    ? NetworkImage(controller.userProfilePicture.value)
                    : null,
                child: controller.userProfilePicture.value.isEmpty
                    ? Text(
                        _getInitials(controller.userName.value),
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.userName.value.isNotEmpty
                        ? controller.userName.value
                        : 'User',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Contact Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Row(
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 16,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              controller.userEmail.value,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => controller.userPhone.value.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: AppColors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    controller.userPhone.value,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
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

  // ============================================
  // METRICS GRID
  // ============================================
  // 
  // DASHBOARD RESPONSIBILITY: Summary View (Read-Only)
  // ====================================================
  // - Displays backend-calculated summary totals
  // - NO approval/pending badges (summary only)
  // - NO frontend calculations
  // - NO status inference
  // - Accepts backend summary as source of truth
  // 
  // Backend API Response Mapping:
  // - hours_today → hoursToday → "Hours Today"
  // - hours_this_week → hoursThisWeek → "Hours This Week"
  // - event_this_week → eventsThisWeek → "Events This Week"
  // - leave_application_this_week → leaveThisWeek → "Leave This Week"
  // 
  // IMPORTANT: Dashboard totals may differ from Hours screen totals
  // - Dashboard = Backend summary calculation (may include auto-approval)
  // - Hours screen = Detailed per-entry breakdown (shows all entries with status)
  // - This difference is EXPECTED and ACCEPTABLE
  // - Do NOT try to match totals - they serve different purposes
  // 
  // Dashboard is READ-ONLY - displays API values only
  // No calculations on frontend - defaults to 0 if missing
  Widget _buildMetricsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 174.86 / 110.85,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Card 1: Hours Today (maps from backend: hours_today)
        // Dashboard = Summary only - NO approval/pending badges
        Obx(
          () => _buildMetricCard(
            icon: Icons.access_time,
            iconColor: const Color(0xFF155DFC),
            value: '${controller.hoursToday.value}h',
            subtitle: "Hours Today",
            isDark: isDark,
          ),
        ),
        // Card 2: Hours This Week (maps from backend: hours_this_week)
        // Dashboard = Summary only - NO approval/pending badges
        Obx(
          () => _buildMetricCard(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF00A63E),
            value: '${controller.hoursThisWeek.value}h',
            subtitle: "Hours This Week",
            isDark: isDark,
          ),
        ),
        // Card 3: Events This Week (maps from backend: event_this_week)
        // Dashboard = Summary only - NO approval/pending badges
        Obx(
          () => _buildMetricCard(
            icon: Icons.calendar_today,
            iconColor: const Color(0xFF9810FA),
            value: controller.eventsThisWeek.value,
            subtitle: "Events This Week",
            isDark: isDark,
          ),
        ),
        // Card 4: Leave This Week (maps from backend: leave_application_this_week)
        // Dashboard = Summary only - NO approval/pending badges
        Obx(
          () => _buildMetricCard(
            icon: Icons.umbrella,
            iconColor: const Color(0xFFE7000B),
            value: controller.leaveThisWeek.value, // From API: leave_application_this_week
            subtitle: "Leave This Week",
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  /// Build loading state for metrics grid
  /// Shows skeleton/loading indicators while fetching dashboard summary
  Widget _buildLoadingMetricsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 174.86 / 110.85,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.black.withValues(alpha: 0.10),
              width: 1.48,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Loading icon placeholder
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.mutedDark : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Loading value placeholder
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.mutedDark : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Loading subtitle placeholder
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.mutedDark : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Build individual metric card
  /// 
  /// Dashboard is READ-ONLY - displays API values only
  /// No calculations on frontend - values come directly from backend
  /// 
  /// IMPORTANT: Dashboard shows NO approval/pending badges
  /// - Summary view only (no status indicators)
  /// - Status badges are shown ONLY on Hours screen (detailed view)
  /// 
  /// Parameters:
  /// - value: Display value (formatted from backend API)
  /// - subtitle: UI label (e.g., "Hours Today", "Hours This Week", "Events This Week")
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.black.withValues(alpha: 0.10),
          width: 1.48,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon
          Icon(icon, size: 22, color: iconColor),
          // Value (read-only from API)
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              color: isDark
                  ? AppColors.foregroundDark
                  : const Color(0xFF0A0A0A),
              fontWeight: FontWeight.w600,
            ),
          ),
          // Subtitle (UI label)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : const Color(0xFF4A5565),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================
  // NEXT EVENT CARD
  // ============================================
  Widget _buildNextEventCard() {
    return Obx(() {
      final meeting = controller.nextMeeting.value;
      if (meeting == null) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFFF3EE), Color(0xFFFFF8F6)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Next Event",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    meeting.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                ),
                if (meeting.meetingType != null)
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        _formatMeetingType(meeting.meetingType!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E2939),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${_formatDate(meeting.date)} at ${meeting.startTime}",
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
            ),
            const SizedBox(height: 20),
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.countdown.value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "until start",
                    style: TextStyle(fontSize: 13, color: Color(0xFF4A5565)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============================================
  // QUICK ACTION CARDS
  // ============================================
  Widget _buildQuickActionCards() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.edit_outlined,
          title: "Manual Time Entry",
          subtitle: "Log check-in/check-out times for this week",
          onTap: controller.openManualTimeEntryModal,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFFF3EE), Color(0xFFFFF8F6)],
          ),
          border: Border.all(
            color: const Color(0xFFFF6900).withValues(alpha: 0.20),
            width: 1.48,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, color: const Color(0xFFFF6B35), size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      color: Color(0xFF4A5565),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF4A5565),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    return parts
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join('')
        .toUpperCase();
  }

  String _formatMeetingType(String type) {
    switch (type) {
      case 'team-meeting':
        return 'Team Meeting';
      case 'client-meeting':
        return 'Client Meeting';
      case 'one-on-one':
        return 'One-on-One';
      case 'training':
        return 'Training';
      default:
        return 'Other';
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return isoDate;
    }
  }
}

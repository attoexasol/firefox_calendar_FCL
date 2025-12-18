import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Dashboard Metrics Grid
/// Converted from React Dashboard Metrics Section
/// Displays Hours Today, Hours This Week, Events This Week, Leave This Week
class DashboardMetricsGrid extends GetView<DashboardController> {
  const DashboardMetricsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 174.86 / 110.85,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Obx(
          () => DashboardMetricCard(
            icon: Icons.access_time,
            iconColor: const Color(0xFF155DFC), // Blue
            value: controller.hoursToday.value,
            subtitle: "Hours Today",
            isDark: isDark,
          ),
        ),
        Obx(
          () => DashboardMetricCard(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF00A63E), // Green
            value: controller.hoursThisWeek.value,
            subtitle: "Hours This Week",
            isDark: isDark,
          ),
        ),
        Obx(
          () => DashboardMetricCard(
            icon: Icons.calendar_today,
            iconColor: const Color(0xFF9810FA), // Purple
            value: controller.eventsThisWeek.value,
            subtitle: "Events This Week",
            isDark: isDark,
          ),
        ),
        Obx(
          () => DashboardMetricCard(
            icon: Icons.umbrella,
            iconColor: const Color(0xFFE7000B), // Red
            value: controller.leaveThisWeek.value,
            subtitle: "Leave This Week",
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

/// Individual Metric Card
/// Converted from React MetricCard component
class DashboardMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String subtitle;
  final bool isDark;

  const DashboardMetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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

          // Value
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

          // Subtitle
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
}

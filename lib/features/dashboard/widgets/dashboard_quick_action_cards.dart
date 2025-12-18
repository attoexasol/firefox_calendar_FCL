import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Dashboard Quick Action Cards
/// Converted from React Quick Actions Section
/// Displays Manual Time Entry and Create Meeting cards
class DashboardQuickActionCards extends GetView<DashboardController> {
  const DashboardQuickActionCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Manual Time Entry Card
        DashboardActionCard(
          icon: Icons.edit_outlined,
          title: "Manual Time Entry",
          subtitle: "Log check-in/check-out times for this week",
          onTap: controller.openManualTimeEntryModal,
        ),
        const SizedBox(height: 12),

        // Create Meeting Card
        DashboardActionCard(
          icon: Icons.add_circle_outline,
          title: "Create Meeting",
          subtitle: "Schedule a new event or meeting",
          onTap: controller.openCreateMeetingModal,
        ),
      ],
    );
  }
}

/// Individual Action Card
/// Converted from React ManualTimeEntryCard component
class DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            colors: [
              Color(0xFFFFF3EE), // light peach
              Color(0xFFFFF8F6), // lighter peach
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFF6900).withValues(alpha: 0.20),
            width: 1.48,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Box
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

            // Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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

            // Arrow icon
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
}

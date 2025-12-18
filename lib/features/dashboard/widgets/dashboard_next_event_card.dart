import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Dashboard Next Event Card
/// Converted from React NextEventCard component
/// Displays upcoming event with countdown timer
class DashboardNextEventCard extends GetView<DashboardController> {
  const DashboardNextEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meeting = controller.nextMeeting.value;

      // Don't show if no meeting
      if (meeting == null) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFF3EE), // light peach gradient
              Color(0xFFFFF8F6), // lighter end color
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Next Event" header
            const Text(
              "Next Event",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFF6B35), // Primary orange
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Event title + Tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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

                // Event type badge
                if (meeting.meetingType != null)
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatMeetingType(meeting.meetingType!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E2939),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Date and time
            Text(
              "${_formatDate(meeting.date)} at ${meeting.startTime}",
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
            ),

            const SizedBox(height: 20),

            // Countdown section
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

  /// Format meeting type for display
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

  /// Format date to readable format
  /// Converts "2025-12-07" to "07/12/2025"
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return isoDate;
    }
  }
}

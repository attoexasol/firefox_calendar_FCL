import 'package:firefox_calendar/core/theme/app_colors.dart';
import 'package:firefox_calendar/core/theme/app_text_styles.dart';
import 'package:firefox_calendar/core/theme/app_theme.dart';
import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Event Details Dialog
/// Displays full event details fetched from API
class EventDetailsDialog extends GetView<CalendarController> {
  const EventDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final meeting = controller.selectedMeeting.value;
      final eventDetails = controller.eventDetails.value;
      final isLoading = controller.isLoadingEventDetails.value;
      final error = controller.eventDetailsError.value;

      if (meeting == null) return const SizedBox.shrink();

      return Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LEFT: Title + Subtitle
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventDetails?['title'] ?? meeting.title,
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Meeting details and information',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // RIGHT: Close button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: controller.closeMeetingDetail,
                      icon: const Icon(Icons.close),
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: isLoading
                      ? _buildLoadingState(isDark)
                      : error.isNotEmpty
                          ? _buildErrorState(error, isDark)
                          : _buildEventDetails(eventDetails ?? {}, meeting, isDark),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.closeMeetingDetail(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForegroundLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: AppTextStyles.buttonMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading event details...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: AppTextStyles.h4.copyWith(
              color: isDark
                  ? AppColors.foregroundDark
                  : AppColors.foregroundLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(
    Map<String, dynamic> eventData,
    dynamic meeting,
    bool isDark,
  ) {
    // Parse date and time from API response
    final dateStr = eventData['date'] ?? meeting.date;
    final startTimeStr = eventData['start_time'] ?? meeting.startTime;
    final endTimeStr = eventData['end_time'] ?? meeting.endTime;
    final description = eventData['description'] ?? meeting.description ?? '';
    final createdBy = eventData['created_by'] ?? eventData['user_id'];
    final eventTypeId = eventData['event_type_id'];

    // Format date
    DateTime? eventDate;
    try {
      if (dateStr is String) {
        eventDate = DateTime.parse(dateStr.split('T')[0]);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Format time
    String startTime = '';
    String endTime = '';
    try {
      if (startTimeStr is String) {
        final parts = startTimeStr.contains('T')
            ? startTimeStr.split('T')[1].split(':')
            : startTimeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final min = parts[1];
          startTime = '${hour.toString().padLeft(2, '0')}:$min';
        }
      } else {
        startTime = meeting.startTime;
      }

      if (endTimeStr is String) {
        final parts = endTimeStr.contains('T')
            ? endTimeStr.split('T')[1].split(':')
            : endTimeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final min = parts[1];
          endTime = '${hour.toString().padLeft(2, '0')}:$min';
        }
      } else {
        endTime = meeting.endTime;
      }
    } catch (e) {
      startTime = meeting.startTime;
      endTime = meeting.endTime;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date
        _buildDetailRow(
          icon: Icons.calendar_today,
          label: 'Date',
          value: eventDate != null
              ? _formatDate(eventDate)
              : dateStr.toString(),
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // Time
        _buildDetailRow(
          icon: Icons.access_time,
          label: 'Time',
          value: '$startTime - $endTime',
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // Attendees (if available)
        if (meeting.attendees != null && meeting.attendees.isNotEmpty) ...[
          _buildDetailRow(
            icon: Icons.people,
            label: 'Attendees',
            value: meeting.attendees.join(', '),
            isDark: isDark,
            isMultiLine: true,
          ),
          const SizedBox(height: 16),
        ],

        // Description
        if (description.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Status
        if (meeting.type != null) ...[
          Row(
            children: [
              Text(
                'Status: ',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: meeting.type == 'confirmed'
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.yellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  meeting.type == 'confirmed' ? 'Confirmed' : 'Tentative',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: meeting.type == 'confirmed'
                        ? Colors.green.shade900
                        : Colors.yellow.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Category
        if (meeting.category != null) ...[
          Row(
            children: [
              Text(
                'Category: ',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: meeting.category == 'meeting'
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  meeting.category == 'meeting' ? 'Meeting' : 'Leave',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: meeting.category == 'meeting'
                        ? Colors.blue.shade900
                        : Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Event Type
        if (meeting.primaryEventType != null || eventTypeId != null) ...[
          _buildDetailRow(
            icon: Icons.video_library,
            label: 'Event Type',
            value: meeting.primaryEventType ?? 'Event Type ID: $eventTypeId',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ],

        // // Created By (if available)
        // if (createdBy != null) ...[
        //   _buildDetailRow(
        //     icon: Icons.person,
        //     label: 'Created By',
        //     value: 'User ID: $createdBy',
        //     isDark: isDark,
        //   ),
        // ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}


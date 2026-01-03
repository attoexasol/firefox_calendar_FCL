import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';
import 'package:firefox_calendar/features/calendar/view/event_details_dialog.dart';
import 'package:firefox_calendar/features/calendar/view/hour_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget that listens to selectedMeeting changes and shows dialog
class EventDetailsListener extends StatefulWidget {
  final CalendarController controller;

  const EventDetailsListener({
    super.key,
    required this.controller,
  });

  @override
  State<EventDetailsListener> createState() => _EventDetailsListenerState();
}

class _EventDetailsListenerState extends State<EventDetailsListener> {
  Meeting? _lastShownMeeting;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Extract Rx value once in Obx scope
      final meeting = widget.controller.selectedMeeting.value;
      
      // Show dialog when a new meeting is selected
      if (meeting != null && meeting != _lastShownMeeting) {
        _lastShownMeeting = meeting;
        
        // Capture meeting reference for use in callback (avoid accessing Rx in callback)
        final capturedMeeting = meeting;
        
        // Show dialog after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Use captured value instead of accessing Rx in callback
          if (mounted && widget.controller.selectedMeeting.value == capturedMeeting) {
            Get.dialog(
              const EventDetailsDialog(),
              barrierDismissible: true,
            ).then((_) {
              // Clean up when dialog is closed (use captured value)
              if (mounted && widget.controller.selectedMeeting.value == capturedMeeting) {
                widget.controller.closeMeetingDetail();
                _lastShownMeeting = null;
              }
            });
          }
        });
      } else if (meeting == null) {
        _lastShownMeeting = null;
      }
      
      return const SizedBox.shrink();
    });
  }
}

/// Hour Details Listener
/// Watches for selectedWorkHour changes and shows HourDetailsDialog
class HourDetailsListener extends StatefulWidget {
  final CalendarController controller;

  const HourDetailsListener({
    super.key,
    required this.controller,
  });

  @override
  State<HourDetailsListener> createState() => _HourDetailsListenerState();
}

class _HourDetailsListenerState extends State<HourDetailsListener> {
  WorkHour? _lastShownWorkHour;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Extract Rx value once in Obx scope
      final workHour = widget.controller.selectedWorkHour.value;
      
      // Show dialog when a new work hour is selected
      if (workHour != null && workHour != _lastShownWorkHour) {
        _lastShownWorkHour = workHour;
        
        // Capture workHour reference for use in callback (avoid accessing Rx in callback)
        final capturedWorkHour = workHour;
        
        // Show dialog after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Use captured value instead of accessing Rx in callback
          if (mounted && widget.controller.selectedWorkHour.value == capturedWorkHour) {
            Get.dialog(
              const HourDetailsDialog(),
              barrierDismissible: true,
            ).then((_) {
              // Clean up when dialog is closed (use captured value)
              if (mounted && widget.controller.selectedWorkHour.value == capturedWorkHour) {
                widget.controller.closeWorkHourDetail();
                _lastShownWorkHour = null;
              }
            });
          }
        });
      } else if (workHour == null) {
        _lastShownWorkHour = null;
      }
      
      return const SizedBox.shrink();
    });
  }
}


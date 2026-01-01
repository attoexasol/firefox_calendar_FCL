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
      final meeting = widget.controller.selectedMeeting.value;
      
      // Show dialog when a new meeting is selected
      if (meeting != null && meeting != _lastShownMeeting) {
        _lastShownMeeting = meeting;
        
        // Show dialog after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.controller.selectedMeeting.value == meeting) {
            Get.dialog(
              const EventDetailsDialog(),
              barrierDismissible: true,
            ).then((_) {
              // Clean up when dialog is closed
              if (mounted && widget.controller.selectedMeeting.value == meeting) {
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
      final workHour = widget.controller.selectedWorkHour.value;
      
      // Show dialog when a new work hour is selected
      if (workHour != null && workHour != _lastShownWorkHour) {
        _lastShownWorkHour = workHour;
        
        // Show dialog after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.controller.selectedWorkHour.value == workHour) {
            Get.dialog(
              const HourDetailsDialog(),
              barrierDismissible: true,
            ).then((_) {
              // Clean up when dialog is closed
              if (mounted && widget.controller.selectedWorkHour.value == workHour) {
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


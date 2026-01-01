import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';

/// Helper class to combine meetings and work hours for sorting
class CellItem {
  final CellItemType type;
  final Meeting? meeting;
  final WorkHour? workHour;
  final String startTime;

  CellItem({
    required this.type,
    this.meeting,
    this.workHour,
    required this.startTime,
  });
}

enum CellItemType {
  meeting,
  workHour,
}


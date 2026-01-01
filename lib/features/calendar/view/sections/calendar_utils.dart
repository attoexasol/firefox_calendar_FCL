import 'package:firefox_calendar/features/calendar/controller/calendar_controller.dart';

/// Utility functions for calendar formatting and helpers
class CalendarUtils {
  /// Format hour to 12-hour format with AM/PM
  static String formatHour(int hour) {
    // Convert 24-hour to 12-hour format
    if (hour == 0) {
      return '12:00 AM'; // Midnight
    } else if (hour < 12) {
      // 01:00 AM to 11:00 AM
      final hourStr = hour.toString().padLeft(2, '0');
      return '$hourStr:00 AM';
    } else if (hour == 12) {
      return '12:00 PM'; // Noon
    } else {
      // 01:00 PM to 11:00 PM (convert 13-23 to 1-11)
      final displayHour = hour - 12;
      final hourStr = displayHour.toString().padLeft(2, '0');
      return '$hourStr:00 PM';
    }
  }

  /// Get weekday full name
  static String getWeekdayFull(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  /// Get weekday short name
  static String getWeekdayShort(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  /// Get month short name
  static String getMonthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Get month full name
  static String getMonthFull(int month) {
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
    return months[month - 1];
  }

  /// Format date based on type
  static String formatDate(DateTime date, String type) {
    switch (type) {
      case 'day':
        return '${getWeekdayFull(date.weekday)}, ${getMonthFull(date.month)} ${date.day}, ${date.year}';
      case 'short':
        return '${getMonthShort(date.month)} ${date.day}';
      case 'full':
        return '${getMonthFull(date.month)} ${date.day}, ${date.year}';
      case 'month':
        return '${getMonthFull(date.month)} ${date.year}';
      default:
        return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// Get unique users from meetings
  static List<String> getUsersFromMeetings(List<Meeting> meetings) {
    final userSet = <String>{};
    for (var meeting in meetings) {
      userSet.add(meeting.creator);
      userSet.addAll(meeting.attendees);
    }
    return userSet.toList()..sort();
  }

  /// Get user initials from email/name
  static String getUserInitials(String userEmail) {
    if (userEmail.isEmpty) return 'U';
    
    // Try to extract name from email or use email
    final parts = userEmail.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    } else if (parts.isNotEmpty) {
      final name = parts[0];
      if (name.length >= 2) {
        return name.substring(0, 2).toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return userEmail[0].toUpperCase();
  }

  /// Get display name from email
  static String getDisplayName(String userEmail) {
    if (userEmail.isEmpty) return 'User';
    
    // Try to extract name from email
    final parts = userEmail.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[0].substring(1)} ${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
    } else if (parts.isNotEmpty) {
      final name = parts[0];
      return name[0].toUpperCase() + name.substring(1);
    }
    return userEmail.split('@')[0];
  }

  /// Format date as ISO string (YYYY-MM-DD)
  static String formatDateToIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}


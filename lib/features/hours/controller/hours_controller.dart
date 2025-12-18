import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Hours Controller - Updated to match React Hours component
/// Manages hours tracking, work logs, and timesheet data
class HoursController extends GetxController {
  // Storage
  final storage = GetStorage();

  // Tab management - matching screenshot tabs
  final RxString activeTab = 'day'.obs; // day, week, month
  
  // User data
  final RxString userEmail = ''.obs;
  final RxString userName = ''.obs;

  // Current week navigation
  final Rx<DateTime> currentDate = DateTime.now().obs;
  
  // Work logs - updated to match React component structure
  final RxList<WorkLog> workLogs = <WorkLog>[].obs;
  
  // Loading and modal states
  final RxBool isLoading = false.obs;
  final RxBool showTimeEntryModal = false.obs;

  // Computed values for summary
  // int get totalEntries => workLogs.length;
  // double get totalHours => workLogs.fold(0.0, (sum, log) => sum + log.hours);
  
int get totalEntries => getFilteredWorkLogs().length;
double get totalHours =>
    getFilteredWorkLogs().fold(0.0, (sum, log) => sum + log.hours);

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadMockWorkLogs();
  }

  /// Load user data from storage
  void _loadUserData() {
    userEmail.value = storage.read('userEmail') ?? '';
    userName.value = storage.read('userName') ?? 'User';
  }

  /// Tab management methods
  void setActiveTab(String tab) {
    activeTab.value = tab;
  }

  /// Get current week dates for header display
  String getCurrentWeekRange() {
    final weekDates = _getCurrentWeekDates();
    final startDate = weekDates.first;
    final endDate = weekDates.last;
    
    return '${_formatDateShort(startDate)} - ${_formatDateShort(endDate)}, ${startDate.year}';
  }

  /// Get current week dates
  List<DateTime> _getCurrentWeekDates() {
    final currentDay = currentDate.value.weekday;
    final monday = currentDate.value.subtract(Duration(days: currentDay - 1));
    
    return List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });
  }

  /// Navigate to previous week
  void navigateToPreviousWeek() {
    currentDate.value = currentDate.value.subtract(const Duration(days: 7));
  }

  /// Navigate to next week
  void navigateToNextWeek() {
    currentDate.value = currentDate.value.add(const Duration(days: 7));
  }

  /// Navigate to current week (Today button)
  void navigateToToday() {
    currentDate.value = DateTime.now();
  }

  /// Load mock work logs to match screenshot
  void _loadMockWorkLogs() {
    workLogs.value = [
      WorkLog(
        id: '1',
        workType: 'Development',
        date: DateTime(2025, 12, 10), // 12/10/2025 from screenshot
        hours: 7.5,
        status: 'pending',
        timestamp: DateTime(2025, 12, 10, 9, 0), // 09:00 AM
      ),
      WorkLog(
        id: '2',
        workType: 'Client Meeting',
        date: DateTime(2025, 12, 9), // 12/9/2025 from screenshot
        hours: 6.5,
        status: 'approved',
        timestamp: DateTime(2025, 12, 9, 9, 0), // 09:00 AM
      ),
      WorkLog(
        id: '3',
        workType: 'Training',
        date: DateTime(2025, 12, 8), // 12/8/2025 from screenshot
        hours: 8.0,
        status: 'approved',
        timestamp: DateTime(2025, 12, 8, 9, 0), // 09:00 AM
      ),
    ];
  }

  /// Get filtered work logs based on active period
  List<WorkLog> getFilteredWorkLogs() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (activeTab.value) {
      case 'day':
        return workLogs.where((log) {
          final logDate = DateTime(log.date.year, log.date.month, log.date.day);
          return logDate.isAtSameMomentAs(today);
        }).toList();
        
      case 'week':
        final weekDates = _getCurrentWeekDates();
        final weekStart = weekDates.first;
        final weekEnd = weekDates.last;
        
        return workLogs.where((log) {
          return log.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                 log.date.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
        
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        
        return workLogs.where((log) {
          return log.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                 log.date.isBefore(monthEnd.add(const Duration(days: 1)));
        }).toList();
        
      default:
        return workLogs;
    }
  }

  /// Get status color for badge
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Open time entry modal
  void openTimeEntryModal() {
    showTimeEntryModal.value = true;
  }

  /// Close time entry modal
  void closeTimeEntryModal() {
    showTimeEntryModal.value = false;
  }

  /// Add new work log
  Future<void> addWorkLog(WorkLog workLog) async {
    workLogs.add(workLog);
    workLogs.sort((a, b) => b.date.compareTo(a.date));
    workLogs.refresh();
  }

  /// Format date for display (Dec 8)
  String _formatDateShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Format date for work log display (12/10/2025)
  String formatWorkLogDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Format time for work log display (09:00 AM)
  String formatWorkLogTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}

/// Work Log Model - matches React component structure
class WorkLog {
  final String id;
  final String workType; // Development, Client Meeting, Training, etc.
  final DateTime date;
  final double hours;
  final String status; // pending, approved, rejected
  final DateTime timestamp; // when entry was logged

  WorkLog({
    required this.id,
    required this.workType,
    required this.date,
    required this.hours,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'workType': workType,
    'date': date.toIso8601String(),
    'hours': hours,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
  };

  factory WorkLog.fromJson(Map<String, dynamic> json) => WorkLog(
    id: json['id'] ?? '',
    workType: json['workType'] ?? 'Development',
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    hours: json['hours']?.toDouble() ?? 0.0,
    status: json['status'] ?? 'pending',
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
  );
}
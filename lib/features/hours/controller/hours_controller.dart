import 'package:firefox_calendar/services/auth_service.dart';
import 'package:firefox_calendar/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Hours Controller - Detailed per-entry breakdown
/// 
/// RESPONSIBILITY: Detailed View (with Status Badges)
/// ===================================================
/// - Fetches individual work hour entries (GET /api/all/user_hours)
/// - Displays entries with approved/pending status badges
/// - Shows delete buttons for pending entries
/// - Per-entry status display
/// - Detailed per-day breakdown
/// 
/// DIFFERENCE FROM DASHBOARD:
/// - Dashboard = Summary totals (backend-calculated via POST /api/dashboard/summary)
/// - Hours Controller = Detailed entries (via GET /api/all/user_hours)
/// - Dashboard totals may differ from Hours screen totals (this is expected)
/// - Dashboard shows aggregated summary, Hours shows individual entries
/// - Dashboard = read-only summary, Hours = detailed with status badges
/// 
/// Manages hours tracking, work logs, and timesheet data
class HoursController extends GetxController {
  // Storage and services
  final storage = GetStorage();
  final AuthService _authService = AuthService();

  // Tab management - matching screenshot tabs
  final RxString activeTab = 'day'.obs; // day, week, month
  
  // User data
  final RxString userEmail = ''.obs;
  final RxString userName = ''.obs;

  // Current week navigation
  final Rx<DateTime> currentDate = DateTime.now().obs;
  
  // Work logs - updated to match React component structure
  final RxList<WorkLog> workLogs = <WorkLog>[].obs;
  
  // Calendar events - for informational display
  final RxList<CalendarEvent> calendarEvents = <CalendarEvent>[].obs;
  final RxBool isLoadingEvents = false.obs;
  final RxString eventsError = ''.obs;
  
  // Loading and modal states
  final RxBool isLoading = false.obs;
  final RxBool showTimeEntryModal = false.obs;
  final RxBool showStartTimerModal = false.obs;
  
  // Start Timer Modal state
  // Static work type options (hardcoded - no API)
  static const List<Map<String, String>> workTypeOptions = [
    {'label': 'Team Meeting', 'value': 'team_meating'},
    {'label': 'One-to-one', 'value': 'one_to_one'},
    {'label': 'Client Meeting', 'value': 'client_meeting'},
    {'label': 'Training', 'value': 'training'},
    {'label': 'Personal Appointment', 'value': 'personal_appointment'},
    {'label': 'Annual Leave', 'value': 'annual_leave'},
    {'label': 'Personal Leave', 'value': 'personal_leave'},
    {'label': 'Work Day', 'value': 'work_day'},
  ];
  
  final RxString selectedWorkType = ''.obs; // Stores ENUM value (e.g., "client_meeting")
  final RxString descriptionText = ''.obs;
  final RxString descriptionError = ''.obs;
  final TextEditingController descriptionController = TextEditingController();

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
    // Fetch work hours from API instead of mock data
    fetchWorkHours();
    // Fetch calendar events for informational display
    fetchCalendarEvents();
    // Work types are static (hardcoded) - no API call needed
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data when screen becomes visible
    // This ensures fresh data when returning to the Hours screen
    fetchWorkHours();
    fetchCalendarEvents();
  }

  /// Load user data from storage
  void _loadUserData() {
    userEmail.value = storage.read('userEmail') ?? '';
    userName.value = storage.read('userName') ?? 'User';
  }

  /// Tab management methods
  /// When tab changes, fetch work hours for the new range
  void setActiveTab(String tab) {
    activeTab.value = tab;
    // Fetch work hours for the new range
    fetchWorkHours();
    // Fetch calendar events for the new range
    fetchCalendarEvents();
  }

  /// Navigate to previous period (day/week/month)
  void navigateToPreviousWeek() {
    final oldDate = currentDate.value;
    
    switch (activeTab.value) {
      case 'day':
        currentDate.value = oldDate.subtract(const Duration(days: 1));
        break;
      case 'week':
        currentDate.value = oldDate.subtract(const Duration(days: 7));
        break;
      case 'month':
        currentDate.value = DateTime(oldDate.year, oldDate.month - 1, oldDate.day);
        break;
    }
    
    fetchWorkHours();
    fetchCalendarEvents();
  }

  /// Navigate to next period (day/week/month)
  void navigateToNextWeek() {
    final oldDate = currentDate.value;
    
    switch (activeTab.value) {
      case 'day':
        currentDate.value = oldDate.add(const Duration(days: 1));
        break;
      case 'week':
        currentDate.value = oldDate.add(const Duration(days: 7));
        break;
      case 'month':
        currentDate.value = DateTime(oldDate.year, oldDate.month + 1, oldDate.day);
        break;
    }
    
    fetchWorkHours();
    fetchCalendarEvents();
  }

  /// Navigate to current week/month (Today button)
  void navigateToToday() {
    currentDate.value = DateTime.now();
    fetchWorkHours();
    fetchCalendarEvents();
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


  /// Load mock work logs with complete data structure
  /// Includes: title, date, login_time, logout_time, total hours, and status
  /// Structured for Dashboard summaries and Payroll calculations
  void _loadMockWorkLogs() {
    final now = DateTime.now();
    
    workLogs.value = [
      WorkLog(
        id: '1',
        title: 'Work Day',
        workType: 'Development',
        date: DateTime(now.year, now.month, now.day), // Today
        hours: 8.5,
        status: 'pending',
        timestamp: DateTime(now.year, now.month, now.day, 9, 0), // Logged at 09:00 AM
        loginTime: DateTime(now.year, now.month, now.day, 9, 0), // Start: 09:00 AM
        logoutTime: DateTime(now.year, now.month, now.day, 17, 30), // End: 05:30 PM
      ),
      WorkLog(
        id: '2',
        title: 'Work Day',
        workType: 'Client Meeting',
        date: DateTime(now.year, now.month, now.day - 1), // Yesterday
        hours: 7.0,
        status: 'approved',
        timestamp: DateTime(now.year, now.month, now.day - 1, 8, 30), // Logged at 08:30 AM
        loginTime: DateTime(now.year, now.month, now.day - 1, 8, 30), // Start: 08:30 AM
        logoutTime: DateTime(now.year, now.month, now.day - 1, 15, 30), // End: 03:30 PM
      ),
      WorkLog(
        id: '3',
        title: 'Work Day',
        workType: 'Training',
        date: DateTime(now.year, now.month, now.day - 2), // 2 days ago
        hours: 6.5,
        status: 'approved',
        timestamp: DateTime(now.year, now.month, now.day - 2, 9, 15), // Logged at 09:15 AM
        loginTime: DateTime(now.year, now.month, now.day - 2, 9, 15), // Start: 09:15 AM
        logoutTime: DateTime(now.year, now.month, now.day - 2, 15, 45), // End: 03:45 PM
      ),
      WorkLog(
        id: '4',
        title: 'Work Day',
        workType: 'Development',
        date: DateTime(now.year, now.month, now.day - 3), // 3 days ago
        hours: 8.0,
        status: 'pending',
        timestamp: DateTime(now.year, now.month, now.day - 3, 8, 45), // Logged at 08:45 AM
        loginTime: DateTime(now.year, now.month, now.day - 3, 8, 45), // Start: 08:45 AM
        logoutTime: DateTime(now.year, now.month, now.day - 3, 16, 45), // End: 04:45 PM
      ),
      WorkLog(
        id: '5',
        title: 'Work Day',
        workType: 'Project Review',
        date: DateTime(now.year, now.month, now.day - 4), // 4 days ago
        hours: 7.5,
        status: 'approved',
        timestamp: DateTime(now.year, now.month, now.day - 4, 9, 0), // Logged at 09:00 AM
        loginTime: DateTime(now.year, now.month, now.day - 4, 9, 0), // Start: 09:00 AM
        logoutTime: DateTime(now.year, now.month, now.day - 4, 16, 30), // End: 04:30 PM
      ),
    ];
  }

  /// Format date to YYYY-MM-DD string (consistent with CalendarController)
  String _formatDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if a date string (YYYY-MM-DD) matches the current filter
  /// Shared filter function for both events and work hours
  /// Uses currentDate.value (not DateTime.now())
  bool _isDateInFilter(String dateString) {
    if (dateString.isEmpty) return false;
    
    try {
      switch (activeTab.value) {
        case 'day':
          // Day view: exact date match (YYYY-MM-DD string comparison)
          final currentDateStr = _formatDateString(currentDate.value);
          final isMatch = dateString == currentDateStr;
          return isMatch;
          
        case 'week':
          // Week view: date is within current week (Monday to Sunday, inclusive)
          final weekDates = _getCurrentWeekDates();
          final weekStart = weekDates.first;
          final weekEnd = weekDates.last;
          
          // Parse item date
          final itemDate = DateTime.parse(dateString);
          final itemDateOnly = DateTime(itemDate.year, itemDate.month, itemDate.day);
          final weekStartOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
          final weekEndOnly = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
          
          // Check if item date is within week range (inclusive boundaries)
          final isMatch = (itemDateOnly.isAtSameMomentAs(weekStartOnly) ||
                          itemDateOnly.isAtSameMomentAs(weekEndOnly) ||
                          (itemDateOnly.isAfter(weekStartOnly) && itemDateOnly.isBefore(weekEndOnly)));
          return isMatch;
          
        case 'month':
          // Month view: date is in current month (year and month match)
          // Parse the date string and compare year and month
          try {
            final itemDate = DateTime.parse(dateString);
            final itemYear = itemDate.year;
            final itemMonth = itemDate.month;
            final currentYear = currentDate.value.year;
            final currentMonth = currentDate.value.month;
            
            // Compare year and month directly
            final isMatch = itemYear == currentYear && itemMonth == currentMonth;
            
            // Debug logging for month filter
            if (!isMatch) {
              print('🔍 [Month Filter] Entry filtered out:');
              print('   Entry date: $itemYear-$itemMonth (from: $dateString)');
              print('   Current date: $currentYear-$currentMonth');
            }
            
            return isMatch;
          } catch (e) {
            print('❌ [Month Filter] Error parsing date: $dateString - $e');
            return false;
          }
          
        default:
          return true;
      }
    } catch (e) {
      print('❌ [Date Filter] Error filtering date: $dateString - $e');
      print('   Active tab: ${activeTab.value}');
      print('   Current date: ${currentDate.value}');
      return false;
    }
  }

  /// Get filtered work logs based on active period
  /// Uses shared filter function for consistency
  /// Get filtered work logs based on active tab (day/week/month)
  /// This method is reactive - accessing workLogs inside makes it observable
  List<WorkLog> getFilteredWorkLogs() {
    if (workLogs.isEmpty) return [];
    
    final filtered = workLogs.where((log) {
      try {
        // Convert log date to YYYY-MM-DD format
        final logDateStr = _formatDateString(log.date);
        return _isDateInFilter(logDateStr);
      } catch (e) {
        print('⚠️ [HoursController] Error filtering work log: $e');
        print('   Log date: ${log.date}');
        return false;
      }
    }).toList();
    
    return filtered;
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

  /// Reusable method to create complete work hours entry
  /// Can be used by Hours screen and Dashboard
  /// Creates entry with title, date, login_time, logout_time, and status "pending"
  Future<Map<String, dynamic>> createCompleteWorkHoursEntry({
    required String title,
    required String date,
    required String loginTime,
    required String logoutTime,
  }) async {
    print('═══════════════════════════════════════════════════════════');
    print('📝 [HoursController] Creating complete work hours entry');
    print('   Title: $title');
    print('   Date: $date');
    print('   Login Time: $loginTime');
    print('   Logout Time: $logoutTime');
    print('   Status: pending');
    print('═══════════════════════════════════════════════════════════');

    final result = await _authService.createUserHours(
      title: title,
      date: date,
      loginTime: loginTime,
      logoutTime: logoutTime,
      totalHours: null, // Backend will calculate
      status: 'pending', // Status remains "pending" after creation
    );

    if (result['success'] == true) {
      final sessionData = result['data'];
      if (sessionData != null) {
        print('✅ [HoursController] Complete entry created successfully');
        print('   Entry ID: ${sessionData['id']}');
        print('   Status: ${sessionData['status'] ?? 'pending'}');
        print('═══════════════════════════════════════════════════════════');
        
        // Refresh work logs after creation
        await refreshWorkLogs();
      }
    }

    return result;
  }

  /// Update an existing work hours entry
  /// Parameters: id, title (optional), date (optional), loginTime (optional), logoutTime (optional), status (optional)
  /// Returns: Map with success status and message
  Future<Map<String, dynamic>> updateWorkLog({
    required String id,
    String? title,
    String? date,
    String? loginTime,
    String? logoutTime,
    String? status,
  }) async {
    if (isLoading.value) {
      return {
        'success': false,
        'message': 'Another operation is in progress',
      };
    }

    try {
      isLoading.value = true;

      print('═══════════════════════════════════════════════════════════');
      print('📝 [HoursController] Updating work hours entry');
      print('   Entry ID: $id');
      if (title != null) print('   Title: $title');
      if (date != null) print('   Date: $date');
      if (loginTime != null) print('   Login Time: $loginTime');
      if (logoutTime != null) print('   Logout Time: $logoutTime');
      if (status != null) print('   Status: $status');
      print('═══════════════════════════════════════════════════════════');

      final result = await _authService.updateUserHours(
        id: id,
        title: title,
        date: date,
        loginTime: loginTime,
        logoutTime: logoutTime,
        status: status,
      );

      if (result['success'] == true) {
        print('✅ [HoursController] Entry updated successfully');
        
        // Refresh work logs after update
        await refreshWorkLogs();

        Get.snackbar(
          'Success',
          result['message'] ?? 'Work hours entry updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to update work hours entry',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
      }

      return result;
    } catch (e) {
      print('❌ [HoursController] Error updating work log: $e');
      Get.snackbar(
        'Error',
        'Failed to update work hours entry: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
      return {
        'success': false,
        'message': 'Error updating work hours entry',
        'error': e.toString(),
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a work hours entry with confirmation
  /// Parameters: id - The ID of the entry to delete
  /// Returns: Map with success status and message
  Future<Map<String, dynamic>> deleteWorkLog({
    required String id,
  }) async {
    if (isLoading.value) {
      return {
        'success': false,
        'message': 'Another operation is in progress',
      };
    }

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Work Hours Entry'),
        content: const Text('Are you sure you want to delete this work hours entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return {
        'success': false,
        'message': 'Delete operation cancelled',
      };
    }

    try {
      isLoading.value = true;

      print('═══════════════════════════════════════════════════════════');
      print('🗑️ [HoursController] Deleting work hours entry');
      print('   Entry ID: $id');
      print('═══════════════════════════════════════════════════════════');

      final result = await _authService.deleteUserHours(id: id);

      if (result['success'] == true) {
        print('✅ [HoursController] Entry deleted successfully');
        
        // Remove entry from local state
        workLogs.removeWhere((log) => log.id == id);
        workLogs.refresh();

        // Recalculate total hours (automatically updates via getter)
        // Total hours will be recalculated based on remaining entries

        Get.snackbar(
          'Success',
          result['message'] ?? 'Work hours entry deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to delete work hours entry',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
      }

      return result;
    } catch (e) {
      print('❌ [HoursController] Error deleting work log: $e');
      Get.snackbar(
        'Error',
        'Failed to delete work hours entry: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
      return {
        'success': false,
        'message': 'Error deleting work hours entry',
        'error': e.toString(),
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch work hours from API
  /// Fetches entries based on current tab (day/week/month) and current date
  /// Controller handles filtering & grouping
  Future<void> fetchWorkHours() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      print('═══════════════════════════════════════════════════════════');
      print('🔄 [HoursController] Fetching work hours from API');
      print('   Active Tab: ${activeTab.value}');
      print('   Current Date: ${currentDate.value}');
      print('   Date String: ${currentDate.value.toIso8601String().split('T')[0]}');
      print('═══════════════════════════════════════════════════════════');

      // Format current date as YYYY-MM-DD
      final currentDateStr = _formatDateString(currentDate.value);

      // Call API with range and current_date
      final result = await _authService.getUserHours(
        range: activeTab.value, // day, week, or month
        currentDate: currentDateStr, // YYYY-MM-DD
      );

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List && data.isNotEmpty) {
          // Parse API response to WorkLog objects
          workLogs.value = data.map((entry) {
            try {
              return WorkLog.fromApiJson(entry as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ [HoursController] Error parsing work log entry: $e');
              print('   Entry data: $entry');
              return null;
            }
          }).whereType<WorkLog>().toList();
          
          // Sort by date (newest first)
          workLogs.sort((a, b) => b.date.compareTo(a.date));
          workLogs.refresh();

          final filteredCount = getFilteredWorkLogs().length;
          print('✅ [HoursController] Fetched ${workLogs.length} work hours entries');
          print('   Filtered entries for ${activeTab.value} view: $filteredCount');
          print('   Current filter date: ${currentDate.value.year}-${currentDate.value.month}-${currentDate.value.day}');
          
          // Debug: Log all entry dates when month filter is active
          if (activeTab.value == 'month') {
            print('📅 [Month Filter Debug] All entry dates:');
            for (final log in workLogs) {
              print('   Entry: ${log.date.year}-${log.date.month}-${log.date.day} (Status: ${log.status})');
            }
            print('   Looking for: ${currentDate.value.year}-${currentDate.value.month}');
          }
        } else {
          workLogs.value = [];
          print('⚠️ [HoursController] No work hours entries found in API response');
        }
      } else {
        print('❌ [HoursController] Failed to fetch work hours: ${result['message']}');
        // Fallback to empty list on error
        workLogs.value = [];
      }
    } catch (e, stackTrace) {
      print('❌ [HoursController] Error fetching work hours: $e');
      print('   Stack trace: $stackTrace');
      workLogs.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh work logs list from API
  /// This method should be called after create, update, or delete operations
  /// Uses GET /api/all/user_hours to fetch all data and update UI immediately
  Future<void> refreshWorkLogs() async {
    try {
      print('🔄 [HoursController] Refreshing work logs after create/update/delete...');
      
      // Use getAllUserHours to fetch all data (no date filtering)
      final result = await _authService.getAllUserHours();
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          // Get current user ID from storage
          final userId = storage.read('userId');
          final userIdInt = userId is int ? userId : (userId is String ? int.tryParse(userId) : null);
          
          // Filter for current user only
          final userWorkLogs = data.where((entry) {
            if (entry is! Map<String, dynamic>) return false;
            
            // Extract user ID from entry
            int? entryUserId;
            if (entry['user'] != null && entry['user'] is Map) {
              final userMap = entry['user'] as Map<String, dynamic>;
              final userIdValue = userMap['id'];
              
              if (userIdValue is int) {
                entryUserId = userIdValue;
              } else if (userIdValue is String) {
                entryUserId = int.tryParse(userIdValue);
              } else if (userIdValue != null) {
                entryUserId = int.tryParse(userIdValue.toString());
              }
            }
            
            // Include entry if user ID matches
            return entryUserId != null && entryUserId == userIdInt;
          }).toList();
          
          // Parse API response to WorkLog objects
          final parsedLogs = userWorkLogs.map((entry) {
            try {
              return WorkLog.fromApiJson(entry as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ [HoursController] Error parsing work log entry: $e');
              print('   Entry data: $entry');
              return null;
            }
          }).whereType<WorkLog>().toList();
          
          // Sort by date (newest first)
          parsedLogs.sort((a, b) => b.date.compareTo(a.date));
          
          // Update workLogs with new list - this triggers reactivity
          workLogs.value = parsedLogs;
          workLogs.refresh(); // Force UI update
          
          print('✅ [HoursController] Refreshed ${workLogs.length} work hours entries');
          print('   Filtered entries for ${activeTab.value} view: ${getFilteredWorkLogs().length}');
          
          // Debug: Log the newly created entry if it exists
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final todayEntries = workLogs.where((log) {
            final logDate = DateTime(log.date.year, log.date.month, log.date.day);
            return logDate.isAtSameMomentAs(todayDate) && 
                   log.status.toLowerCase() == 'pending' &&
                   log.loginTime != null &&
                   log.logoutTime == null;
          }).toList();
          if (todayEntries.isNotEmpty) {
            print('🟢 [HoursController] Found ${todayEntries.length} active timer entry(ies) for today');
          }
        } else {
          print('⚠️ [HoursController] No work hours entries in refresh response');
        }
      } else {
        print('❌ [HoursController] Failed to refresh work logs: ${result['message']}');
      }
    } catch (e) {
      print('❌ [HoursController] Error refreshing work logs: $e');
      // Fallback to regular fetch if refresh fails
      await fetchWorkHours();
    }
  }

  // ============================================================
  // CALENDAR EVENTS - Informational Display
  // ============================================================

  /// Fetch calendar events from API
  /// Fetches current user's events for informational display
  /// Events are filtered by date based on activeTab
  Future<void> fetchCalendarEvents() async {
    if (isLoadingEvents.value) return;

    try {
      isLoadingEvents.value = true;
      eventsError.value = '';
      
      print('═══════════════════════════════════════════════════════════');
      print('📅 [HoursController] Fetching calendar events...');
      print('   Active Tab: ${activeTab.value}');
      print('   Current Date: ${currentDate.value}');
      print('═══════════════════════════════════════════════════════════');

      // Format current date as YYYY-MM-DD
      final currentDateStr = _formatDateString(currentDate.value);
      
      // Determine range based on active tab
      String range = 'day'; // Default to day for Hours screen
      if (activeTab.value == 'week') {
        range = 'week';
      } else if (activeTab.value == 'month') {
        range = 'month';
      }

      // Call API to get current user's events
      final result = await _authService.getMyEvents(
        range: range,
        currentDate: currentDateStr,
      );

      if (result['success'] == true && result['data'] != null) {
        final eventsData = result['data'];
        
        // Handle both single event object and list of events
        List<dynamic> eventsList;
        if (eventsData is List) {
          eventsList = eventsData;
        } else if (eventsData is Map) {
          eventsList = [eventsData];
        } else {
          eventsList = [];
        }

        // Map API response to CalendarEvent objects
        final mappedEvents = eventsList.map((eventData) {
          return _mapEventToCalendarEvent(eventData as Map<String, dynamic>);
        }).where((event) => event != null).cast<CalendarEvent>().toList();

        // Filter events by date based on active tab
        calendarEvents.value = _filterEventsByDate(mappedEvents);
        
        print('✅ [HoursController] Fetched ${mappedEvents.length} events, ${calendarEvents.length} after filtering');
      } else {
        eventsError.value = result['message'] ?? 'Failed to fetch events';
        print('❌ [HoursController] Failed to fetch events: ${result['message']}');
        calendarEvents.value = [];
      }
    } catch (e) {
      isLoadingEvents.value = false;
      eventsError.value = 'An error occurred while fetching events';
      print('💥 [HoursController] Error fetching calendar events: $e');
      calendarEvents.value = [];
    } finally {
      isLoadingEvents.value = false;
    }
  }

  /// Map API event data to CalendarEvent model
  CalendarEvent? _mapEventToCalendarEvent(Map<String, dynamic> eventData) {
    try {
      // Extract date and time
      final dateStr = eventData['date']?.toString() ?? '';
      final startTimeStr = eventData['start_time']?.toString() ?? '';
      final endTimeStr = eventData['end_time']?.toString() ?? '';
      final title = eventData['title']?.toString() ?? 'Untitled Event';
      final id = eventData['id']?.toString() ?? '';
      
      // Extract event type name
      String? eventTypeName;
      if (eventData['event_type'] != null && eventData['event_type'] is Map) {
        final eventType = eventData['event_type'] as Map<String, dynamic>;
        eventTypeName = eventType['event_name']?.toString();
      }

      // Parse date
      DateTime? parsedDate;
      if (dateStr.isNotEmpty) {
        try {
          String datePart = dateStr;
          if (dateStr.contains('T')) {
            datePart = dateStr.split('T')[0];
          }
          parsedDate = DateTime.parse(datePart);
        } catch (e) {
          print('⚠️ [HoursController] Error parsing date: $dateStr');
        }
      }

      // Parse start time
      DateTime? parsedStartTime;
      if (startTimeStr.isNotEmpty && parsedDate != null) {
        try {
          if (startTimeStr.contains('T')) {
            parsedStartTime = DateTime.parse(startTimeStr);
          } else {
            // Time-only format (HH:MM) - combine with date
            final timeParts = startTimeStr.split(':');
            if (timeParts.length >= 2) {
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;
              parsedStartTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
            }
          }
        } catch (e) {
          print('⚠️ [HoursController] Error parsing start_time: $startTimeStr');
        }
      }

      // Parse end time
      DateTime? parsedEndTime;
      if (endTimeStr.isNotEmpty && parsedDate != null) {
        try {
          if (endTimeStr.contains('T')) {
            parsedEndTime = DateTime.parse(endTimeStr);
          } else {
            // Time-only format (HH:MM) - combine with date
            final timeParts = endTimeStr.split(':');
            if (timeParts.length >= 2) {
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;
              parsedEndTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
            }
          }
        } catch (e) {
          print('⚠️ [HoursController] Error parsing end_time: $endTimeStr');
        }
      }

      if (parsedDate == null) {
        print('⚠️ [HoursController] Skipping event with invalid date: $title');
        return null;
      }

      return CalendarEvent(
        id: id,
        title: title,
        eventTypeName: eventTypeName,
        date: parsedDate,
        startTime: parsedStartTime,
        endTime: parsedEndTime,
      );
    } catch (e) {
      print('❌ [HoursController] Error mapping event: $e');
      return null;
    }
  }

  /// Filter events by date based on active tab
  /// Uses shared filter function for consistency with work hours
  /// Day: Show only events for selected date
  /// Week: Show events in current week
  /// Month: Show events in current month
  List<CalendarEvent> _filterEventsByDate(List<CalendarEvent> events) {
    return events.where((event) {
      // Convert event date to YYYY-MM-DD format
      final eventDateStr = _formatDateString(event.date);
      return _isDateInFilter(eventDateStr);
    }).toList();
  }

  /// Get filtered calendar events for display
  /// Returns events filtered by current date/tab selection
  List<CalendarEvent> getFilteredCalendarEvents() {
    // Re-apply filter in case tab/date changed after initial fetch
    return _filterEventsByDate(calendarEvents);
  }

  // ============================================================
  // Helper methods for Dashboard summaries and Payroll calculations
  // These methods are structured for future use but not implemented yet
  // ============================================================

  /// Get work logs for today
  /// Returns: List of WorkLog entries for today's date
  /// Use case: Dashboard "Hours Today" summary
  List<WorkLog> getTodayWorkLogs() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    return workLogs.where((log) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      return logDate.isAtSameMomentAs(todayDate);
    }).toList();
  }

  /// Get work logs for current week
  /// Returns: List of WorkLog entries within the current week
  /// Use case: Dashboard "Hours This Week" summary
  List<WorkLog> getThisWeekWorkLogs() {
    final weekDates = _getCurrentWeekDates();
    final weekStart = weekDates.first;
    final weekEnd = weekDates.last;
    
    return workLogs.where((log) {
      return log.isInDateRange(weekStart, weekEnd);
    }).toList();
  }

  /// Get approved work logs only
  /// Returns: List of WorkLog entries with status "approved"
  /// Use case: Payroll calculations (only approved hours count)
  List<WorkLog> getApprovedWorkLogs() {
    return workLogs.where((log) => log.isApproved).toList();
  }

  /// Get approved work logs for a specific date range
  /// Parameters: startDate, endDate
  /// Returns: List of approved WorkLog entries within the date range
  /// Use case: Payroll calculations for specific period
  List<WorkLog> getApprovedWorkLogsInRange(DateTime startDate, DateTime endDate) {
    return workLogs.where((log) {
      return log.isApproved && log.isInDateRange(startDate, endDate);
    }).toList();
  }

  /// Calculate total hours from a list of work logs
  /// Parameters: List of WorkLog entries
  /// Returns: Total hours as double
  /// Use case: Dashboard summaries and Payroll calculations
  double calculateTotalHours(List<WorkLog> logs) {
    return logs.fold(0.0, (sum, log) => sum + log.hours);
  }

  /// Get work logs with complete time information
  /// Returns: List of WorkLog entries that have both loginTime and logoutTime
  /// Use case: Data validation and accurate time tracking
  List<WorkLog> getCompleteWorkLogs() {
    return workLogs.where((log) => log.hasCompleteTimeInfo).toList();
  }

  /// Validate work log data consistency
  /// Returns: Map with validation results
  /// Use case: Ensure data integrity before Dashboard/Payroll calculations
  Map<String, dynamic> validateWorkLogData() {
    final totalEntries = workLogs.length;
    final entriesWithCompleteTime = getCompleteWorkLogs().length;
    final approvedEntries = getApprovedWorkLogs().length;
    final todayEntries = getTodayWorkLogs().length;
    final thisWeekEntries = getThisWeekWorkLogs().length;

    return {
      'totalEntries': totalEntries,
      'entriesWithCompleteTime': entriesWithCompleteTime,
      'entriesMissingTimeInfo': totalEntries - entriesWithCompleteTime,
      'approvedEntries': approvedEntries,
      'todayEntries': todayEntries,
      'thisWeekEntries': thisWeekEntries,
      'isDataConsistent': entriesWithCompleteTime == totalEntries,
    };
  }

  // ============================================================
  // START TIMER MODAL FUNCTIONALITY
  // ============================================================

  /// Get work type label from ENUM value
  /// Used for displaying work type in UI (e.g., "client_meeting" → "Client Meeting")
  String getWorkTypeLabel(String? value) {
    if (value == null || value.isEmpty) return '';
    final option = workTypeOptions.firstWhereOrNull(
      (option) => option['value'] == value,
    );
    return option?['label'] ?? value;
  }

  /// Open Start Timer modal
  void openStartTimerModal() {
    // Reset form
    selectedWorkType.value = '';
    descriptionText.value = '';
    descriptionError.value = '';
    descriptionController.text = ''; // Clear controller text
    showStartTimerModal.value = true;
  }

  /// Close Start Timer modal
  void closeStartTimerModal() {
    showStartTimerModal.value = false;
    // Reset form
    selectedWorkType.value = '';
    descriptionText.value = '';
    descriptionError.value = '';
    descriptionController.text = ''; // Clear controller text
  }

  /// Check if description is required for selected work type
  /// Uses ENUM values (not labels)
  bool isDescriptionRequired(String? workTypeValue) {
    if (workTypeValue == null || workTypeValue.isEmpty) return false;
    
    // Description is REQUIRED for these ENUM values:
    final requiredTypes = [
      'team_meating',
      'client_meeting',
      'training',
      'work_day',
    ];
    
    return requiredTypes.contains(workTypeValue);
  }

  /// Validate form before starting timer
  bool validateStartTimerForm() {
    descriptionError.value = '';
    
    // Work type is required
    if (selectedWorkType.value.isEmpty) {
      return false;
    }
    
    // Description is required for certain work types
    if (isDescriptionRequired(selectedWorkType.value)) {
      if (descriptionText.value.trim().isEmpty) {
        final workTypeLabel = getWorkTypeLabel(selectedWorkType.value);
        descriptionError.value = 'Description is required for $workTypeLabel';
        return false;
      }
    }
    
    return true;
  }

  /// Start timer with work type and description
  /// This method is called from the modal when user clicks "Start Timer"
  Future<void> startTimerWithDetails() async {
    if (!validateStartTimerForm()) {
      return;
    }

    try {
      isLoading.value = true;

      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final currentDateTime = now.toIso8601String().split('.')[0];
      final loginTime = currentDateTime.replaceAll('T', ' ');

      // Get work type label for logging (UI display)
      final workTypeLabel = getWorkTypeLabel(selectedWorkType.value);
      
      print('🟢 [HoursController] Starting timer with details');
      print('   Work Type (Label): $workTypeLabel');
      print('   Work Type (ENUM): ${selectedWorkType.value}');
      print('   Description: ${descriptionText.value}');
      print('   Date: $todayStr');
      print('   Login Time: $loginTime');

      // Call CREATE user hours API with work_type (ENUM value) and description
      final result = await _authService.createUserHours(
        title: 'Work Day',
        date: todayStr,
        loginTime: loginTime,
        logoutTime: null,
        totalHours: null,
        status: 'pending',
        workType: selectedWorkType.value, // Send ENUM value (e.g., "client_meeting")
        description: descriptionText.value.trim().isNotEmpty ? descriptionText.value.trim() : null,
      );

      if (result['success'] == true) {
        print('✅ [HoursController] Timer started successfully');
        
        // Close modal
        closeStartTimerModal();
        
        // Refresh work logs
        await refreshWorkLogs();
        
        // Also refresh dashboard if available
        try {
          if (Get.isRegistered<DashboardController>()) {
            final dashboardController = Get.find<DashboardController>();
            await dashboardController.refreshDashboardSummary();
          }
        } catch (e) {
          print('⚠️ [HoursController] Could not refresh dashboard: $e');
        }

        Get.snackbar(
          'Success',
          'Timer started successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to start timer',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ [HoursController] Error starting timer: $e');
      Get.snackbar(
        'Error',
        'Failed to start timer: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current active session (if timer is running)
  WorkLog? getActiveSession() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    return workLogs.firstWhereOrNull((log) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      return logDate.isAtSameMomentAs(todayDate) && 
             log.status.toLowerCase() == 'pending' &&
             log.loginTime != null &&
             log.logoutTime == null;
    });
  }
}

/// Work Log Model - for work hours entries
/// 
/// Structured to support:
/// - Dashboard summaries (Hours Today, Hours This Week)
/// - Payroll calculations (approved hours only)
/// - Accurate time tracking (login_time and logout_time)
/// 
/// Data Structure:
/// - id: Unique identifier
/// - title: Entry title (e.g., "Work Day")
/// - workType: Type of work (e.g., "Development", "Client Meeting")
/// - date: Work date (YYYY-MM-DD, time component should be 00:00:00)
/// - hours: Total hours worked (calculated from loginTime and logoutTime)
/// - status: Entry status ("pending", "approved", "rejected") - defaults to "pending"
/// - timestamp: When the entry was logged/created
/// - loginTime: Start time of work session (required for accurate tracking)
/// - logoutTime: End time of work session (required for accurate tracking)
/// 
/// Usage:
/// - Dashboard: Use getTodayWorkLogs() and getThisWeekWorkLogs() for summaries
/// - Payroll: Use getApprovedWorkLogs() or getApprovedWorkLogsInRange() for calculations
/// - Validation: Use hasCompleteTimeInfo to ensure data integrity
class WorkLog {
  final String id;
  final String title; // Work Day, etc.
  final String workType; // Development, Client Meeting, Training, etc.
  final DateTime date; // Work date (YYYY-MM-DD)
  final double hours; // Total hours worked (calculated from loginTime and logoutTime)
  final String status; // pending, approved, rejected (default: "pending")
  final DateTime timestamp; // Logged time (when entry was created)
  final String? description; // Description text (optional)
  
  // Start and end times - required for Dashboard summaries and Payroll calculations
  final DateTime? loginTime; // Start time (when work session started)
  final DateTime? logoutTime; // End time (when work session ended)

  WorkLog({
    required this.id,
    required this.title,
    required this.workType,
    required this.date,
    required this.hours,
    String? status, // Optional, defaults to "pending"
    required this.timestamp,
    this.loginTime, // Optional - start time of work session
    this.logoutTime, // Optional - end time of work session
    this.description, // Optional - description text
  }) : status = status ?? 'pending'; // Default status is "pending"

  /// Check if entry has complete time information (both start and end times)
  bool get hasCompleteTimeInfo => loginTime != null && logoutTime != null;

  /// Check if entry is approved (for payroll calculations)
  bool get isApproved => status.toLowerCase() == 'approved';

  /// Check if entry is for today
  bool isToday() {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if entry is within a date range (for week/month summaries)
  bool isInDateRange(DateTime startDate, DateTime endDate) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'workType': workType,
    'date': date.toIso8601String(),
    'hours': hours,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'login_time': loginTime?.toIso8601String(),
    'logout_time': logoutTime?.toIso8601String(),
    'description': description,
  };

  factory WorkLog.fromJson(Map<String, dynamic> json) {
    // Parse date
    DateTime parsedDate;
    if (json['date'] != null) {
      final dateStr = json['date'].toString();
      // Handle both ISO format and date-only format
      if (dateStr.contains('T')) {
        parsedDate = DateTime.parse(dateStr);
      } else {
        parsedDate = DateTime.parse('${dateStr}T00:00:00');
      }
      // Extract date only (remove time component)
      parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    } else {
      parsedDate = DateTime.now();
      parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    }

    // Parse login_time (start time)
    DateTime? parsedLoginTime;
    if (json['login_time'] != null) {
      try {
        parsedLoginTime = DateTime.parse(json['login_time'].toString());
      } catch (e) {
        print('⚠️ [WorkLog] Error parsing login_time: ${json['login_time']}');
      }
    }

    // Parse logout_time (end time)
    DateTime? parsedLogoutTime;
    if (json['logout_time'] != null) {
      try {
        parsedLogoutTime = DateTime.parse(json['logout_time'].toString());
      } catch (e) {
        print('⚠️ [WorkLog] Error parsing logout_time: ${json['logout_time']}');
      }
    }

    // Parse timestamp (logged time)
    DateTime parsedTimestamp;
    if (json['timestamp'] != null || json['created_at'] != null) {
      final timestampStr = json['timestamp'] ?? json['created_at'];
      try {
        parsedTimestamp = DateTime.parse(timestampStr.toString());
      } catch (e) {
        parsedTimestamp = DateTime.now();
      }
    } else {
      parsedTimestamp = DateTime.now();
    }

    // Parse hours (total_hours)
    double parsedHours = 0.0;
    if (json['hours'] != null) {
      if (json['hours'] is double) {
        parsedHours = json['hours'] as double;
      } else if (json['hours'] is int) {
        parsedHours = (json['hours'] as int).toDouble();
      } else if (json['hours'] is String) {
        parsedHours = double.tryParse(json['hours'].toString()) ?? 0.0;
      }
    } else if (json['total_hours'] != null) {
      // Handle format like "8h" or "8.5h"
      final totalHoursStr = json['total_hours'].toString().replaceAll('h', '').replaceAll('H', '').trim();
      parsedHours = double.tryParse(totalHoursStr) ?? 0.0;
    }

    return WorkLog(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Work Day',
      workType: json['workType'] ?? json['work_type'] ?? 'Development',
      date: parsedDate,
      hours: parsedHours,
      status: json['status'] ?? 'pending',
      timestamp: parsedTimestamp,
      loginTime: parsedLoginTime,
      logoutTime: parsedLogoutTime,
      description: json['description']?.toString(),
    );
  }

  /// Factory constructor for API response format
  /// API returns: work_date (YYYY-MM-DD), login_time (HH:MM), logout_time (HH:MM), total_hours (number), status
  /// Note: API uses 'work_date' field, but also supports 'date' for backward compatibility
  factory WorkLog.fromApiJson(Map<String, dynamic> json) {
    // Parse date - API returns 'work_date' but also check 'date' for compatibility
    DateTime parsedDate;
    final dateValue = json['work_date'] ?? json['date']; // API uses 'work_date', fallback to 'date'
    
    if (dateValue != null) {
      final dateStr = dateValue.toString();
      // Handle both ISO format and date-only format
      if (dateStr.contains('T')) {
        parsedDate = DateTime.parse(dateStr);
      } else {
        parsedDate = DateTime.parse('${dateStr}T00:00:00');
      }
      // Extract date only (remove time component)
      parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    } else {
      parsedDate = DateTime.now();
      parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    }

    // Parse login_time (HH:MM format like "09:00" or full datetime)
    DateTime? parsedLoginTime;
    if (json['login_time'] != null) {
      try {
        final loginTimeStr = json['login_time'].toString();
        if (loginTimeStr.contains('T') || loginTimeStr.contains(' ')) {
          // Full datetime format
          parsedLoginTime = DateTime.parse(loginTimeStr);
        } else {
          // Time-only format (HH:MM) - combine with date
          final timeParts = loginTimeStr.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            parsedLoginTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
          }
        }
      } catch (e) {
        print('⚠️ [WorkLog] Error parsing login_time: ${json['login_time']}');
      }
    }

    // Parse logout_time (HH:MM format like "17:30" or full datetime)
    DateTime? parsedLogoutTime;
    if (json['logout_time'] != null) {
      try {
        final logoutTimeStr = json['logout_time'].toString();
        if (logoutTimeStr.contains('T') || logoutTimeStr.contains(' ')) {
          // Full datetime format
          parsedLogoutTime = DateTime.parse(logoutTimeStr);
        } else {
          // Time-only format (HH:MM) - combine with date
          final timeParts = logoutTimeStr.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            parsedLogoutTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
          }
        }
      } catch (e) {
        print('⚠️ [WorkLog] Error parsing logout_time: ${json['logout_time']}');
      }
    }

    // Parse timestamp (use created_at if available, otherwise use current time)
    DateTime parsedTimestamp;
    if (json['created_at'] != null) {
      try {
        parsedTimestamp = DateTime.parse(json['created_at'].toString());
      } catch (e) {
        parsedTimestamp = DateTime.now();
      }
    } else {
      parsedTimestamp = DateTime.now();
    }

    // Parse total_hours (number format)
    double parsedHours = 0.0;
    if (json['total_hours'] != null) {
      if (json['total_hours'] is double) {
        parsedHours = json['total_hours'] as double;
      } else if (json['total_hours'] is int) {
        parsedHours = (json['total_hours'] as int).toDouble();
      } else if (json['total_hours'] is String) {
        // Handle format like "8.5" or "8.5h"
        final totalHoursStr = json['total_hours'].toString().replaceAll('h', '').replaceAll('H', '').trim();
        parsedHours = double.tryParse(totalHoursStr) ?? 0.0;
      }
    }

    // Status comes directly from API response - do NOT modify it
    // UI layer will normalize for display/comparison purposes
    final statusFromApi = json['status']?.toString() ?? 'pending';
    
    return WorkLog(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Work Day',
      workType: json['workType'] ?? json['work_type'] ?? 'Development',
      date: parsedDate,
      hours: parsedHours,
      status: statusFromApi, // Status comes directly from API - no modification
      timestamp: parsedTimestamp,
      loginTime: parsedLoginTime,
      logoutTime: parsedLogoutTime,
      description: json['description']?.toString(),
    );
  }
}

/// Calendar Event Model - for informational display in Hours screen
/// Simplified model for displaying events as read-only cards
class CalendarEvent {
  final String id;
  final String title;
  final String? eventTypeName; // event_type.event_name from API
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;

  CalendarEvent({
    required this.id,
    required this.title,
    this.eventTypeName,
    required this.date,
    this.startTime,
    this.endTime,
  });

  /// Format time for display (09:00 AM format)
  String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  /// Get formatted time range (e.g., "09:00 AM - 05:00 PM")
  String getTimeRange() {
    if (startTime != null && endTime != null) {
      return '${formatTime(startTime!)} - ${formatTime(endTime!)}';
    } else if (startTime != null) {
      return formatTime(startTime!);
    } else if (endTime != null) {
      return formatTime(endTime!);
    }
    return 'All day';
  }
}
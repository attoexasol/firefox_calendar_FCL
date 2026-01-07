import 'package:firefox_calendar/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Work Hours Dashboard Controller
/// 
/// RESPONSIBILITY: Work Hours Summary Dashboard
/// ============================================
/// - Fetches ALL user hours from API (GET /api/all/user_hours)
/// - Filters on frontend for logged-in user only
/// - Only considers status = "approved" records
/// - Calculates totals for Day/Week/Month
/// - Displays results in card format
/// 
/// Key Features:
/// - Frontend filtering by user.id
/// - Status filtering (only "approved")
/// - Date range calculations (today, this week, this month)
/// - Total hours calculation by summing total_hours
class WorkHoursDashboardController extends GetxController {
  // Storage and services
  final storage = GetStorage();
  final AuthService _authService = AuthService();

  // Loading state
  final RxBool isLoading = false.obs;

  // Work hours data (all records from API)
  final RxList<Map<String, dynamic>> allWorkHours = <Map<String, dynamic>>[].obs;

  // Filtered and calculated totals
  final RxDouble hoursToday = 0.0.obs;
  final RxDouble hoursThisWeek = 0.0.obs;
  final RxDouble hoursThisMonth = 0.0.obs;

  // Error state
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllUserHours();
  }

  /// Fetch all user hours from API
  /// This returns ALL users' records - we filter on frontend
  Future<void> fetchAllUserHours() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _authService.getAllUserHours();

      if (result['success'] == true) {
        final data = result['data'] as List<dynamic>? ?? [];
        allWorkHours.value = data.cast<Map<String, dynamic>>();
        
        // Calculate totals after fetching
        _calculateTotals();
        
        print('✅ [WorkHoursDashboard] Fetched ${allWorkHours.length} work hours records');
      } else {
        errorMessage.value = result['message'] ?? 'Failed to fetch work hours';
        print('❌ [WorkHoursDashboard] Error: ${errorMessage.value}');
      }
    } catch (e) {
      errorMessage.value = 'Network error. Please check your connection.';
      print('❌ [WorkHoursDashboard] Exception: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get logged-in user ID from storage
  int? get _loggedInUserId {
    final userId = storage.read('userId');
    if (userId is int) return userId;
    if (userId is String) {
      return int.tryParse(userId);
    }
    return null;
  }

  /// Filter work hours for logged-in user and approved status
  List<Map<String, dynamic>> _getFilteredWorkHours() {
    final userId = _loggedInUserId;
    if (userId == null) {
      print('⚠️ [WorkHoursDashboard] User ID not found in storage');
      return [];
    }

    return allWorkHours.where((record) {
      // Filter by user ID
      final recordUserId = _extractUserId(record);
      if (recordUserId != userId) {
        return false;
      }

      // Filter by status = "approved"
      final status = record['status']?.toString().toLowerCase() ?? '';
      if (status != 'approved') {
        return false;
      }

      return true;
    }).toList();
  }

  /// Extract user ID from record
  /// Handles both direct user.id and nested user.id structures
  int? _extractUserId(Map<String, dynamic> record) {
    // Try direct user_id field
    if (record.containsKey('user_id')) {
      final userId = record['user_id'];
      if (userId is int) return userId;
      if (userId is String) return int.tryParse(userId);
    }

    // Try nested user.id structure
    if (record.containsKey('user')) {
      final user = record['user'];
      if (user is Map<String, dynamic>) {
        final userId = user['id'];
        if (userId is int) return userId;
        if (userId is String) return int.tryParse(userId);
      }
    }

    return null;
  }

  /// Parse work_date from record
  /// Handles various date formats
  DateTime? _parseWorkDate(Map<String, dynamic> record) {
    final workDate = record['work_date']?.toString();
    if (workDate == null || workDate.isEmpty) {
      return null;
    }

    try {
      // Try parsing as YYYY-MM-DD
      final parts = workDate.split(' ');
      final datePart = parts[0]; // Get date part before space (if time included)
      
      final dateParts = datePart.split('-');
      if (dateParts.length == 3) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        return DateTime(year, month, day);
      }

      // Try parsing as full DateTime string
      return DateTime.parse(workDate);
    } catch (e) {
      print('⚠️ [WorkHoursDashboard] Error parsing work_date: $workDate - $e');
      return null;
    }
  }

  /// Parse total_hours from record
  double _parseTotalHours(Map<String, dynamic> record) {
    final totalHours = record['total_hours'];
    
    if (totalHours == null) {
      return 0.0;
    }

    if (totalHours is double) {
      return totalHours;
    }

    if (totalHours is int) {
      return totalHours.toDouble();
    }

    if (totalHours is String) {
      return double.tryParse(totalHours) ?? 0.0;
    }

    return 0.0;
  }

  /// Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Check if date is in current week (Monday to Sunday)
  bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    
    // Get Monday of current week
    final daysFromMonday = now.weekday - 1; // Monday = 1, so subtract 1
    final monday = DateTime(now.year, now.month, now.day - daysFromMonday);
    
    // Get Sunday of current week
    final sunday = monday.add(const Duration(days: 6));
    
    // Check if date is within week range (inclusive)
    return date.isAtSameMomentAs(monday) ||
           date.isAtSameMomentAs(sunday) ||
           (date.isAfter(monday) && date.isBefore(sunday));
  }

  /// Check if date is in current month
  bool _isInCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Calculate totals for Day/Week/Month
  void _calculateTotals() {
    final filtered = _getFilteredWorkHours();
    
    double todayTotal = 0.0;
    double weekTotal = 0.0;
    double monthTotal = 0.0;

    for (final record in filtered) {
      final workDate = _parseWorkDate(record);
      if (workDate == null) continue;

      final totalHours = _parseTotalHours(record);

      // Calculate totals based on date ranges
      if (_isToday(workDate)) {
        todayTotal += totalHours;
      }

      if (_isInCurrentWeek(workDate)) {
        weekTotal += totalHours;
      }

      if (_isInCurrentMonth(workDate)) {
        monthTotal += totalHours;
      }
    }

    hoursToday.value = todayTotal;
    hoursThisWeek.value = weekTotal;
    hoursThisMonth.value = monthTotal;

    print('📊 [WorkHoursDashboard] Calculated totals:');
    print('   Today: ${hoursToday.value} hours');
    print('   This Week: ${hoursThisWeek.value} hours');
    print('   This Month: ${hoursThisMonth.value} hours');
  }

  /// Refresh data
  @override
  Future<void> refresh() async {
    await fetchAllUserHours();
  }

  /// Format hours for display (e.g., "8.5" -> "8.5 hrs" or "8.0" -> "8 hrs")
  String formatHours(double hours) {
    if (hours == hours.toInt()) {
      return '${hours.toInt()} hrs';
    }
    return '${hours.toStringAsFixed(1)} hrs';
  }
}


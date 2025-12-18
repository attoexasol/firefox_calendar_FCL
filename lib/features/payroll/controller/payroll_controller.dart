import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Payroll Controller
/// Converted from React Payroll.tsx
/// Manages payroll data, employee information, and payment tracking
class PayrollController extends GetxController {
  // Storage
  final storage = GetStorage();

  // User data
  final RxString userEmail = ''.obs;
  final RxString userName = ''.obs;
  final RxBool isAdmin = false.obs;

  // Selected employee for detail popup
  final Rx<Employee?> selectedEmployee = Rx<Employee?>(null);

  // Employees list
  final RxList<Employee> employees = <Employee>[].obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool showEmployeeDetail = false.obs;

  // Summary metrics (for admin view)
  final RxString totalHoursToday = '21.5'.obs;
  final RxString totalHoursThisWeek = '109.5'.obs;
  final RxString paymentsDue = '3,700'.obs;
  final RxString paymentsCompleted = '1,350'.obs;
  final RxString leavesThisWeek = '3'.obs;
  final RxString currentAvailability = '8/10'.obs;
  final RxString meetingsThisWeek = '12'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadMockEmployees();
    _loadSummaryMetrics();
  }

  /// Load user data from storage
  void _loadUserData() {
    userEmail.value = storage.read('userEmail') ?? '';
    userName.value = storage.read('userName') ?? 'User';
    
    // Mock admin check - replace with actual logic
    isAdmin.value = userEmail.value == 'admin@gmail.com';
  }

  /// Load mock employees data
  /// TODO: Replace with actual API call
  void _loadMockEmployees() {
    employees.value = [
      Employee(
        id: '1',
        name: 'Sarah Wilson',
        email: 'sarah.wilson@firefoxtraining.com.au',
        hoursToday: 8.0,
        hoursWeek: 40.0,
        leaveTakenThisWeek: 0,
        annualLeaveAccrued: 18,
        personalLeaveAccrued: 12,
        daysInLeaveAccrued: 5,
        paymentAmount: 1400,
        paymentStatus: 'confirmed',
      ),
      Employee(
        id: '2',
        name: 'Michael Chen',
        email: 'michael.chen@firefoxtraining.com.au',
        hoursToday: 7.5,
        hoursWeek: 37.5,
        leaveTakenThisWeek: 1,
        annualLeaveAccrued: 15,
        personalLeaveAccrued: 10,
        daysInLeaveAccrued: 2,
        paymentAmount: 1250,
        paymentStatus: 'pending',
      ),
      Employee(
        id: '3',
        name: 'Emma Thompson',
        email: 'emma.thompson@firefoxtraining.com.au',
        hoursToday: 6.0,
        hoursWeek: 32.0,
        leaveTakenThisWeek: 2,
        annualLeaveAccrued: 20,
        personalLeaveAccrued: 15,
        daysInLeaveAccrued: 8,
        paymentAmount: 1050,
        paymentStatus: 'confirmed',
      ),
      Employee(
        id: '4',
        name: 'James Rodriguez',
        email: 'james.rodriguez@firefoxtraining.com.au',
        hoursToday: 0.0,
        hoursWeek: 0.0,
        leaveTakenThisWeek: 0,
        annualLeaveAccrued: 12,
        personalLeaveAccrued: 8,
        daysInLeaveAccrued: 3,
        paymentAmount: 0,
        paymentStatus: 'pending',
      ),
    ];
  }

  /// Load summary metrics for admin view
  void _loadSummaryMetrics() {
    if (!isAdmin.value) return;

    // Calculate metrics from employees data
    double totalToday = 0;
    double totalWeek = 0;
    int totalLeaves = 0;
    double totalPayments = 0;
    double completedPayments = 0;

    for (var employee in employees) {
      totalToday += employee.hoursToday;
      totalWeek += employee.hoursWeek;
      totalLeaves += employee.leaveTakenThisWeek;
      totalPayments += employee.paymentAmount;
      
      if (employee.paymentStatus == 'confirmed') {
        completedPayments += employee.paymentAmount;
      }
    }

    totalHoursToday.value = '${totalToday}h';
    totalHoursThisWeek.value = '${totalWeek}h';
    leavesThisWeek.value = totalLeaves.toString();
    paymentsDue.value = '\$${(totalPayments - completedPayments).toStringAsFixed(0)}';
    paymentsCompleted.value = '\$${completedPayments.toStringAsFixed(0)}';
    
    // Mock availability and meetings
    currentAvailability.value = '${employees.length - totalLeaves}/${employees.length}';
    meetingsThisWeek.value = '12';
  }

  /// Get current user employee data
  Employee? getCurrentEmployee() {
    if (isAdmin.value) return null;
    
    // Find employee by email or create mock data
    final employee = employees.firstWhereOrNull(
      (emp) => emp.email == userEmail.value,
    );
    
    if (employee != null) return employee;
    
    // Return mock data for current user
    return Employee(
      id: 'current',
      name: userName.value,
      email: userEmail.value,
      hoursToday: 7.5,
      hoursWeek: 37.5,
      leaveTakenThisWeek: 0,
      annualLeaveAccrued: 15,
      personalLeaveAccrued: 10,
      daysInLeaveAccrued: 3,
      paymentAmount: 1250,
      paymentStatus: 'pending',
    );
  }

  /// Open employee detail popup
  void openEmployeeDetail(Employee employee) {
    selectedEmployee.value = employee;
    showEmployeeDetail.value = true;
  }

  /// Close employee detail popup
  void closeEmployeeDetail() {
    selectedEmployee.value = null;
    showEmployeeDetail.value = false;
  }

  /// Handle export functionality
  Future<void> handleExport(String format) async {
    if (!isAdmin.value) return;

    isLoading.value = true;

    try {
      // Simulate export process
      await Future.delayed(const Duration(milliseconds: 800));

      Get.snackbar(
        'Export',
        'Exporting payroll data as ${format.toUpperCase()}...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade900,
        duration: const Duration(seconds: 2),
      );

      // TODO: Implement actual export functionality
      print('Exporting as $format');

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to export data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get payment history for current employee
  List<PaymentHistory> getPaymentHistory() {
    return [
      PaymentHistory(
        weekEnding: 'Week Ending Nov 17, 2025',
        hours: 37.5,
        amount: 1250,
        status: 'confirmed',
      ),
      PaymentHistory(
        weekEnding: 'Week Ending Nov 10, 2025',
        hours: 40.0,
        amount: 1333,
        status: 'confirmed',
      ),
      PaymentHistory(
        weekEnding: 'Week Ending Nov 3, 2025',
        hours: 35.0,
        amount: 1167,
        status: 'confirmed',
      ),
    ];
  }

  /// Get status color for payment status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status background color
  Color getStatusBackgroundColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return isDark 
            ? Colors.green.shade900.withValues(alpha: 0.4)
            : Colors.green.shade100;
      case 'pending':
        return isDark 
            ? Colors.orange.shade900.withValues(alpha: 0.4)
            : Colors.orange.shade100;
      case 'rejected':
        return isDark 
            ? Colors.red.shade900.withValues(alpha: 0.4)
            : Colors.red.shade100;
      default:
        return isDark 
            ? Colors.grey.shade900.withValues(alpha: 0.4)
            : Colors.grey.shade100;
    }
  }

  /// Get status text color
  Color getStatusTextColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return isDark ? Colors.green.shade100 : Colors.green.shade800;
      case 'pending':
        return isDark ? Colors.orange.shade100 : Colors.orange.shade800;
      case 'rejected':
        return isDark ? Colors.red.shade100 : Colors.red.shade800;
      default:
        return isDark ? Colors.grey.shade100 : Colors.grey.shade800;
    }
  }

  /// Format status text for display
  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
}

/// Employee Model
/// Converted from React Employee interface
class Employee {
  final String id;
  final String name;
  final String email;
  final double hoursToday;
  final double hoursWeek;
  final int leaveTakenThisWeek;
  final int annualLeaveAccrued;
  final int personalLeaveAccrued;
  final int daysInLeaveAccrued;
  final double paymentAmount;
  final String paymentStatus; // 'confirmed', 'pending', 'rejected'

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.hoursToday,
    required this.hoursWeek,
    required this.leaveTakenThisWeek,
    required this.annualLeaveAccrued,
    required this.personalLeaveAccrued,
    required this.daysInLeaveAccrued,
    required this.paymentAmount,
    required this.paymentStatus,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'hoursToday': hoursToday,
    'hoursWeek': hoursWeek,
    'leaveTakenThisWeek': leaveTakenThisWeek,
    'annualLeaveAccrued': annualLeaveAccrued,
    'personalLeaveAccrued': personalLeaveAccrued,
    'daysInLeaveAccrued': daysInLeaveAccrued,
    'paymentAmount': paymentAmount,
    'paymentStatus': paymentStatus,
  };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    hoursToday: json['hoursToday']?.toDouble() ?? 0.0,
    hoursWeek: json['hoursWeek']?.toDouble() ?? 0.0,
    leaveTakenThisWeek: json['leaveTakenThisWeek'] ?? 0,
    annualLeaveAccrued: json['annualLeaveAccrued'] ?? 0,
    personalLeaveAccrued: json['personalLeaveAccrued'] ?? 0,
    daysInLeaveAccrued: json['daysInLeaveAccrued'] ?? 0,
    paymentAmount: json['paymentAmount']?.toDouble() ?? 0.0,
    paymentStatus: json['paymentStatus'] ?? 'pending',
  );
}

/// Payment History Model
class PaymentHistory {
  final String weekEnding;
  final double hours;
  final double amount;
  final String status;

  PaymentHistory({
    required this.weekEnding,
    required this.hours,
    required this.amount,
    required this.status,
  });
}

/// Summary Metric Model
class SummaryMetric {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
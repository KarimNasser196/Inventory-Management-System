// lib/providers/maintenance_provider.dart (محدث مع إحصائيات يومية)

import 'package:flutter/foundation.dart';
import '../models/maintenance_record.dart';
import '../services/database_helper.dart';

class MaintenanceProvider with ChangeNotifier {
  List<MaintenanceRecord> _maintenanceRecords = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MaintenanceRecord> get maintenanceRecords => _maintenanceRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // إحصائيات عامة
  int get totalRecords => _maintenanceRecords.length;

  int get pendingRecords =>
      _maintenanceRecords.where((r) => r.status == 'قيد الإصلاح').length;

  int get readyForPickup =>
      _maintenanceRecords.where((r) => r.status == 'جاهز للاستلام').length;

  int get completedRecords =>
      _maintenanceRecords.where((r) => r.status == 'تم التسليم').length;

  int get rejectedRecords =>
      _maintenanceRecords.where((r) => r.status == 'مرفوض').length;

  double get totalRevenue => _maintenanceRecords
      .where((r) => r.status == 'تم التسليم')
      .fold<double>(0, (sum, r) => sum + r.cost);

  double get totalPaid =>
      _maintenanceRecords.fold<double>(0, (sum, r) => sum + r.paidAmount);

  double get totalRemaining => _maintenanceRecords
      .where((r) =>
          r.status != 'تم التسليم' && r.status != 'ملغي' && r.status != 'مرفوض')
      .fold<double>(0, (sum, r) => sum + r.remainingAmount);

  // ⭐ إحصائيات اليوم
  Map<String, int> getTodayStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayRecords = _maintenanceRecords.where((r) {
      final recordDate = DateTime(
        r.receivedDate.year,
        r.receivedDate.month,
        r.receivedDate.day,
      );
      return recordDate == today;
    }).toList();

    return {
      'received': todayRecords.length,
      'inProgress': todayRecords.where((r) => r.status == 'قيد الإصلاح').length,
      'ready': todayRecords.where((r) => r.status == 'جاهز للاستلام').length,
      'delivered': todayRecords.where((r) => r.status == 'تم التسليم').length,
      'rejected': todayRecords.where((r) => r.status == 'مرفوض').length,
    };
  }

  // ⭐ إحصائيات مالية حسب الفترة
  Map<String, double> getFinancialStatistics(String period) {
    final now = DateTime.now();
    List<MaintenanceRecord> filteredRecords = [];

    switch (period) {
      case 'اليوم':
        final today = DateTime(now.year, now.month, now.day);
        filteredRecords = _maintenanceRecords.where((r) {
          final recordDate = DateTime(
            r.receivedDate.year,
            r.receivedDate.month,
            r.receivedDate.day,
          );
          return recordDate == today;
        }).toList();
        break;

      case 'هذا الأسبوع':
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        filteredRecords = _maintenanceRecords
            .where((r) => r.receivedDate.isAfter(weekStart))
            .toList();
        break;

      case 'هذا الشهر':
        final monthStart = DateTime(now.year, now.month, 1);
        filteredRecords = _maintenanceRecords
            .where((r) => r.receivedDate.isAfter(monthStart))
            .toList();
        break;

      default: // 'الكل'
        filteredRecords = _maintenanceRecords;
    }

    // حساب الإيرادات (من الأجهزة المكتملة فقط)
    double revenue = filteredRecords
        .where((r) => r.status == 'تم التسليم')
        .fold<double>(0, (sum, r) => sum + r.cost);

    // حساب المتبقي (من الأجهزة قيد العمل والجاهزة للاستلام)
    double remaining = filteredRecords
        .where((r) => r.status == 'قيد الإصلاح' || r.status == 'جاهز للاستلام')
        .fold<double>(0, (sum, r) => sum + r.remainingAmount);

    return {
      'revenue': revenue,
      'remaining': remaining,
    };
  }

  // إحصائيات حسب تاريخ محدد
  Map<String, int> getStatisticsByDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);

    final dateRecords = _maintenanceRecords.where((r) {
      final recordDate = DateTime(
        r.receivedDate.year,
        r.receivedDate.month,
        r.receivedDate.day,
      );
      return recordDate == targetDate;
    }).toList();

    return {
      'received': dateRecords.length,
      'inProgress': dateRecords.where((r) => r.status == 'قيد الإصلاح').length,
      'ready': dateRecords.where((r) => r.status == 'جاهز للاستلام').length,
      'delivered': dateRecords.where((r) => r.status == 'تم التسليم').length,
      'rejected': dateRecords.where((r) => r.status == 'مرفوض').length,
      'cancelled': dateRecords.where((r) => r.status == 'ملغي').length,
    };
  }

  // إحصائيات حسب فترة
  Map<String, int> getStatisticsByPeriod(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final periodRecords = _maintenanceRecords.where((r) {
      return r.receivedDate.isAfter(start) && r.receivedDate.isBefore(end);
    }).toList();

    return {
      'received': periodRecords.length,
      'inProgress':
          periodRecords.where((r) => r.status == 'قيد الإصلاح').length,
      'ready': periodRecords.where((r) => r.status == 'جاهز للاستلام').length,
      'delivered': periodRecords.where((r) => r.status == 'تم التسليم').length,
      'rejected': periodRecords.where((r) => r.status == 'مرفوض').length,
      'cancelled': periodRecords.where((r) => r.status == 'ملغي').length,
    };
  }

  MaintenanceProvider() {
    _initializeData();
  }

  void _initializeData() {
    Future.delayed(Duration.zero, () async {
      try {
        _isLoading = true;
        notifyListeners();

        await fetchMaintenanceRecords();

        _isLoading = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error initializing maintenance data: $e');
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchMaintenanceRecords() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final recordsData = await dbHelper.getMaintenanceRecords();
      _maintenanceRecords =
          recordsData.map((data) => MaintenanceRecord.fromMap(data)).toList();

      // ترتيب حسب التاريخ (الأحدث أولاً)
      _maintenanceRecords.sort(
        (a, b) => b.receivedDate.compareTo(a.receivedDate),
      );

      debugPrint('Fetched ${_maintenanceRecords.length} maintenance records');
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching maintenance records: $e');
      _maintenanceRecords = [];
      _errorMessage = 'فشل في جلب سجلات الصيانة: $e';
      notifyListeners();
    }
  }

  Future<void> addMaintenanceRecord(MaintenanceRecord record) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final id = await dbHelper.insertMaintenanceRecord(record.toMap());

      if (id == -1) throw Exception('فشل في إضافة سجل الصيانة');

      final newRecord = record.copyWith(id: id);
      _maintenanceRecords.insert(0, newRecord);

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding maintenance record: $e');
      _errorMessage = 'فشل في إضافة سجل الصيانة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMaintenanceRecord(MaintenanceRecord record) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final result = await dbHelper.updateMaintenanceRecord(
        record.id!,
        record.toMap(),
      );

      if (result == 0) throw Exception('فشل في تحديث سجل الصيانة');

      final index = _maintenanceRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _maintenanceRecords[index] = record;
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating maintenance record: $e');
      _errorMessage = 'فشل في تحديث سجل الصيانة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMaintenanceRecord(int id) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final result = await dbHelper.deleteMaintenanceRecord(id);

      if (result == 0) throw Exception('فشل في حذف سجل الصيانة');

      _maintenanceRecords.removeWhere((r) => r.id == id);

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting maintenance record: $e');
      _errorMessage = 'فشل في حذف سجل الصيانة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStatus(int id, String newStatus) async {
    try {
      final record = _maintenanceRecords.firstWhere((r) => r.id == id);

      // إذا كانت الحالة الجديدة "تم التسليم"، قم بإضافة تاريخ التسليم
      final updatedRecord = record.copyWith(
        status: newStatus,
        deliveryDate:
            newStatus == 'تم التسليم' ? DateTime.now() : record.deliveryDate,
      );

      await updateMaintenanceRecord(updatedRecord);
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> addPayment(int id, double amount) async {
    try {
      final record = _maintenanceRecords.firstWhere((r) => r.id == id);
      final newPaidAmount = record.paidAmount + amount;

      if (newPaidAmount > record.cost) {
        throw Exception('المبلغ المدفوع أكبر من التكلفة');
      }

      final updatedRecord = record.copyWith(paidAmount: newPaidAmount);
      await updateMaintenanceRecord(updatedRecord);
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    }
  }

  List<MaintenanceRecord> getRecordsByStatus(String status) {
    return _maintenanceRecords.where((r) => r.status == status).toList();
  }

  List<MaintenanceRecord> searchRecords(String query) {
    if (query.isEmpty) return _maintenanceRecords;

    final lowerQuery = query.toLowerCase();
    return _maintenanceRecords.where((r) {
      return r.customerName.toLowerCase().contains(lowerQuery) ||
          r.customerPhone.contains(query) ||
          r.deviceType.toLowerCase().contains(lowerQuery) ||
          r.problemDescription.toLowerCase().contains(lowerQuery) ||
          r.repairCode.contains(query);
    }).toList();
  }

  Future<MaintenanceRecord?> getRecordByCode(String repairCode) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final recordData = await dbHelper.getMaintenanceRecordByCode(repairCode);

      if (recordData != null) {
        return MaintenanceRecord.fromMap(recordData);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting record by code: $e');
      return null;
    }
  }

  Future<MaintenanceRecord?> getRecordByPhone(String phone) async {
    try {
      final records =
          _maintenanceRecords.where((r) => r.customerPhone == phone).toList();
      if (records.isNotEmpty) {
        return records.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting record by phone: $e');
      return null;
    }
  }

  Map<String, int> getStatusStatistics() {
    final stats = <String, int>{};
    for (var record in _maintenanceRecords) {
      stats[record.status] = (stats[record.status] ?? 0) + 1;
    }
    return stats;
  }
}

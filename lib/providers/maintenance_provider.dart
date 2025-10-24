// lib/providers/maintenance_provider.dart

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

  // إحصائيات
  int get totalRecords => _maintenanceRecords.length;

  int get pendingRecords => _maintenanceRecords
      .where((r) => r.status == 'قيد الفحص' || r.status == 'قيد الإصلاح')
      .length;

  int get readyForPickup =>
      _maintenanceRecords.where((r) => r.status == 'جاهز للاستلام').length;

  int get completedRecords =>
      _maintenanceRecords.where((r) => r.status == 'تم التسليم').length;

  double get totalRevenue => _maintenanceRecords
      .where((r) => r.status == 'تم التسليم')
      .fold<double>(0, (sum, r) => sum + r.actualCost);

  double get totalPaid =>
      _maintenanceRecords.fold<double>(0, (sum, r) => sum + r.paidAmount);

  double get totalRemaining => _maintenanceRecords
      .where((r) => r.status != 'تم التسليم' && r.status != 'ملغي')
      .fold<double>(0, (sum, r) => sum + r.remainingAmount);

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
      _maintenanceRecords = recordsData
          .map((data) => MaintenanceRecord.fromMap(data))
          .toList();

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
      final updatedRecord = record.copyWith(
        status: newStatus,
        actualDeliveryDate: newStatus == 'تم التسليم' ? DateTime.now() : null,
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

      if (newPaidAmount > record.actualCost) {
        throw Exception('المبلغ المدفوع أكبر من التكلفة الفعلية');
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
          r.deviceBrand.toLowerCase().contains(lowerQuery) ||
          r.deviceModel.toLowerCase().contains(lowerQuery) ||
          (r.serialNumber?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Map<String, int> getStatusStatistics() {
    final stats = <String, int>{};
    for (var record in _maintenanceRecords) {
      stats[record.status] = (stats[record.status] ?? 0) + 1;
    }
    return stats;
  }

  List<MaintenanceRecord> getOverdueRecords() {
    final now = DateTime.now();
    return _maintenanceRecords.where((r) {
      if (r.expectedDeliveryDate == null) return false;
      if (r.status == 'تم التسليم' || r.status == 'ملغي') return false;
      return r.expectedDeliveryDate!.isBefore(now);
    }).toList();
  }
}

// lib/providers/representative_provider.dart

import 'package:flutter/foundation.dart';
import 'package:soundtry/models/representative.dart';
import 'package:soundtry/models/representative_transaction.dart';
import 'package:soundtry/models/return_detail.dart';
import 'package:soundtry/services/database_helper.dart';

class RepresentativeProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Representative> _representatives = [];
  List<Representative> _filteredRepresentatives = [];
  String _filterType = 'الكل'; // 'الكل', 'مندوب', 'عميل'
  bool _showOnlyWithDebt = false;

  List<Representative> get representatives => _filteredRepresentatives;
  String get filterType => _filterType;
  bool get showOnlyWithDebt => _showOnlyWithDebt;

  // إحصائيات عامة
  int get totalRepresentatives => _representatives.length;
  int get totalMandoubs =>
      _representatives.where((r) => r.type == 'مندوب').length;
  int get totalCustomers =>
      _representatives.where((r) => r.type == 'عميل').length;
  double get totalDebts =>
      _representatives.fold(0.0, (sum, r) => sum + r.remainingDebt);
  double get totalPaid =>
      _representatives.fold(0.0, (sum, r) => sum + r.totalPaid);

  RepresentativeProvider() {
    loadRepresentatives();
  }

  // تحميل جميع المندوبين/العملاء
  Future<void> loadRepresentatives() async {
    try {
      final data = await _dbHelper.getRepresentatives();
      _representatives =
          data.map((map) => Representative.fromMap(map)).toList();
      _applyFilters();
      notifyListeners();
      debugPrint('Loaded ${_representatives.length} representatives');
    } catch (e) {
      debugPrint('Error loading representatives: $e');
    }
  }

  // تطبيق الفلاتر
  void _applyFilters() {
    _filteredRepresentatives = _representatives.where((rep) {
      bool matchesType = _filterType == 'الكل' || rep.type == _filterType;
      bool matchesDebt = !_showOnlyWithDebt || rep.hasDebt;
      return matchesType && matchesDebt;
    }).toList();

    // ترتيب حسب المديونية (الأعلى أولاً)
    _filteredRepresentatives
        .sort((a, b) => b.remainingDebt.compareTo(a.remainingDebt));
  }

  // تغيير الفلتر حسب النوع
  void setFilterType(String type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  // تفعيل/إلغاء عرض المديونين فقط
  void toggleShowOnlyWithDebt() {
    _showOnlyWithDebt = !_showOnlyWithDebt;
    _applyFilters();
    notifyListeners();
  }

  // إضافة مندوب/عميل جديد
  Future<bool> addRepresentative(Representative representative) async {
    try {
      final id = await _dbHelper.insertRepresentative(representative.toMap());
      if (id > 0) {
        await loadRepresentatives();
        debugPrint('Added representative with id: $id');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding representative: $e');
      return false;
    }
  }

  // تحديث مندوب/عميل
  Future<bool> updateRepresentative(Representative representative) async {
    try {
      if (representative.id == null) return false;

      final result = await _dbHelper.updateRepresentative(
        representative.id!,
        representative.toMap(),
      );

      if (result > 0) {
        await loadRepresentatives();
        debugPrint('Updated representative id: ${representative.id}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating representative: $e');
      return false;
    }
  }

  // حذف مندوب/عميل
  Future<bool> deleteRepresentative(int id) async {
    try {
      final result = await _dbHelper.deleteRepresentative(id);
      if (result > 0) {
        await loadRepresentatives();
        debugPrint('Deleted representative id: $id');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting representative: $e');
      return false;
    }
  }

  // الحصول على مندوب/عميل بالـ ID
  Representative? getRepresentativeById(int id) {
    try {
      return _representatives.firstWhere((rep) => rep.id == id);
    } catch (e) {
      return null;
    }
  }

  // إضافة دفعة لمندوب/عميل
  Future<bool> addPayment({
    required int representativeId,
    required double amount,
    String? notes,
  }) async {
    try {
      final rep = getRepresentativeById(representativeId);
      if (rep == null) return false;

      // تحديث إجمالي المدفوع
      final updatedRep = rep.copyWith(
        totalPaid: rep.totalPaid + amount,
      );

      // حفظ معاملة الدفعة
      final transaction = RepresentativeTransaction(
        representativeId: representativeId,
        representativeName: rep.name,
        type: 'دفعة',
        amount: amount,
        paidAmount: amount,
        remainingDebt: updatedRep.remainingDebt,
        notes: notes,
      );

      await _dbHelper.insertRepresentativeTransaction(transaction.toMap());
      await updateRepresentative(updatedRep);

      debugPrint('Added payment of $amount for representative ${rep.name}');
      return true;
    } catch (e) {
      debugPrint('Error adding payment: $e');
      return false;
    }
  }

  // تسجيل عملية بيع آجلة
  Future<bool> recordDeferredSale({
    required int representativeId,
    required double totalAmount,
    required double paidAmount,
    required String productsSummary,
    String? invoiceNumber,
    List<int>? saleIds,
    String? notes,
  }) async {
    try {
      final rep = getRepresentativeById(representativeId);
      if (rep == null) return false;

      final remainingAmount = totalAmount - paidAmount;

      // تحديث إجمالي الديون والمدفوع
      final updatedRep = rep.copyWith(
        totalDebt: rep.totalDebt + totalAmount,
        totalPaid: rep.totalPaid + paidAmount,
      );

      // حفظ معاملة البيع
      final transaction = RepresentativeTransaction(
        representativeId: representativeId,
        representativeName: rep.name,
        type: 'بيع',
        amount: totalAmount,
        paidAmount: paidAmount,
        remainingDebt: updatedRep.remainingDebt,
        productsSummary: productsSummary,
        invoiceNumber: invoiceNumber,
        saleIds: saleIds?.join(','),
        notes: notes,
      );

      await _dbHelper.insertRepresentativeTransaction(transaction.toMap());
      await updateRepresentative(updatedRep);

      debugPrint('Recorded deferred sale for representative ${rep.name}');
      return true;
    } catch (e) {
      debugPrint('Error recording deferred sale: $e');
      return false;
    }
  }

  // تسجيل مرتجع بضاعة
  // تسجيل مرتجع
  Future<bool> recordReturn({
    required int representativeId,
    required double returnAmount,
    required String productsSummary,
    required String invoiceNumber,
    String? notes,
  }) async {
    try {
      final db = await _dbHelper.database;

      // الحصول على المندوب
      final repData = await db.query(
        'representatives',
        where: 'id = ?',
        whereArgs: [representativeId],
      );

      if (repData.isEmpty) {
        debugPrint('❌ المندوب غير موجود');
        return false;
      }

      // ⭐⭐⭐ استخدام نفس الأسماء الموجودة في الـ database
      // بنقرأ من الأعمدة اللي راجعة من query
      final currentTotalDebt =
          (repData.first['totalDebt'] as num?)?.toDouble() ??
              (repData.first['total_debt'] as num?)?.toDouble() ??
              0.0;
      final currentTotalPaid =
          (repData.first['totalPaid'] as num?)?.toDouble() ??
              (repData.first['total_paid'] as num?)?.toDouble() ??
              0.0;

      debugPrint('📊 البيانات الحالية:');
      debugPrint('   - إجمالي الدين: $currentTotalDebt');
      debugPrint('   - إجمالي المدفوع: $currentTotalPaid');
      debugPrint('   - قيمة المرتجع: $returnAmount');

      // تحديث الحساب: تقليل الدين
      final newTotalDebt = currentTotalDebt - returnAmount;
      final newRemainingDebt = newTotalDebt - currentTotalPaid;

      debugPrint('📊 البيانات الجديدة:');
      debugPrint('   - إجمالي الدين الجديد: $newTotalDebt');
      debugPrint('   - المتبقي الجديد: $newRemainingDebt');

      // ⭐⭐⭐ استخدام نفس الطريقة الموجودة في updateRepresentative
      // نحدث بالطريقة الآمنة
      final representative = getRepresentativeById(representativeId);
      if (representative == null) {
        debugPrint('❌ فشل في الحصول على بيانات المندوب');
        return false;
      }

      final updatedRep = representative.copyWith(
        totalDebt: newTotalDebt,
        totalPaid: currentTotalPaid, // نفس القيمة
      );

      // استخدام دالة التحديث الموجودة
      final updateSuccess = await updateRepresentative(updatedRep);

      if (!updateSuccess) {
        debugPrint('❌ فشل تحديث بيانات المندوب');
        return false;
      }

      // ⭐⭐⭐ تسجيل المعاملة باستخدام أسماء camelCase الصحيحة
      final transactionResult = await db.insert('representative_transactions', {
        'representativeId': representativeId, // بدون underscore
        'representativeName': representative.name,
        'type': 'مرتجع',
        'amount': returnAmount,
        'paidAmount': 0,
        'remainingDebt': newRemainingDebt,
        'productsSummary': productsSummary,
        'invoiceNumber': invoiceNumber,
        'notes': notes,
        'dateTime': DateTime.now().toIso8601String(),
      });

      if (transactionResult == 0) {
        debugPrint('❌ فشل تسجيل معاملة المرتجع');
        return false;
      }

      debugPrint('✅ تم تسجيل المرتجع بنجاح - الدين الجديد: $newRemainingDebt');

      return true;
    } catch (e) {
      debugPrint('❌ Error recording return: $e');
      return false;
    }
  }

  Future<List<RepresentativeTransaction>> getTransactions(
      int representativeId) async {
    try {
      final data =
          await _dbHelper.getRepresentativeTransactions(representativeId);
      return data.map((map) => RepresentativeTransaction.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  // الحصول على جميع المعاملات
  Future<List<RepresentativeTransaction>> getAllTransactions() async {
    try {
      final data = await _dbHelper.getAllRepresentativeTransactions();
      return data.map((map) => RepresentativeTransaction.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting all transactions: $e');
      return [];
    }
  }

  // البحث عن مندوب/عميل
  List<Representative> searchRepresentatives(String query) {
    if (query.isEmpty) {
      return _filteredRepresentatives;
    }

    return _filteredRepresentatives.where((rep) {
      return rep.name.toLowerCase().contains(query.toLowerCase()) ||
          (rep.phone?.contains(query) ?? false);
    }).toList();
  }

  // الحصول على أعلى 5 مديونين
  List<Representative> getTopDebtors() {
    final debtors = _representatives.where((r) => r.hasDebt).toList();
    debtors.sort((a, b) => b.remainingDebt.compareTo(a.remainingDebt));
    return debtors.take(5).toList();
  }
}

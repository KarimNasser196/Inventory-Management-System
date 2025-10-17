import 'package:flutter/foundation.dart';
import '../models/laptop.dart';
import '../models/sale.dart';
import '../models/return.dart';
import '../services/database_helper.dart';

class LaptopProvider with ChangeNotifier {
  List<Laptop> _laptops = [];
  List<Sale> _sales = [];
  List<Return> _returns = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Laptop> get laptops => _searchQuery.isEmpty
      ? _laptops
      : _laptops
            .where(
              (laptop) =>
                  laptop.name.contains(_searchQuery) ||
                  laptop.model.contains(_searchQuery) ||
                  laptop.serialNumber.contains(_searchQuery) ||
                  (laptop.customer?.contains(_searchQuery) ?? false),
            )
            .toList();

  List<Sale> get sales => _sales;
  List<Return> get returns => _returns;
  bool get isLoading => _isLoading;

  int get availableLaptopsCount =>
      _laptops.where((laptop) => laptop.status == 'متاح').length;
  int get soldLaptopsCount =>
      _laptops.where((laptop) => laptop.status == 'مباع').length;
  int get returnedLaptopsCount =>
      _laptops.where((laptop) => laptop.status == 'مرتجع').length;

  LaptopProvider() {
    fetchLaptops();
    fetchSales();
    fetchReturns();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchLaptops() async {
    _isLoading = true;
    notifyListeners();

    try {
      final laptops = await DatabaseHelper.instance.getLaptops();
      _laptops = laptops;
    } catch (e) {
      debugPrint('Error fetching laptops: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSales() async {
    try {
      final sales = await DatabaseHelper.instance.getSales();
      _sales = sales;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching sales: $e');
    }
  }

  Future<void> fetchReturns() async {
    try {
      final returns = await DatabaseHelper.instance.getReturns();
      _returns = returns;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching returns: $e');
    }
  }

  Future<void> addLaptop(Laptop laptop) async {
    try {
      final id = await DatabaseHelper.instance.insertLaptop(laptop);
      final newLaptop = laptop.copyWith(id: id);
      _laptops.add(newLaptop);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding laptop: $e');
      rethrow;
    }
  }

  Future<void> updateLaptop(Laptop laptop) async {
    try {
      await DatabaseHelper.instance.updateLaptop(laptop);
      final index = _laptops.indexWhere((l) => l.id == laptop.id);
      if (index != -1) {
        _laptops[index] = laptop;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating laptop: $e');
      rethrow;
    }
  }

  Future<void> deleteLaptop(int id) async {
    try {
      await DatabaseHelper.instance.deleteLaptop(id);
      _laptops.removeWhere((laptop) => laptop.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting laptop: $e');
      rethrow;
    }
  }

  Future<void> sellLaptop(Laptop laptop, Sale sale) async {
    try {
      // Update laptop status
      final updatedLaptop = laptop.copyWith(
        status: 'مباع',
        customer: sale.customerName,
        date: sale.date,
        notes: sale.notes,
      );

      await DatabaseHelper.instance.updateLaptop(updatedLaptop);

      // Add sale record
      final saleId = await DatabaseHelper.instance.insertSale(sale);
      final newSale = Sale(
        id: saleId,
        laptopId: sale.laptopId,
        customerName: sale.customerName,
        price: sale.price,
        date: sale.date,
        notes: sale.notes,
      );

      // Update local data
      final index = _laptops.indexWhere((l) => l.id == laptop.id);
      if (index != -1) {
        _laptops[index] = updatedLaptop;
      }

      _sales.add(newSale);
      notifyListeners();
    } catch (e) {
      debugPrint('Error selling laptop: $e');
      rethrow;
    }
  }

  Future<void> returnLaptop(Laptop laptop, Return returnData) async {
    try {
      // Update laptop status
      final updatedLaptop = laptop.copyWith(
        status: 'مرتجع',
        date: returnData.date,
      );

      await DatabaseHelper.instance.updateLaptop(updatedLaptop);

      // Add return record
      final returnId = await DatabaseHelper.instance.insertReturn(returnData);
      final newReturn = Return(
        id: returnId,
        laptopId: returnData.laptopId,
        date: returnData.date,
        reason: returnData.reason,
      );

      // Update local data
      final index = _laptops.indexWhere((l) => l.id == laptop.id);
      if (index != -1) {
        _laptops[index] = updatedLaptop;
      }

      _returns.add(newReturn);
      notifyListeners();
    } catch (e) {
      debugPrint('Error returning laptop: $e');
      rethrow;
    }
  }

  List<Sale> getRecentSales({int limit = 5}) {
    final sortedSales = List<Sale>.from(_sales)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedSales.take(limit).toList();
  }

  List<Return> getRecentReturns({int limit = 5}) {
    final sortedReturns = List<Return>.from(_returns)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedReturns.take(limit).toList();
  }

  Future<void> resetData() async {
    try {
      await DatabaseHelper.instance.clear();
      _laptops.clear();
      _sales.clear();
      _returns.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting data: $e');
      rethrow;
    }
  }
}

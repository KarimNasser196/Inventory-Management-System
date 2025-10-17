import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/sale_transaction.dart';
import '../models/inventory_transaction.dart';
import '../services/database_helper.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<SaleTransaction> _sales = [];
  List<InventoryTransaction> _inventoryTransactions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;

  List<Product> get products => _searchQuery.isEmpty
      ? _products
      : _products.where((product) {
          final query = _searchQuery.toLowerCase();
          return product.name.toLowerCase().contains(query) ||
              (product.model?.toLowerCase().contains(query) ?? false) ||
              (product.specifications?.toLowerCase().contains(query) ??
                  false) ||
              product.supplierName.toLowerCase().contains(query);
        }).toList();

  List<SaleTransaction> get sales => _sales;
  List<InventoryTransaction> get inventoryTransactions =>
      _inventoryTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalProducts => _products.length;
  int get totalQuantityInStock =>
      _products.fold<int>(0, (sum, p) => sum + p.quantity);
  double get totalInventoryValue => _products.fold<double>(
    0,
    (sum, p) => sum + (p.purchasePrice * p.quantity),
  );

  ProductProvider() {
    fetchProducts();
    fetchSales();
    fetchInventoryTransactions();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final dbHelper = DatabaseHelper.instance;
      final productsData = await dbHelper.getProducts();
      _products = productsData.map((data) => Product.fromMap(data)).toList();
      debugPrint('Fetched ${productsData.length} products');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      _products = [];
      _errorMessage = 'فشل في جلب المنتجات: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      if (_products.any(
        (p) => p.name.toLowerCase() == product.name.toLowerCase(),
      )) {
        throw Exception('اسم المنتج موجود بالفعل');
      }
      if (product.name.isEmpty) throw Exception('اسم المنتج مطلوب');
      if (product.supplierName.isEmpty) throw Exception('اسم المورد مطلوب');
      if (product.quantity < 0)
        throw Exception('الكمية يجب أن تكون رقم إيجابي');
      if (product.purchasePrice < 0 ||
          product.retailPrice < 0 ||
          product.wholesalePrice < 0 ||
          product.bulkWholesalePrice < 0) {
        throw Exception('الأسعار يجب أن تكون أرقام إيجابية');
      }

      final dbHelper = DatabaseHelper.instance;
      final productMap = product.toMap();
      productMap['dateAdded'] = DateTime.now().toIso8601String();
      debugPrint('Inserting product: $productMap');
      final id = await dbHelper.insertProduct(productMap);
      if (id == -1) throw Exception('فشل في إدراج المنتج في قاعدة البيانات');
      final newProduct = product.copyWith(id: id);
      _products.add(newProduct);

      final inventoryTx = InventoryTransaction(
        productId: id,
        productName: product.name,
        transactionType: 'إضافة',
        quantityChange: product.quantity,
        quantityAfter: product.quantity,
        notes: 'إضافة منتج جديد',
        dateTime: DateTime.now(),
      );
      final txId = await dbHelper.insertInventoryTransaction(
        inventoryTx.toMap(),
      );
      if (txId == -1) throw Exception('فشل في إدراج معاملة المخزون');
      _inventoryTransactions.add(inventoryTx.copyWith(id: txId));

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding product: $e');
      _errorMessage = 'فشل في إضافة المنتج: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final oldProduct = _products.firstWhere(
        (p) => p.id == product.id,
        orElse: () => throw Exception('المنتج غير موجود في القائمة'),
      );
      final result = await dbHelper.updateProduct(product.id!, product.toMap());
      if (result == 0)
        throw Exception(
          'فشل في تحديث المنتج: لم يتم العثور على المنتج أو البيانات غير صالحة',
        );
      if (oldProduct.quantity != product.quantity) {
        final quantityChange = product.quantity - oldProduct.quantity;
        final transactionType = quantityChange > 0 ? 'زيادة' : 'نقصان';
        final inventoryTx = InventoryTransaction(
          productId: product.id!,
          productName: product.name,
          transactionType: transactionType,
          quantityChange: quantityChange,
          quantityAfter: product.quantity,
          notes: 'تعديل كمية المنتج',
          dateTime: DateTime.now(),
        );
        final txId = await dbHelper.insertInventoryTransaction(
          inventoryTx.toMap(),
        );
        if (txId == -1) throw Exception('فشل في إدراج معاملة المخزون');
        _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      }
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      _errorMessage = 'فشل في تحديث المنتج: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final result = await dbHelper.deleteProduct(id);
      if (result == 0)
        throw Exception('فشل في حذف المنتج: لم يتم العثور على المنتج');
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      _errorMessage = 'فشل في حذف المنتج: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sellProduct(
    Product product,
    int quantitySold,
    String customerName,
    String? notes,
  ) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      // Verify product exists in database
      final productData = await dbHelper.getProducts();
      final exists = productData.any((p) => p['id'] == product.id);
      if (!exists) {
        throw Exception(
          'المنتج غير موجود في قاعدة البيانات (ID: ${product.id})',
        );
      }
      if (quantitySold > product.quantity) {
        throw Exception('الكمية المطلوبة أكثر من المتاح (${product.quantity})');
      }
      if (quantitySold <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من 0');
      }
      if (customerName.isEmpty) {
        throw Exception('اسم العميل مطلوب');
      }

      // Begin transaction
      final db = await dbHelper.database; // Await to get Database object
      await db.transaction((txn) async {
        final priceType = product.getPriceType(quantitySold);
        final unitPrice = product.getPrice(quantitySold);
        final newQuantity = product.quantity - quantitySold;
        final sale = SaleTransaction(
          productId: product.id!,
          productName: product.name,
          priceType: priceType,
          unitPrice: unitPrice,
          purchasePrice: product.purchasePrice,
          quantitySold: quantitySold,
          quantityRemainingInStock: newQuantity,
          customerName: customerName,
          supplierName: product.supplierName,
          saleDateTime: DateTime.now(),
          notes: notes,
        );
        debugPrint('Inserting sale: ${sale.toMap()}');
        final saleId = await txn.insert('sales', sale.toMap());
        if (saleId == 0)
          throw Exception('فشل في إدراج البيع في قاعدة البيانات');

        _sales.add(sale.copyWith(id: saleId));

        debugPrint(
          'Updating product ID ${product.id} with new quantity: $newQuantity',
        );
        final updateResult = await dbHelper.updateProductQuantity(
          product.id!,
          newQuantity,
        );
        if (updateResult == 0) {
          throw Exception(
            'فشل في تحديث كمية المنتج: لم يتم العثور على المنتج (ID: ${product.id})',
          );
        }
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product.copyWith(quantity: newQuantity);
        } else {
          debugPrint(
            'Warning: Product ID ${product.id} not found in in-memory list',
          );
          await fetchProducts(); // Refresh products list
        }

        final inventoryTx = InventoryTransaction(
          productId: product.id!,
          productName: product.name,
          transactionType: 'بيع',
          quantityChange: -quantitySold,
          quantityAfter: newQuantity,
          relatedSaleId: saleId.toString(),
          notes: 'بيع لـ $customerName',
          dateTime: DateTime.now(),
        );
        debugPrint('Inserting inventory transaction: ${inventoryTx.toMap()}');
        final txId = await txn.insert(
          'inventory_transactions',
          inventoryTx.toMap(),
        );
        if (txId == 0) throw Exception('فشل في إدراج معاملة المخزون');
        _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error selling product: $e');
      _errorMessage = 'فشل في تسجيل البيع: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> returnProduct(
    Product product,
    int quantityReturned,
    String reason,
  ) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final productData = await dbHelper.getProducts();
      final exists = productData.any((p) => p['id'] == product.id);
      if (!exists) {
        throw Exception(
          'المنتج غير موجود في قاعدة البيانات (ID: ${product.id})',
        );
      }
      if (quantityReturned <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من 0');
      }

      final newQuantity = product.quantity + quantityReturned;
      debugPrint(
        'Updating product ID ${product.id} with new quantity: $newQuantity',
      );
      final updateResult = await dbHelper.updateProductQuantity(
        product.id!,
        newQuantity,
      );
      if (updateResult == 0) {
        throw Exception(
          'فشل في تحديث كمية المنتج: لم يتم العثور على المنتج (ID: ${product.id})',
        );
      }
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product.copyWith(quantity: newQuantity);
      } else {
        await fetchProducts(); // Refresh products list
      }

      final inventoryTx = InventoryTransaction(
        productId: product.id!,
        productName: product.name,
        transactionType: 'استرجاع',
        quantityChange: quantityReturned,
        quantityAfter: newQuantity,
        notes: reason,
        dateTime: DateTime.now(),
      );
      final txId = await dbHelper.insertInventoryTransaction(
        inventoryTx.toMap(),
      );
      if (txId == -1) throw Exception('فشل في إدراج معاملة المخزون');
      _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      notifyListeners();
    } catch (e) {
      debugPrint('Error returning product: $e');
      _errorMessage = 'فشل في تسجيل الاسترجاع: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchSales() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final salesData = await dbHelper.getSales();
      _sales = salesData.map((data) => SaleTransaction.fromMap(data)).toList();
      debugPrint('Fetched ${_sales.length} sales');
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching sales: $e');
      _sales = [];
      _errorMessage = 'فشل في جلب المبيعات: $e';
      notifyListeners();
    }
  }

  Future<void> fetchInventoryTransactions() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final txData = await dbHelper.getAllInventoryTransactions();
      _inventoryTransactions = txData
          .map((data) => InventoryTransaction.fromMap(data))
          .toList();
      debugPrint(
        'Fetched ${_inventoryTransactions.length} inventory transactions',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching inventory transactions: $e');
      _inventoryTransactions = [];
      _errorMessage = 'فشل في جلب معاملات المخزون: $e';
      notifyListeners();
    }
  }

  List<SaleTransaction> getRecentSales({int limit = 5}) {
    final sorted = List<SaleTransaction>.from(_sales)
      ..sort((a, b) => b.saleDateTime.compareTo(a.saleDateTime));
    return sorted.take(limit).toList();
  }

  double calculateTotalProfit() {
    final totalProfit = _sales.fold<double>(
      0,
      (sum, sale) =>
          sum + (sale.unitPrice - sale.purchasePrice) * sale.quantitySold,
    );
    debugPrint('Calculated total profit: $totalProfit');
    return totalProfit;
  }

  Future<void> refreshProducts() async {
    await fetchProducts();
  }
}

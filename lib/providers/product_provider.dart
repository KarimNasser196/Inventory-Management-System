// lib/providers/product_provider.dart (COMPLETE - مع جميع الدوال المطلوبة)

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
  bool _isInitialized = false;

  List<Product> get products => _searchQuery.isEmpty
      ? _products
      : _products.where((product) {
          final query = _searchQuery.toLowerCase();
          return product.name.toLowerCase().contains(query) ||
              (product.specifications?.toLowerCase().contains(query) ??
                  false) ||
              product.supplierName.toLowerCase().contains(query);
        }).toList();

  List<SaleTransaction> get sales => _sales;
  List<InventoryTransaction> get inventoryTransactions =>
      _inventoryTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  int get totalProducts => _products.length;
  int get totalQuantityInStock =>
      _products.fold<int>(0, (sum, p) => sum + p.quantity);
  double get totalInventoryValue => _products.fold<double>(
        0,
        (sum, p) => sum + (p.purchasePrice * p.quantity),
      );

  ProductProvider() {
    _initializeData();
  }

  /// FIX: Defer all initialization to avoid build phase issues
  void _initializeData() {
    Future.delayed(Duration.zero, () async {
      try {
        _isLoading = true;
        notifyListeners();

        await fetchProducts();
        await fetchSales();
        await fetchInventoryTransactions();

        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error initializing data: $e');
        _isLoading = false;
        _isInitialized = false;
        notifyListeners();
      }
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final productsData = await dbHelper.getProducts();
      _products = productsData.map((data) => Product.fromMap(data)).toList();
      debugPrint('Fetched ${productsData.length} products');
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      _products = [];
      _errorMessage = 'فشل في جلب المنتجات: $e';
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
      if (product.quantity < 0) {
        throw Exception('الكمية يجب أن تكون رقم إيجابي');
      }
      if (product.purchasePrice <= 0 ||
          product.retailPrice <= 0 ||
          product.wholesalePrice <= 0 ||
          product.bulkWholesalePrice <= 0) {
        throw Exception('الأسعار يجب أن تكون أرقام موجبة');
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
      _errorMessage = null;
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
      if (result == 0) {
        throw Exception(
          'فشل في تحديث المنتج: لم يتم العثور على المنتج أو البيانات غير صالحة',
        );
      }

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
      }

      _errorMessage = null;
      notifyListeners();
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
      if (result == 0) {
        throw Exception('فشل في حذف المنتج: لم يتم العثور على المنتج');
      }

      _products.removeWhere((p) => p.id == id);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      _errorMessage = 'فشل في حذف المنتج: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sellProductWithCustomPrice(
    Product product,
    int quantitySold,
    String customerName,
    double customPrice,
    String? notes,
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
      if (quantitySold > product.quantity) {
        throw Exception('الكمية المطلوبة أكثر من المتاح (${product.quantity})');
      }
      if (quantitySold <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من 0');
      }
      if (customerName.isEmpty) {
        throw Exception('اسم العميل مطلوب');
      }
      if (customPrice <= 0) {
        throw Exception('السعر يجب أن يكون أكبر من 0');
      }

      final db = await dbHelper.database;

      try {
        await db.transaction((txn) async {
          final newQuantity = product.quantity - quantitySold;

          final sale = SaleTransaction(
            productId: product.id!,
            productName: product.name,
            priceType: 'سعر مخصص',
            unitPrice: customPrice,
            purchasePrice: product.purchasePrice,
            quantitySold: quantitySold,
            quantityRemainingInStock: newQuantity,
            customerName: customerName,
            supplierName: product.supplierName,
            saleDateTime: DateTime.now(),
            notes: notes,
          );

          debugPrint('Inserting sale with custom price: ${sale.toMap()}');
          final saleId = await txn.insert('sales', sale.toMap());
          if (saleId == 0) {
            throw Exception('فشل في إدراج البيع في قاعدة البيانات');
          }

          _sales.add(sale.copyWith(id: saleId));

          debugPrint(
            'Updating product ID ${product.id} with new quantity: $newQuantity',
          );
          final updateResult = await txn.rawUpdate(
            'UPDATE products SET quantity = ? WHERE id = ?',
            [newQuantity, product.id!],
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
            await fetchProducts();
          }

          final inventoryTx = InventoryTransaction(
            productId: product.id!,
            productName: product.name,
            transactionType: 'بيع',
            quantityChange: -quantitySold,
            quantityAfter: newQuantity,
            relatedSaleId: saleId.toString(),
            notes: 'بيع لـ $customerName بسعر $customPrice',
            dateTime: DateTime.now(),
          );

          debugPrint('Inserting inventory transaction: ${inventoryTx.toMap()}');
          final txId = await txn.insert(
            'inventory_transactions',
            inventoryTx.toMap(),
          );
          if (txId == 0) {
            throw Exception('فشل في إدراج معاملة المخزون');
          }
          _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
        });
      } catch (e) {
        debugPrint('Transaction error: $e');
        rethrow;
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error selling product with custom price: $e');
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
        await fetchProducts();
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
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error returning product: $e');
      _errorMessage = 'فشل في تسجيل الاسترجاع: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ⭐ دالة استرجاع منتج من عملية بيع (NEW)
  // ═══════════════════════════════════════════════════════════════

  Future<void> returnSale(
    int saleId,
    int quantityReturned,
    String reason,
  ) async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // البحث عن البيع
      final saleIndex = _sales.indexWhere((s) => s.id == saleId);
      if (saleIndex == -1) {
        throw Exception('البيع غير موجود');
      }

      final sale = _sales[saleIndex];
      final product = _products.firstWhere(
        (p) => p.id == sale.productId,
        orElse: () => throw Exception('المنتج غير موجود'),
      );

      if (quantityReturned > sale.quantitySold) {
        throw Exception(
          'كمية الاسترجاع لا يمكن أن تكون أكثر من الكمية المباعة (${sale.quantitySold})',
        );
      }

      if (quantityReturned <= 0) {
        throw Exception('كمية الاسترجاع يجب أن تكون أكبر من 0');
      }

      // تحديث كمية المنتج (إضافة الكمية المسترجعة)
      final newQuantity = product.quantity + quantityReturned;
      final updateResult = await dbHelper.updateProductQuantity(
        sale.productId,
        newQuantity,
      );
      if (updateResult == 0) {
        throw Exception('فشل في تحديث كمية المنتج');
      }

      // تحديث المنتج في الذاكرة
      final productIndex = _products.indexWhere((p) => p.id == sale.productId);
      if (productIndex != -1) {
        _products[productIndex] = product.copyWith(quantity: newQuantity);
      }

      // حذف البيع أو تحديثه حسب الكمية المسترجعة
      if (quantityReturned == sale.quantitySold) {
        // إذا تم استرجاع كل الكمية - حذف البيع تماماً
        await dbHelper.deleteSale(saleId);
        _sales.removeAt(saleIndex);
        debugPrint('تم حذف البيع رقم $saleId نهائياً');
      } else {
        // إذا كان الاسترجاع جزئي - تقليل الكمية المباعة
        final remainingQuantity = sale.quantitySold - quantityReturned;
        final updatedSale = sale.copyWith(
          quantitySold: remainingQuantity,
          quantityRemainingInStock:
              sale.quantityRemainingInStock + quantityReturned,
        );
        await dbHelper.updateSale(saleId, updatedSale.toMap());
        _sales[saleIndex] = updatedSale;
        debugPrint(
          'تم تحديث البيع رقم $saleId - الكمية المتبقية: $remainingQuantity',
        );
      }

      // تسجيل معاملة الاسترجاع في حركة المخزون
      final inventoryTx = InventoryTransaction(
        productId: sale.productId,
        productName: sale.productName,
        transactionType: 'استرجاع من بيع',
        quantityChange: quantityReturned,
        quantityAfter: newQuantity,
        relatedSaleId: saleId.toString(),
        notes: reason,
        dateTime: DateTime.now(),
      );

      final txId = await dbHelper.insertInventoryTransaction(
        inventoryTx.toMap(),
      );
      if (txId == -1) throw Exception('فشل في تسجيل معاملة المخزون');

      _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      _errorMessage = null;
      notifyListeners();

      debugPrint(
        'تم الاسترجاع بنجاح: $quantityReturned من ${sale.productName}',
      );
    } catch (e) {
      debugPrint('Error returning sale: $e');
      _errorMessage = 'فشل في الاسترجاع: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ⭐ دالة حذف عملية بيع وإرجاع الكمية (NEW)
  // ═══════════════════════════════════════════════════════════════

  Future<void> deleteSale(int saleId) async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // الحصول على بيانات البيع
      final sale = _sales.firstWhere(
        (s) => s.id == saleId,
        orElse: () => throw Exception('البيع غير موجود'),
      );

      // الحصول على المنتج وإرجاع الكمية
      final product = _products.firstWhere(
        (p) => p.id == sale.productId,
        orElse: () => throw Exception('المنتج غير موجود'),
      );

      final updatedQuantity = product.quantity + sale.quantitySold;

      // تحديث المنتج في قاعدة البيانات
      final updateResult = await dbHelper.updateProductQuantity(
        product.id!,
        updatedQuantity,
      );
      if (updateResult == 0) {
        throw Exception('فشل في تحديث كمية المنتج');
      }

      // تسجيل عملية الإرجاع في سجل المخزون
      final inventoryTx = InventoryTransaction(
        productId: product.id!,
        productName: product.name,
        transactionType: 'إلغاء بيع',
        quantityChange: sale.quantitySold,
        quantityAfter: updatedQuantity,
        notes: 'إلغاء فاتورة رقم: ${_extractInvoiceNumber(sale.notes)}',
        relatedSaleId: saleId.toString(),
        dateTime: DateTime.now(),
      );

      final txId = await dbHelper.insertInventoryTransaction(
        inventoryTx.toMap(),
      );
      if (txId == -1) throw Exception('فشل في تسجيل معاملة المخزون');

      // حذف البيع من قاعدة البيانات
      await dbHelper.deleteSale(saleId);

      // تحديث القوائم المحلية
      _sales.removeWhere((s) => s.id == saleId);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product.copyWith(quantity: updatedQuantity);
      }

      _inventoryTransactions.add(inventoryTx.copyWith(id: txId));
      _errorMessage = null;
      notifyListeners();

      debugPrint('✅ تم حذف البيع وإرجاع الكمية بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حذف البيع: $e');
      _errorMessage = 'فشل في حذف البيع: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // دالة مساعدة: استخراج رقم الفاتورة
  // ═══════════════════════════════════════════════════════════════

  String _extractInvoiceNumber(String? notes) {
    if (notes == null || notes.isEmpty) return 'غير محدد';
    final match = RegExp(r'فاتورة:\s*(.+?)(?:\||$)').firstMatch(notes);
    return match?.group(1)?.trim() ?? 'غير محدد';
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
      _inventoryTransactions =
          txData.map((data) => InventoryTransaction.fromMap(data)).toList();
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

  // ═══════════════════════════════════════════════════════════════
  // دالة تحديث سجل المخزون (Helper)
  // ═══════════════════════════════════════════════════════════════

  Future<void> refreshInventoryTransactions() async {
    try {
      await fetchInventoryTransactions();
    } catch (e) {
      debugPrint('❌ خطأ في تحديث سجل المخزون: $e');
    }
  }
}

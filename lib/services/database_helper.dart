import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);
    debugPrint('Database path: $path');

    try {
      if (Platform.isWindows) {
        sqfliteFfiInit();
        final databaseFactory = databaseFactoryFfi;
        return await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 5,
            onCreate: _createDB,
            onUpgrade: _upgradeDB,
          ),
        );
      } else {
        throw UnsupportedError('This app is only supported on Windows desktop');
      }
    } catch (e) {
      debugPrint('Error opening database: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    debugPrint('Creating database tables...');

    try {
      await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType,
  model $textNullableType,
  specifications $textNullableType,
  purchasePrice $realType,
  retailPrice $realType,
  wholesalePrice $realType,
  bulkWholesalePrice $realType,
  supplierName $textType,
  quantity $integerType,
  dateAdded $textType,
  notes $textNullableType
)
''');
      await db.execute(
        'CREATE INDEX idx_supplierName ON products(supplierName)',
      );
      debugPrint('Created products table');

      await db.execute('''
CREATE TABLE sales (
  id $idType,
  productId $integerType,
  productName $textType,
  priceType $textType,
  unitPrice $realType,
  purchasePrice $realType,
  quantitySold $integerType,
  quantityRemainingInStock $integerType,
  totalAmount $realType,
  customerName $textType,
  supplierName $textType,
  saleDateTime $textType,
  notes $textNullableType,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db.execute('CREATE INDEX idx_productId_sales ON sales(productId)');
      await db.execute('CREATE INDEX idx_saleDateTime ON sales(saleDateTime)');
      debugPrint('Created sales table');

      await db.execute('''
CREATE TABLE inventory_transactions (
  id $idType,
  productId $integerType,
  productName $textType,
  transactionType $textType,
  quantityChange $integerType,
  quantityAfter $integerType,
  dateTime $textType,
  relatedSaleId $textNullableType,
  notes $textNullableType,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db.execute(
        'CREATE INDEX idx_productId_inventory ON inventory_transactions(productId)',
      );
      await db.execute(
        'CREATE INDEX idx_dateTime_inventory ON inventory_transactions(dateTime)',
      );
      debugPrint('Created inventory_transactions table');
    } catch (e) {
      debugPrint('Error creating tables: $e');
      rethrow;
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'inventory_management.db');
      final backupPath = join(
        documentsDirectory.path,
        'inventory_management_backup_${DateTime.now().toIso8601String()}.db',
      );
      await File(dbPath).copy(backupPath);
      debugPrint('Backed up database to $backupPath');
    } catch (e) {
      debugPrint('Error backing up database: $e');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('''
INSERT INTO products (name, model, specifications, purchasePrice, retailPrice, wholesalePrice, bulkWholesalePrice, supplierName, quantity, dateAdded, notes)
SELECT name, model, specifications, purchasePrice, retailPrice, wholesalePrice, bulkWholesalePrice, supplierName, quantity, dateAdded, notes FROM laptops;
''');
        await db.execute('DROP TABLE IF EXISTS laptops');
        debugPrint('Migrated laptops to products');
      } catch (e) {
        debugPrint('Error migrating laptops: $e');
      }
      try {
        await db.execute(
          'ALTER TABLE sales ADD COLUMN purchasePrice REAL NOT NULL DEFAULT 0',
        );
        debugPrint('Added purchasePrice to sales');
      } catch (e) {
        debugPrint('Error adding purchasePrice to sales: $e');
      }
      try {
        await db.execute('''
INSERT INTO inventory_transactions (productId, productName, transactionType, quantityChange, quantityAfter, dateTime, notes)
SELECT productId, productName, 'استرجاع', quantityReturned, quantityAfter, returnDate, reason FROM returns;
''');
        await db.execute('DROP TABLE IF EXISTS returns');
        debugPrint('Migrated returns to inventory_transactions');
      } catch (e) {
        debugPrint('Error migrating returns: $e');
      }
      try {
        await db.execute(
          'CREATE INDEX idx_productId_sales ON sales(productId)',
        );
        await db.execute(
          'CREATE INDEX idx_saleDateTime ON sales(saleDateTime)',
        );
        await db.execute(
          'CREATE INDEX idx_productId_inventory ON inventory_transactions(productId)',
        );
        await db.execute(
          'CREATE INDEX idx_dateTime_inventory ON inventory_transactions(dateTime)',
        );
        await db.execute(
          'CREATE INDEX idx_supplierName ON products(supplierName)',
        );
        debugPrint('Created indexes');
      } catch (e) {
        debugPrint('Error adding indexes: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE products RENAME TO products_old');
        await db.execute('''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  model TEXT,
  specifications TEXT,
  purchasePrice REAL NOT NULL,
  retailPrice REAL NOT NULL,
  wholesalePrice REAL NOT NULL,
  bulkWholesalePrice REAL NOT NULL,
  supplierName TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  dateAdded TEXT NOT NULL,
  notes TEXT
)
''');
        await db.execute('''
INSERT INTO products (id, name, model, specifications, purchasePrice, retailPrice, wholesalePrice, bulkWholesalePrice, supplierName, quantity, dateAdded, notes)
SELECT id, name, model, specifications, purchasePrice, retailPrice, wholesalePrice, bulkWholesalePrice, supplierName, quantity, dateAdded, notes
FROM products_old
''');
        await db.execute('DROP TABLE products_old');
        await db.execute(
          'CREATE INDEX idx_supplierName ON products(supplierName)',
        );
        debugPrint('Migrated products table to make model nullable');
      } catch (e) {
        debugPrint('Error migrating products table: $e');
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE sales ADD COLUMN totalAmount REAL NOT NULL DEFAULT 0',
        );
        debugPrint('Added totalAmount to sales');
      } catch (e) {
        debugPrint('Error adding totalAmount to sales: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    try {
      final products = await db.query('products');
      debugPrint('Fetched ${products.length} products: $products');
      return products;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    try {
      final id = await db.insert(
        'products',
        product,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Inserted product with id: $id, data: $product');
      return id;
    } catch (e) {
      debugPrint('Error inserting product: $e, data: $product');
      return -1;
    }
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    try {
      final existing = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (existing.isEmpty) {
        debugPrint('Error: Product ID $id not found in database');
        return 0;
      }
      final result = await db.update(
        'products',
        product,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint(
        'Updated product id $id: $result row(s) affected, data: $product',
      );
      return result;
    } catch (e) {
      debugPrint('Error updating product id $id: $e, data: $product');
      return 0;
    }
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    try {
      final result = await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Deleted product id $id: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return 0;
    }
  }

  Future<int> updateProductQuantity(int productId, int newQuantity) async {
    final db = await database;
    try {
      final existing = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (existing.isEmpty) {
        debugPrint('Error: Product ID $productId not found in database');
        return 0;
      }
      final result = await db.update(
        'products',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [productId],
      );
      debugPrint(
        'Updated quantity for product id $productId to $newQuantity: $result row(s) affected',
      );
      return result;
    } catch (e) {
      debugPrint('Error updating quantity for product id $productId: $e');
      return 0;
    }
  }

  Future<int> decrementProductQuantity(int productId, int amount) async {
    final db = await database;
    try {
      final result = await db.query(
        'products',
        columns: ['quantity'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (result.isNotEmpty) {
        int currentQuantity = result.first['quantity'] as int;
        int newQuantity = currentQuantity - amount;
        if (newQuantity < 0) newQuantity = 0;
        final updateResult = await updateProductQuantity(
          productId,
          newQuantity,
        );
        debugPrint(
          'Decremented quantity for product id $productId by $amount, new quantity: $newQuantity',
        );
        return updateResult;
      }
      debugPrint('No product found with id $productId');
      return 0;
    } catch (e) {
      debugPrint('Error decrementing quantity for product id $productId: $e');
      return 0;
    }
  }

  Future<int> incrementProductQuantity(int productId, int amount) async {
    final db = await database;
    try {
      final result = await db.query(
        'products',
        columns: ['quantity'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (result.isNotEmpty) {
        int currentQuantity = result.first['quantity'] as int;
        int newQuantity = currentQuantity + amount;
        final updateResult = await updateProductQuantity(
          productId,
          newQuantity,
        );
        debugPrint(
          'Incremented quantity for product id $productId by $amount, new quantity: $newQuantity',
        );
        return updateResult;
      }
      debugPrint('No product found with id $productId');
      return 0;
    } catch (e) {
      debugPrint('Error incrementing quantity for product id $productId: $e');
      return 0;
    }
  }

  Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    try {
      final id = await db.insert(
        'sales',
        sale,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Inserted sale with id: $id, data: $sale');
      return id;
    } catch (e) {
      debugPrint('Error inserting sale: $e, data: $sale');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final db = await database;
    try {
      final sales = await db.query('sales', orderBy: 'saleDateTime DESC');
      debugPrint('Fetched ${sales.length} sales');
      return sales;
    } catch (e) {
      debugPrint('Error fetching sales: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSalesByProduct(int productId) async {
    final db = await database;
    try {
      final sales = await db.query(
        'sales',
        where: 'productId = ?',
        whereArgs: [productId],
        orderBy: 'saleDateTime DESC',
      );
      debugPrint('Fetched ${sales.length} sales for product id $productId');
      return sales;
    } catch (e) {
      debugPrint('Error fetching sales for product $productId: $e');
      return [];
    }
  }

  Future<int> insertInventoryTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final db = await database;
    try {
      final id = await db.insert(
        'inventory_transactions',
        transaction,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint(
        'Inserted inventory transaction with id: $id, data: $transaction',
      );
      return id;
    } catch (e) {
      debugPrint(
        'Error inserting inventory transaction: $e, data: $transaction',
      );
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getInventoryTransactions(
    int productId,
  ) async {
    final db = await database;
    try {
      final transactions = await db.query(
        'inventory_transactions',
        where: 'productId = ?',
        whereArgs: [productId],
        orderBy: 'dateTime DESC',
      );
      debugPrint(
        'Fetched ${transactions.length} inventory transactions for product id $productId',
      );
      return transactions;
    } catch (e) {
      debugPrint(
        'Error fetching inventory transactions for product $productId: $e',
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllInventoryTransactions() async {
    final db = await database;
    try {
      final transactions = await db.query(
        'inventory_transactions',
        orderBy: 'dateTime DESC',
      );
      debugPrint('Fetched ${transactions.length} inventory transactions');
      return transactions;
    } catch (e) {
      debugPrint('Error fetching all inventory transactions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await database;
    try {
      final products = await db.query('products');
      final sales = await db.query('sales');
      int totalProducts = products.length;
      int totalQuantityInStock = products.fold<int>(
        0,
        (sum, product) => sum + (product['quantity'] as int? ?? 0),
      );
      double totalSalesAmount = sales.fold<double>(
        0,
        (sum, sale) => sum + (sale['totalAmount'] as num? ?? 0).toDouble(),
      );
      debugPrint(
        'Inventory summary: $totalProducts products, $totalQuantityInStock in stock, $totalSalesAmount sales amount',
      );
      return {
        'totalProducts': totalProducts,
        'totalQuantityInStock': totalQuantityInStock,
        'totalSalesAmount': totalSalesAmount,
        'totalSalesCount': sales.length,
      };
    } catch (e) {
      debugPrint('Error getting inventory summary: $e');
      return {
        'totalProducts': 0,
        'totalQuantityInStock': 0,
        'totalSalesAmount': 0.0,
        'totalSalesCount': 0,
      };
    }
  }

  Future<double> calculateTotalProfit() async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
SELECT SUM((s.unitPrice - s.purchasePrice) * s.quantitySold) as totalProfit
FROM sales s
''');
      final totalProfit =
          (result.first['totalProfit'] as num?)?.toDouble() ?? 0;
      debugPrint('Calculated total profit: $totalProfit');
      return totalProfit;
    } catch (e) {
      debugPrint('Error calculating total profit: $e');
      return 0.0;
    }
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('Database closed');
  }

  Future<int> updateSale(int saleId, Map<String, dynamic> saleData) async {
    final db = await database;
    try {
      final result = await db.update(
        'sales',
        saleData,
        where: 'id = ?',
        whereArgs: [saleId],
      );
      debugPrint('Updated sale id $saleId: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error updating sale: $e');
      return 0;
    }
  }

  Future<int> deleteSale(int saleId) async {
    final db = await database;
    try {
      final result = await db.delete(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );
      debugPrint('Deleted sale id $saleId: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error deleting sale: $e');
      return 0;
    }
  }
}

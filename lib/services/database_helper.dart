// lib/services/database_helper.dart (UPDATED WITH REPRESENTATIVES & CUSTOMERS)

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
            version: 10, // ⭐ تحديث النسخة
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
      // جدول المنتجات
      await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType,
  category $textNullableType,
  warehouse $textNullableType,
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
      await db.execute('CREATE INDEX idx_supplierName ON products(supplierName)');
      debugPrint('Created products table');

      // جدول المبيعات
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
  representativeId $textNullableType,
  paymentType $textNullableType,
  paidAmount $realType,
  remainingAmount $realType,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db.execute('CREATE INDEX idx_productId_sales ON sales(productId)');
      await db.execute('CREATE INDEX idx_saleDateTime ON sales(saleDateTime)');
      await db.execute('CREATE INDEX idx_representativeId ON sales(representativeId)');
      debugPrint('Created sales table');

      // جدول حركة المخزون
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
      await db.execute('CREATE INDEX idx_productId_inventory ON inventory_transactions(productId)');
      await db.execute('CREATE INDEX idx_dateTime_inventory ON inventory_transactions(dateTime)');
      await db.execute('CREATE INDEX idx_relatedSaleId ON inventory_transactions(relatedSaleId)');
      debugPrint('Created inventory_transactions table');

      // جدول الصيانة
      await db.execute('''
CREATE TABLE maintenance_records (
  id $idType,
  deviceType $textType,
  customerName $textType,
  problemDescription $textType,
  status $textType,
  cost $realType,
  paidAmount $realType,
  receivedDate $textType,
  deliveryDate $textNullableType,
  repairCode $textType
)
''');
      await db.execute('CREATE INDEX idx_customerName ON maintenance_records(customerName)');
      await db.execute('CREATE INDEX idx_status ON maintenance_records(status)');
      await db.execute('CREATE INDEX idx_receivedDate ON maintenance_records(receivedDate)');
      await db.execute('CREATE INDEX idx_repairCode ON maintenance_records(repairCode)');
      debugPrint('Created maintenance_records table');

      // جدول الأصناف
      await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  created_at $textType
)
''');
      debugPrint('Created categories table');

      // جدول الموردين
      await db.execute('''
CREATE TABLE suppliers (
  id $idType,
  name $textType,
  phone $textNullableType,
  created_at $textType
)
''');
      debugPrint('Created suppliers table');

      // جدول المخازن
      await db.execute('''
CREATE TABLE warehouses (
  id $idType,
  name $textType,
  location $textNullableType,
  created_at $textType
)
''');
      debugPrint('Created warehouses table');

      // ⭐ جدول المندوبين/العملاء
      await db.execute('''
CREATE TABLE representatives (
  id $idType,
  name $textType,
  phone $textNullableType,
  address $textNullableType,
  type $textType,
  totalDebt $realType,
  totalPaid $realType,
  createdAt $textType,
  notes $textNullableType
)
''');
      await db.execute('CREATE INDEX idx_rep_name ON representatives(name)');
      await db.execute('CREATE INDEX idx_rep_type ON representatives(type)');
      debugPrint('Created representatives table');

      // ⭐ جدول معاملات المندوبين (مبيعات/دفعات/مرتجعات)
      await db.execute('''
CREATE TABLE representative_transactions (
  id $idType,
  representativeId $integerType,
  representativeName $textType,
  type $textType,
  amount $realType,
  paidAmount $realType,
  remainingDebt $realType,
  productsSummary $textNullableType,
  dateTime $textType,
  notes $textNullableType,
  invoiceNumber $textNullableType,
  saleIds $textNullableType,
  FOREIGN KEY (representativeId) REFERENCES representatives (id) ON DELETE CASCADE
)
''');
      await db.execute('CREATE INDEX idx_rep_trans_rep_id ON representative_transactions(representativeId)');
      await db.execute('CREATE INDEX idx_rep_trans_date ON representative_transactions(dateTime)');
      await db.execute('CREATE INDEX idx_rep_trans_type ON representative_transactions(type)');
      debugPrint('Created representative_transactions table');

      // ⭐ جدول تفاصيل المرتجعات
      await db.execute('''
CREATE TABLE return_details (
  id $idType,
  saleId $integerType,
  productId $integerType,
  productName $textType,
  quantityReturned $integerType,
  unitPrice $realType,
  totalAmount $realType,
  returnDateTime $textType,
  reason $textNullableType,
  representativeId $textNullableType,
  FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db.execute('CREATE INDEX idx_return_sale_id ON return_details(saleId)');
      await db.execute('CREATE INDEX idx_return_rep_id ON return_details(representativeId)');
      debugPrint('Created return_details table');

    } catch (e) {
      debugPrint('Error creating tables: $e');
      rethrow;
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');

    // إنشاء نسخة احتياطية
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'inventory_management.db');
      final backupPath = join(
        documentsDirectory.path,
        'inventory_management_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      await File(dbPath).copy(backupPath);
      debugPrint('Backed up database to $backupPath');
    } catch (e) {
      debugPrint('Error backing up database: $e');
    }

    // الترقيات القديمة (1-9) - نفس الكود السابق
    if (oldVersion < 9) {
      // ... (كل الترقيات القديمة)
    }

    // ⭐ النسخة 10: إضافة نظام المندوبين والعملاء
    if (oldVersion < 10) {
      try {
        // إضافة جدول المندوبين/العملاء
        await db.execute('''
CREATE TABLE IF NOT EXISTS representatives (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  type TEXT NOT NULL,
  totalDebt REAL NOT NULL DEFAULT 0,
  totalPaid REAL NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  notes TEXT
)
''');
        await db.execute('CREATE INDEX idx_rep_name ON representatives(name)');
        await db.execute('CREATE INDEX idx_rep_type ON representatives(type)');
        debugPrint('✅ Created representatives table');

        // إضافة جدول معاملات المندوبين
        await db.execute('''
CREATE TABLE IF NOT EXISTS representative_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  representativeId INTEGER NOT NULL,
  representativeName TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  paidAmount REAL NOT NULL DEFAULT 0,
  remainingDebt REAL NOT NULL DEFAULT 0,
  productsSummary TEXT,
  dateTime TEXT NOT NULL,
  notes TEXT,
  invoiceNumber TEXT,
  saleIds TEXT,
  FOREIGN KEY (representativeId) REFERENCES representatives (id) ON DELETE CASCADE
)
''');
        await db.execute('CREATE INDEX idx_rep_trans_rep_id ON representative_transactions(representativeId)');
        await db.execute('CREATE INDEX idx_rep_trans_date ON representative_transactions(dateTime)');
        await db.execute('CREATE INDEX idx_rep_trans_type ON representative_transactions(type)');
        debugPrint('✅ Created representative_transactions table');

        // إضافة جدول تفاصيل المرتجعات
        await db.execute('''
CREATE TABLE IF NOT EXISTS return_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  saleId INTEGER NOT NULL,
  productId INTEGER NOT NULL,
  productName TEXT NOT NULL,
  quantityReturned INTEGER NOT NULL,
  unitPrice REAL NOT NULL,
  totalAmount REAL NOT NULL,
  returnDateTime TEXT NOT NULL,
  reason TEXT,
  representativeId TEXT,
  FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
        await db.execute('CREATE INDEX idx_return_sale_id ON return_details(saleId)');
        await db.execute('CREATE INDEX idx_return_rep_id ON return_details(representativeId)');
        debugPrint('✅ Created return_details table');

        // تحديث جدول المبيعات لإضافة الأعمدة الجديدة
        final salesColumns = await db.rawQuery('PRAGMA table_info(sales)');
        final columnNames = salesColumns.map((col) => col['name'] as String).toSet();

        if (!columnNames.contains('representativeId')) {
          await db.execute('ALTER TABLE sales ADD COLUMN representativeId TEXT');
          debugPrint('✅ Added representativeId to sales');
        }

        if (!columnNames.contains('paymentType')) {
          await db.execute('ALTER TABLE sales ADD COLUMN paymentType TEXT DEFAULT "نقد"');
          debugPrint('✅ Added paymentType to sales');
        }

        if (!columnNames.contains('paidAmount')) {
          await db.execute('ALTER TABLE sales ADD COLUMN paidAmount REAL DEFAULT 0');
          debugPrint('✅ Added paidAmount to sales');
        }

        if (!columnNames.contains('remainingAmount')) {
          await db.execute('ALTER TABLE sales ADD COLUMN remainingAmount REAL DEFAULT 0');
          debugPrint('✅ Added remainingAmount to sales');
        }

        debugPrint('✅ Successfully upgraded to version 10 with Representatives & Customers system');
      } catch (e) {
        debugPrint('❌ Error in version 10 upgrade: $e');
      }
    }
  }

  // ========== دوال المندوبين/العملاء ==========

  Future<List<Map<String, dynamic>>> getRepresentatives({String? type}) async {
    final db = await database;
    try {
      if (type != null) {
        return await db.query(
          'representatives',
          where: 'type = ?',
          whereArgs: [type],
          orderBy: 'name ASC',
        );
      }
      return await db.query('representatives', orderBy: 'name ASC');
    } catch (e) {
      debugPrint('Error fetching representatives: $e');
      return [];
    }
  }

  Future<int> insertRepresentative(Map<String, dynamic> representative) async {
    final db = await database;
    try {
      final id = await db.insert('representatives', representative);
      debugPrint('Inserted representative with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting representative: $e');
      return -1;
    }
  }

  Future<int> updateRepresentative(int id, Map<String, dynamic> representative) async {
    final db = await database;
    try {
      return await db.update(
        'representatives',
        representative,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updating representative: $e');
      return 0;
    }
  }

  Future<int> deleteRepresentative(int id) async {
    final db = await database;
    try {
      return await db.delete('representatives', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error deleting representative: $e');
      return 0;
    }
  }

  // ========== دوال معاملات المندوبين ==========

  Future<int> insertRepresentativeTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    try {
      final id = await db.insert('representative_transactions', transaction);
      debugPrint('Inserted representative transaction with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting representative transaction: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getRepresentativeTransactions(int representativeId) async {
    final db = await database;
    try {
      return await db.query(
        'representative_transactions',
        where: 'representativeId = ?',
        whereArgs: [representativeId],
        orderBy: 'dateTime DESC',
      );
    } catch (e) {
      debugPrint('Error fetching representative transactions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllRepresentativeTransactions() async {
    final db = await database;
    try {
      return await db.query('representative_transactions', orderBy: 'dateTime DESC');
    } catch (e) {
      debugPrint('Error fetching all representative transactions: $e');
      return [];
    }
  }

  // ========== دوال المرتجعات ==========

  Future<int> insertReturnDetail(Map<String, dynamic> returnDetail) async {
    final db = await database;
    try {
      final id = await db.insert('return_details', returnDetail);
      debugPrint('Inserted return detail with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting return detail: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getReturnsBySaleId(int saleId) async {
    final db = await database;
    try {
      return await db.query(
        'return_details',
        where: 'saleId = ?',
        whereArgs: [saleId],
        orderBy: 'returnDateTime DESC',
      );
    } catch (e) {
      debugPrint('Error fetching returns by sale id: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllReturns() async {
    final db = await database;
    try {
      return await db.query('return_details', orderBy: 'returnDateTime DESC');
    } catch (e) {
      debugPrint('Error fetching all returns: $e');
      return [];
    }
  }

  // ========== دوال المنتجات ==========

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    try {
      final products = await db.query('products');
      debugPrint('Fetched ${products.length} products');
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
      debugPrint('Inserted product with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting product: $e');
      return -1;
    }
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    try {
      final result = await db.update(
        'products',
        product,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Updated product id $id: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error updating product: $e');
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
      debugPrint('Deleted product id $id');
      return result;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return 0;
    }
  }

  Future<int> updateProductQuantity(int productId, int newQuantity) async {
    final db = await database;
    try {
      final result = await db.update(
        'products',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [productId],
      );
      debugPrint('Updated quantity for product id $productId to $newQuantity');
      return result;
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      return 0;
    }
  }

  // ========== دوال المبيعات ==========

  Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    try {
      final id = await db.insert(
        'sales',
        sale,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Inserted sale with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting sale: $e');
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

  Future<int> updateSale(int saleId, Map<String, dynamic> saleData) async {
    final db = await database;
    try {
      final result = await db.update(
        'sales',
        saleData,
        where: 'id = ?',
        whereArgs: [saleId],
      );
      debugPrint('Updated sale id $saleId');
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
      debugPrint('Deleted sale id $saleId');
      return result;
    } catch (e) {
      debugPrint('Error deleting sale: $e');
      return 0;
    }
  }

  // ========== دوال حركة المخزون ==========

  Future<int> insertInventoryTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    try {
      final id = await db.insert(
        'inventory_transactions',
        transaction,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Inserted inventory transaction with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting inventory transaction: $e');
      return -1;
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
      debugPrint('Error fetching inventory transactions: $e');
      return [];
    }
  }

  // ========== دوال الصيانة ==========

  Future<List<Map<String, dynamic>>> getMaintenanceRecords() async {
    final db = await database;
    try {
      final records = await db.query(
        'maintenance_records',
        orderBy: 'receivedDate DESC',
      );
      debugPrint('Fetched ${records.length} maintenance records');
      return records;
    } catch (e) {
      debugPrint('Error fetching maintenance records: $e');
      return [];
    }
  }

  Future<int> insertMaintenanceRecord(Map<String, dynamic> record) async {
    final db = await database;
    try {
      final id = await db.insert(
        'maintenance_records',
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Inserted maintenance record with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting maintenance record: $e');
      return -1;
    }
  }

  Future<int> updateMaintenanceRecord(int id, Map<String, dynamic> record) async {
    final db = await database;
    try {
      final result = await db.update(
        'maintenance_records',
        record,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Updated maintenance record id $id: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error updating maintenance record: $e');
      return 0;
    }
  }

  Future<int> deleteMaintenanceRecord(int id) async {
    final db = await database;
    try {
      final result = await db.delete(
        'maintenance_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Deleted maintenance record id $id: $result row(s) affected');
      return result;
    } catch (e) {
      debugPrint('Error deleting maintenance record: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getMaintenanceRecordsByStatus(String status) async {
    final db = await database;
    try {
      final records = await db.query(
        'maintenance_records',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'receivedDate DESC',
      );
      return records;
    } catch (e) {
      debugPrint('Error fetching maintenance records by status: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMaintenanceRecordByCode(String repairCode) async {
    final db = await database;
    try {
      final records = await db.query(
        'maintenance_records',
        where: 'repairCode = ?',
        whereArgs: [repairCode],
        limit: 1,
      );
      if (records.isNotEmpty) {
        return records.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching maintenance record by code: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getMaintenanceStatistics() async {
    final db = await database;
    try {
      final records = await db.query('maintenance_records');

      int total = records.length;
      int pending = records.where((r) => r['status'] == 'قيد الإصلاح').length;
      int ready = records.where((r) => r['status'] == 'جاهز للاستلام').length;
      int completed = records.where((r) => r['status'] == 'تم التسليم').length;

      double totalRevenue = records
          .where((r) => r['status'] == 'تم التسليم')
          .fold<double>(0, (sum, r) => sum + (r['cost'] as num).toDouble());

      double totalPaid = records.fold<double>(
        0,
        (sum, r) => sum + (r['paidAmount'] as num).toDouble(),
      );

      return {
        'total': total,
        'pending': pending,
        'ready': ready,
        'completed': completed,
        'totalRevenue': totalRevenue,
        'totalPaid': totalPaid,
      };
    } catch (e) {
      debugPrint('Error getting maintenance statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'ready': 0,
        'completed': 0,
        'totalRevenue': 0.0,
        'totalPaid': 0.0,
      };
    }
  }

  // ========== دوال عامة ==========

  Future<void> deleteAllData() async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.delete('sales');
        await txn.delete('inventory_transactions');
        await txn.delete('products');
        await txn.delete('maintenance_records');
        await txn.delete('representatives');
        await txn.delete('representative_transactions');
        await txn.delete('return_details');
        debugPrint('Deleted all data from database');
      });
    } catch (e) {
      debugPrint('Error deleting all data: $e');
      rethrow;
    }
  }

  Future<void> resetDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'inventory_management.db');

      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
        debugPrint('Database file deleted: $path');
      }

      _database = await _initDB('inventory_management.db');
      debugPrint('Database reset successfully');
    } catch (e) {
      debugPrint('Error resetting database: $e');
      rethrow;
    }
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('Database closed');
  }
}

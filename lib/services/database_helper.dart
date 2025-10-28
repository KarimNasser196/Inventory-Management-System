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
            version: 9, // تحديث إلى النسخة 9
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
      await db.execute(
        'CREATE INDEX idx_supplierName ON products(supplierName)',
      );
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
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
)
''');
      await db.execute('CREATE INDEX idx_productId_sales ON sales(productId)');
      await db.execute('CREATE INDEX idx_saleDateTime ON sales(saleDateTime)');
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
      await db.execute(
        'CREATE INDEX idx_productId_inventory ON inventory_transactions(productId)',
      );
      await db.execute(
        'CREATE INDEX idx_dateTime_inventory ON inventory_transactions(dateTime)',
      );
      debugPrint('Created inventory_transactions table');

      // جدول الصيانة (مبسط)
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
      await db.execute(
        'CREATE INDEX idx_customerName ON maintenance_records(customerName)',
      );
      await db.execute(
        'CREATE INDEX idx_status ON maintenance_records(status)',
      );
      await db.execute(
        'CREATE INDEX idx_receivedDate ON maintenance_records(receivedDate)',
      );
      await db.execute(
        'CREATE INDEX idx_repairCode ON maintenance_records(repairCode)',
      );
      debugPrint('Created simplified maintenance_records table');

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

    // الترقيات القديمة
    if (oldVersion < 3) {
      try {
        await db.execute('''
INSERT INTO products (name, specifications, purchasePrice, retailPrice, wholesalePrice, bulkWholesalePrice, supplierName, quantity, dateAdded, notes)
SELECT name, specifications, purchasePrice, retailPrice, wholesalePrice, bulkWholesalePrice, supplierName, quantity, dateAdded, notes FROM laptops;
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
INSERT INTO products (id, name, specifications, purchasePrice, retailPrice, wholesalePrice, bulkWholesalePrice, supplierName, quantity, dateAdded, notes)
SELECT id, name, specifications, purchasePrice, retailPrice, wholesalePrice, bulkWholesalePrice, supplierName, quantity, dateAdded, notes
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

    // إضافة جدول الصيانة (نسخة معقدة)
    if (oldVersion < 6) {
      try {
        await db.execute('''
CREATE TABLE maintenance_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deviceType TEXT NOT NULL,
  deviceBrand TEXT NOT NULL,
  deviceModel TEXT NOT NULL,
  serialNumber TEXT,
  customerName TEXT NOT NULL,
  customerPhone TEXT NOT NULL,
  problemDescription TEXT NOT NULL,
  status TEXT NOT NULL,
  estimatedCost REAL NOT NULL,
  actualCost REAL NOT NULL,
  paidAmount REAL NOT NULL,
  receivedDate TEXT NOT NULL,
  expectedDeliveryDate TEXT,
  actualDeliveryDate TEXT,
  technicianNotes TEXT,
  usedParts TEXT,
  customerNotes TEXT,
  isWarranty INTEGER NOT NULL,
  warrantyDays INTEGER
)
''');
        await db.execute(
          'CREATE INDEX idx_customerPhone ON maintenance_records(customerPhone)',
        );
        await db.execute(
          'CREATE INDEX idx_status ON maintenance_records(status)',
        );
        await db.execute(
          'CREATE INDEX idx_receivedDate ON maintenance_records(receivedDate)',
        );
        debugPrint('Created maintenance_records table (old version)');
      } catch (e) {
        debugPrint('Error creating maintenance_records table: $e');
      }
    }

    // تبسيط جدول الصيانة
    if (oldVersion < 7) {
      try {
        // التحقق من وجود الجدول القديم
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='maintenance_records'",
        );

        if (tables.isNotEmpty) {
          // إنشاء جدول مؤقت بالهيكل الجديد المبسط
          await db.execute('''
CREATE TABLE maintenance_records_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deviceType TEXT NOT NULL,
  customerName TEXT NOT NULL,
  problemDescription TEXT NOT NULL,
  status TEXT NOT NULL,
  cost REAL NOT NULL,
  paidAmount REAL NOT NULL,
  receivedDate TEXT NOT NULL,
  deliveryDate TEXT,
  repairCode TEXT NOT NULL
)
''');

          // نقل البيانات القديمة إلى الجدول الجديد
          await db.execute('''
INSERT INTO maintenance_records_new 
  (id, deviceType, customerName, problemDescription, status, cost, paidAmount, receivedDate, deliveryDate, repairCode)
SELECT 
  id, 
  deviceType, 
  customerName, 
  problemDescription, 
  CASE 
    WHEN status = 'قيد الفحص' THEN 'قيد الإصلاح'
    ELSE status
  END,
  actualCost, 
  paidAmount, 
  receivedDate,
  actualDeliveryDate,
  printf('%06d', abs(random() % 900000 + 100000))
FROM maintenance_records
''');

          // حذف الجدول القديم
          await db.execute('DROP TABLE maintenance_records');

          // إعادة تسمية الجدول الجديد
          await db.execute(
            'ALTER TABLE maintenance_records_new RENAME TO maintenance_records',
          );

          // إنشاء الفهارس
          await db.execute(
            'CREATE INDEX idx_customerName ON maintenance_records(customerName)',
          );
          await db.execute(
            'CREATE INDEX idx_status ON maintenance_records(status)',
          );
          await db.execute(
            'CREATE INDEX idx_receivedDate ON maintenance_records(receivedDate)',
          );
          await db.execute(
            'CREATE INDEX idx_repairCode ON maintenance_records(repairCode)',
          );

          debugPrint('Successfully simplified maintenance_records table');
        } else {
          // إذا لم يكن الجدول موجوداً، أنشئ الجدول المبسط مباشرة
          await db.execute('''
CREATE TABLE maintenance_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deviceType TEXT NOT NULL,
  customerName TEXT NOT NULL,
  problemDescription TEXT NOT NULL,
  status TEXT NOT NULL,
  cost REAL NOT NULL,
  paidAmount REAL NOT NULL,
  receivedDate TEXT NOT NULL,
  deliveryDate TEXT,
  repairCode TEXT NOT NULL
)
''');
          await db.execute(
            'CREATE INDEX idx_customerName ON maintenance_records(customerName)',
          );
          await db.execute(
            'CREATE INDEX idx_status ON maintenance_records(status)',
          );
          await db.execute(
            'CREATE INDEX idx_receivedDate ON maintenance_records(receivedDate)',
          );
          await db.execute(
            'CREATE INDEX idx_repairCode ON maintenance_records(repairCode)',
          );
          debugPrint('Created new simplified maintenance_records table');
        }
      } catch (e) {
        debugPrint('Error simplifying maintenance_records table: $e');
        // في حالة الفشل، حاول إنشاء جدول جديد
        try {
          await db.execute('DROP TABLE IF EXISTS maintenance_records');
          await db.execute('''
CREATE TABLE maintenance_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deviceType TEXT NOT NULL,
  customerName TEXT NOT NULL,
  problemDescription TEXT NOT NULL,
  status TEXT NOT NULL,
  cost REAL NOT NULL,
  paidAmount REAL NOT NULL,
  receivedDate TEXT NOT NULL,
  deliveryDate TEXT,
  repairCode TEXT NOT NULL
)
''');
          await db.execute(
            'CREATE INDEX idx_customerName ON maintenance_records(customerName)',
          );
          await db.execute(
            'CREATE INDEX idx_status ON maintenance_records(status)',
          );
          await db.execute(
            'CREATE INDEX idx_receivedDate ON maintenance_records(receivedDate)',
          );
          await db.execute(
            'CREATE INDEX idx_repairCode ON maintenance_records(repairCode)',
          );
          debugPrint(
            'Created fresh simplified maintenance_records table after error',
          );
        } catch (e2) {
          debugPrint('Fatal error creating maintenance_records table: $e2');
        }
      }
    }

    // إضافة حقول deliveryDate و repairCode للجداول الموجودة
    if (oldVersion < 8) {
      try {
        // التحقق من وجود الأعمدة
        final tableInfo = await db.rawQuery(
          'PRAGMA table_info(maintenance_records)',
        );
        final columnNames = tableInfo
            .map((col) => col['name'] as String)
            .toList();

        if (!columnNames.contains('deliveryDate')) {
          await db.execute(
            'ALTER TABLE maintenance_records ADD COLUMN deliveryDate TEXT',
          );
          debugPrint('Added deliveryDate column');
        }

        if (!columnNames.contains('repairCode')) {
          await db.execute(
            'ALTER TABLE maintenance_records ADD COLUMN repairCode TEXT NOT NULL DEFAULT "000000"',
          );

          // تحديث السجلات الموجودة بأكواد عشوائية
          await db.execute('''
            UPDATE maintenance_records 
            SET repairCode = printf('%06d', abs(random() % 900000 + 100000))
            WHERE repairCode = "000000"
          ''');

          await db.execute(
            'CREATE INDEX idx_repairCode ON maintenance_records(repairCode)',
          );
          debugPrint('Added repairCode column and generated codes');
        }
      } catch (e) {
        debugPrint('Error adding deliveryDate/repairCode columns: $e');
      }
    }

    // إضافة جداول الأصناف والموردين والمخازن
    if (oldVersion < 9) {
      try {
        // جدول الأصناف
        await db.execute('''
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
        debugPrint('Created categories table');

        // جدول الموردين
        await db.execute('''
CREATE TABLE IF NOT EXISTS suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  created_at TEXT NOT NULL
)
''');
        debugPrint('Created suppliers table');

        // جدول المخازن
        await db.execute('''
CREATE TABLE IF NOT EXISTS warehouses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  location TEXT,
  created_at TEXT NOT NULL
)
''');
        debugPrint('Created warehouses table');
      } catch (e) {
        debugPrint('Error creating categories/suppliers/warehouses tables: $e');
      }
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

  // ========== دوال الصيانة (مبسطة) ==========

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

  Future<int> updateMaintenanceRecord(
    int id,
    Map<String, dynamic> record,
  ) async {
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

  Future<List<Map<String, dynamic>>> getMaintenanceRecordsByStatus(
    String status,
  ) async {
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

  Future<Map<String, dynamic>?> getMaintenanceRecordByCode(
    String repairCode,
  ) async {
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

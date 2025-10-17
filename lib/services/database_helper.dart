import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/laptop.dart';
import '../models/sale.dart';
import '../models/return.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('laptop_inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      documentsDirectory = await getApplicationDocumentsDirectory();
    } else {
      documentsDirectory = await getApplicationDocumentsDirectory();
    }

    final path = join(documentsDirectory.path, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Laptops table
    await db.execute('''
    CREATE TABLE laptops (
      id $idType,
      name $textType,
      serialNumber $textType,
      model $textType,
      price $realType,
      status $textType,
      customer $textNullableType,
      date $textNullableType,
      notes $textNullableType
    )
    ''');

    // Sales table
    await db.execute('''
    CREATE TABLE sales (
      id $idType,
      laptopId $integerType,
      customerName $textType,
      price $realType,
      date $textType,
      notes $textNullableType,
      FOREIGN KEY (laptopId) REFERENCES laptops (id) ON DELETE CASCADE
    )
    ''');

    // Returns table
    await db.execute('''
    CREATE TABLE returns (
      id $idType,
      laptopId $integerType,
      date $textType,
      reason $textType,
      FOREIGN KEY (laptopId) REFERENCES laptops (id) ON DELETE CASCADE
    )
    ''');
  }

  // Laptop CRUD operations
  Future<List<Laptop>> getLaptops() async {
    final db = await instance.database;
    final result = await db.query('laptops');
    return result.map((json) => Laptop.fromMap(json)).toList();
  }

  Future<int> insertLaptop(Laptop laptop) async {
    final db = await instance.database;
    return await db.insert('laptops', laptop.toMap());
  }

  Future<int> updateLaptop(Laptop laptop) async {
    final db = await instance.database;
    return await db.update(
      'laptops',
      laptop.toMap(),
      where: 'id = ?',
      whereArgs: [laptop.id],
    );
  }

  Future<int> deleteLaptop(int id) async {
    final db = await instance.database;
    return await db.delete('laptops', where: 'id = ?', whereArgs: [id]);
  }

  // Sale operations
  Future<List<Sale>> getSales() async {
    final db = await instance.database;
    final result = await db.query('sales');
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  Future<int> insertSale(Sale sale) async {
    final db = await instance.database;
    return await db.insert('sales', sale.toMap());
  }

  // Return operations
  Future<List<Return>> getReturns() async {
    final db = await instance.database;
    final result = await db.query('returns');
    return result.map((json) => Return.fromMap(json)).toList();
  }

  Future<int> insertReturn(Return returnData) async {
    final db = await instance.database;
    return await db.insert('returns', returnData.toMap());
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future clear() async {
    final db = await instance.database;
    await db.delete('laptops');
    await db.delete('sales');
    await db.delete('returns');
  }
}

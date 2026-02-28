import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  final String _productTableName = "Product";
  final String _productIdColumnName = "ProductID";
  final String _productNameColumnName = "ProductName";
  final String _productCategoryColumnName = "Category";
  final String _productTotalUnitColumnName = "TotalUnit";
  final String _productPriceColumnName = "Price";
  final String _productUnitColumnName = "Unit";
  final String _productImagePathColumnName = "ImagePath";
  final String _productWarehouseIdColumnName = "WarehouseId";
  final String _productWarehouseNameColumnName = "WarehouseName";
  final String _productWarehouseLocationColumnName = "WarehouseLocation";

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    try {
      final databaseDirPath = await getDatabasesPath();
      final databasePath = join(databaseDirPath, "master_db.db");
      final database = await openDatabase(
        databasePath,
        version: 1,
        onCreate: (db, version) {
          db.execute('''
          CREATE TABLE $_productTableName(
            $_productIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
            $_productNameColumnName TEXT NOT NULL,
            $_productCategoryColumnName TEXT,
            $_productTotalUnitColumnName INTEGER,
            $_productPriceColumnName REAL,
            $_productUnitColumnName TEXT,
            $_productImagePathColumnName TEXT,
            $_productWarehouseIdColumnName TEXT,
            $_productWarehouseNameColumnName TEXT,
            $_productWarehouseLocationColumnName TEXT
          )
          ''');
        },
      );
      return database;
    } catch (e) {
      debugPrint("Error opening database: $e");
      rethrow;
    }
  }

  Future<int> addProduct({
    required String name,
    required String category,
    required int stock,
    required double price,
    required String unit,
    String? imagePath,
    String? warehouseId,
    String? warehouseName,
    String? warehouseLocation,
  }) async {
    final db = await database;
    return await db.insert(_productTableName, {
      _productNameColumnName: name,
      _productCategoryColumnName: category,
      _productTotalUnitColumnName: stock,
      _productPriceColumnName: price,
      _productUnitColumnName: unit,
      _productImagePathColumnName: imagePath,
      _productWarehouseIdColumnName: warehouseId,
      _productWarehouseNameColumnName: warehouseName,
      _productWarehouseLocationColumnName: warehouseLocation,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query(_productTableName);
  }

  // ฟังก์ชันลบสินค้าออกจากฐานข้อมูล
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      _productTableName,
      where: '$_productIdColumnName = ?',
      whereArgs: [id],
    );
  }

  // ฟังก์ชันอัปเดตข้อมูลสินค้า
  Future<int> updateProduct({
    required int id,
    required String name,
    required String category,
    required int stock,
    required double price,
    required String unit,
    String? imagePath,
    String? warehouseId,
    String? warehouseName,
    String? warehouseLocation,
  }) async {
    final db = await database;
    return await db.update(
      _productTableName,
      {
        _productNameColumnName: name,
        _productCategoryColumnName: category,
        _productTotalUnitColumnName: stock,
        _productPriceColumnName: price,
        _productUnitColumnName: unit,
        _productImagePathColumnName: imagePath,
        _productWarehouseIdColumnName: warehouseId,
        _productWarehouseNameColumnName: warehouseName,
        _productWarehouseLocationColumnName: warehouseLocation,
      },
      where: '$_productIdColumnName = ?',
      whereArgs: [id],
    );
  }

  // ฟังก์ชันสำหรับ Debug: ดึงข้อมูลทั้งหมดมาแสดงใน Console
  Future<void> printAllProducts() async {
    final products = await getProducts();
    print('==================== DATABASE CONTENT ====================');
    if (products.isEmpty) {
      print('ฐานข้อมูลว่างเปล่า (Empty)');
    } else {
      for (var p in products) {
        print('ID: ${p[_productIdColumnName]} | ชื่อ: ${p[_productNameColumnName]} | ราคา: ${p[_productPriceColumnName]} | สต็อก: ${p[_productTotalUnitColumnName]}');
      }
    }
    print('==========================================================');
  }
}

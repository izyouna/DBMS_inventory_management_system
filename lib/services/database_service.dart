import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  // ระบบสำรองสำหรับ Web (Memory Storage)
  final List<Map<String, dynamic>> _webMemoryDb = [];
  int _webIdCounter = 1;

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

  Future<Database?> get database async {
    if (kIsWeb) return null; // บนเว็บเราจะไม่ใช้ Database Object ตรงๆ
    if (_db != null) return _db!;
    try {
      _db = await getDatabase();
      return _db;
    } catch (e) {
      debugPrint("Database initialization failed: $e");
      return null;
    }
  }

  Future<Database> getDatabase() async {
    String databasePath;
    final databaseDirPath = await getDatabasesPath();
    databasePath = join(databaseDirPath, "master_db.db");

    return await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
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
      ),
    );
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
    final data = {
      _productNameColumnName: name,
      _productCategoryColumnName: category,
      _productTotalUnitColumnName: stock,
      _productPriceColumnName: price,
      _productUnitColumnName: unit,
      _productImagePathColumnName: imagePath,
      _productWarehouseIdColumnName: warehouseId,
      _productWarehouseNameColumnName: warehouseName,
      _productWarehouseLocationColumnName: warehouseLocation,
    };

    if (kIsWeb) {
      final webData = Map<String, dynamic>.from(data);
      webData[_productIdColumnName] = _webIdCounter++;
      _webMemoryDb.add(webData);
      return webData[_productIdColumnName];
    }

    final db = await database;
    if (db == null) return -1;
    return await db.insert(_productTableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(_webMemoryDb);
    }

    final db = await database;
    if (db == null) return [];
    return await db.query(_productTableName);
  }

  Future<int> deleteProduct(int id) async {
    if (kIsWeb) {
      _webMemoryDb.removeWhere((p) => p[_productIdColumnName] == id);
      return 1;
    }

    final db = await database;
    if (db == null) return 0;
    return await db.delete(
      _productTableName,
      where: '$_productIdColumnName = ?',
      whereArgs: [id],
    );
  }

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
    final data = {
      _productNameColumnName: name,
      _productCategoryColumnName: category,
      _productTotalUnitColumnName: stock,
      _productPriceColumnName: price,
      _productUnitColumnName: unit,
      _productImagePathColumnName: imagePath,
      _productWarehouseIdColumnName: warehouseId,
      _productWarehouseNameColumnName: warehouseName,
      _productWarehouseLocationColumnName: warehouseLocation,
    };

    if (kIsWeb) {
      final index = _webMemoryDb.indexWhere((p) => p[_productIdColumnName] == id);
      if (index != -1) {
        final updatedData = Map<String, dynamic>.from(data);
        updatedData[_productIdColumnName] = id;
        _webMemoryDb[index] = updatedData;
        return 1;
      }
      return 0;
    }

    final db = await database;
    if (db == null) return 0;
    return await db.update(
      _productTableName,
      data,
      where: '$_productIdColumnName = ?',
      whereArgs: [id],
    );
  }

  Future<void> printAllProducts() async {
    final products = await getProducts();
    print('==================== DATABASE CONTENT (Platform: ${kIsWeb ? 'Web' : 'Native'}) ====================');
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

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  // ระบบสำรองสำหรับ Web (Memory Storage)
  final List<Map<String, dynamic>> _webMemoryDb = [];
  final List<Map<String, dynamic>> _webWarehouseMemoryDb = [
    {'WarehouseID': 'W1', 'WarehouseName': 'หน้าร้าน'},
    {'WarehouseID': 'W2', 'WarehouseName': 'โรงรถ'},
    {'WarehouseID': 'W3', 'WarehouseName': 'คลังสินค้าหลังร้าน'},
  ];
  final List<Map<String, dynamic>> _webPaymentTypeDb = [
    {'PaymentID': 'PAY1', 'TypeName': 'เงินสด'},
    {'PaymentID': 'PAY2', 'TypeName': 'QR Code / โอนเงิน'},
    {'PaymentID': 'PAY3', 'TypeName': 'ขายเชื่อ (ค้างชำระ)'},
  ];
  final List<Map<String, dynamic>> _webSaleOrderDb = [];
  final List<Map<String, dynamic>> _webOrderDetailDb = [];
  int _webIdCounter = 1;

  // Table Names
  final String _productTableName = "Product";
  final String _warehouseTableName = "Warehouse";
  final String _saleOrderTableName = "SaleOrder";
  final String _orderDetailTableName = "OrderDetail";
  final String _paymentTypeTableName = "PaymentType";
  final String _purchaseOrderTableName = "PurchaseOrder";
  final String _purchaseDetailTableName = "PurchaseDetail";
  final String _purchaseTypeTableName = "PurchaseType";
  final String _creditPaymentHistoryTableName = "CreditPaymentHistory";

  // Product Columns
  final String _productIdColumnName = "ProductID";
  final String _productNameColumnName = "ProductName";
  final String _productCategoryColumnName = "Category";
  final String _productTotalUnitColumnName = "TotalUnit";
  final String _productPriceColumnName = "Price";
  final String _productUnitColumnName = "Unit";
  final String _productImagePathColumnName = "ImagePath";
  final String _productWarehouseIdColumnName = "WarehouseID";

  // Warehouse Columns
  final String _warehouseIdColumnName = "WarehouseID";
  final String _warehouseNameColumnName = "WarehouseName";

  // SaleOrder Columns
  final String _orderIdColumnName = "OrderID";
  final String _orderDateColumnName = "OrderDate";
  final String _orderTotalAmountColumnName = "TotalAmount";
  final String _orderPaymentStatusColumnName = "PaymentStatus";
  final String _orderStatusColumnName = "OrderStatus";
  final String _orderPaymentIdColumnName = "PaymentID";

  // OrderDetail / PurchaseDetail Columns
  final String _detailUnitPriceColumnName = "UnitPrice";
  final String _detailQuantityColumnName = "Quantity";

  // PaymentType Columns
  final String _paymentIdColumnName = "PaymentID";
  final String _paymentTypeNameColumnName = "TypeName";

  // PurchaseOrder Columns
  final String _poIdColumnName = "POID";
  final String _poReceiveDateColumnName = "ReceiveDate";
  final String _poTotalCostColumnName = "TotalCost";
  final String _poPaidAmountColumnName = "PaidAmount"; 
  final String _poBillImagePathColumnName = "BillImagePath";
  final String _poStatusColumnName = "Status"; 
  final String _poPaymentStatusColumnName = "PaymentStatus"; 
  final String _poTypeIdColumnName = "PTID";

  // PurchaseType Columns
  final String _ptIdColumnName = "PTID";
  final String _ptNameColumnName = "PTName";

  // CreditPaymentHistory Columns
  final String _cphIdColumnName = "PaymentID";
  final String _cphAmountPaidColumnName = "AmountPaid";
  final String _cphPaidDateColumnName = "PaidDate";
  final String _cphPaidImagePathColumnName = "PaidImagePath";

  DatabaseService._constructor();

  Future<Database?> get database async {
    if (kIsWeb) return null;
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
        version: 14,
        onCreate: (db, version) async {
          await _createTables(db);
          await _seedInitialData(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 14) {
            await db.execute("DROP TABLE IF EXISTS $_creditPaymentHistoryTableName");
            await db.execute("DROP TABLE IF EXISTS $_purchaseDetailTableName");
            await db.execute("DROP TABLE IF EXISTS $_purchaseOrderTableName");
            await db.execute("DROP TABLE IF EXISTS $_purchaseTypeTableName");
            await db.execute("DROP TABLE IF EXISTS $_orderDetailTableName");
            await db.execute("DROP TABLE IF EXISTS $_paymentTypeTableName");
            await db.execute("DROP TABLE IF EXISTS $_saleOrderTableName");
            await db.execute("DROP TABLE IF EXISTS $_productTableName");
            await db.execute("DROP TABLE IF EXISTS $_warehouseTableName");
            await _createTables(db);
            await _seedInitialData(db);
          }
        },
      ),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_warehouseTableName(
        $_warehouseIdColumnName TEXT PRIMARY KEY,
        $_warehouseNameColumnName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_paymentTypeTableName(
        $_paymentIdColumnName TEXT PRIMARY KEY,
        $_paymentTypeNameColumnName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_purchaseTypeTableName(
        $_ptIdColumnName TEXT PRIMARY KEY,
        $_ptNameColumnName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_productTableName(
        $_productIdColumnName TEXT PRIMARY KEY,
        $_productNameColumnName TEXT NOT NULL,
        $_productCategoryColumnName TEXT,
        $_productTotalUnitColumnName INTEGER,
        $_productPriceColumnName REAL,
        $_productUnitColumnName TEXT,
        $_productImagePathColumnName TEXT,
        $_productWarehouseIdColumnName TEXT,
        FOREIGN KEY ($_productWarehouseIdColumnName) REFERENCES $_warehouseTableName($_warehouseIdColumnName)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_saleOrderTableName(
        $_orderIdColumnName TEXT PRIMARY KEY,
        $_orderDateColumnName TEXT NOT NULL,
        $_orderTotalAmountColumnName REAL NOT NULL,
        $_orderPaymentStatusColumnName TEXT NOT NULL,
        $_orderStatusColumnName TEXT NOT NULL,
        $_orderPaymentIdColumnName TEXT,
        FOREIGN KEY ($_orderPaymentIdColumnName) REFERENCES $_paymentTypeTableName($_paymentIdColumnName)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_orderDetailTableName(
        $_orderIdColumnName TEXT,
        $_productIdColumnName TEXT,
        $_detailUnitPriceColumnName REAL NOT NULL,
        $_detailQuantityColumnName INTEGER NOT NULL,
        PRIMARY KEY ($_orderIdColumnName, $_productIdColumnName),
        FOREIGN KEY ($_orderIdColumnName) REFERENCES $_saleOrderTableName($_orderIdColumnName),
        FOREIGN KEY ($_productIdColumnName) REFERENCES $_productTableName($_productIdColumnName)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_purchaseOrderTableName(
        $_poIdColumnName TEXT PRIMARY KEY,
        $_poReceiveDateColumnName TEXT NOT NULL,
        $_poTotalCostColumnName REAL NOT NULL,
        $_poPaidAmountColumnName REAL NOT NULL DEFAULT 0,
        $_poBillImagePathColumnName TEXT,
        $_poStatusColumnName TEXT NOT NULL,
        $_poPaymentStatusColumnName TEXT NOT NULL,
        $_poTypeIdColumnName TEXT,
        FOREIGN KEY ($_poTypeIdColumnName) REFERENCES $_purchaseTypeTableName($_ptIdColumnName)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_purchaseDetailTableName(
        $_poIdColumnName TEXT,
        $_productIdColumnName TEXT,
        $_detailUnitPriceColumnName REAL NOT NULL,
        $_detailQuantityColumnName INTEGER NOT NULL,
        PRIMARY KEY ($_poIdColumnName, $_productIdColumnName),
        FOREIGN KEY ($_poIdColumnName) REFERENCES $_purchaseOrderTableName($_poIdColumnName),
        FOREIGN KEY ($_productIdColumnName) REFERENCES $_productTableName($_productIdColumnName)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_creditPaymentHistoryTableName(
        $_cphIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_poIdColumnName TEXT NOT NULL,
        $_cphAmountPaidColumnName REAL NOT NULL,
        $_cphPaidDateColumnName TEXT NOT NULL,
        $_cphPaidImagePathColumnName TEXT,
        FOREIGN KEY ($_poIdColumnName) REFERENCES $_purchaseOrderTableName($_poIdColumnName)
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    await db.insert(_warehouseTableName, {_warehouseIdColumnName: 'W1', _warehouseNameColumnName: 'หน้าร้าน'});
    await db.insert(_warehouseTableName, {_warehouseIdColumnName: 'W2', _warehouseNameColumnName: 'โรงรถ'});
    await db.insert(_warehouseTableName, {_warehouseIdColumnName: 'W3', _warehouseNameColumnName: 'คลังสินค้าหลังร้าน'});

    await db.insert(_paymentTypeTableName, {_paymentIdColumnName: 'PAY1', _paymentTypeNameColumnName: 'เงินสด'});
    await db.insert(_paymentTypeTableName, {_paymentIdColumnName: 'PAY2', _paymentTypeNameColumnName: 'QR Code / โอนเงิน'});
    await db.insert(_paymentTypeTableName, {_paymentIdColumnName: 'PAY3', _paymentTypeNameColumnName: 'ขายเชื่อ (ค้างชำระ)'});

    await db.insert(_purchaseTypeTableName, {_ptIdColumnName: 'PT1', _ptNameColumnName: 'เงินสด'});
    await db.insert(_purchaseTypeTableName, {_ptIdColumnName: 'PT2', _ptNameColumnName: 'ค้างชำระ (เครดิต)'});
  }

  Future<String> _generateCustomId(String tableName, String idColumn, String prefix) async {
    final db = await database;
    if (db == null) return "${prefix}1";
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return "$prefix${count + 1}";
  }

  // --- Warehouse Methods ---
  Future<String> addWarehouse(String name) async {
    if (kIsWeb) {
      final newId = "W${_webWarehouseMemoryDb.length + 1}";
      _webWarehouseMemoryDb.add({'WarehouseID': newId, 'WarehouseName': name});
      return newId;
    }
    final db = await database;
    if (db == null) return "";
    final newId = await _generateCustomId(_warehouseTableName, _warehouseIdColumnName, "W");
    await db.insert(_warehouseTableName, {_warehouseIdColumnName: newId, _warehouseNameColumnName: name});
    return newId;
  }

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    if (kIsWeb) return List<Map<String, dynamic>>.from(_webWarehouseMemoryDb);
    final db = await database;
    if (db == null) return [];
    return await db.query(_warehouseTableName);
  }

  // --- Product Methods ---
  Future<String> addProduct({
    required String name,
    required String category,
    required int stock,
    required double price,
    required String unit,
    String? imagePath,
    String? warehouseId,
  }) async {
    if (kIsWeb) {
      final newId = "P${_webIdCounter++}";
      _webMemoryDb.add({
        _productIdColumnName: newId,
        _productNameColumnName: name,
        _productCategoryColumnName: category,
        _productTotalUnitColumnName: stock,
        _productPriceColumnName: price,
        _productUnitColumnName: unit,
        _productImagePathColumnName: imagePath,
        _productWarehouseIdColumnName: warehouseId,
      });
      return newId;
    }
    final db = await database;
    if (db == null) return "";
    final newId = await _generateCustomId(_productTableName, _productIdColumnName, "P");
    final data = {
      _productIdColumnName: newId,
      _productNameColumnName: name,
      _productCategoryColumnName: category,
      _productTotalUnitColumnName: stock,
      _productPriceColumnName: price,
      _productUnitColumnName: unit,
      _productImagePathColumnName: imagePath,
      _productWarehouseIdColumnName: warehouseId,
    };
    await db.insert(_productTableName, data);
    return newId;
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    if (kIsWeb) {
      return _webMemoryDb.map((product) {
        final warehouse = _webWarehouseMemoryDb.firstWhere(
          (w) => w['WarehouseID'].toString() == product[_productWarehouseIdColumnName]?.toString(),
          orElse: () => {},
        );
        final result = Map<String, dynamic>.from(product);
        if (warehouse.isNotEmpty) result['WarehouseName'] = warehouse['WarehouseName'];
        return result;
      }).toList();
    }
    final db = await database;
    if (db == null) return [];
    return await db.rawQuery('''
      SELECT p.*, w.$_warehouseNameColumnName
      FROM $_productTableName p
      LEFT JOIN $_warehouseTableName w ON p.$_productWarehouseIdColumnName = w.$_warehouseIdColumnName
    ''');
  }

  Future<int> deleteProduct(String id) async {
    if (kIsWeb) {
      _webMemoryDb.removeWhere((p) => p[_productIdColumnName] == id);
      return 1;
    }
    final db = await database;
    if (db == null) return 0;
    return await db.delete(_productTableName, where: '$_productIdColumnName = ?', whereArgs: [id]);
  }

  Future<int> updateProduct({
    required String id,
    required String name,
    required String category,
    required int stock,
    required double price,
    required String unit,
    String? imagePath,
    String? warehouseId,
  }) async {
    final data = {
      _productNameColumnName: name,
      _productCategoryColumnName: category,
      _productTotalUnitColumnName: stock,
      _productPriceColumnName: price,
      _productUnitColumnName: unit,
      _productImagePathColumnName: imagePath,
      _productWarehouseIdColumnName: warehouseId,
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
    return await db.update(_productTableName, data, where: '$_productIdColumnName = ?', whereArgs: [id]);
  }

  // --- SaleOrder, OrderDetail & Payment Methods ---
  Future<String> saveOrder({
    required String date,
    required double totalAmount,
    required String paymentStatus, 
    required String paymentType, 
    required List<Map<String, dynamic>> items,
  }) async {
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      final pType = _webPaymentTypeDb.firstWhere(
        (p) => p['TypeName'] == paymentType,
        orElse: () => _webPaymentTypeDb[0],
      );
      _webSaleOrderDb.add({
        'OrderID': orderId,
        'OrderDate': date,
        'TotalAmount': totalAmount,
        'PaymentStatus': paymentStatus,
        'OrderStatus': 'Confirmed',
        'PaymentID': pType['PaymentID'],
      });
      for (var item in items) {
        _webOrderDetailDb.add({
          'OrderID': orderId,
          'ProductID': item['ProductID'],
          'UnitPrice': item['UnitPrice'],
          'Quantity': item['Quantity'],
        });
      }
      return orderId;
    }

    final db = await database;
    if (db == null) return "";

    return await db.transaction((txn) async {
      final List<Map<String, dynamic>> pTypes = await txn.query(
        _paymentTypeTableName,
        where: '$_paymentTypeNameColumnName = ?',
        whereArgs: [paymentType],
      );
      String paymentId = pTypes.isNotEmpty ? pTypes.first[_paymentIdColumnName] : "PAY1";

      await txn.insert(_saleOrderTableName, {
        _orderIdColumnName: orderId,
        _orderDateColumnName: date,
        _orderTotalAmountColumnName: totalAmount,
        _orderPaymentStatusColumnName: paymentStatus,
        _orderStatusColumnName: 'Confirmed',
        _orderPaymentIdColumnName: paymentId,
      });

      for (var item in items) {
        await txn.insert(_orderDetailTableName, {
          _orderIdColumnName: orderId,
          _productIdColumnName: item['ProductID'],
          _detailUnitPriceColumnName: item['UnitPrice'],
          _detailQuantityColumnName: item['Quantity'],
        });
        await txn.execute('''
          UPDATE $_productTableName SET $_productTotalUnitColumnName = $_productTotalUnitColumnName - ? WHERE $_productIdColumnName = ?
        ''', [item['Quantity'], item['ProductID']]);
      }
      return orderId;
    });
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    if (kIsWeb) {
      return _webSaleOrderDb.map((order) {
        final payment = _webPaymentTypeDb.firstWhere((p) => p['PaymentID'] == order['PaymentID'], orElse: () => {});
        return {...order, 'TypeName': payment['TypeName'] ?? 'ไม่ระบุ'};
      }).toList();
    }
    final db = await database;
    if (db == null) return [];
    return await db.rawQuery('''
      SELECT o.*, p.$_paymentTypeNameColumnName
      FROM $_saleOrderTableName o
      LEFT JOIN $_paymentTypeTableName p ON o.$_orderPaymentIdColumnName = p.$_paymentIdColumnName
      ORDER BY o.$_orderDateColumnName DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getOrderDetails(String orderId) async {
    if (kIsWeb) {
      final details = _webOrderDetailDb.where((d) => d['OrderID'] == orderId).toList();
      return details.map((d) {
        final product = _webMemoryDb.firstWhere((p) => p['ProductID'] == d['ProductID'], orElse: () => {});
        return {...d, 'ProductName': product['ProductName'] ?? 'Unknown'};
      }).toList();
    }
    final db = await database;
    if (db == null) return [];
    return await db.rawQuery('''
      SELECT d.*, p.$_productNameColumnName, p.$_productUnitColumnName
      FROM $_orderDetailTableName d
      JOIN $_productTableName p ON d.$_productIdColumnName = p.$_productIdColumnName
      WHERE d.$_orderIdColumnName = ?
    ''', [orderId]);
  }

  Future<bool> cancelOrder(String orderId) async {
    if (kIsWeb) {
      final index = _webSaleOrderDb.indexWhere((o) => o['OrderID'] == orderId);
      if (index != -1 && _webSaleOrderDb[index]['OrderStatus'] == 'Confirmed') {
        _webSaleOrderDb[index]['OrderStatus'] = 'Cancelled';
        // คืนสต็อกใน Web Memory
        final details = _webOrderDetailDb.where((d) => d['OrderID'] == orderId);
        for (var d in details) {
          final pIndex = _webMemoryDb.indexWhere((p) => p['ProductID'] == d['ProductID']);
          if (pIndex != -1) {
            _webMemoryDb[pIndex]['TotalUnit'] += d['Quantity'];
          }
        }
        return true;
      }
      return false;
    }

    final db = await database;
    if (db == null) return false;

    return await db.transaction((txn) async {
      // 1. ตรวจสอบสถานะปัจจุบันก่อน
      final List<Map<String, dynamic>> order = await txn.query(
        _saleOrderTableName,
        where: '$_orderIdColumnName = ? AND $_orderStatusColumnName = ?',
        whereArgs: [orderId, 'Confirmed'],
      );

      if (order.isEmpty) return false;

      // 2. อัปเดตสถานะบิลเป็น Cancelled
      await txn.update(
        _saleOrderTableName,
        {_orderStatusColumnName: 'Cancelled'},
        where: '$_orderIdColumnName = ?',
        whereArgs: [orderId],
      );

      // 3. ดึงรายการสินค้าเพื่อนำไปคืนสต็อก
      final List<Map<String, dynamic>> details = await txn.query(
        _orderDetailTableName,
        where: '$_orderIdColumnName = ?',
        whereArgs: [orderId],
      );

      // 4. คืนสต็อกสินค้าแต่ละรายการ
      for (var item in details) {
        await txn.execute('''
          UPDATE $_productTableName 
          SET $_productTotalUnitColumnName = $_productTotalUnitColumnName + ? 
          WHERE $_productIdColumnName = ?
        ''', [item['Quantity'], item['ProductID']]);
      }

      return true;
    });
  }

  // --- PurchaseOrder Methods ---
  Future<String> savePurchaseOrder({
    required String receiveDate,
    required double totalCost,
    required List<Map<String, dynamic>> items,
    String? billImagePath,
    required String purchaseType,
    required String paymentStatus,
  }) async {
    final poId = 'PO-${DateTime.now().millisecondsSinceEpoch}';

    final db = await database;
    if (db == null) return "";

    return await db.transaction((txn) async {
      final List<Map<String, dynamic>> ptTypes = await txn.query(
        _purchaseTypeTableName,
        where: '$_ptNameColumnName = ?',
        whereArgs: [purchaseType],
      );
      String ptId = ptTypes.isNotEmpty ? ptTypes.first[_ptIdColumnName] : "PT1";

      await txn.insert(_purchaseOrderTableName, {
        _poIdColumnName: poId,
        _poReceiveDateColumnName: receiveDate,
        _poTotalCostColumnName: totalCost,
        _poPaidAmountColumnName: paymentStatus == 'Paid' ? totalCost : 0, // ถ้าจ่ายสดให้ยอดจ่ายครบเลย
        _poBillImagePathColumnName: billImagePath,
        _poStatusColumnName: 'Confirmed', 
        _poPaymentStatusColumnName: paymentStatus,
        _poTypeIdColumnName: ptId,
      });

      for (var item in items) {
        await txn.insert(_purchaseDetailTableName, {
          _poIdColumnName: poId,
          _productIdColumnName: item['ProductID'],
          _detailUnitPriceColumnName: item['UnitPrice'],
          _detailQuantityColumnName: item['Quantity'],
        });
        // เพิ่มสต็อกสินค้า
        await txn.execute('''
          UPDATE $_productTableName SET $_productTotalUnitColumnName = $_productTotalUnitColumnName + ? WHERE $_productIdColumnName = ?
        ''', [item['Quantity'], item['ProductID']]);
      }
      return poId;
    });
  }

  Future<bool> cancelPurchaseOrder(String poId) async {
    final db = await database;
    if (db == null) return false;

    return await db.transaction((txn) async {
      // 1. ตรวจสอบสถานะปัจจุบัน
      final List<Map<String, dynamic>> po = await txn.query(
        _purchaseOrderTableName,
        where: '$_poIdColumnName = ? AND $_poStatusColumnName = ?',
        whereArgs: [poId, 'Confirmed'],
      );

      if (po.isEmpty) return false;

      // 2. อัปเดตสถานะเป็น Cancelled
      await txn.update(
        _purchaseOrderTableName,
        {_poStatusColumnName: 'Cancelled'},
        where: '$_poIdColumnName = ?',
        whereArgs: [poId],
      );

      // 3. ดึงรายการสินค้าเพื่อนำไปหักสต็อกคืน
      final List<Map<String, dynamic>> details = await txn.query(
        _purchaseDetailTableName,
        where: '$_poIdColumnName = ?',
        whereArgs: [poId],
      );

      // 4. หักสต็อกคืน (Deduct)
      for (var item in details) {
        await txn.execute('''
          UPDATE $_productTableName 
          SET $_productTotalUnitColumnName = $_productTotalUnitColumnName - ? 
          WHERE $_productIdColumnName = ?
        ''', [item['Quantity'], item['ProductID']]);
      }

      return true;
    });
  }

  Future<bool> addPurchasePayment({
    required String poId,
    required double amount,
    String? imagePath,
  }) async {
    final db = await database;
    if (db == null) return false;

    return await db.transaction((txn) async {
      final List<Map<String, dynamic>> poResults = await txn.query(
        _purchaseOrderTableName,
        where: '$_poIdColumnName = ?',
        whereArgs: [poId],
      );
      if (poResults.isEmpty) return false;
      final po = poResults.first;

      await txn.insert(_creditPaymentHistoryTableName, {
        _poIdColumnName: poId,
        _cphAmountPaidColumnName: amount,
        _cphPaidDateColumnName: DateTime.now().toIso8601String(),
        _cphPaidImagePathColumnName: imagePath,
      });

      final double currentPaid = (po[_poPaidAmountColumnName] as num).toDouble();
      final double totalCost = (po[_poTotalCostColumnName] as num).toDouble();
      final double newPaid = currentPaid + amount;

      final Map<String, dynamic> updateData = {
        _poPaidAmountColumnName: newPaid,
      };

      if (newPaid >= totalCost) {
        updateData[_poPaymentStatusColumnName] = 'Paid';
      }

      await txn.update(
        _purchaseOrderTableName,
        updateData,
        where: '$_poIdColumnName = ?',
        whereArgs: [poId],
      );

      return true;
    });
  }

  Future<bool> payPurchaseDebt(String poId) async {
    final db = await database;
    if (db == null) return false;
    
    final poResults = await db.query(
      _purchaseOrderTableName,
      where: '$_poIdColumnName = ?',
      whereArgs: [poId],
    );
    if (poResults.isEmpty) return false;
    final totalCost = (poResults.first[_poTotalCostColumnName] as num).toDouble();
    final currentPaid = (poResults.first[_poPaidAmountColumnName] as num).toDouble();
    final balance = totalCost - currentPaid;

    if (balance <= 0) return true;

    return await addPurchasePayment(poId: poId, amount: balance);
  }

  Future<List<Map<String, dynamic>>> getPurchasePaymentHistory(String poId) async {
    final db = await database;
    if (db == null) return [];
    return await db.query(
      _creditPaymentHistoryTableName,
      where: '$_poIdColumnName = ?',
      whereArgs: [poId], // เพิ่มพารามิเตอร์ที่ขาดไป
      orderBy: '$_cphPaidDateColumnName DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    final db = await database;
    if (db == null) return [];
    return await db.rawQuery('''
      SELECT po.*, pt.$_ptNameColumnName
      FROM $_purchaseOrderTableName po
      LEFT JOIN $_purchaseTypeTableName pt ON po.$_poTypeIdColumnName = pt.$_ptIdColumnName
      ORDER BY po.$_poReceiveDateColumnName DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getPurchaseOrderDetails(String poId) async {
    final db = await database;
    if (db == null) return [];
    return await db.rawQuery('''
      SELECT d.*, p.$_productNameColumnName, p.$_productUnitColumnName
      FROM $_purchaseDetailTableName d
      JOIN $_productTableName p ON d.$_productIdColumnName = p.$_productIdColumnName
      WHERE d.$_poIdColumnName = ?
    ''', [poId]);
  }

  Future<void> printAllProducts() async {
    final products = await getProducts();
    print('==================== DATABASE CONTENT (Platform: ${kIsWeb ? 'Web' : 'Native'}) ====================');
    if (products.isEmpty) {
      print('ฐานข้อมูลว่างเปล่า (Empty)');
    } else {
      for (var p in products) {
        print('ID: ${p[_productIdColumnName]} | ชื่อ: ${p[_productNameColumnName]} | ราคา: ${p[_productPriceColumnName]} | สต็อก: ${p[_productTotalUnitColumnName]} | คลัง: ${p[_warehouseNameColumnName] ?? 'ไม่มี'}');
      }
    }
    print('==========================================================');
  }
}

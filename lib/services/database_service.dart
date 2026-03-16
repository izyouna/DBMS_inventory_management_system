import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  final SupabaseClient _supabase = Supabase.instance.client;

  DatabaseService._constructor();

  // --- Helper Methods ---
  Future<String> _generateCustomId(
    String tableName,
    String idColumn,
    String prefix,
  ) async {
    final String col = idColumn.toLowerCase();
    final response = await _supabase
        .from(tableName)
        .select(col)
        .order(col, ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return "${prefix}1";

    String lastId = response[col].toString();
    if (lastId.startsWith(prefix)) {
      int? currentId = int.tryParse(lastId.substring(prefix.length));
      if (currentId != null) {
        return "$prefix${currentId + 1}";
      }
    }
    return "${prefix}1";
  }

  // --- Storage Methods ---
  Future<String?> uploadProductImage(dynamic file) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'public/$fileName';

      final Uint8List bytes = await _getFileBytes(file);
      await _supabase.storage.from('products').uploadBinary(path, bytes);

      final String publicUrl = _supabase.storage
          .from('products')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      return null;
    }
  }

  Future<String?> uploadBillImage(dynamic file) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'public/$fileName';

      final Uint8List bytes = await _getFileBytes(file);
      await _supabase.storage.from('bills').uploadBinary(path, bytes);

      return path;
    } catch (e) {
      debugPrint('Error uploading bill image: $e');
      return null;
    }
  }

  Future<Uint8List> _getFileBytes(dynamic file) async {
    if (file is Uint8List) return file;
    if (file is File) return await file.readAsBytes();
    return await file.readAsBytes();
  }

  Future<String?> getSignedUrl(String path) async {
    if (path.isEmpty) return null;
    try {
      return await _supabase.storage.from('bills').createSignedUrl(path, 600);
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }

  // --- Warehouse Methods ---
  Future<String> addWarehouse(String name) async {
    final newId = await _generateCustomId('warehouse', 'warehouseid', 'W');
    await _supabase.from('warehouse').insert({
      'warehouseid': newId,
      'warehousename': name,
    });
    return newId;
  }

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    return await _supabase.from('warehouse').select();
  }

  // --- Supplier Methods ---
  Future<String> addSupplier({
    required String name,
    required String phone,
  }) async {
    final newId = await _generateCustomId('supplier', 'supplier_id', 'S');
    await _supabase.from('supplier').insert({
      'supplier_id': newId,
      'supplier_name': name,
      'phone': phone,
    });
    return newId;
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    return await _supabase.from('supplier').select();
  }

  Future<void> deleteSupplier(String id) async {
    await _supabase.from('supplier').delete().eq('supplier_id', id);
  }

  Future<void> updateSupplier({
    required String id,
    required String name,
    required String phone,
  }) async {
    await _supabase
        .from('supplier')
        .update({'supplier_name': name, 'phone': phone})
        .eq('supplier_id', id);
  }

  // --- Customer Methods ---
  Future<List<Map<String, dynamic>>> getCustomers() async {
    return await _supabase
        .from('customer')
        .select()
        .order('customername', ascending: true);
  }

  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    try {
      final cleanPhone = phone.trim();
      final response = await _supabase
          .from('customer')
          .select(
            '*, debtrecord(remainingamount, debtstatus, debtrecordstatus)',
          )
          .eq('customerphone', cleanPhone)
          .order('customerid', ascending: false)
          .limit(1);

      if (response == null || (response as List).isEmpty) return null;

      final customer = response[0];
      double totalDebt = 0;
      if (customer['debtrecord'] != null) {
        final List records = customer['debtrecord'] as List;
        for (var dr in records) {
          if (dr['debtstatus'] == 'Pending' &&
              dr['debtrecordstatus'] == 'Confirmed') {
            totalDebt += (dr['remainingamount'] as num).toDouble();
          }
        }
      }

      final Map<String, dynamic> result = Map<String, dynamic>.from(customer);
      result['total_debt'] = totalDebt;
      return result;
    } catch (e) {
      debugPrint('Error fetching customer by phone: $e');
      return null;
    }
  }

  Future<void> updateCustomerCreditLimit(int customerId, double limit) async {
    await _supabase
        .from('customer')
        .update({'credit_limit': limit})
        .eq('customerid', customerId);
  }

  // --- Category Methods ---
  Future<String> addCategory(String name) async {
    final newId = await _generateCustomId('category', 'categoryid', 'C');
    await _supabase.from('category').insert({
      'categoryid': newId,
      'categoryname': name,
    });
    return newId;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return await _supabase.from('category').select();
  }

  // --- Product Unit Methods ---
  Future<List<Map<String, dynamic>>> getProductUnits() async {
    return await _supabase.from('productunit').select();
  }

  // --- Product Methods ---
  Future<String> addProduct({
    required String name,
    String? categoryId,
    required int stock,
    required double price,
    double markupPercentage = 0.0,
    required String unitId,
    String? imagePath,
    String? warehouseId,
  }) async {
    final newId = await _generateCustomId('product', 'productid', 'P');
    await _supabase.from('product').insert({
      'productid': newId,
      'productname': name,
      'categoryid': categoryId,
      'totalunit': stock,
      'price': price,
      'markup_percentage': markupPercentage,
      'unitid': unitId,
      'productimagepath': imagePath,
      'warehouseid': warehouseId,
      'is_active': 1,
    });

    // หากมีการระบุจำนวนเริ่มต้น ให้สร้างล็อตสินค้าและทรานแซกชันด้วย
    if (stock > 0) {
      final poId = 'INIT-${DateTime.now().millisecondsSinceEpoch}';

      // 1. สร้างหัวบิลสั่งซื้อเสมือนสำหรับยอดยกมา
      try {
        await _supabase.from('purchaseorder').insert({
          'poid': poId,
          'receivedate': DateTime.now().toIso8601String(),
          'totalcost': 0,
          'paidamount': 0,
          'status': 'Confirmed',
          'paymentstatus': 'Paid',
        });

        // 2. สร้างล็อตสินค้าเพื่อให้ FIFO ทำงานได้
        await _supabase.from('purchasedetail').insert({
          'poid': poId,
          'productid': newId,
          'unitprice': 0,
          'quantity': stock,
          'quantity_remaining': stock,
        });

        // 3. บันทึกทรานแซกชัน
        await _supabase.from('stock_transaction').insert({
          'transaction_id': 'TX-${DateTime.now().microsecondsSinceEpoch}',
          'productid': newId,
          'type': 'IN',
          'quantity': stock,
          'balance_after': stock,
          'reference_id': poId,
          'created_at': DateTime.now().toIso8601String(),
          'remarks': 'บันทึกยอดยกมาเริ่มต้น',
        });
      } catch (e) {
        debugPrint('Error creating initial stock records: $e');
      }
    }

    return newId;
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    return await _supabase
        .from('product')
        .select('''
      *,
      warehouse (warehousename),
      category (categoryname),
      productunit (unitname)
    ''')
        .eq('is_active', 1);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase
        .from('product')
        .update({'is_active': 0})
        .eq('productid', id);
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    String? categoryId,
    int? stock, // เปลี่ยนเป็น optional
    required double price,
    double? markupPercentage, // เปลี่ยนเป็น optional
    required String unitId,
    String? imagePath,
    String? warehouseId,
  }) async {
    final Map<String, dynamic> updateData = {
      'productname': name,
      'categoryid': categoryId,
      'price': price,
      'unitid': unitId,
      'productimagepath': imagePath,
      'warehouseid': warehouseId,
    };

    if (markupPercentage != null) {
      updateData['markup_percentage'] = markupPercentage;
    }

    // อัปเดตสต็อกเฉพาะเมื่อมีการส่งมาเท่านั้น (ปกติจะไม่ส่งมาจากหน้า Edit หรือ PO)
    if (stock != null) {
      updateData['totalunit'] = stock;
    }

    await _supabase
        .from('product')
        .update(updateData)
        .eq('productid', id);
  }

  // --- SaleOrder & Debt Methods ---
  Future<String> saveOrder({
    required String date,
    required double totalAmount,
    required String paymentStatus,
    String? paymentId,
    required List<Map<String, dynamic>> items,
    String? customerName,
    String? phone,
    String? dueDate,
    double? creditLimit,
  }) async {
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _supabase.from('saleorder').insert({
        'order_id': orderId,
        'orderdate': date,
        'totalamount': totalAmount,
        'paymentstatus': paymentStatus,
        'status': 'Confirmed',
        'paymentid': paymentId,
      });

      // 1. รวบรวมข้อมูลสินค้าที่ถูกสั่งซื้อ (Grouping by productid)
      final Map<String, double> productQtyMap = {};
      final Map<String, double> productPriceMap = {};
      for (var item in items) {
        final String pid = (item['productid'] ?? item['ProductID']).toString();
        final double qty = (item['quantity'] ?? item['Quantity'] as num).toDouble();
        final double price = (item['unit_price'] ?? item['UnitPrice'] ?? item['unitprice'] ?? 0).toDouble();
        
        productQtyMap[pid] = (productQtyMap[pid] ?? 0) + qty;
        productPriceMap[pid] = price;
      }

      final List<String> productIds = productQtyMap.keys.toList();

      final List<dynamic> allProductsRaw = await _supabase
          .from('product')
          .select('productid, totalunit')
          .inFilter('productid', productIds);
      
      final Map<String, int> productStockMap = {
        for (var p in allProductsRaw) p['productid'].toString(): (p['totalunit'] as num).toInt()
      };

      final List<dynamic> allBatchesRaw = await _supabase
          .from('purchasedetail')
          .select('*, purchaseorder(receivedate)')
          .inFilter('productid', productIds)
          .gt('quantity_remaining', 0)
          .order('receivedate', referencedTable: 'purchaseorder', ascending: true);
      
      List<Map<String, dynamic>> localBatches = List<Map<String, dynamic>>.from(
        allBatchesRaw.map((b) => Map<String, dynamic>.from(b))
      );

      List<Map<String, dynamic>> orderDetailsToInsert = [];
      List<Map<String, dynamic>> stockTransactionsToInsert = [];
      List<Map<String, dynamic>> batchUpdates = [];
      List<Map<String, dynamic>> productUpdates = [];

      final int baseTimestamp = DateTime.now().microsecondsSinceEpoch;
      int itemIndex = 0;

      for (String productId in productIds) {
        double qtyToSell = productQtyMap[productId]!;
        double unitPrice = productPriceMap[productId]!;

        if (qtyToSell <= 0) continue;

        double remainingToExit = qtyToSell;
        double totalCostForThisItem = 0;

        for (var batch in localBatches) {
          if (batch['productid'] != productId || remainingToExit <= 0.0001) continue;

          double batchRemaining = (batch['quantity_remaining'] as num).toDouble();
          double batchCostPrice = (batch['unitprice'] as num).toDouble();
          double takeFromBatch = 0;

          if (batchRemaining <= remainingToExit) {
            takeFromBatch = batchRemaining;
            remainingToExit -= batchRemaining;
            batch['quantity_remaining'] = 0;
          } else {
            takeFromBatch = remainingToExit;
            batch['quantity_remaining'] = batchRemaining - takeFromBatch;
            remainingToExit = 0;
          }

          if (takeFromBatch > 0) {
            batchUpdates.add({
              'poid': batch['poid'],
              'productid': productId,
              'quantity_remaining': batch['quantity_remaining'],
              'unitprice': batch['unitprice'],
            });
            totalCostForThisItem += (takeFromBatch * batchCostPrice);
          }
        }

        double finalCostPrice = (qtyToSell - remainingToExit) > 0
            ? (totalCostForThisItem / (qtyToSell - remainingToExit))
            : 0;

        orderDetailsToInsert.add({
          'order_id': orderId,
          'productid': productId,
          'unit_price': unitPrice,
          'quantity': qtyToSell,
          'cost_price': finalCostPrice,
        });

        if (productStockMap.containsKey(productId)) {
          int currentStock = productStockMap[productId]!;
          int newStock = currentStock - qtyToSell.round();
          if (newStock < 0) newStock = 0;

          debugPrint('DEBUG: Stock Update for $productId: $currentStock -> $newStock (qty: $qtyToSell)');
          productUpdates.add({'productid': productId, 'totalunit': newStock});

          stockTransactionsToInsert.add({
            'transaction_id': 'TX-${baseTimestamp + itemIndex}',
            'productid': productId,
            'type': 'OUT',
            'quantity': qtyToSell,
            'balance_after': newStock,
            'cost_price': finalCostPrice,
            'reference_id': orderId,
            'created_at': DateTime.now().toIso8601String(),
            'remarks': 'ขายสินค้าบิล $orderId (FIFO)',
          });
          itemIndex++;
        }
      }

      final List<Future> dbOperations = [];
      if (orderDetailsToInsert.isNotEmpty) {
        dbOperations.add(_supabase.from('orderdetail').insert(orderDetailsToInsert));
      }
      if (stockTransactionsToInsert.isNotEmpty) {
        dbOperations.add(_supabase.from('stock_transaction').insert(stockTransactionsToInsert));
      }
      if (batchUpdates.isNotEmpty) {
        dbOperations.add(_supabase.from('purchasedetail').upsert(batchUpdates));
      }
      if (productUpdates.isNotEmpty) {
        dbOperations.add(_supabase.from('product').upsert(productUpdates));
      }

      await Future.wait(dbOperations).timeout(const Duration(seconds: 30));

      // 5. จัดการข้อมูลลูกค้า (บันทึกทุกกรณีที่มีชื่อลูกค้า เพื่อเก็บเป็นฐานข้อมูล)
      int? finalCustomerId;
      if (customerName != null && customerName.isNotEmpty) {
        final cleanPhone = phone?.trim() ?? '';

        Map<String, dynamic>? existing;
        // ค้นหาลูกค้าเดิม (เฉพาะกรณีที่มีเบอร์โทรศัพท์เท่านั้น)
        if (cleanPhone.isNotEmpty) {
          final results = await _supabase
              .from('customer')
              .select('customerid')
              .eq('customerphone', cleanPhone)
              .limit(1);

          if (results != null && (results as List).isNotEmpty) {
            existing = results[0];
          }
        }

        if (existing != null) {
          finalCustomerId = existing['customerid'];
        } else {
          try {
            // ดึง ID สูงสุดมาบวก 1
            final lastCustomer = await _supabase
                .from('customer')
                .select('customerid')
                .order('customerid', ascending: false)
                .limit(1)
                .maybeSingle();

            int nextId;
            if (lastCustomer != null) {
              nextId = int.parse(lastCustomer['customerid'].toString()) + 1;
            } else {
              nextId = (DateTime.now().millisecondsSinceEpoch % 1000000) + 1000;
            }

            final newCustomer = await _supabase
                .from('customer')
                .insert({
                  'customerid': nextId,
                  'customername': customerName,
                  'customerphone': cleanPhone,
                  'credit_limit': creditLimit ?? 0.0,
                })
                .select('customerid')
                .maybeSingle();

            finalCustomerId = newCustomer != null
                ? newCustomer['customerid']
                : nextId;
          } catch (e) {
            debugPrint('Error creating customer: $e');
            // กรณีสร้างไม่สำเร็จ (เช่น เบอร์ซ้ำที่ไม่ได้ตรวจเจอตอนแรก) ให้ลองหาด้วยเบอร์อีกครั้ง
            if (cleanPhone.isNotEmpty) {
              final retry = await _supabase
                  .from('customer')
                  .select('customerid')
                  .eq('customerphone', cleanPhone)
                  .maybeSingle();
              finalCustomerId = retry?['customerid'];
            }
          }
        }
      }

      // 6. จัดการข้อมูลหนี้สิน (เฉพาะกรณีขายเชื่อ)
      if (paymentStatus == 'ขายเชื่อ (ค้างชำระ)' ||
          paymentStatus == 'ค้างชำระ') {
        // สร้างรหัสหนี้ที่สั้นลงและปลอดภัย
        final debtId =
            'D${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        await _supabase.from('debtrecord').insert({
          'debtid': debtId,
          'order_id': orderId,
          'debtstatus': 'Pending',
          'debtrecordstatus': 'Confirmed',
          'originalamount': totalAmount,
          'remainingamount': totalAmount,
          'startdate': date,
          'due_date': dueDate,
          'customerid': finalCustomerId,
        });
      }

      return orderId;
    } catch (e) {
      debugPrint('Error in saveOrder: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    return await _supabase
        .from('saleorder')
        .select('''
      *,
      paymenttype (paymentname),
      debtrecord (
        *,
        customer (customername, customerphone)
      )
    ''')
        .order('orderdate', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getOrderDetails(String orderId) async {
    return await _supabase
        .from('orderdetail')
        .select('''
      *,
      product (productid, productname, unitid, productunit (unitname))
    ''')
        .eq('order_id', orderId);
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      await _supabase
          .from('saleorder')
          .update({'status': 'Cancelled'})
          .eq('order_id', orderId);
      await _supabase
          .from('debtrecord')
          .update({'debtrecordstatus': 'Cancelled'})
          .eq('order_id', orderId);

      final details = await getOrderDetails(orderId);
      final int baseTimestamp = DateTime.now().microsecondsSinceEpoch;
      int itemIndex = 0;
      for (var item in details) {
        final String productId = item['productid'];
        final double qty = (item['quantity'] as num).toDouble();

        final productResponse = await _supabase
            .from('product')
            .select('totalunit')
            .eq('productid', productId)
            .single();

        final int currentStock = (productResponse['totalunit'] as num).toInt();
        final int newStock = currentStock + qty.round();

        await _supabase
            .from('product')
            .update({'totalunit': newStock})
            .eq('productid', productId);

        final latestBatch = await _supabase
            .from('purchasedetail')
            .select('poid, quantity_remaining')
            .eq('productid', productId)
            .order('poid', ascending: false)
            .limit(1)
            .maybeSingle();

        if (latestBatch != null) {
          double currentRemaining = (latestBatch['quantity_remaining'] as num)
              .toDouble();
          await _supabase
              .from('purchasedetail')
              .update({'quantity_remaining': currentRemaining + qty})
              .eq('poid', latestBatch['poid'])
              .eq('productid', productId);
        }

        await _supabase.from('stock_transaction').insert({
          'transaction_id': 'TX-${baseTimestamp + itemIndex}',
          'productid': productId,
          'type': 'ADJ_IN',
          'quantity': qty,
          'balance_after': newStock,
          'reference_id': orderId,
          'created_at': DateTime.now().toIso8601String(),
          'remarks': 'ยกเลิกบิลขาย $orderId (คืนสต็อกเข้าล็อตล่าสุด)',
        });
        itemIndex++;
      }
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  // --- Payment & Purchase Type Methods ---
  Future<List<Map<String, dynamic>>> getPaymentTypes() async {
    return await _supabase.from('paymenttype').select();
  }

  Future<List<Map<String, dynamic>>> getPurchaseTypes() async {
    return await _supabase.from('purchasetype').select();
  }

  // --- PurchaseOrder Methods ---
  Future<String> savePurchaseOrder({
    required String receiveDate,
    required double totalCost,
    required List<Map<String, dynamic>> items,
    String? billImagePath,
    String? ptId,
    required String paymentStatus,
    String? supplierId,
    String? dueDate,
  }) async {
    final poId = 'PO-${DateTime.now().millisecondsSinceEpoch}';

    await _supabase.from('purchaseorder').insert({
      'poid': poId,
      'receivedate': receiveDate,
      'totalcost': totalCost,
      'paidamount': paymentStatus == 'Paid' ? totalCost : 0,
      'billimagepath': billImagePath,
      'status': 'Confirmed',
      'paymentstatus': paymentStatus,
      'ptid': ptId,
      'supplier_id': supplierId,
      'due_date': dueDate,
    });

    final int baseTimestamp = DateTime.now().microsecondsSinceEpoch;
    int itemIndex = 0;
    for (var item in items) {
      final String productId = item['productid'] ?? item['ProductID'];
      final double qty = (item['quantity'] ?? item['Quantity'] as num)
          .toDouble();
      final double unitPrice = (item['unitprice'] ?? item['UnitPrice'] ?? 0)
          .toDouble();

      await _supabase.from('purchasedetail').insert({
        'poid': poId,
        'productid': productId,
        'unitprice': unitPrice,
        'quantity': qty,
        'quantity_remaining': qty,
      });

      final productResponse = await _supabase
          .from('product')
          .select('totalunit')
          .eq('productid', productId)
          .single();

      final int currentStock = (productResponse['totalunit'] as num).toInt();
      final int newStock = currentStock + qty.round();

      await _supabase
          .from('product')
          .update({'totalunit': newStock})
          .eq('productid', productId);

      await _supabase.from('stock_transaction').insert({
        'transaction_id': 'TX-${baseTimestamp + itemIndex}',
        'productid': productId,
        'type': 'IN',
        'quantity': qty,
        'balance_after': newStock,
        'cost_price': unitPrice,
        'reference_id': poId,
        'created_at': DateTime.now().toIso8601String(),
        'remarks': 'ซื้อสินค้าเข้าบิล $poId',
      });
      itemIndex++;
    }

    return poId;
  }

  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    return await _supabase
        .from('purchaseorder')
        .select('''
      *,
      purchasetype (ptname),
      supplier (supplier_name)
    ''')
        .order('receivedate', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getPurchaseOrderDetails(
    String poId,
  ) async {
    return await _supabase
        .from('purchasedetail')
        .select('''
      *,
      product (productid, productname, unitid, productunit (unitname))
    ''')
        .eq('poid', poId);
  }

  Future<bool> cancelPurchaseOrder(String poId) async {
    try {
      await _supabase
          .from('purchaseorder')
          .update({'status': 'Cancelled'})
          .eq('poid', poId);

      final details = await getPurchaseOrderDetails(poId);
      final int baseTimestamp = DateTime.now().microsecondsSinceEpoch;
      int itemIndex = 0;
      for (var item in details) {
        final String productId = item['productid'];
        final double qty = (item['quantity'] as num).toDouble();

        final productResponse = await _supabase
            .from('product')
            .select('totalunit')
            .eq('productid', productId)
            .single();

        final int currentStock = (productResponse['totalunit'] as num).toInt();
        final int newStock = currentStock - qty.round();

        await _supabase
            .from('product')
            .update({'totalunit': newStock < 0 ? 0 : newStock})
            .eq('productid', productId);

        await _supabase
            .from('purchasedetail')
            .update({'quantity_remaining': 0})
            .eq('poid', poId)
            .eq('productid', productId);

        await _supabase.from('stock_transaction').insert({
          'transaction_id': 'TX-${baseTimestamp + itemIndex}',
          'productid': productId,
          'type': 'ADJ_OUT',
          'quantity': qty,
          'balance_after': newStock < 0 ? 0 : newStock,
          'reference_id': poId,
          'created_at': DateTime.now().toIso8601String(),
          'remarks': 'ยกเลิกบิลซื้อ $poId',
        });
        itemIndex++;
      }
      return true;
    } catch (e) {
      debugPrint('Error cancelling purchase order: $e');
      return false;
    }
  }

  Future<bool> addPurchasePayment({
    required String poId,
    required double amount,
    String? imagePath,
  }) async {
    try {
      final po = await _supabase
          .from('purchaseorder')
          .select()
          .eq('poid', poId)
          .single();

      await _supabase.from('creditpaymenthistory').insert({
        'poid': poId,
        'amountpaid': amount,
        'paiddate': DateTime.now().toIso8601String(),
        'paidimagepath': imagePath,
      });

      final double currentPaid = (po['paidamount'] as num).toDouble();
      final double totalCost = (po['totalcost'] as num).toDouble();
      final double newPaid = currentPaid + amount;

      final Map<String, dynamic> updateData = {'paidamount': newPaid};

      if (newPaid >= totalCost) {
        updateData['paymentstatus'] = 'Paid';
      }

      await _supabase.from('purchaseorder').update(updateData).eq('poid', poId);
      return true;
    } catch (e) {
      debugPrint('Error adding purchase payment: $e');
      return false;
    }
  }

  Future<bool> payPurchaseDebt(String poId) async {
    try {
      final po = await _supabase
          .from('purchaseorder')
          .select()
          .eq('poid', poId)
          .single();
      final double totalCost = (po['totalcost'] as num).toDouble();
      final double currentPaid = (po['paidamount'] as num).toDouble();
      final double balance = totalCost - currentPaid;

      if (balance <= 0) return true;
      return await addPurchasePayment(poId: poId, amount: balance);
    } catch (e) {
      debugPrint('Error paying purchase debt: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPurchasePaymentHistory(
    String poId,
  ) async {
    return await _supabase
        .from('creditpaymenthistory')
        .select()
        .eq('poid', poId)
        .order('paiddate', ascending: false);
  }

  // --- Debt Payment Methods ---
  Future<List<Map<String, dynamic>>> getDebtRecords() async {
    return await _supabase
        .from('debtrecord')
        .select('''
          *,
          customer (customername, customerphone)
        ''')
        .eq('debtrecordstatus', 'Confirmed')
        .order('startdate', ascending: false);
  }

  Future<bool> addDebtPayment({
    required String debtId,
    required double amount,
    String? imagePath,
  }) async {
    try {
      final debt = await _supabase
          .from('debtrecord')
          .select()
          .eq('debtid', debtId)
          .single();

      await _supabase.from('deptpaymenthistory').insert({
        'debtid': debtId,
        'amountpaid': amount,
        'paiddate': DateTime.now().toIso8601String(),
        'deptpaidimagepath': imagePath,
      });

      final double currentRemaining = (debt['remainingamount'] as num)
          .toDouble();
      final double newRemaining = currentRemaining - amount;

      final Map<String, dynamic> updateData = {
        'remainingamount': newRemaining < 0 ? 0 : newRemaining,
      };

      if (newRemaining <= 0) {
        updateData['debtstatus'] = 'Paid';
        await _supabase
            .from('saleorder')
            .update({'paymentstatus': 'ชำระแล้ว'})
            .eq('order_id', debt['order_id']);
      }

      await _supabase
          .from('debtrecord')
          .update(updateData)
          .eq('debtid', debtId);
      return true;
    } catch (e) {
      debugPrint('Error adding debt payment: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDebtPaymentHistory(
    String debtId,
  ) async {
    return await _supabase
        .from('deptpaymenthistory')
        .select()
        .eq('debtid', debtId)
        .order('paiddate', ascending: false);
  }
}

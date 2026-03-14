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
    // In Supabase, we can fetch the latest ID to generate the next one
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

      // For private bucket, we store the path, not the public URL
      return path;
    } catch (e) {
      debugPrint('Error uploading bill image: $e');
      return null;
    }
  }

  Future<Uint8List> _getFileBytes(dynamic file) async {
    if (file is Uint8List) return file;
    if (file is File) return await file.readAsBytes();
    // Assuming it's XFile from image_picker
    return await file.readAsBytes();
  }

  Future<String?> getSignedUrl(String path) async {
    if (path.isEmpty) return null;
    try {
      return await _supabase.storage
          .from('bills')
          .createSignedUrl(path, 600); // 10 minutes
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
      'unitid': unitId,
      'productimagepath': imagePath,
      'warehouseid': warehouseId,
      'is_active': 1,
    });
    return newId;
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    // Joining with warehouse, category and productunit
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
    required int stock,
    required double price,
    required String unitId,
    String? imagePath,
    String? warehouseId,
  }) async {
    await _supabase
        .from('product')
        .update({
          'productname': name,
          'categoryid': categoryId,
          'totalunit': stock,
          'price': price,
          'unitid': unitId,
          'productimagepath': imagePath,
          'warehouseid': warehouseId,
        })
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
  }) async {
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    // In Supabase, we don't have client-side transactions across multiple tables as easily as sqflite.
    // For a robust solution, one would use a Postgres Function (RPC).
    // Here we'll do sequential calls for simplicity, though it lacks atomicity.

    await _supabase.from('saleorder').insert({
      'order_id': orderId,
      'orderdate': date,
      'totalamount': totalAmount,
      'paymentstatus': paymentStatus,
      'status': 'Confirmed',
      'paymentid': paymentId,
    });

    for (var item in items) {
      await _supabase.from('orderdetail').insert({
        'order_id': orderId,
        'productid': item['productid'] ?? item['ProductID'],
        'unit_price': item['unitprice'] ?? item['UnitPrice'],
        'quantity': item['quantity'] ?? item['Quantity'],
      });

      // Update stock
      final productResponse = await _supabase
          .from('product')
          .select('totalunit')
          .eq('productid', item['productid'] ?? item['ProductID'])
          .single();

      final int currentStock = productResponse['totalunit'];
      await _supabase
          .from('product')
          .update({
            'totalunit':
                currentStock -
                (item['quantity'] ?? item['Quantity'] as num).toInt(),
          })
          .eq('productid', item['productid'] ?? item['ProductID']);
    }

    if (paymentStatus == 'ค้างชำระ') {
      final debtId = 'DBT-${DateTime.now().millisecondsSinceEpoch}';
      await _supabase.from('debtrecord').insert({
        'debtid': debtId,
        'order_id': orderId,
        'debtstatus': 'Pending',
        'debtrecordstatus': 'Confirmed',
        'originalamount': totalAmount,
        'remainingamount': totalAmount,
        'startdate': date,
        'customername': customerName,
        'customerphone': phone,
      });
    }

    return orderId;
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    return await _supabase
        .from('saleorder')
        .select('''
      *,
      paymenttype (paymentname),
      debtrecord (customername, customerphone)
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
      for (var item in details) {
        final productResponse = await _supabase
            .from('product')
            .select('totalunit')
            .eq('productid', item['productid'])
            .single();

        final int currentStock = productResponse['totalunit'];
        await _supabase
            .from('product')
            .update({
              'totalunit': currentStock + (item['quantity'] as num).toInt(),
            })
            .eq('productid', item['productid']);
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
    });

    for (var item in items) {
      await _supabase.from('purchasedetail').insert({
        'poid': poId,
        'productid': item['productid'] ?? item['ProductID'],
        'unitprice': item['unitprice'] ?? item['UnitPrice'],
        'quantity': item['quantity'] ?? item['Quantity'],
      });

      // Update stock
      final productResponse = await _supabase
          .from('product')
          .select('totalunit')
          .eq('productid', item['productid'] ?? item['ProductID'])
          .single();

      final int currentStock = productResponse['totalunit'];
      await _supabase
          .from('product')
          .update({
            'totalunit':
                currentStock +
                (item['quantity'] ?? item['Quantity'] as num).toInt(),
          })
          .eq('productid', item['productid'] ?? item['ProductID']);
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
      for (var item in details) {
        final productResponse = await _supabase
            .from('product')
            .select('totalunit')
            .eq('productid', item['productid'])
            .single();

        final int currentStock = productResponse['totalunit'];
        await _supabase
            .from('product')
            .update({
              'totalunit': currentStock - (item['quantity'] as num).toInt(),
            })
            .eq('productid', item['productid']);
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
        .select()
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

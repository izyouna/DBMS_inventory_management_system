import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/database_service.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  List<Order> _orders = [];
  List<Map<String, dynamic>> _debtRecords = [];

  Map<String, CartItem> get items => {..._items};
  List<Order> get orders => [..._orders];
  List<Map<String, dynamic>> get debtRecords => [..._debtRecords];

  List<Order> get unpaidOrders => _orders.where((o) => !o.isPaid).toList();

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.total;
    });
    return total;
  }

  CartProvider() {
    loadOrdersFromDatabase();
    loadDebtRecords();
  }

  Future<void> loadDebtRecords() async {
    try {
      _debtRecords = await DatabaseService.instance.getDebtRecords();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading debt records: $e");
    }
  }

  // 1. โหลดเฉพาะหัวบิล (Header) จาก Database (ล่าสุดขึ้นก่อนเพราะ SQL ใช้ DESC)
  Future<void> loadOrdersFromDatabase() async {
    try {
      final dbOrders = await DatabaseService.instance.getOrders();
      _orders = dbOrders.map((orderMap) => Order.fromMap(orderMap, [])).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading orders: $e");
    }
  }

  // 2. ดึงรายละเอียดสินค้าจาก Database เมื่อกดดู
  Future<List<CartItem>> getOrderItemsFromDb(String orderId) async {
    try {
      final details = await DatabaseService.instance.getOrderDetails(orderId);
      return details.map((d) {
        final productData = d['product'];
        String unitLabel = 'ไม่ระบุหน่วย';
        
        if (productData != null && productData['productunit'] != null) {
          unitLabel = productData['productunit']['unitname'] ?? 'ไม่ระบุหน่วย';
        }

        return CartItem(
          product: Product(
            id: (productData != null ? productData['productid'] : (d['productid'] ?? '')).toString(),
            name: productData != null ? (productData['productname'] ?? 'ไม่พบชื่อสินค้า') : (d['productname'] ?? 'ไม่พบชื่อสินค้า'),
            price: (d['unit_price'] ?? 0).toDouble(),
            stock: 0, 
            unit: ProductUnit(
              id: (productData != null ? productData['unitid'] : '').toString(), 
              label: unitLabel
            ),
            category: ProductCategory(id: '', label: ''),
          ),
          quantity: (d['quantity'] ?? 0).toInt(),
        );
      }).toList();
    } catch (e) {

      debugPrint("Error fetching order details: $e");
      return [];
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(product.id, (existing) => CartItem(product: existing.product, quantity: existing.quantity + 1));
    } else {
      _items.putIfAbsent(product.id, () => CartItem(product: product));
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // ฟังก์ชัน Checkout (ส่ง paymentStatus)
  Future<Order> checkout(PaymentMethod method, {Customer? customer, String? dueDate}) async {
    final now = DateTime.now();
    final paymentType = method.name; 
    
    final List<Map<String, dynamic>> dbItems = _items.values.map((item) => {
      'productid': item.product.id,
      'unit_price': item.product.price,
      'quantity': item.quantity,
    }).toList();

    String? paymentId;
    if (method is CashPayment) paymentId = 'PAY1';
    else if (method is QRPayment) paymentId = 'PAY2';
    else if (method is CreditPayment) paymentId = 'PAY3';

    // 1. บันทึกลง Database
    final orderId = await DatabaseService.instance.saveOrder(
      date: now.toIso8601String(),
      totalAmount: totalAmount,
      paymentStatus: method is CreditPayment ? 'ค้างชำระ' : 'ชำระแล้ว',
      paymentId: paymentId,
      items: dbItems,
      customerName: customer?.name,
      phone: customer?.phone,
      dueDate: dueDate,
      creditLimit: customer?.creditLimit, // ส่งวงเงินเครดิตไปด้วย
    );

    // 2. สร้าง Order object สำหรับส่งกลับ (เพื่อให้มีรายการสินค้าครบถ้วนสำหรับปริ้น)
    final completedOrder = Order(
      id: orderId,
      items: _items.values.toList(),
      totalAmount: totalAmount,
      dateTime: now,
      paymentMethod: paymentType,
      documentType: method is CreditPayment ? DocumentType.invoice : DocumentType.receipt,
      isPaid: method is! CreditPayment,
      customer: customer,
      dueDate: dueDate != null ? DateTime.parse(dueDate) : null,
    );

    // ล้างตะกร้าทันทีหลังบันทึกสำเร็จ
    _items.clear();
    
    // รีโหลดประวัติบิลและลูกหนี้แบบเบื้องหลัง (ไม่ต้องรอให้เสร็จก่อน return)
    loadOrdersFromDatabase().catchError((e) => debugPrint("Error reloading orders: $e"));
    loadDebtRecords().catchError((e) => debugPrint("Error reloading debt: $e"));
    
    notifyListeners();
    return completedOrder;
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existing) => CartItem(product: existing.product, quantity: existing.quantity - 1));
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void payDebt(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];
      _orders[index] = Order(
        id: oldOrder.id,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        dateTime: oldOrder.dateTime,
        paymentMethod: 'ชำระหนี้แล้ว',
        documentType: DocumentType.receipt,
        isPaid: true,
        orderStatus: oldOrder.orderStatus,
        customer: oldOrder.customer,
      );
      notifyListeners();
    }
  }

  // เพิ่มระบบจ่ายหนี้รายครั้ง (ลูกหนี้)
  Future<bool> addDebtPayment({
    required String debtId,
    required double amount,
    dynamic image,
  }) async {
    String? uploadedPath;
    if (image != null) {
      uploadedPath = await DatabaseService.instance.uploadBillImage(image);
    }

    final success = await DatabaseService.instance.addDebtPayment(
      debtId: debtId,
      amount: amount,
      imagePath: uploadedPath,
    );
    if (success) {
      await loadDebtRecords();
      await loadOrdersFromDatabase();
    }
    return success;
  }

  Future<List<Map<String, dynamic>>> getDebtPaymentHistory(String debtId) async {
    return await DatabaseService.instance.getDebtPaymentHistory(debtId);
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      final success = await DatabaseService.instance.cancelOrder(orderId);
      if (success) {
        await loadOrdersFromDatabase(); 
        await loadDebtRecords();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error cancelling order: $e");
      return false;
    }
  }
}

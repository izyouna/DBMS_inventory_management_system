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
        return CartItem(
          product: Product(
            id: d['ProductID'] ?? '',
            name: d['ProductName'] ?? 'ไม่พบชื่อสินค้า',
            price: (d['UnitPrice'] ?? 0).toDouble(),
            stock: 0, 
            unit: ProductUnit(id: '', label: d['Unit'] ?? ''),
            category: ProductCategory(id: '', label: ''),
          ),
          quantity: d['Quantity'] ?? 0,
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
  Future<Order> checkout(PaymentMethod method, {Customer? customer}) async {
    final now = DateTime.now();
    final paymentType = method.name; 
    
    final List<Map<String, dynamic>> dbItems = _items.values.map((item) => {
      'ProductID': item.product.id,
      'UnitPrice': item.product.price,
      'Quantity': item.quantity,
    }).toList();

    // 1. บันทึกลง Database
    final orderId = await DatabaseService.instance.saveOrder(
      date: now.toIso8601String(),
      totalAmount: totalAmount,
      paymentStatus: method is CreditPayment ? 'ค้างชำระ' : 'ชำระแล้ว',
      paymentType: paymentType,
      items: dbItems,
      customerName: customer?.name,
      phone: customer?.phone,
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
    );

    // 3. รีโหลดประวัติบิลและลูกหนี้จาก Database
    await loadOrdersFromDatabase();
    await loadDebtRecords();
    
    clearCart();
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
    String? imagePath,
  }) async {
    final success = await DatabaseService.instance.addDebtPayment(
      debtId: debtId,
      amount: amount,
      imagePath: imagePath,
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

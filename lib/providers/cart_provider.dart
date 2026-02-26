import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/customer.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  final List<Order> _orders = [];

  Map<String, CartItem> get items => {..._items};
  List<Order> get orders => [..._orders];

  List<Order> get unpaidOrders => _orders.where((o) => !o.isPaid).toList();

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.total;
    });
    return total;
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // ฟังก์ชัน Checkout
  Order checkout(PaymentMethod method, {Customer? customer}) {
    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      items: _items.values.toList(),
      totalAmount: totalAmount,
      dateTime: DateTime.now(),
      paymentMethod: method.name,
      documentType: method.documentType,
      isPaid: method is! CreditPayment,
      customer: customer,
    );
    
    _orders.add(order);
    method.processPayment(totalAmount);
    clearCart();
    return order;
  }

  void payDebt(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      // ในแอปจริงควรเปลี่ยนเป็นสร้าง Order ใหม่ หรือ Update ฐานข้อมูล
      // แต่ในเชิง Object เราจะสร้าง copy ของ Order ที่เปลี่ยนสถานะ isPaid
      final oldOrder = _orders[index];
      _orders[index] = Order(
        id: oldOrder.id,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        dateTime: oldOrder.dateTime,
        paymentMethod: 'ชำระหนี้แล้ว', // หรือระบุวิธีที่ชำระจริง
        documentType: DocumentType.receipt,
        isPaid: true,
        customer: oldOrder.customer,
      );
      notifyListeners();
    }
  }
}

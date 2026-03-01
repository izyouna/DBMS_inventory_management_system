import 'cart_item.dart';
import 'customer.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime dateTime;
  final String paymentMethod;
  final DocumentType documentType;
  final bool isPaid;
  final String orderStatus; // Confirmed, Cancelled
  final Customer? customer;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.dateTime,
    required this.paymentMethod,
    required this.documentType,
    this.isPaid = true,
    this.orderStatus = 'Confirmed',
    this.customer,
  });

  String get documentName => documentType == DocumentType.receipt ? 'ใบเสร็จรับเงิน' : 'ใบแจ้งหนี้';

  // แปลงจาก Map (Database) มาเป็น Order Object (รองรับโครงสร้าง v8)
  factory Order.fromMap(Map<String, dynamic> map, List<CartItem> items) {
    return Order(
      id: map['OrderID'].toString(),
      items: items,
      totalAmount: (map['TotalAmount'] ?? 0).toDouble(),
      dateTime: DateTime.parse(map['OrderDate']),
      paymentMethod: map['TypeName'] ?? 'ไม่ระบุ',
      // ใช้ PaymentStatus แทน Status เดิม
      documentType: map['PaymentStatus'] == 'ค้างชำระ' ? DocumentType.invoice : DocumentType.receipt,
      isPaid: map['PaymentStatus'] != 'ค้างชำระ',
      orderStatus: map['OrderStatus'] ?? 'Confirmed',
      customer: null, 
    );
  }
}

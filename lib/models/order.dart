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

  // แปลงจาก Map (Database) มาเป็น Order Object
  factory Order.fromMap(Map<String, dynamic> map, List<CartItem> items) {
    Customer? customer;
    
    // Handle joined debtrecord
    final debtRecord = map['debtrecord'];
    if (debtRecord != null) {
      // Supabase join might return a list or a map
      final record = (debtRecord is List && debtRecord.isNotEmpty) ? debtRecord.first : debtRecord;
      if (record is Map) {
        final customerData = record['customer'];
        if (customerData != null) {
          customer = Customer(
            id: (record['customerid'] ?? record['id'])?.toString() ?? '',
            name: customerData['customername'] ?? '',
            phone: customerData['customerphone'] ?? '',
          );
        } else if (record['customername'] != null) {
          // Fallback if it was somehow flat (though our query is nested now)
          customer = Customer(
            id: (record['customerid'] ?? record['id'])?.toString() ?? '',
            name: record['customername'] ?? '',
            phone: record['customerphone'] ?? '',
          );
        }
      }
    }

    // Handle joined paymenttype
    String paymentMethodName = 'ไม่ระบุ';
    final paymentType = map['paymenttype'];
    if (paymentType != null) {
      paymentMethodName = paymentType['paymentname'] ?? 'ไม่ระบุ';
    }

    final paymentStatus = map['paymentstatus'];

    return Order(
      id: (map['order_id'] ?? '').toString(), 
      items: items,
      totalAmount: (map['totalamount'] ?? 0).toDouble(),
      dateTime: DateTime.parse(map['orderdate']),
      paymentMethod: paymentMethodName,
      documentType: paymentStatus == 'ค้างชำระ' ? DocumentType.invoice : DocumentType.receipt,
      isPaid: paymentStatus != 'ค้างชำระ',
      orderStatus: map['status'] ?? 'Confirmed', 
      customer: customer, 
    );
  }
}

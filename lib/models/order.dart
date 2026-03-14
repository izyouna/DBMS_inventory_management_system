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
    final debtRecord = map['debtrecord'] ?? map['DebtRecord'];
    if (debtRecord != null) {
      // Supabase join might return a list or a map
      final record = (debtRecord is List && debtRecord.isNotEmpty) ? debtRecord.first : debtRecord;
      if (record is Map && (record['customername'] ?? record['CustomerName']) != null) {
        customer = Customer(
          id: (record['customerid'] ?? record['CustomerID'] ?? record['id'])?.toString() ?? '',
          name: record['customername'] ?? record['CustomerName'] ?? record['name'] ?? '',
          phone: record['customerphone'] ?? record['CustomerPhone'] ?? record['phone'] ?? '',
        );
      }
    }

    // Handle joined paymenttype
    String paymentMethodName = 'ไม่ระบุ';
    final paymentType = map['paymenttype'] ?? map['PaymentType'];
    if (paymentType != null) {
      paymentMethodName = (paymentType['paymentname'] ?? paymentType['PaymentName']) ?? 'ไม่ระบุ';
    }

    final paymentStatus = map['paymentstatus'] ?? map['PaymentStatus'];

    return Order(
      id: (map['order_id'] ?? map['Order_ID'] ?? map['OrderID'] ?? '').toString(), 
      items: items,
      totalAmount: (map['totalamount'] ?? map['TotalAmount'] ?? 0).toDouble(),
      dateTime: DateTime.parse(map['orderdate'] ?? map['OrderDate']),
      paymentMethod: paymentMethodName,
      documentType: paymentStatus == 'ค้างชำระ' ? DocumentType.invoice : DocumentType.receipt,
      isPaid: paymentStatus != 'ค้างชำระ',
      orderStatus: map['status'] ?? map['Status'] ?? 'Confirmed', 
      customer: customer, 
    );
  }
}

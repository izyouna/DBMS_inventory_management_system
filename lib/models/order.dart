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
  final Customer? customer;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.dateTime,
    required this.paymentMethod,
    required this.documentType,
    this.isPaid = true,
    this.customer,
  });

  String get documentName => documentType == DocumentType.receipt ? 'ใบเสร็จรับเงิน' : 'ใบแจ้งหนี้';
}

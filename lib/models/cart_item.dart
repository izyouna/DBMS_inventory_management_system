import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

enum DocumentType { receipt, invoice }

abstract class PaymentMethod {
  String get name;
  DocumentType get documentType;
  void processPayment(double amount);
}

class CashPayment implements PaymentMethod {
  @override
  String get name => 'เงินสด';
  
  @override
  DocumentType get documentType => DocumentType.receipt;

  @override
  void processPayment(double amount) {
    print('ชำระด้วยเงินสด: $amount บาท -> ออกใบเสร็จรับเงิน');
  }
}

class QRPayment implements PaymentMethod {
  @override
  String get name => 'QR Code / โอนเงิน';

  @override
  DocumentType get documentType => DocumentType.receipt;

  @override
  void processPayment(double amount) {
    print('สร้าง QR Code สำหรับยอด: $amount บาท -> ออกใบเสร็จรับเงิน');
  }
}

class CreditPayment implements PaymentMethod {
  @override
  String get name => 'ขายเชื่อ (ค้างชำระ)';

  @override
  DocumentType get documentType => DocumentType.invoice;

  @override
  void processPayment(double amount) {
    print('บันทึกยอดค้างชำระ: $amount บาท -> ออกใบแจ้งหนี้');
  }
}

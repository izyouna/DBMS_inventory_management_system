class Supplier {
  final String supplierId;
  final String supplierName;
  final String phone;

  Supplier({
    required this.supplierId,
    required this.supplierName,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'phone': phone,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      supplierId: map['supplier_id'],
      supplierName: map['supplier_name'],
      phone: map['phone'],
    );
  }
}

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
      'SupplierID': supplierId,
      'SupplierName': supplierName,
      'Phone': phone,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      supplierId: map['SupplierID'],
      supplierName: map['SupplierName'],
      phone: map['Phone'],
    );
  }
}

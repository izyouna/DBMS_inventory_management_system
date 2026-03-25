class Customer {
  final String id;
  final String name;
  final String phone;
  final double creditLimit;
  final double totalDebt; // ยอดหนี้รวม (ถ้าต้องการเก็บไว้คำนวณ)

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.creditLimit = 0.0,
    this.totalDebt = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerid': id,
      'customername': name,
      'customerphone': phone,
      'credit_limit': creditLimit,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: (map['customerid'] ?? map['CustomerID'] ?? map['id'])?.toString() ?? '',
      name: map['customername'] ?? map['CustomerName'] ?? map['name'] ?? '',
      phone: map['customerphone'] ?? map['CustomerPhone'] ?? map['phone'] ?? '',
      creditLimit: (map['credit_limit'] ?? 0.0).toDouble(),
      totalDebt: (map['total_debt'] ?? 0.0).toDouble(), // กรณีมีการ join ยอดหนี้รวมมาให้
    );
  }
}

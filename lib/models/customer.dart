class Customer {
  final String id;
  final String name;
  final String phone;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerid': id,
      'customername': name,
      'customerphone': phone,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: (map['customerid'] ?? map['CustomerID'] ?? map['id'])?.toString() ?? '',
      name: map['customername'] ?? map['CustomerName'] ?? map['name'] ?? '',
      phone: map['customerphone'] ?? map['CustomerPhone'] ?? map['phone'] ?? '',
    );
  }
}

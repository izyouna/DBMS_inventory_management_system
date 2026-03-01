class Warehouse {
  final String id;
  final String name;

  Warehouse({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'WarehouseID': id,
      'WarehouseName': name,
    };
  }

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['WarehouseID']?.toString() ?? '',
      name: map['WarehouseName'] ?? '',
    );
  }
}

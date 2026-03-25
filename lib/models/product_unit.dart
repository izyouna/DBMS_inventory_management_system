class ProductUnit {
  final String id;
  final String label;

  ProductUnit({required this.id, required this.label});

  Map<String, dynamic> toMap() => {
    'unitid': id,
    'unitname': label,
  };

  factory ProductUnit.fromMap(Map<String, dynamic> map) => 
      ProductUnit(
        id: (map['unitid'] ?? map['UnitID'])?.toString() ?? '', 
        label: map['unitname'] ?? map['UnitName'] ?? ''
      );
}

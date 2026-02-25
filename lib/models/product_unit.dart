class ProductUnit {
  final String id;
  final String label;

  ProductUnit({required this.id, required this.label});

  Map<String, dynamic> toMap() => {'id': id, 'label': label};
  factory ProductUnit.fromMap(Map<String, dynamic> map) => 
      ProductUnit(id: map['id'], label: map['label']);
}

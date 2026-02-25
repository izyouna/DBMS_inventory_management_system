class ProductCategory {
  final String id;
  final String label;

  ProductCategory({required this.id, required this.label});

  Map<String, dynamic> toMap() => {'id': id, 'label': label};
  factory ProductCategory.fromMap(Map<String, dynamic> map) => 
      ProductCategory(id: map['id'], label: map['label']);
}

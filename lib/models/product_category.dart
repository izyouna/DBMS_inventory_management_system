class ProductCategory {
  final String id;
  final String label;

  ProductCategory({required this.id, required this.label});

  Map<String, dynamic> toMap() => {
    'categoryid': id,
    'categoryname': label,
  };

  factory ProductCategory.fromMap(Map<String, dynamic> map) => 
      ProductCategory(
        id: (map['categoryid'] ?? map['CategoryID'] ?? map['id'] ?? '')?.toString() ?? '', 
        label: map['categoryname'] ?? map['CategoryName'] ?? map['label'] ?? ''
      );
}

import 'product_category.dart';
import 'product_unit.dart';

// Export เพื่อให้ไฟล์อื่นที่ import product.dart สามารถเห็น ProductCategory และ ProductUnit ได้ทันที
export 'product_category.dart';
export 'product_unit.dart';

class Product {
  String id;
  String name;
  int stock;
  double price;
  ProductUnit unit;
  ProductCategory category;
  final String? imagePath; //ใส่ ? เพื่อบอกว่าเป็นค่าว่างได้


  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.unit,
    required this.category,
    this.imagePath,
  });

  bool get isLowStock => stock <= 3;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stock': stock,
      'price': price,
      'unitId': unit.id,
      'unitLabel': unit.label,
      'categoryId': category.id,
      'categoryLabel': category.label,
      'imagePath': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      stock: map['stock'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      unit: ProductUnit(id: map['unitId'], label: map['unitLabel']),
      category: ProductCategory(id: map['categoryId'], label: map['categoryLabel']),
      imagePath: map['imagePath'],
    );
  }
}

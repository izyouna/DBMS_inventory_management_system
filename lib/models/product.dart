import 'product_category.dart';
import 'product_unit.dart';
import 'warehouse.dart';

// Export เพื่อให้ไฟล์อื่นที่ import product.dart สามารถเห็น ProductCategory และ ProductUnit ได้ทันที
export 'product_category.dart';
export 'product_unit.dart';
export 'warehouse.dart';

class Product {
  String id;
  String name;
  int stock;
  double price;
  ProductUnit unit;
  ProductCategory category;
  Warehouse? warehouse;
  final String? imagePath; //ใส่ ? เพื่อบอกว่าเป็นค่าว่างได้

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.unit,
    required this.category,
    this.warehouse,
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
      'warehouseId': warehouse?.id,
      'warehouseName': warehouse?.name,
      'warehouseLocation': warehouse?.location,
      'imagePath': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['ProductID']?.toString() ?? '',
      name: map['ProductName'] ?? '',
      stock: map['TotalUnit'] ?? 0,
      price: (map['Price'] ?? 0).toDouble(),
      unit: ProductUnit(id: '', label: map['Unit'] ?? ''),
      category: ProductCategory(id: '', label: map['Category'] ?? ''),
      warehouse: map['warehouseId'] != null
          ? Warehouse(
              id: map['warehouseId'],
              name: map['warehouseName'],
              location: map['warehouseLocation'],
            )
          : null,
      imagePath: map['ImagePath'],
    );
  }
}

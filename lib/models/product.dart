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
  double markupPercentage; // เปอร์เซ็นต์กำไรที่ต้องการ
  ProductUnit unit;
  ProductCategory category;
  Warehouse? warehouse;
  final String? imagePath; //ใส่ ? เพื่อบอกว่าเป็นค่าว่างได้

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    this.markupPercentage = 0.0,
    required this.unit,
    required this.category,
    this.warehouse,
    this.imagePath,
  });

  bool get isLowStock => stock <= 5;

  Map<String, dynamic> toMap() {
    return {
      'productid': id,
      'productname': name,
      'totalunit': stock,
      'price': price,
      'markup_percentage': markupPercentage,
      'categoryid': category.id, 
      'unitid': unit.id,
      'warehouseid': warehouse?.id,
      'productimagepath': imagePath, 
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, List<ProductCategory> categories, List<ProductUnit> units) {
    String categoryId = map['categoryid']?.toString() ?? '';
    String unitId = map['unitid']?.toString() ?? '';

    // ค้นหา Category
    ProductCategory category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () {
        final categoryMap = map['category'];
        if (categoryMap != null && categoryMap['categoryname'] != null) {
          return ProductCategory(id: categoryId, label: categoryMap['categoryname']);
        }
        return ProductCategory(id: categoryId, label: 'ไม่ระบุหมวดหมู่');
      },
    );

    // ค้นหา Unit
    ProductUnit unit = units.firstWhere(
      (u) => u.id == unitId,
      orElse: () {
        final unitMap = map['productunit'];
        if (unitMap != null && unitMap['unitname'] != null) {
          return ProductUnit(id: unitId, label: unitMap['unitname']);
        }
        return ProductUnit(id: unitId, label: 'ไม่ระบุหน่วย');
      },
    );

    final warehouseId = map['warehouseid'];
    final warehouseMap = map['warehouse'];

    return Product(
      id: map['productid']?.toString() ?? '',
      name: map['productname'] ?? '',
      stock: (map['totalunit'] ?? 0).toInt(),
      price: (map['price'] ?? 0).toDouble(),
      markupPercentage: (map['markup_percentage'] ?? 0.0).toDouble(),
      unit: unit,
      category: category,
      warehouse: warehouseId != null
          ? Warehouse(
              id: warehouseId.toString(),
              name: warehouseMap != null ? warehouseMap['warehousename'] : 'ไม่ระบุคลัง',
            )
          : null,
      imagePath: map['productimagepath'],
    );
  }
}

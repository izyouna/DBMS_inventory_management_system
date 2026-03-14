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

  bool get isLowStock => stock <= 5;

  Map<String, dynamic> toMap() {
    return {
      'productid': id,
      'productname': name,
      'totalunit': stock,
      'price': price,
      'categoryid': category.id, 
      'unitid': unit.id,
      'warehouseid': warehouse?.id,
      'productimagepath': imagePath, 
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, List<ProductCategory> categories, List<ProductUnit> units) {
    String categoryId = (map['categoryid'] ?? map['CategoryID'])?.toString() ?? '';
    String unitId = (map['unitid'] ?? map['UnitID'])?.toString() ?? '';

    // ค้นหา Category
    ProductCategory category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () {
        final categoryMap = map['category'] ?? map['Category'];
        if (categoryMap != null && (categoryMap['categoryname'] ?? categoryMap['CategoryName']) != null) {
          return ProductCategory(id: categoryId, label: categoryMap['categoryname'] ?? categoryMap['CategoryName']);
        }
        return ProductCategory(id: categoryId, label: 'ไม่ระบุหมวดหมู่');
      },
    );

    // ค้นหา Unit
    ProductUnit unit = units.firstWhere(
      (u) => u.id == unitId,
      orElse: () {
        final unitMap = map['productunit'] ?? map['ProductUnit'];
        if (unitMap != null && (unitMap['unitname'] ?? unitMap['UnitName']) != null) {
          return ProductUnit(id: unitId, label: unitMap['unitname'] ?? unitMap['UnitName']);
        }
        return ProductUnit(id: unitId, label: 'ไม่ระบุหน่วย');
      },
    );

    final warehouseId = map['warehouseid'] ?? map['WarehouseID'];
    final warehouseMap = map['warehouse'] ?? map['Warehouse'];

    return Product(
      id: (map['productid'] ?? map['ProductID'])?.toString() ?? '',
      name: map['productname'] ?? map['ProductName'] ?? '',
      stock: (map['totalunit'] ?? map['TotalUnit'] ?? 0).toInt(),
      price: (map['price'] ?? map['Price'] ?? 0).toDouble(),
      unit: unit,
      category: category,
      warehouse: warehouseId != null
          ? Warehouse(
              id: warehouseId.toString(),
              name: warehouseMap != null ? (warehouseMap['warehousename'] ?? warehouseMap['WarehouseName']) : 'ไม่ระบุคลัง',
            )
          : null,
      imagePath: map['productimagepath'] ?? map['ProductImagePath'],
    );
  }
}

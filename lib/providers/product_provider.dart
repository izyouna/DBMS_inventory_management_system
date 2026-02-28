import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';

class ProductProvider with ChangeNotifier {
  final List<ProductCategory> _categories = [
    ProductCategory(id: 'cat1', label: 'ปุ๋ย'),
    ProductCategory(id: 'cat2', label: 'ยาฆ่าแมลง'),
    ProductCategory(id: 'cat3', label: 'เมล็ดพันธุ์'),
    ProductCategory(id: 'cat4', label: 'อุปกรณ์'),
    ProductCategory(id: 'cat5', label: 'ทั่วไป'),
  ];

  final List<ProductUnit> _units = [
    ProductUnit(id: 'u1', label: 'ชิ้น'),
    ProductUnit(id: 'u2', label: 'กระสอบ'),
    ProductUnit(id: 'u3', label: 'ขวด'),
    ProductUnit(id: 'u4', label: 'กล่อง'),
    ProductUnit(id: 'u5', label: 'ถุง'),
  ];

  final List<Warehouse> _warehouses = [
    Warehouse(id: 'w1', name: 'หน้าร้าน', location: 'โซน A'),
    Warehouse(id: 'w2', name: 'คลังสินค้าหลังร้าน', location: 'โซน B'),
    Warehouse(id: 'w3', name: 'โรงรถ', location: 'โซน C'),
  ];

  List<Product> _products = []; // เปลี่ยนจาก late final เป็น List ปกติ

  ProductProvider() {
    _products = []; // เริ่มต้นเป็นรายการว่าง
    loadProductsFromDatabase(); // โหลดจาก DB ทันทีที่สร้าง Provider
  }

  // ฟังก์ชันโหลดข้อมูลจาก SQLite
  Future<void> loadProductsFromDatabase() async {
    try {
      final dbProducts = await DatabaseService.instance.getProducts();
      
      if (dbProducts.isEmpty) {
        // ถ้าใน DB ไม่มีข้อมูลเลย ให้ใส่ข้อมูลเริ่มต้นและบันทึกลง DB
        await _setInitialProducts();
        // โหลดใหม่อีกครั้งหลังจากบันทึกแล้วเพื่อให้ได้ ID ที่ถูกต้องจาก DB
        final updatedDbProducts = await DatabaseService.instance.getProducts();
        _products = updatedDbProducts.map((map) => Product.fromMap(map, _categories, _units)).toList();
      } else {
        _products = dbProducts.map((map) => Product.fromMap(map, _categories, _units)).toList();
      }
    } catch (e) {
      debugPrint("Error loading products: $e");
      // กรณีโหลดไม่ได้ (เช่น บน Windows ที่ไม่ได้ตั้งค่า) ให้ใช้ข้อมูลใน Memory ไปก่อน
      _products = [
        Product(
          id: '1',
          name: 'ปุ๋ยอินทรีย์ 50kg',
          price: 450.0,
          stock: 10,
          unit: _units[1],
          category: _categories[0],
          warehouse: _warehouses[1],
        ),
      ];
    }
    notifyListeners();
  }

  Future<void> _setInitialProducts() async {
    // บันทึกสินค้าเริ่มต้นลงฐานข้อมูลจริงๆ
    await DatabaseService.instance.addProduct(
      name: 'ปุ๋ยอินทรีย์ 50kg',
      price: 450.0,
      stock: 10,
      unit: _units[1].label,
      category: _categories[0].label,
      warehouseId: _warehouses[1].id,
      warehouseName: _warehouses[1].name,
      warehouseLocation: _warehouses[1].location,
    );
  }

  List<Product> get products => [..._products];
  List<ProductCategory> get categories => [..._categories];
  List<ProductUnit> get units => [..._units];
  List<Warehouse> get warehouses => [..._warehouses];
  Map<String, int> _cart = {};
  Map<String, int> get cart => {..._cart};

  void addWarehouse(Warehouse warehouse) {
    _warehouses.add(warehouse);
    notifyListeners();
  }

  List<Product> getProductsByWarehouse(String warehouseId) {
    return _products.where((p) => p.warehouse?.id == warehouseId).toList();
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) async {
    // 1. อัปเดตใน List ของ Provider ทันทีเพื่อให้ UI เปลี่ยนแปลงเร็วขึ้น
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }

    // 2. บันทึกลง SQLite ในเบื้องหลัง
    final dbId = int.tryParse(updatedProduct.id);
    if (dbId != null) {
      try {
        await DatabaseService.instance.updateProduct(
          id: dbId,
          name: updatedProduct.name,
          category: updatedProduct.category.label,
          stock: updatedProduct.stock,
          price: updatedProduct.price,
          unit: updatedProduct.unit.label,
          imagePath: updatedProduct.imagePath,
          warehouseId: updatedProduct.warehouse?.id,
          warehouseName: updatedProduct.warehouse?.name,
          warehouseLocation: updatedProduct.warehouse?.location,
        );
      } catch (e) {
        debugPrint("Error updating database: $e");
      }
    }
  }

  void deleteProduct(String id) async {
    // ลบใน SQLite (ต้องแปลง id เป็น int ก่อนส่ง)
    final dbId = int.tryParse(id);
    if (dbId != null) {
      await DatabaseService.instance.deleteProduct(dbId);
    }
    
    // ลบในรายการของ Provider เพื่ออัปเดต UI ทันที
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void reduceStock(String productId, int quantity) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index].stock -= quantity;
      if (_products[index].stock < 0) _products[index].stock = 0;
      notifyListeners();
    }
  }

  int get lowStockCount => _products.where((p) => p.isLowStock).length;

  // --- Image Management (Reusable) ---
  XFile? _productImage;
  final ImagePicker _picker = ImagePicker();

  XFile? get productImage => _productImage;

  // เลือกรูปภาพจาก Camera หรือ Gallery
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _productImage = pickedFile;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // ล้างรูปภาพออก
  void clearImage() {
    _productImage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // ตั้งค่ารูปภาพโดยตรง (ใช้ตอนกดแก้ไขสินค้า)
  void setImageFromPath(String? path) {
    if (path != null) {
      _productImage = XFile(path);
    } else {
      _productImage = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

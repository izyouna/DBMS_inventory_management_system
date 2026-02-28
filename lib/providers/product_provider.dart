import 'package:flutter/foundation.dart';
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

  List<Warehouse> _warehouses = [];
  List<Product> _products = [];

  ProductProvider() {
    loadProductsFromDatabase();
  }

  // ฟังก์ชันโหลดข้อมูลจากฐานข้อมูล
  Future<void> loadProductsFromDatabase() async {
    try {
      // 1. โหลด Warehouses ก่อน
      final dbWarehouses = await DatabaseService.instance.getWarehouses();
      _warehouses = dbWarehouses.map((map) => Warehouse.fromMap(map)).toList();

      // 2. โหลด Products
      final dbProducts = await DatabaseService.instance.getProducts();
      
      if (dbProducts.isEmpty) {
        // ถ้าฐานข้อมูลว่าง พยายามสร้างสินค้าตัวอย่างลง DB
        if (!kIsWeb) {
          await _setInitialProducts();
          final updatedDbProducts = await DatabaseService.instance.getProducts();
          if (updatedDbProducts.isNotEmpty) {
            _products = updatedDbProducts.map((map) => Product.fromMap(map, _categories, _units)).toList();
          }
        } else {
          _setInitialFallback();
        }
      } else {
        _products = dbProducts.map((map) => Product.fromMap(map, _categories, _units)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading products: $e");
      _setInitialFallback();
      notifyListeners();
    }
  }

  void _setInitialFallback() {
    // ข้อมูลสำรองหากโหลดไม่ได้
    _products = [
      Product(
        id: '1',
        name: 'ปุ๋ยอินทรีย์ 50kg',
        price: 450.0,
        stock: 10,
        unit: _units[1],
        category: _categories[0],
        warehouse: _warehouses.isNotEmpty ? _warehouses[0] : null,
      ),
    ];
  }

  Future<void> _setInitialProducts() async {
    if (_warehouses.isEmpty) return;
    
    await DatabaseService.instance.addProduct(
      name: 'ปุ๋ยอินทรีย์ 50kg',
      price: 450.0,
      stock: 10,
      unit: _units[1].label,
      category: _categories[0].label,
      warehouseId: _warehouses[0].id,
    );
  }

  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  List<ProductUnit> get units => _units;
  List<Warehouse> get warehouses => _warehouses;

  void addWarehouse(String name) async {
    final id = await DatabaseService.instance.addWarehouse(name);
    _warehouses.add(Warehouse(id: id.toString(), name: name));
    notifyListeners();
  }

  List<Product> getProductsByWarehouse(String warehouseId) {
    return _products.where((p) => p.warehouse?.id == warehouseId).toList();
  }

  void addProduct(Product product) {
    final existingIndex = _products.indexWhere((p) => p.id == product.id);
    if (existingIndex == -1) {
      _products.add(product);
      notifyListeners();
    }
  }

  void updateProduct(Product updatedProduct) async {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }

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
        );
      } catch (e) {
        debugPrint("Error updating database: $e");
      }
    }
  }

  void deleteProduct(String id) async {
    final dbId = int.tryParse(id);
    if (dbId != null) {
      try {
        await DatabaseService.instance.deleteProduct(dbId);
      } catch (e) {
        debugPrint("Error deleting from database: $e");
      }
    }
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

  XFile? _productImage;
  final ImagePicker _picker = ImagePicker();
  XFile? get productImage => _productImage;

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

  void clearImage() {
    _productImage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

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

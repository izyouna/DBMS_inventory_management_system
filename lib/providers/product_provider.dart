import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';

class ProductProvider with ChangeNotifier {
  List<ProductCategory> _categories = [];

  List<ProductUnit> _units = [];

  List<Warehouse> _warehouses = [];
  List<Product> _products = [];

  ProductProvider() {
    loadProductsFromDatabase();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ฟังก์ชันโหลดข้อมูลจากฐานข้อมูล
  Future<void> loadProductsFromDatabase({bool force = false}) async {
    if (_isLoading && !force) return;
    _isLoading = true;
    if (force) notifyListeners(); // แจ้ง UI ว่ากำลังเริ่มโหลดใหม่จริงๆ
    
    try {
      debugPrint("--- Start Loading Products (Force: $force) ---");
      
      // ดึงข้อมูลทั้งหมดแบบขนานเพื่อความเร็ว
      final results = await Future.wait([
        DatabaseService.instance.getCategories(),
        DatabaseService.instance.getProductUnits(),
        DatabaseService.instance.getWarehouses(),
        DatabaseService.instance.getProducts(),
      ]);

      final dbCategories = results[0] as List<Map<String, dynamic>>;
      final dbUnits = results[1] as List<Map<String, dynamic>>;
      final dbWarehouses = results[2] as List<Map<String, dynamic>>;
      final dbProducts = results[3] as List<Map<String, dynamic>>;

      _categories = dbCategories.map((map) => ProductCategory.fromMap(map)).toList();
      _units = dbUnits.map((map) => ProductUnit.fromMap(map)).toList();
      _warehouses = dbWarehouses.map((map) => Warehouse.fromMap(map)).toList();

      _products = dbProducts
          .map((map) {
            try {
              return Product.fromMap(map, _categories, _units);
            } catch (e) {
              debugPrint("Error parsing product: $e | Data: $map");
              return null;
            }
          })
          .whereType<Product>()
          .toList();
      
      debugPrint("Successfully loaded ${_products.length} products");
      debugPrint("--- Finish Loading Products ---");

    } catch (e) {
      debugPrint("Critical error loading products: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  List<ProductUnit> get units => _units;
  List<Warehouse> get warehouses => _warehouses;

  void addWarehouse(String name) async {
    final id = await DatabaseService.instance.addWarehouse(name);
    _warehouses.add(Warehouse(id: id, name: name));
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

    try {
      String? finalImagePath = updatedProduct.imagePath;

      // If a new image was picked, upload it first
      if (_productImage != null) {
        debugPrint("Uploading new image for product: ${updatedProduct.name}");
        final uploadedUrl = await DatabaseService.instance.uploadProductImage(_productImage!);
        if (uploadedUrl != null) {
          finalImagePath = uploadedUrl;
          // Update the local object with the real URL
          if (index != -1) {
            _products[index].id = updatedProduct.id; // ensure consistency
            // Note: In a real app, we might want to update the local product again
          }
        }
      }

      await DatabaseService.instance.updateProduct(
        id: updatedProduct.id,
        name: updatedProduct.name,
        categoryId: updatedProduct.category.id,
        // ไม่ส่ง stock ไปเพื่อป้องกันการเขียนทับด้วยข้อมูลเก่า
        price: updatedProduct.price,
        markupPercentage: updatedProduct.markupPercentage,
        unitId: updatedProduct.unit.id,
        imagePath: finalImagePath,
        warehouseId: updatedProduct.warehouse?.id,
      );
      
      // Reload from DB to ensure local state matches server (especially URLs)
      loadProductsFromDatabase();
    } catch (e) {
      debugPrint("Error updating database: $e");
    }
  }

  void deleteProduct(String id) async {
    try {
      await DatabaseService.instance.deleteProduct(id);
    } catch (e) {
      debugPrint("Error deleting from database: $e");
    }
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
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

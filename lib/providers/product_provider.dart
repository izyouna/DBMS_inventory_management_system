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

  // ฟังก์ชันโหลดข้อมูลจากฐานข้อมูล
  Future<void> loadProductsFromDatabase() async {
    try {
      debugPrint("--- Start Loading Products ---");
      // 1. โหลด Categories
      final dbCategories = await DatabaseService.instance.getCategories();
      debugPrint("Raw Categories from DB: $dbCategories");
      _categories = dbCategories
          .map((map) => ProductCategory.fromMap(map))
          .toList();
      debugPrint("Parsed Categories: ${_categories.length}");

      // 2. โหลด Units
      final dbUnits = await DatabaseService.instance.getProductUnits();
      debugPrint("Raw Units from DB: $dbUnits");
      _units = dbUnits.map((map) => ProductUnit.fromMap(map)).toList();
      debugPrint("Parsed Units: ${_units.length}");

      // 3. โหลด Warehouses
      final dbWarehouses = await DatabaseService.instance.getWarehouses();
      debugPrint("Raw Warehouses from DB: $dbWarehouses");
      _warehouses = dbWarehouses.map((map) => Warehouse.fromMap(map)).toList();
      debugPrint("Parsed Warehouses: ${_warehouses.length}");

      // 4. โหลด Products
      final dbProducts = await DatabaseService.instance.getProducts();
      debugPrint("Raw Products from DB: $dbProducts");

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

      notifyListeners();
    } catch (e) {
      debugPrint("Critical error loading products: $e");
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
        stock: updatedProduct.stock,
        price: updatedProduct.price,
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

  void reduceStock(String productId, int quantity) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final newStock = _products[index].stock - quantity;
      _products[index].stock = newStock < 0 ? 0 : newStock;
      notifyListeners();

      try {
        await DatabaseService.instance.updateProduct(
          id: productId,
          name: _products[index].name,
          categoryId: _products[index].category.id,
          stock: _products[index].stock,
          price: _products[index].price,
          unitId: _products[index].unit.id, // Updated from .label
          imagePath: _products[index].imagePath,
          warehouseId: _products[index].warehouse?.id,
        );
      } catch (e) {
        debugPrint("Error updating stock in DB: $e");
      }
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

import 'package:flutter/material.dart';
import '../models/product.dart';

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

  late final List<Product> _products;

  ProductProvider() {
    _products = [
      Product(
        id: '1',
        name: 'ปุ๋ยอินทรีย์ 50kg',
        price: 450.0,
        stock: 10,
        unit: _units[1],
        category: _categories[0],
      ),
      Product(
        id: '2',
        name: 'ยาฆ่าแมลง 1L',
        price: 250.0,
        stock: 3,
        unit: _units[2],
        category: _categories[1],
      ),
      Product(
        id: '3',
        name: 'เมล็ดข้าวโพด 5kg',
        price: 320.0,
        stock: 20,
        unit: _units[4],
        category: _categories[2],
      ),
      Product(
        id: '4',
        name: 'เมล็ดข้าวหอมมะลิ 5kg',
        price: 350.0,
        stock: 15,
        unit: _units[4],
        category: _categories[2],
      ),
      Product(
        id: '5',
        name: 'อุปกรณ์ฉีดพ่น',
        price: 890.0,
        stock: 5,
        unit: _units[0],
        category: _categories[3],
      ),
    ];
  }

  List<Product> get products => [..._products];
  List<ProductCategory> get categories => [..._categories];
  List<ProductUnit> get units => [..._units];
  Map<String, int> _cart = {};
  Map<String, int> get cart => {..._cart};

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _cart.remove(id);
    notifyListeners();
  }

  void addToCart(String productId) {
    _cart[productId] = (_cart[productId] ?? 0) + 1;
    notifyListeners();
  }

  void removeFromCart(String productId) {
    if (_cart.containsKey(productId)) {
      if (_cart[productId]! > 1) {
        _cart[productId] = _cart[productId]! - 1;
      } else {
        _cart.remove(productId);
      }
      notifyListeners();
    }
  }

  double get totalAmount {
    double total = 0.0;
    _cart.forEach((id, qty) {
      final product = _products.firstWhere((p) => p.id == id);
      total += product.price * qty;
    });
    return total;
  }

  int get cartCount => _cart.values.fold(0, (sum, qty) => sum + qty);
  int get lowStockCount => _products.where((p) => p.isLowStock).length;
}

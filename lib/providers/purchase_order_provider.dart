import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class PurchaseOrderItem {
  final Product product;
  int quantity;
  double costPrice;

  PurchaseOrderItem({
    required this.product,
    this.quantity = 1,
    required this.costPrice,
  });

  double get total => quantity * costPrice;
}

class PurchaseOrderProvider with ChangeNotifier {
  final Map<String, PurchaseOrderItem> _items = {};
  List<Map<String, dynamic>> _purchaseHistory = [];
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;

  Map<String, PurchaseOrderItem> get items => {..._items};
  List<Map<String, dynamic>> get purchaseHistory => _purchaseHistory;
  List<Map<String, dynamic>> get suppliers => _suppliers;
  String? get selectedSupplierId => _selectedSupplierId;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.total;
    });
    return total;
  }

  PurchaseOrderProvider() {
    loadPurchaseHistory();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    try {
      _suppliers = await DatabaseService.instance.getSuppliers();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading suppliers: $e");
    }
  }

  void selectSupplier(String? id) {
    _selectedSupplierId = id;
    notifyListeners();
  }

  Future<void> addSupplier(String name, String phone) async {
    await DatabaseService.instance.addSupplier(name: name, phone: phone);
    await loadSuppliers();
  }

  Future<void> updateSupplier(String id, String name, String phone) async {
    await DatabaseService.instance.updateSupplier(id: id, name: name, phone: phone);
    await loadSuppliers();
  }

  Future<void> deleteSupplier(String id) async {
    await DatabaseService.instance.deleteSupplier(id);
    await loadSuppliers();
  }

  Future<void> loadPurchaseHistory() async {
    try {
      _purchaseHistory = await DatabaseService.instance.getPurchaseOrders();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading purchase history: $e");
    }
  }

  Future<void> payDebt(String poId) async {
    // วิธีเก่า (จ่ายครบทีเดียว) จะถูกแทนที่ด้วยระบบจ่ายรายครั้ง
    // แต่เรายังเก็บไว้เผื่อเรียกใช้
    final success = await DatabaseService.instance.payPurchaseDebt(poId);
    if (success) {
      await loadPurchaseHistory();
    }
  }

  Future<bool> addPayment({
    required String poId,
    required double amount,
    String? imagePath,
  }) async {
    String? uploadedPath;
    if (imagePath != null && !imagePath.startsWith('http')) {
      uploadedPath = await DatabaseService.instance.uploadBillImage(File(imagePath));
    } else {
      uploadedPath = imagePath;
    }

    final success = await DatabaseService.instance.addPurchasePayment(
      poId: poId,
      amount: amount,
      imagePath: uploadedPath,
    );
    if (success) {
      await loadPurchaseHistory();
    }
    return success;
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String poId) async {
    return await DatabaseService.instance.getPurchasePaymentHistory(poId);
  }

  Future<List<Map<String, dynamic>>> getPurchaseOrderDetails(String poId) async {
    try {
      return await DatabaseService.instance.getPurchaseOrderDetails(poId);
    } catch (e) {
      debugPrint("Error loading purchase details: $e");
      return [];
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += 1;
    } else {
      _items[product.id] = PurchaseOrderItem(
        product: product,
        quantity: 1,
        costPrice: product.price * 0.7, // สมมติราคาต้นทุนเริ่มต้นที่ 70% ของราคาขาย
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity -= 1;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void updateCostPrice(String productId, double newCost) {
    if (_items.containsKey(productId)) {
      _items[productId]!.costPrice = newCost;
      notifyListeners();
    }
  }

  void updateQuantity(String productId, int newQty) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity = newQty;
      notifyListeners();
    }
  }

  void updateQuantityById(String productId, int newQty) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity = newQty;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _selectedSupplierId = null;
    notifyListeners();
  }
}

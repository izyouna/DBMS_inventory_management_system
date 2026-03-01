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

  Map<String, PurchaseOrderItem> get items => {..._items};
  List<Map<String, dynamic>> get purchaseHistory => _purchaseHistory;

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
  }

  Future<void> loadPurchaseHistory() async {
    try {
      _purchaseHistory = await DatabaseService.instance.getPurchaseOrders();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading purchase history: $e");
    }
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
    notifyListeners();
  }
}

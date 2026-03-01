import 'package:flutter/foundation.dart';
import '../models/product.dart';

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

  Map<String, PurchaseOrderItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.total;
    });
    return total;
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

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/store_item_card.dart';
import 'Cart.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _search = '';
  String _selectedCategoryLabel = 'ทั้งหมด';

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final products = productProvider.products;
    final List<String> categoryFilterLabels = ['ทั้งหมด'];
    categoryFilterLabels.addAll(productProvider.categories.map((c) => c.label));

    final filtered = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_search.toLowerCase());
      final matchesCat = _selectedCategoryLabel == 'ทั้งหมด' ? true : p.category.label == _selectedCategoryLabel;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ขายสินค้า',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // ... (Search and Chips logic remains similar, but using productProvider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้า...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final catLabel = categoryFilterLabels[index];
                final selected = catLabel == _selectedCategoryLabel;
                return ChoiceChip(
                  label: Text(catLabel, style: GoogleFonts.prompt()),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategoryLabel = catLabel),
                  selectedColor: const Color(0xFF1E2736),
                  labelStyle: GoogleFonts.prompt(color: selected ? Colors.white : Colors.black),
                  backgroundColor: Colors.white,
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: categoryFilterLabels.length,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final p = filtered[index];
                return StoreItemCard(
                  product: p,
                  inCart: cartProvider.items[p.id]?.quantity ?? 0,
                  onAdd: () => cartProvider.addItem(p),
                  onRemove: () => cartProvider.removeSingleItem(p.id),
                );
              },
            ),
          ),
          _buildCartSummary(context, cartProvider),
        ],
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ตะกร้าสินค้า', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
                Text('จำนวน ${cart.itemCount} รายการ', style: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(
            '฿${cart.totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: cart.itemCount == 0 
                ? null 
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2736),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('ชำระเงิน', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

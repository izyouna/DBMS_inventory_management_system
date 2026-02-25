import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/store_item_card.dart';

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
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final products = provider.products;
        
        final List<String> categoryFilterLabels = ['ทั้งหมด'];
        categoryFilterLabels.addAll(provider.categories.map((c) => c.label));

<<<<<<< HEAD
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
            fontSize: 24,
=======
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
            title: Text('ขายสินค้า', style: GoogleFonts.prompt(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
>>>>>>> origin/bigb
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(hintText: 'ค้นหาสินค้า...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
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
                      selectedColor: const Color.fromARGB(255, 30, 39, 54).withOpacity(0.9),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return StoreItemCard(product: p, inCart: provider.cart[p.id] ?? 0, onAdd: () => provider.addToCart(p.id), onRemove: () => provider.removeFromCart(p.id));
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ตะกร้าสินค้า', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
                          Text('จำนวน ${provider.cartCount} ชิ้น', style: GoogleFonts.prompt(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Text('฿${provider.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: provider.cart.isEmpty ? null : () {},
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2736), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text('ชำระเงิน', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

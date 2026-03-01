import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/purchase_order_provider.dart';
import '../widgets/store_item_card.dart';
import 'PurchaseOrderCart.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  String _search = '';
  String _selectedCategoryLabel = 'ทั้งหมด';

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final poProvider = Provider.of<PurchaseOrderProvider>(context);

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'สั่งซื้อสินค้าเข้าสต็อก',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้าที่ต้องการสั่งซื้อ...',
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
                final itemInPo = poProvider.items[p.id];
                return StoreItemCard(
                  product: p,
                  inCart: itemInPo?.quantity ?? 0,
                  onAdd: () => poProvider.addItem(p),
                  onRemove: () => poProvider.removeSingleItem(p.id),
                  isPurchaseOrder: true, // เพิ่มบรรทัดนี้
                );
              },
            ),
          ),
          _buildPOSummary(context, poProvider),
        ],
      ),
    );
  }

  Widget _buildPOSummary(BuildContext context, PurchaseOrderProvider po) {
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
                Text('รายการสั่งซื้อ', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
                Text('จำนวน ${po.itemCount} รายการ', style: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(
            '฿${po.totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: po.itemCount == 0 
                ? null 
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseOrderCartScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2736),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('สรุปรายการ', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

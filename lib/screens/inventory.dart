import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/inventory_item_card.dart';
import 'AddProduct.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';

  void _openAddProduct(ProductProvider provider) async {
    final newProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (newProduct != null) {
      provider.addProduct(newProduct);
    }
  }

  void _showEditDialog(ProductProvider provider, Product product) {
    final nameController = TextEditingController(text: product.name);
    final stockController = TextEditingController(text: product.stock.toString());
    final priceController = TextEditingController(text: product.price.toString());
    
    ProductUnit selectedUnit = provider.units.firstWhere((u) => u.id == product.unit.id);
    ProductCategory selectedCategory = provider.categories.firstWhere((c) => c.id == product.category.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แก้ไขสินค้า', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextField(controller: nameController, decoration: _inputDecoration('ชื่อสินค้า')),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: stockController, keyboardType: TextInputType.number, decoration: _inputDecoration('จำนวน'))),
                        const SizedBox(width: 16),
                        Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: _inputDecoration('ราคา'))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ProductCategory>(
                      value: selectedCategory,
                      items: provider.categories.map((c) => DropdownMenuItem(value: c, child: Text(c.label, style: GoogleFonts.prompt()))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => selectedCategory = v); },
                      decoration: _inputDecoration('หมวดหมู่'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ProductUnit>(
                      value: selectedUnit,
                      items: provider.units.map((u) => DropdownMenuItem(value: u, child: Text(u.label, style: GoogleFonts.prompt()))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => selectedUnit = v); },
                      decoration: _inputDecoration('หน่วย'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          provider.updateProduct(Product(
                            id: product.id,
                            name: nameController.text.trim(),
                            stock: int.tryParse(stockController.text.trim()) ?? 0,
                            price: double.tryParse(priceController.text.trim()) ?? 0.0,
                            unit: selectedUnit,
                            category: selectedCategory,
                          ));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2736), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text('บันทึกการแก้ไข', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(ProductProvider provider, Product product) {
    showDialog(
      context: context,
<<<<<<< HEAD
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ยืนยันการลบ', style: GoogleFonts.prompt()),
          content: Text(
            'ต้องการลบ "${product['name']}" ออกจากรายการหรือไม่?',
            style: GoogleFonts.prompt(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.prompt(color: Colors.grey[700]),
              ),
            ),
            TextButton(
              onPressed: () {
                if (originalIndex != -1) {
                  setState(() {
                    _products.removeAt(originalIndex);
                  });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ลบสินค้าเรียบร้อยแล้ว',
                      style: GoogleFonts.prompt(),
                    ),
                    backgroundColor: const Color(0xFF1E2736),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              child: Text(
                'ลบ',
                style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.prompt(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'สินค้า',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search),
        //     color: Colors.black,
        //     onPressed: () {},
        //   ),
        // ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E2736),
        onPressed: _openAddProduct,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้าในคลัง...',
                hintStyle: GoogleFonts.prompt(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final p = filtered[index];
                final lowStock = (p['stock'] as int) <= 3;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 226, 232, 240),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF1E2736),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] as String,
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'คงเหลือ ${p['stock']} ${p['unit']}',
                              style: GoogleFonts.prompt(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lowStock)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 254, 242, 199),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ใกล้หมด',
                                style: GoogleFonts.prompt(
                                  color:
                                      const Color.fromARGB(255, 180, 83, 9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _showEditDialog(index),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          size: 18, color: Colors.grey[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'แก้ไข',
                                        style: GoogleFonts.prompt(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showDeleteConfirm(index),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.delete_outline,
                                          size: 18, color: Color(0xFFDC2626)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ลบ',
                                        style: GoogleFonts.prompt(
                                          fontSize: 12,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: filtered.length,
            ),
          ),
=======
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการลบ', style: GoogleFonts.prompt()),
        content: Text('ต้องการลบ "${product.name}" หรือไม่?', style: GoogleFonts.prompt()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
          TextButton(onPressed: () { provider.deleteProduct(product.id); Navigator.pop(context); }, child: Text('ลบ', style: GoogleFonts.prompt(color: Colors.red))),
>>>>>>> origin/bigb
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14));

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final filtered = provider.products.where((p) => p.name.toLowerCase().contains(_search.toLowerCase())).toList();
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text('สินค้า', style: GoogleFonts.prompt(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20))),
          floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF1E2736), onPressed: () => _openAddProduct(provider), child: const Icon(Icons.add, color: Colors.white)),
          body: Column(
            children: [
              Padding(padding: const EdgeInsets.all(16), child: TextField(onChanged: (v) => setState(() => _search = v), decoration: InputDecoration(hintText: 'ค้นหา...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))),
              Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), itemBuilder: (context, index) => InventoryItemCard(product: filtered[index], onEdit: () => _showEditDialog(provider, filtered[index]), onDelete: () => _showDeleteConfirm(provider, filtered[index])), separatorBuilder: (_, __) => const SizedBox(height: 10), itemCount: filtered.length)),
            ],
          ),
        );
      },
    );
  }
}

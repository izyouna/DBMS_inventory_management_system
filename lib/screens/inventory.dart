import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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

    // ดึงรูปเดิมมาแสดงใน Provider
    provider.setImageFromPath(product.imagePath);

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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('แก้ไขสินค้า', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    
                    // ส่วนเลือกรูปในหน้าแก้ไข (Cross-platform)
                    GestureDetector(
                      onTap: () async {
                        await provider.pickImage(ImageSource.gallery);
                        setModalState(() {});
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: provider.productImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: kIsWeb
                                    ? Image.network(provider.productImage!.path, fit: BoxFit.cover)
                                    : Image.file(File(provider.productImage!.path), fit: BoxFit.cover),
                              )
                            : const Icon(Icons.add_a_photo, color: Colors.grey),
                      ),
                    ),
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
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          provider.updateProduct(Product(
                            id: product.id,
                            name: nameController.text.trim(),
                            stock: int.tryParse(stockController.text.trim()) ?? 0,
                            price: double.tryParse(priceController.text.trim()) ?? 0.0,
                            unit: selectedUnit,
                            category: selectedCategory,
                            imagePath: provider.productImage?.path,
                          ));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2736),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
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
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการลบ', style: GoogleFonts.prompt()),
        content: Text('ต้องการลบ "${product.name}" หรือไม่?', style: GoogleFonts.prompt()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
          TextButton(onPressed: () { provider.deleteProduct(product.id); Navigator.pop(context); }, child: Text('ลบ', style: GoogleFonts.prompt(color: Colors.red))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final filtered = provider.products.where((p) => p.name.toLowerCase().contains(_search.toLowerCase())).toList();
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text('สินค้า', style: GoogleFonts.prompt(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF1E2736),
            onPressed: () => _openAddProduct(provider),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'ค้นหา...', prefixIcon: const Icon(Icons.search),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) => InventoryItemCard(
                    product: filtered[index],
                    onEdit: () => _showEditDialog(provider, filtered[index]),
                    onDelete: () => _showDeleteConfirm(provider, filtered[index]),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: filtered.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

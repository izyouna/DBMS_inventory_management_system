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
  String? _selectedCategoryId;
  String? _selectedWarehouseId;

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
    final stockController = TextEditingController(
      text: product.stock.toString(),
    );
    final priceController = TextEditingController(
      text: product.price.toString(),
    );

    ProductUnit selectedUnit = provider.units.firstWhere(
      (u) => u.id == product.unit.id,
    );
    ProductCategory selectedCategory = provider.categories.firstWhere(
      (c) => c.id == product.category.id,
    );
    Warehouse? selectedWarehouse = product.warehouse != null 
      ? provider.warehouses.firstWhere((w) => w.id == product.warehouse!.id)
      : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แก้ไขสินค้า',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration('ชื่อสินค้า'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('จำนวน'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('ราคา'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ProductCategory>(
                      value: selectedCategory,
                      items: provider.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label, style: GoogleFonts.prompt()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => selectedCategory = v);
                      },
                      decoration: _inputDecoration('หมวดหมู่'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Warehouse>(
                      value: selectedWarehouse,
                      items: provider.warehouses
                          .map(
                            (w) => DropdownMenuItem(
                              value: w,
                              child: Text('${w.name} (${w.location})', style: GoogleFonts.prompt()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedWarehouse = v);
                      },
                      decoration: _inputDecoration('คลังสินค้า'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ProductUnit>(
                      value: selectedUnit,
                      items: provider.units
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.label, style: GoogleFonts.prompt()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedUnit = v);
                      },
                      decoration: _inputDecoration('หน่วย'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          provider.updateProduct(
                            Product(
                              id: product.id,
                              name: nameController.text.trim(),
                              stock:
                                  int.tryParse(stockController.text.trim()) ??
                                  0,
                              price:
                                  double.tryParse(
                                    priceController.text.trim(),
                                  ) ??
                                  0.0,
                              unit: selectedUnit,
                              category: selectedCategory,
                              warehouse: selectedWarehouse,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2736),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'บันทึกการแก้ไข',
                          style: GoogleFonts.prompt(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
        content: Text(
          'ต้องการลบ "${product.name}" หรือไม่?',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          TextButton(
            onPressed: () {
              provider.deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: Text('ลบ', style: GoogleFonts.prompt(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  InputDecoration _filterDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.prompt(fontSize: 14, color: Colors.blueGrey),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[200]!),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final filtered = provider.products.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(_search.toLowerCase());
          final matchesCategory = _selectedCategoryId == null || p.category.id == _selectedCategoryId;
          final matchesWarehouse = _selectedWarehouseId == null || p.warehouse?.id == _selectedWarehouseId;
          return matchesSearch && matchesCategory && matchesWarehouse;
        }).toList();

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
                fontSize: 20,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF1E2736),
            onPressed: () => _openAddProduct(provider),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อสินค้า...',
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
              // Filter Dropdowns
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Dropdown หมวดหมู่
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedCategoryId,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('ทุกหมวดหมู่', style: GoogleFonts.prompt(fontSize: 13)),
                          ),
                          ...provider.categories.map((cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.label, style: GoogleFonts.prompt(fontSize: 13)),
                          )),
                        ],
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                        decoration: _filterDecoration('หมวดหมู่'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Dropdown คลังสินค้า
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedWarehouseId,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('ทุกคลัง', style: GoogleFonts.prompt(fontSize: 13)),
                          ),
                          ...provider.warehouses.map((wh) => DropdownMenuItem(
                            value: wh.id,
                            child: Text(wh.name, style: GoogleFonts.prompt(fontSize: 13)),
                          )),
                        ],
                        onChanged: (v) => setState(() => _selectedWarehouseId = v),
                        decoration: _filterDecoration('คลังสินค้า'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) => InventoryItemCard(
                    product: filtered[index],
                    onEdit: () => _showEditDialog(provider, filtered[index]),
                    onDelete: () =>
                        _showDeleteConfirm(provider, filtered[index]),
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

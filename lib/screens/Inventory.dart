import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final void Function(String id, Map<String, dynamic> product) onUpdateProduct;
  final void Function(String id) onDeleteProduct;

  const InventoryScreen({
    super.key,
    required this.products,
    required this.onUpdateProduct,
    required this.onDeleteProduct,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.products;
    return widget.products
        .where((p) =>
            p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showEditDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name'].toString());
    final priceController = TextEditingController(
      text: (product['price'] as num).toStringAsFixed(0),
    );
    final quantityController = TextEditingController(
      text: (product['quantity'] as num).toString(),
    );
    String selectedUnit = product['unit'].toString();
    final units = ['ชิ้น', 'กล่อง', 'ชุด', 'ถุง', 'ขวด', 'กิโลกรัม'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'แก้ไขสินค้า',
                    style: GoogleFonts.prompt(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ชื่อสินค้า',
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration('ชื่อสินค้า'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ราคา (บาท)',
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('0'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'จำนวน',
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('0'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'หน่วย',
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: units.map((unit) {
                      final isSelected = selectedUnit == unit;
                      return ChoiceChip(
                        label: Text(unit, style: GoogleFonts.prompt()),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => selectedUnit = unit);
                          }
                        },
                        selectedColor: const Color(0xFF0891B2).withOpacity(0.2),
                        backgroundColor: Colors.grey[100],
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF0891B2)
                              : Colors.transparent,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final price = double.tryParse(priceController.text);
                        final quantity = int.tryParse(quantityController.text);

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'กรุณากรอกชื่อสินค้า',
                                style: GoogleFonts.prompt(),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (price == null || price < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'กรุณากรอกราคาที่ถูกต้อง',
                                style: GoogleFonts.prompt(),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (quantity == null || quantity < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'กรุณากรอกจำนวนที่ถูกต้อง',
                                style: GoogleFonts.prompt(),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        widget.onUpdateProduct(product['id'].toString(), {
                          'name': name,
                          'price': price,
                          'quantity': quantity,
                          'unit': selectedUnit,
                        });

                        nameController.dispose();
                        priceController.dispose();
                        quantityController.dispose();

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'แก้ไขสินค้า "$name" เรียบร้อยแล้ว',
                              style: GoogleFonts.prompt(),
                            ),
                            backgroundColor: const Color(0xFF0891B2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0891B2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'บันทึก',
                        style: GoogleFonts.prompt(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ยืนยันการลบ', style: GoogleFonts.prompt()),
        content: Text(
          'ต้องการลบ "${product['name']}" ออกจากรายการหรือไม่?',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteProduct(product['id'].toString());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ลบ "${product['name']}" เรียบร้อยแล้ว',
                    style: GoogleFonts.prompt(),
                  ),
                  backgroundColor: const Color(0xFF0891B2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: Text('ลบ', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จัดการสินค้า',
                      style: GoogleFonts.prompt(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'จัดการสต็อกสินค้าของคุณ',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาสินค้า...',
                          hintStyle: GoogleFonts.prompt(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProductCard(
                        product: product,
                        onEdit: () => _showEditDialog(product),
                        onDelete: () => _showDeleteConfirm(product),
                      ),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(20),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0891B2).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0891B2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Color(0xFF0891B2),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'คงเหลือ ${product['quantity']} ${product['unit']}',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '฿${product['price'].toStringAsFixed(0)}',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0891B2),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'แก้ไข',
                            style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                          const SizedBox(width: 4),
                          Text(
                            'ลบ',
                            style: GoogleFonts.prompt(fontSize: 12, color: Colors.red[400]),
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
      ),
    );
  }
}

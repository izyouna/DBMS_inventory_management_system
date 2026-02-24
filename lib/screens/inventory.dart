import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AddProduct.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<Map<String, dynamic>> _products = [
    {'name': 'ปุ๋ยอินทรีย์ 50kg', 'stock': 10, 'unit': 'กระสอบ'},
    {'name': 'ยาฆ่าแมลง 1L', 'stock': 3, 'unit': 'ขวด'},
    {'name': 'เมล็ดข้าวโพด 5kg', 'stock': 20, 'unit': 'ถุง'},
    {'name': 'อุปกรณ์ฉีดพ่น', 'stock': 2, 'unit': 'ชิ้น'},
  ];

  String _search = '';

  List<Map<String, dynamic>> get _filtered {
    return _products.where((p) {
      return p['name']
          .toString()
          .toLowerCase()
          .contains(_search.toLowerCase());
    }).toList();
  }

  void _openAddProduct() async {
    final newProduct = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddProductScreen(),
      ),
    );
    if (newProduct != null) {
      setState(() {
        _products.add(newProduct);
      });
    }
  }

  void _showEditDialog(int index) {
    final product = _filtered[index];
    final originalIndex =
        _products.indexWhere((p) => p['name'] == product['name'] && p['unit'] == product['unit']);

    final nameController = TextEditingController(text: product['name'] as String);
    final stockController =
        TextEditingController(text: (product['stock'] as int).toString());
    String selectedUnit = product['unit'] as String;
    final units = ['ชิ้น', 'กระสอบ', 'ขวด', 'ถุง'];

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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'แก้ไขสินค้า',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ชื่อสินค้า',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration('ชื่อสินค้า'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'จำนวนคงเหลือ',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('จำนวน'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'หน่วย',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: units.map((u) {
                        final selected = selectedUnit == u;
                        return ChoiceChip(
                          label: Text(u, style: GoogleFonts.prompt()),
                          selected: selected,
                          onSelected: (s) {
                            if (s) {
                              setModalState(() => selectedUnit = u);
                            }
                          },
                          selectedColor: const Color(0xFF1E2736),
                          backgroundColor: Colors.grey[100],
                          labelStyle: GoogleFonts.prompt(
                            color: selected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final stock = int.tryParse(stockController.text.trim());

                          if (name.isEmpty || stock == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'กรุณากรอกชื่อและจำนวนให้ถูกต้อง',
                                  style: GoogleFonts.prompt(),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          if (originalIndex != -1) {
                            setState(() {
                              _products[originalIndex] = {
                                'name': name,
                                'stock': stock,
                                'unit': selectedUnit,
                              };
                            });
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'แก้ไขสินค้าเรียบร้อยแล้ว',
                                style: GoogleFonts.prompt(),
                              ),
                              backgroundColor: const Color(0xFF1E2736),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2736),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(int index) {
    final product = _filtered[index];
    final originalIndex =
        _products.indexWhere((p) => p['name'] == product['name'] && p['unit'] == product['unit']);

    showDialog(
      context: context,
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
            fontSize: 20,
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
        ],
      ),
    );
  }
}
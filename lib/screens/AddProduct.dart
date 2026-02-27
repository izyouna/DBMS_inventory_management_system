import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/database_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();

  ProductUnit? _selectedUnit;
  ProductCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.clearImage();
    if (provider.units.isNotEmpty) _selectedUnit = provider.units[0];
    if (provider.categories.isNotEmpty)
      _selectedCategory = provider.categories[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedUnit == null ||
        _selectedCategory == null) {
      return;
    }

    final provider = Provider.of<ProductProvider>(context, listen: false);

    try {
      final name = _nameController.text.trim();
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final imagePath = provider.productImage?.path;

      final id = await DatabaseService.instance.addProduct(
        name: name,
        stock: stock,
        price: price,
        unit: _selectedUnit!.label,
        category: _selectedCategory!.label,
        imagePath: imagePath,
      );

      // สร้างอ็อบเจกต์ Product เพื่อส่งกลับไปแสดงผลทันที
      final newProduct = Product(
        id: id.toString(),
        name: name,
        stock: stock,
        price: price,
        unit: _selectedUnit!,
        category: _selectedCategory!,
        imagePath: imagePath,
      );

      if (mounted) {
        Navigator.pop(context, newProduct);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'เพิ่มสินค้าใหม่',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => provider.pickImage(ImageSource.gallery),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: provider.productImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: kIsWeb
                                ? Image.network(
                                    provider.productImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(provider.productImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'เลือกรูปภาพ',
                                style: GoogleFonts.prompt(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลสินค้า',
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('ชื่อสินค้า'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณากรอกชื่อสินค้า'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('จำนวน'),
                            validator: (v) =>
                                (v == null || int.tryParse(v) == null)
                                ? 'กรุณาระบุุจำนวน'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('ราคาขาย'),
                            validator: (v) =>
                                (v == null || double.tryParse(v) == null)
                                ? 'กรุณาระบุุตัวเลขราคา'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<ProductCategory>(
                      value: _selectedCategory,
                      items: provider.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label, style: GoogleFonts.prompt()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      decoration: _inputDecoration('หมวดหมู่'),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<ProductUnit>(
                      value: _selectedUnit,
                      items: provider.units
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.label, style: GoogleFonts.prompt()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v),
                      decoration: _inputDecoration('หน่วย'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2736),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'บันทึกสินค้า',
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
}

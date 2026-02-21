import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProductScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> product) onProductAdded;

  const AddProductScreen({super.key, required this.onProductAdded});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedUnit = 'ชิ้น';

  final List<String> _units = ['ชิ้น', 'กล่อง', 'ชุด', 'ถุง', 'ขวด', 'กิโลกรัม'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final product = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'unit': _selectedUnit,
      };
      widget.onProductAdded(product);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เพิ่มสินค้า "${_nameController.text}" เรียบร้อยแล้ว',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: const Color(0xFF0891B2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _nameController.clear();
      _priceController.clear();
      _quantityController.clear();
      setState(() => _selectedUnit = 'ชิ้น');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0891B2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF0891B2),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เพิ่มสินค้า',
                            style: GoogleFonts.prompt(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'กรอกข้อมูลสินค้าใหม่',
                            style: GoogleFonts.prompt(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildInputCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('ชื่อสินค้า'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('ตัวอย่าง: สินค้า A'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('ราคา (บาท)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('0'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกราคา';
                          if (double.tryParse(v) == null) return 'กรุณากรอกตัวเลข';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('จำนวน'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('0'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกจำนวน';
                          if (int.tryParse(v) == null) return 'กรุณากรอกตัวเลข';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('หน่วย'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _units.map((unit) {
                          final isSelected = _selectedUnit == unit;
                          return ChoiceChip(
                            label: Text(unit, style: GoogleFonts.prompt()),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedUnit = unit);
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
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'เพิ่มสินค้า',
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.prompt(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.prompt(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: child,
    );
  }
}

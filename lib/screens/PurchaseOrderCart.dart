import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_order_provider.dart';
import '../providers/product_provider.dart';

class PurchaseOrderCartScreen extends StatefulWidget {
  const PurchaseOrderCartScreen({super.key});

  @override
  State<PurchaseOrderCartScreen> createState() => _PurchaseOrderCartScreenState();
}

class _PurchaseOrderCartScreenState extends State<PurchaseOrderCartScreen> {
  File? _billImage;
  final ImagePicker _picker = ImagePicker();
  String _paymentMethod = 'Cash'; // 'Cash' หรือ 'Credit'

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _billImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final poProvider = Provider.of<PurchaseOrderProvider>(context);
    final items = poProvider.items.values.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('สรุปรายการสั่งซื้อ', 
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildBillImageSection(),
          Expanded(
            child: ListView(
              children: [
                const Divider(thickness: 8, color: Color(0xFFF5F6FA)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return _buildOrderItem(item, poProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildSummary(context, poProvider),
        ],
      ),
    );
  }

  Widget _buildBillImageSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('หลักฐานใบเสร็จ / บิลสั่งซื้อ', 
            style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showImageSourceSheet(),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: _billImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_billImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 30, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('คลิกเพื่อเพิ่มรูปภาพบิล', 
                          style: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text('วิธีการชำระเงิน', 
            style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text('เงินสด', style: GoogleFonts.prompt())),
                  selected: _paymentMethod == 'Cash',
                  onSelected: (selected) {
                    if (selected) setState(() => _paymentMethod = 'Cash');
                  },
                  selectedColor: const Color(0xFF1E2736),
                  labelStyle: GoogleFonts.prompt(
                    color: _paymentMethod == 'Cash' ? Colors.white : Colors.black
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text('ค้างชำระ (เครดิต)', style: GoogleFonts.prompt())),
                  selected: _paymentMethod == 'Credit',
                  onSelected: (selected) {
                    if (selected) setState(() => _paymentMethod = 'Credit');
                  },
                  selectedColor: Colors.orange[800],
                  labelStyle: GoogleFonts.prompt(
                    color: _paymentMethod == 'Credit' ? Colors.white : Colors.black
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('เลือกแหล่งที่มาของรูปภาพ', 
              style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('ถ่ายรูปจากกล้อง', style: GoogleFonts.prompt()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('เลือกจากคลังภาพ', style: GoogleFonts.prompt()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(PurchaseOrderItem item, PurchaseOrderProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูปสินค้า (เล็กๆ)
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 226, 232, 240),
              borderRadius: BorderRadius.circular(10),
            ),
            child: item.product.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(item.product.imagePath!,
                            key: ValueKey(item.product.imagePath!),
                            fit: BoxFit.cover)
                        : Image.file(File(item.product.imagePath!),
                            key: ValueKey(item.product.imagePath!),
                            fit: BoxFit.cover),
                  )
                : const Icon(Icons.image_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, 
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                Text('สต็อกปัจจุบัน: ${item.product.stock}', 
                  style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('ทุนต่อหน่วย:', style: GoogleFonts.prompt(fontSize: 13)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      height: 35,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.prompt(fontSize: 13),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          hintText: item.costPrice.toString(),
                        ),
                        onChanged: (v) {
                          final cost = double.tryParse(v);
                          if (cost != null) provider.updateCostPrice(item.product.id, cost);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => provider.removeSingleItem(item.product.id),
                  ),
                  Text('${item.quantity}', 
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => provider.addItem(item.product),
                  ),
                ],
              ),
              Text('฿${item.total.toStringAsFixed(2)}', 
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, PurchaseOrderProvider po) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, 
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ยอดเงินลงทุนรวม', style: GoogleFonts.prompt(fontSize: 16)),
              Text('฿${po.totalAmount.toStringAsFixed(2)}', 
                style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[700])),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: po.itemCount == 0 ? null : () => _confirmPurchase(context, po),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2736),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('ยืนยันการนำสินค้าเข้าสต็อก', 
                style: GoogleFonts.prompt(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPurchase(BuildContext context, PurchaseOrderProvider po) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการสั่งซื้อ', style: GoogleFonts.prompt()),
        content: Text('ระบบจะทำการเพิ่มจำนวนสินค้าเข้าสต็อกตามรายการที่เลือก ยืนยันหรือไม่?', 
          style: GoogleFonts.prompt()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
          TextButton(
            onPressed: () async {
              for (var item in po.items.values) {
                final currentProduct = item.product;
                productProvider.updateProduct(
                  currentProduct..stock = currentProduct.stock + item.quantity
                );
              }
              po.clear();
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('นำสินค้าเข้าสต็อกสำเร็จ!', style: GoogleFonts.prompt()), backgroundColor: Colors.green),
              );
            },
            child: Text('ยืนยัน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

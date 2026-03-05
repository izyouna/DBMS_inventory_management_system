import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_order_provider.dart';
import '../providers/product_provider.dart';
import '../services/database_service.dart';

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
          Expanded(
            child: ListView(
              children: [
                _buildSupplierSection(poProvider),
                const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                _buildBillImageSection(),
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

  Widget _buildSupplierSection(PurchaseOrderProvider poProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ผู้จัดจำหน่าย (Supplier)', 
                style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _showAddSupplierDialog(poProvider),
                icon: const Icon(Icons.add, size: 18),
                label: Text('เพิ่มใหม่', style: GoogleFonts.prompt(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text('เลือกผู้จัดจำหน่าย', style: GoogleFonts.prompt()),
                value: poProvider.selectedSupplierId,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('ไม่ระบุผู้จัดจำหน่าย', style: GoogleFonts.prompt()),
                  ),
                  ...poProvider.suppliers.map((s) {
                    return DropdownMenuItem<String>(
                      value: s['SupplierID'],
                      child: Text(s['SupplierName'], style: GoogleFonts.prompt()),
                    );
                  }).toList(),
                ],
                onChanged: (val) => poProvider.selectSupplier(val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog(PurchaseOrderProvider provider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('เพิ่มผู้จัดจำหน่าย', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อผู้จัดจำหน่าย',
                labelStyle: GoogleFonts.prompt(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                labelStyle: GoogleFonts.prompt(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await provider.addSupplier(nameController.text, phoneController.text);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: Text('บันทึก', style: GoogleFonts.prompt()),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูปสินค้า
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 226, 232, 240),
              borderRadius: BorderRadius.circular(10),
            ),
            child: item.product.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(item.product.imagePath!, fit: BoxFit.cover)
                        : Image.file(File(item.product.imagePath!), fit: BoxFit.cover),
                  )
                : const Icon(Icons.image_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          // ข้อมูลสินค้า
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('สต็อกปัจจุบัน: ${item.product.stock}', 
                  style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('ทุน:', style: GoogleFonts.prompt(fontSize: 12)),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 70,
                      height: 30,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.prompt(fontSize: 12),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          hintText: item.costPrice.toStringAsFixed(0),
                        ),
                        onChanged: (v) {
                          final cost = double.tryParse(v);
                          if (cost != null) provider.updateCostPrice(item.product.id, cost);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('จำนวน:', style: GoogleFonts.prompt(fontSize: 12)),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 50,
                      height: 30,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          hintText: item.quantity.toString(),
                        ),
                        onChanged: (v) {
                          final qty = int.tryParse(v);
                          if (qty != null && qty > 0) {
                            provider.updateQuantity(item.product.id, qty);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ยอดรวมและปุ่มลบ
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => provider.removeSingleItem(item.product.id),
              ),
              const SizedBox(height: 8),
              Text('฿${item.total.toStringAsFixed(2)}', 
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14)),
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
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการสั่งซื้อ', style: GoogleFonts.prompt()),
        content: Text('ระบบจะทำการเพิ่มจำนวนสินค้าเข้าสต็อกและบันทึกข้อมูลการสั่งซื้อ ยืนยันหรือไม่?', 
          style: GoogleFonts.prompt()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
          TextButton(
            onPressed: () async {
              final poProvider = Provider.of<PurchaseOrderProvider>(context, listen: false);
              try {
                // 1. เตรียมข้อมูลสำหรับบันทึกลงฐานข้อมูล
                final List<Map<String, dynamic>> itemsToSave = po.items.values.map((item) {
                  return {
                    'ProductID': item.product.id,
                    'UnitPrice': item.costPrice,
                    'Quantity': item.quantity,
                  };
                }).toList();

                // 2. บันทึกลงตาราง PurchaseOrder และ PurchaseDetail
                // และอัปเดตสต็อกในฐานข้อมูล (จัดการใน DatabaseService.savePurchaseOrder)
                await DatabaseService.instance.savePurchaseOrder(
                  receiveDate: DateTime.now().toIso8601String(),
                  totalCost: po.totalAmount,
                  items: itemsToSave,
                  billImagePath: _billImage?.path, // ส่งพาธรูปภาพบิล
                  purchaseType: _paymentMethod == 'Cash' ? 'เงินสด' : 'ค้างชำระ (เครดิต)', // กำหนดประเภท
                  paymentStatus: _paymentMethod == 'Cash' ? 'Paid' : 'Pending', // ส่งสถานะการชำระเงิน
                  supplierId: poProvider.selectedSupplierId,
                );

                // 3. รีโหลดข้อมูลสินค้าใน Provider เพื่อให้ UI อัปเดตสต็อกล่าสุด
                await productProvider.loadProductsFromDatabase();
                await poProvider.loadPurchaseHistory();

                po.clear();
                
                if (!mounted) return;
                Navigator.pop(ctx); // ปิด Dialog
                Navigator.pop(context); // ออกจากหน้ารถเข็น
                Navigator.pop(context); // ออกจากหน้าเลือกสินค้า

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('นำสินค้าเข้าสต็อกและบันทึกข้อมูลสำเร็จ!', style: GoogleFonts.prompt()), 
                    backgroundColor: Colors.green
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()), 
                    backgroundColor: Colors.red
                  ),
                );
              }
            },
            child: Text('ยืนยัน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

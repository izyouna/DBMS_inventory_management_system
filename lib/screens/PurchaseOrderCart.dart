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
  XFile? _billFile;
  final ImagePicker _picker = ImagePicker();
  String _paymentMethod = 'Cash'; // 'Cash' หรือ 'Credit'
  bool _autoUpdatePrices = true; // อัปเดตราคาขายในระบบตามต้นทุนใหม่โดยอัตโนมัติหรือไม่
  DateTime? _dueDate; // วันครบกำหนดชำระ (สำหรับเครดิต)

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
          _billFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E2736),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
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
                _buildOptionsSection(),
                const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
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
                      value: s['supplier_id'],
                      child: Text(s['supplier_name'], style: GoogleFonts.prompt()),
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
              child: _billFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb 
                        ? Image.network(_billFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_billFile!.path), fit: BoxFit.cover),
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
                    if (selected) {
                      setState(() {
                        _paymentMethod = 'Credit';
                        // กำหนด Due Date เริ่มต้นเป็น 30 วันข้างหน้าถ้ายังไม่ได้เลือก
                        _dueDate ??= DateTime.now().add(const Duration(days: 30));
                      });
                    }
                  },
                  selectedColor: Colors.orange[800],
                  labelStyle: GoogleFonts.prompt(
                    color: _paymentMethod == 'Credit' ? Colors.white : Colors.black
                  ),
                ),
              ),
            ],
          ),
          if (_paymentMethod == 'Credit') ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDueDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.orange[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('วันครบกำหนดชำระ', 
                            style: GoogleFonts.prompt(fontSize: 12, color: Colors.orange[900])),
                          Text(
                            _dueDate == null 
                                ? 'กรุณาเลือกวันที่' 
                                : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year + 543}',
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.orange[900]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit, size: 18, color: Colors.orange[800]),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('อัปเดตราคาขายอัตโนมัติ', 
                  style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('ปรับราคาขายในระบบตามต้นทุนใหม่และ Markup %', 
                  style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: _autoUpdatePrices, 
            onChanged: (v) => setState(() => _autoUpdatePrices = v),
            activeColor: Colors.blue,
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
    // คำนวณราคาขายที่แนะนำจาก Markup % ของสินค้านั้น
    final suggestedPrice = item.costPrice * (1 + (item.product.markupPercentage / 100));

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
                Row(
                  children: [
                    Text('ราคาขายเดิม: ฿${item.product.price.toStringAsFixed(0)}', 
                      style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                      child: Text('Markup: ${item.product.markupPercentage.toStringAsFixed(0)}%', 
                        style: GoogleFonts.prompt(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ทุนใหม่:', style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[700])),
                        SizedBox(
                          width: 80,
                          height: 32,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            controller: TextEditingController(text: item.costPrice.toStringAsFixed(0))
                              ..selection = TextSelection.fromPosition(TextPosition(offset: item.costPrice.toStringAsFixed(0).length)),
                            onChanged: (v) {
                              final cost = double.tryParse(v);
                              if (cost != null) provider.updateCostPrice(item.product.id, cost);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('จำนวน:', style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[700])),
                        SizedBox(
                          width: 60,
                          height: 32,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            controller: TextEditingController(text: item.quantity.toString())
                              ..selection = TextSelection.fromPosition(TextPosition(offset: item.quantity.toString().length)),
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
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ราคาขายใหม่ที่แนะนำ:', style: GoogleFonts.prompt(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.bold)),
                        Text('฿${suggestedPrice.toStringAsFixed(2)}', 
                          style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green[700])),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => provider.removeSingleItem(item.product.id),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ระบบจะทำการเพิ่มจำนวนสินค้าเข้าสต็อกและบันทึกข้อมูลการสั่งซื้อ ยืนยันหรือไม่?', 
              style: GoogleFonts.prompt()),
            if (_autoUpdatePrices) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('ระบบจะอัปเดตราคาขายของสินค้าในร้านตามต้นทุนใหม่โดยอัตโนมัติ', 
                        style: GoogleFonts.prompt(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
          TextButton(
            onPressed: () async {
              final poProvider = Provider.of<PurchaseOrderProvider>(context, listen: false);
              try {
                // 1. เตรียมข้อมูลสำหรับบันทึกลงฐานข้อมูล
                final List<Map<String, dynamic>> itemsToSave = po.items.values.map((item) {
                  return {
                    'productid': item.product.id,
                    'unitprice': item.costPrice,
                    'quantity': item.quantity,
                  };
                }).toList();

                // 2. Upload Bill Image if exists
                String? billUrl;
                if (_billFile != null) {
                  billUrl = await DatabaseService.instance.uploadBillImage(_billFile!);
                }

                // 3. บันทึกลงตาราง PurchaseOrder และ PurchaseDetail
                await DatabaseService.instance.savePurchaseOrder(
                  receiveDate: DateTime.now().toIso8601String(),
                  totalCost: po.totalAmount,
                  items: itemsToSave,
                  billImagePath: billUrl, 
                  ptId: _paymentMethod == 'Cash' ? 'PT1' : 'PT2', 
                  paymentStatus: _paymentMethod == 'Cash' ? 'Paid' : 'Pending', 
                  supplierId: poProvider.selectedSupplierId,
                  dueDate: _paymentMethod == 'Credit' ? _dueDate?.toIso8601String() : null,
                );

                // 4. อัปเดตราคาขายในตาราง Product หากเลือก Auto Update
                if (_autoUpdatePrices) {
                  for (var item in po.items.values) {
                    final newSuggestedPrice = item.costPrice * (1 + (item.product.markupPercentage / 100));
                    await DatabaseService.instance.updateProduct(
                      id: item.product.id,
                      name: item.product.name,
                      categoryId: item.product.category.id,
                      stock: item.product.stock + item.quantity, // อัปเดตสต็อกรวม
                      price: newSuggestedPrice, // ใช้ราคาใหม่ที่แนะนำ
                      unitId: item.product.unit.id,
                      imagePath: item.product.imagePath,
                      warehouseId: item.product.warehouse?.id,
                    );
                  }
                }

                // 5. รีโหลดข้อมูลสินค้าใน Provider เพื่อให้ UI อัปเดตสต็อกล่าสุด
                await productProvider.loadProductsFromDatabase();
                await poProvider.loadPurchaseHistory();

                po.clear();
                
                if (!mounted) return;
                Navigator.pop(ctx); // ปิด Dialog
                Navigator.pop(context, true); // ออกจากหน้ารถเข็น พร้อมส่งผลลัพธ์สำเร็จ

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

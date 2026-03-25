import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_order_provider.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PurchaseOrderProvider>(
        context,
        listen: false,
      ).loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final poProvider = Provider.of<PurchaseOrderProvider>(context);
    final suppliers = poProvider.suppliers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          'รายชื่อผู้จัดจำหน่าย',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: suppliers.isEmpty
          ? Center(
              child: Text(
                'ยังไม่มีข้อมูลผู้จัดจำหน่าย',
                style: GoogleFonts.prompt(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: suppliers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: const Icon(Icons.business, color: Colors.blue),
                    ),
                    title: Text(
                      supplier['supplier_name'] ?? 'ไม่ระบุชื่อ',
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'เบอร์โทร: ${supplier['phone'] ?? '-'}',
                      style: GoogleFonts.prompt(color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                      onPressed: () => _showEditSupplierDialog(
                        context,
                        poProvider,
                        supplier,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplierDialog(context, poProvider),
        backgroundColor: const Color(0xFF1E2736),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'เพิ่มผู้จัดจำหน่าย',
          style: GoogleFonts.prompt(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddSupplierDialog(
    BuildContext context,
    PurchaseOrderProvider provider,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'เพิ่มผู้จัดจำหน่าย',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
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
            const SizedBox(height: 16),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await provider.addSupplier(
                  nameController.text,
                  phoneController.text,
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2736),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'บันทึก',
              style: GoogleFonts.prompt(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSupplierDialog(
    BuildContext context,
    PurchaseOrderProvider provider,
    Map<String, dynamic> supplier,
  ) {
    final nameController = TextEditingController(
      text: supplier['supplier_name'],
    );
    final phoneController = TextEditingController(text: supplier['phone']);
    final String supplierId = supplier['supplier_id'].toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'แก้ไขผู้จัดจำหน่าย',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
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
            const SizedBox(height: 16),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await provider.updateSupplier(
                  supplierId,
                  nameController.text,
                  phoneController.text,
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2736),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'บันทึก',
              style: GoogleFonts.prompt(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

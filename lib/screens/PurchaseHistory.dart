import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_order_provider.dart';
import '../providers/product_provider.dart';
import '../services/database_service.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  String _selectedFilter = 'ทั้งหมด';
  final List<String> _filters = ['ทั้งหมด', 'เงินสด', 'ค้างชำระ'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PurchaseOrderProvider>(context, listen: false).loadPurchaseHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final poProvider = Provider.of<PurchaseOrderProvider>(context);
    
    final filteredHistory = poProvider.purchaseHistory.where((po) {
      if (_selectedFilter == 'ทั้งหมด') return true;
      if (_selectedFilter == 'เงินสด') return po['PTID'] == 'PT1';
      if (_selectedFilter == 'ค้างชำระ') return po['PTID'] == 'PT2';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ประวัติใบสั่งซื้อ',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter, style: GoogleFonts.prompt(fontSize: 13)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                    selectedColor: const Color(0xFF1E2736),
                    labelStyle: GoogleFonts.prompt(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    backgroundColor: const Color(0xFFF5F6FA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Text(
                      'ไม่พบประวัติการสั่งซื้อ',
                      style: GoogleFonts.prompt(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final po = filteredHistory[index];
                      final date = DateTime.parse(po['ReceiveDate']);
                      final status = po['Status'] ?? 'Confirmed';
                      final payStatus = po['PaymentStatus'] ?? 'Paid';
                      final isConfirmed = status == 'Confirmed';
                      final isPaid = payStatus == 'Paid';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () => _showPODetails(context, po),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'PO ID: ${po['POID']}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 4),
                              _buildStatusBadge(
                                isConfirmed ? 'ยืนยันแล้ว' : 'ยกเลิกแล้ว',
                                isConfirmed ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              _buildStatusBadge(
                                isPaid ? 'ชำระแล้ว' : 'ค้างชำระ',
                                isPaid ? Colors.blue : Colors.orange,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วันที่: ${date.toString().split('.')[0]}',
                                style: GoogleFonts.prompt(fontSize: 12),
                              ),
                              if (po['supplier'] != null)
                                Text(
                                  'ผู้จัดจำหน่าย: ${po['supplier']['Supplier_Name']}',
                                  style: GoogleFonts.prompt(fontSize: 11, color: Colors.blueGrey),
                                ),
                              Text(
                                'ประเภท: ${po['PTName'] ?? 'ไม่ระบุ'}',
                                style: GoogleFonts.prompt(fontSize: 11, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '฿${(po['TotalCost'] as num).toStringAsFixed(2)}',
                                style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.prompt(
          fontSize: 9, 
          color: color,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  void _showPODetails(BuildContext context, Map<String, dynamic> po) async {
    final poProvider = Provider.of<PurchaseOrderProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final items = await poProvider.getPurchaseOrderDetails(po['POID']);
    final paymentHistory = await poProvider.getPaymentHistory(po['POID']);
    
    if (!mounted) return;
    Navigator.pop(context);

    final status = po['Status'] ?? 'Confirmed';
    final payStatus = po['PaymentStatus'] ?? 'Paid';
    final isConfirmed = status == 'Confirmed';
    final isPaid = payStatus == 'Paid';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('รายละเอียดใบสั่งซื้อ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(isConfirmed ? 'ยืนยันแล้ว' : 'ยกเลิกแล้ว', isConfirmed ? Colors.green : Colors.red),
                    const SizedBox(height: 4),
                    _buildStatusBadge(isPaid ? 'ชำระแล้ว' : 'ค้างชำระ', isPaid ? Colors.blue : Colors.orange),
                  ],
                ),
              ],
            ),
            Text(po['POID'], style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey)),
            if (po['supplier'] != null)
              Text('ผู้จัดจำหน่าย: ${po['supplier']['Supplier_Name']}', style: GoogleFonts.prompt(fontSize: 12, color: Colors.blueGrey)),
            Text('ประเภทการชำระ: ${po['PTName'] ?? '-'}', style: GoogleFonts.prompt(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text('รายการสินค้า', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14)),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('ไม่พบรายการสินค้า', style: GoogleFonts.prompt(color: Colors.grey)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['ProductName'] ?? 'Unknown', style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('ต้นทุนต่อหน่วย: ฿${(item['UnitPrice'] as num).toStringAsFixed(2)}', 
                                    style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('x${item['Quantity']}', style: GoogleFonts.prompt(fontSize: 14), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('฿${((item['UnitPrice'] as num) * (item['Quantity'] as num)).toStringAsFixed(2)}', 
                                style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const Divider(),
                if (po['BillImagePath'] != null) ...[
                  const SizedBox(height: 8),
                  Text('หลักฐานใบเสร็จ / บิล', style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final url = await DatabaseService.instance.getSignedUrl(po['BillImagePath']);
                      if (context.mounted && url != null) {
                        _showFullScreenImage(context, url);
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: po['BillImagePath'].startsWith('http') || kIsWeb
                            ? Image.network(po['BillImagePath'], fit: BoxFit.cover)
                            : FutureBuilder<String?>(
                                future: DatabaseService.instance.getSignedUrl(po['BillImagePath']),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.network(snapshot.data!, fit: BoxFit.cover);
                                  }
                                  return const Center(child: CircularProgressIndicator());
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                ],
                
                // ประวัติการชำระเงิน (สำหรับบิลเครดิต)
                if (paymentHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('ประวัติการชำระเงิน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue[800])),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paymentHistory.length,
                    itemBuilder: (ctx, i) {
                      final pay = paymentHistory[i];
                      final payDate = DateTime.parse(pay['PaidDate']);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('฿${(pay['AmountPaid'] as num).toStringAsFixed(2)}', 
                                  style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(payDate.toString().split('.')[0], style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            if (pay['PaidImagePath'] != null)
                              IconButton(
                                icon: const Icon(Icons.image_outlined, size: 20, color: Colors.blue),
                                onPressed: () async {
                                  final url = await DatabaseService.instance.getSignedUrl(pay['PaidImagePath']);
                                  if (context.mounted && url != null) {
                                    _showFullScreenImage(context, url);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ยอดรวมต้นทุน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('฿${(po['TotalCost'] as num).toStringAsFixed(2)}', 
                      style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  ],
                ),
                if (!isPaid) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ชำระแล้วสะสม', style: GoogleFonts.prompt(fontSize: 14, color: Colors.green[700])),
                      Text('฿${(po['PaidAmount'] as num).toStringAsFixed(2)}', 
                        style: GoogleFonts.prompt(fontSize: 14, color: Colors.green[700])),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ยอดคงเหลือ', style: GoogleFonts.prompt(fontSize: 14, color: Colors.red)),
                      Text('฿${((po['TotalCost'] as num) - (po['PaidAmount'] as num)).toStringAsFixed(2)}', 
                        style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (isConfirmed)
            TextButton(
              onPressed: () => _confirmCancelPurchase(context, po['POID'], poProvider, productProvider),
              child: Text('ยกเลิกใบสั่งซื้อ', style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelPurchase(BuildContext context, String poId, PurchaseOrderProvider poProvider, ProductProvider productProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการยกเลิก', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการยกเลิกใบสั่งซื้อนี้ใช่หรือไม่? ระบบจะทำการหักจำนวนสินค้าที่เคยนำเข้าออกจากสต็อกโดยอัตโนมัติ', 
          style: GoogleFonts.prompt()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ไม่ยกเลิก', style: GoogleFonts.prompt())),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); 
              Navigator.pop(context); 
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );

              final success = await DatabaseService.instance.cancelPurchaseOrder(poId);
              
              if (!mounted) return;
              Navigator.pop(context); 

              if (success) {
                await poProvider.loadPurchaseHistory();
                await productProvider.loadProductsFromDatabase();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ยกเลิกใบสั่งซื้อและหักสต็อกคืนสำเร็จ', style: GoogleFonts.prompt()), backgroundColor: Colors.orange),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ไม่สามารถยกเลิกได้', style: GoogleFonts.prompt()), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('ยืนยันยกเลิก', style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: kIsWeb
                  ? Image.network(imagePath)
                  : Image.file(File(imagePath)),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

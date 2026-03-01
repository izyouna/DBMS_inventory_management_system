import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/pdf_service.dart';

class DebtReportScreen extends StatelessWidget {
  const DebtReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text('รายการค้างชำระ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF1E2736),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E2736),
            labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'ลูกหนี้ (เงินเข้า)', icon: Icon(Icons.person_outline)),
              Tab(text: 'เจ้าหนี้ (เงินออก)', icon: Icon(Icons.business_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DebtorListView(),
            CreditorListView(),
          ],
        ),
      ),
    );
  }
}

class DebtorListView extends StatelessWidget {
  const DebtorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final unpaidOrders = Provider.of<CartProvider>(context).unpaidOrders;

    return unpaidOrders.isEmpty
        ? Center(child: Text('ไม่มีรายการลูกหนี้ค้างชำระ', style: GoogleFonts.prompt()))
        : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: unpaidOrders.length,
            itemBuilder: (ctx, i) {
              final order = unpaidOrders[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(order.customer?.name ?? 'ไม่ระบุชื่อ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                  subtitle: Text('วันที่: ${order.dateTime.toString().split('.')[0]}', style: GoogleFonts.prompt()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('฿${order.totalAmount}', style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold)),
                          Text('ค้างชำระ', style: GoogleFonts.prompt(fontSize: 10, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.payment, color: Colors.green),
                        onPressed: () {
                          _showPayConfirmDialog(context, order.id, order.totalAmount, order.customer?.name ?? 'ไม่ระบุชื่อ');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  void _showPayConfirmDialog(BuildContext context, String orderId, double amount, String customerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการชำระหนี้', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: Text(
          'ลูกหนี้: $customerName\nยอดชำระ: ฿$amount\n\nยืนยันว่าได้รับชำระเงินเรียบร้อยแล้วใช่หรือไม่?',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).payDebt(orderId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('บันทึกการชำระหนี้สำเร็จ', style: GoogleFonts.prompt())),
              );
            },
            child: Text('ยืนยันชำระเงิน', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class CreditorListView extends StatelessWidget {
  const CreditorListView({super.key});

  @override
  Widget build(BuildContext context) {
    // ปัจจุบันระบบยังไม่ได้บันทึกประวัติใบสั่งซื้อลง DB จริงๆ
    // ส่วนนี้จึงแสดงเป็นหน้าว่างไปก่อน
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'ไม่มีรายการเจ้าหนี้ค้างชำระ',
            style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'รายการสั่งซื้อแบบ "ค้างชำระ" จะปรากฏที่นี่',
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}

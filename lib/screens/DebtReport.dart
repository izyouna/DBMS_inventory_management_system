import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/pdf_service.dart';

class DebtReportScreen extends StatelessWidget {
  const DebtReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unpaidOrders = Provider.of<CartProvider>(context).unpaidOrders;

    return Scaffold(
      appBar: AppBar(
        title: Text('ยอดค้างชำระ (ขายเชื่อ)', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: unpaidOrders.isEmpty
          ? Center(child: Text('ไม่มีรายการค้างชำระ', style: GoogleFonts.prompt()))
          : ListView.builder(
              itemCount: unpaidOrders.length,
              itemBuilder: (ctx, i) {
                final order = unpaidOrders[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          icon: const Icon(Icons.print, color: Colors.blueGrey),
                          onPressed: () => PdfService.printOrder(order),
                        ),
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
            ),
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

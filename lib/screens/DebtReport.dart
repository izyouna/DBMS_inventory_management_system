import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

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
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('฿${order.totalAmount}', style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold)),
                        Text('ค้างชำระ', style: GoogleFonts.prompt(fontSize: 10, color: Colors.orange)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

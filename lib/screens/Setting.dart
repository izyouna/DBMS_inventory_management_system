import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'PurchaseOrder.dart';
import 'PurchaseHistory.dart';
import 'Suppliers.dart';
import 'CustomerCredit.dart'; // นำเข้าหน้าจอใหม่

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.inventory_2, 'title': 'รับสินค้า'},
      {'icon': Icons.history, 'title': 'ประวัติการรับสินค้า'},
      {'icon': Icons.business, 'title': 'ผู้จัดจำหน่าย'},
      {'icon': Icons.group_outlined, 'title': 'จัดการวงเงินลูกค้า'}, // เมนูใหม่
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ตั้งค่า',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = items[index];
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
              leading: CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 226, 232, 240),
                child: Icon(
                  item['icon'] as IconData,
                  color: const Color(0xFF1E2736),
                ),
              ),
              title: Text(
                item['title'] as String,
                style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (item['title'] == 'รับสินค้า') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseOrderScreen(),
                    ),
                  );
                } else if (item['title'] == 'ประวัติการรับสินค้า') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseHistoryScreen(),
                    ),
                  );
                } else if (item['title'] == 'ผู้จัดจำหน่าย') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuppliersScreen(),
                    ),
                  );
                } else if (item['title'] == 'จัดการวงเงินลูกค้า') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerCreditScreen(),
                    ),
                  );
                }
              },
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: items.length,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.storefront, 'title': 'ข้อมูลร้านค้า'},
      {'icon': Icons.receipt_long, 'title': 'รูปแบบใบเสร็จ'},
      {'icon': Icons.payments_outlined, 'title': 'ช่องทางการชำระเงิน'},
      {'icon': Icons.account_circle_outlined, 'title': 'ผู้ใช้งานระบบ'},
      {'icon': Icons.lock_outline, 'title': 'ความปลอดภัย'},
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
                backgroundColor:
                    const Color.fromARGB(255, 226, 232, 240),
                child: Icon(item['icon'] as IconData,
                    color: const Color(0xFF1E2736)),
              ),
              title: Text(
                item['title'] as String,
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // ไว้ต่อยอดหน้า setting ย่อยทีหลัง
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
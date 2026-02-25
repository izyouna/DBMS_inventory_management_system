import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final now = DateTime.now();

    final todayOrders = cartProvider.orders.where((o) => 
        o.dateTime.day == now.day && 
        o.dateTime.month == now.month && 
        o.dateTime.year == now.year).toList();

    final monthOrders = cartProvider.orders.where((o) => 
        o.dateTime.month == now.month && 
        o.dateTime.year == now.year).toList();

    final todaySales = todayOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final monthSales = monthOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final unpaidTotal = cartProvider.unpaidOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'รายงานสรุปผล',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(
            title: 'ยอดขายวันนี้',
            value: '฿${todaySales.toStringAsFixed(2)}',
            color: Colors.green,
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            title: 'ยอดขายเดือนนี้',
            value: '฿${monthSales.toStringAsFixed(2)}',
            color: Colors.blue,
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            title: 'จำนวนบิลวันนี้',
            value: '${todayOrders.length} บิล',
            color: Colors.orange,
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            title: 'ยอดลูกหนี้คงค้าง',
            value: '฿${unpaidTotal.toStringAsFixed(2)}',
            color: Colors.red,
            icon: Icons.person_search_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.prompt(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }
    }
    
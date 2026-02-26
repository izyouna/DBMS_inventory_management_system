import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedFilter = 'ทั้งหมด';
  final List<String> _filters = ['ทั้งหมด', 'เงินสด', 'QR Code / โอนเงิน', 'ขายเชื่อ (ค้างชำระ)', 'ชำระหนี้แล้ว'];

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

    final filteredOrders = _selectedFilter == 'ทั้งหมด'
        ? cartProvider.orders
        : cartProvider.orders.where((o) => o.paymentMethod == _selectedFilter).toList();

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
      body: Column(
        children: [
          Expanded(
            child: ListView(
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
                  title: 'ยอดลูกหนี้คงค้าง',
                  value: '฿${unpaidTotal.toStringAsFixed(2)}',
                  color: Colors.red,
                  icon: Icons.person_search_outlined,
                ),
                const SizedBox(height: 24),
                Text(
                  'ประวัติการซื้อขาย',
                  style: GoogleFonts.prompt(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter, style: GoogleFonts.prompt(fontSize: 12)),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        selectedColor: Colors.blue.withOpacity(0.2),
                        checkmarkColor: Colors.blue,
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (filteredOrders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text('ไม่พบข้อมูล', style: GoogleFonts.prompt(color: Colors.grey)),
                    ),
                  )
                else
                  ...filteredOrders.reversed.map((order) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        'บิล: ${order.id}',
                        style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.dateTime.toString().split('.')[0]} | ${order.paymentMethod}',
                            style: GoogleFonts.prompt(fontSize: 12),
                          ),
                          if (order.customer != null)
                            Text(
                              'ลูกค้า: ${order.customer!.name}',
                              style: GoogleFonts.prompt(fontSize: 12, color: Colors.blue),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '฿${order.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold,
                          color: order.isPaid ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  )).toList(),
              ],
            ),
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

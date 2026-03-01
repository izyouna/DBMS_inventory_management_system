import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text(
            "ร้านเกษตรภัณฑ์",
            style: GoogleFonts.prompt(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF1E2736),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E2736),
            labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'สรุปการขาย', icon: Icon(Icons.trending_up)),
              Tab(text: 'สรุปการซื้อ', icon: Icon(Icons.shopping_bag_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [SalesDashboardTab(), PurchasesDashboardTab()],
        ),
      ),
    );
  }
}

class SalesDashboardTab extends StatelessWidget {
  const SalesDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final confirmedOrders = cartProvider.orders
        .where((o) => o.orderStatus == 'Confirmed')
        .toList();
    final now = DateTime.now();
    final todaySales = confirmedOrders
        .where(
          (o) =>
              o.dateTime.day == now.day &&
              o.dateTime.month == now.month &&
              o.dateTime.year == now.year,
        )
        .fold(0.0, (sum, o) => sum + o.totalAmount);
    final monthSales = confirmedOrders
        .where(
          (o) => o.dateTime.month == now.month && o.dateTime.year == now.year,
        )
        .fold(0.0, (sum, o) => sum + o.totalAmount);
    final totalDebt = cartProvider.unpaidOrders
        .where((o) => o.orderStatus == 'Confirmed')
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    final List<BarChartGroupData> barGroups = [];
    final List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      days.add(DateFormat('E').format(date));
      final dailyTotal = confirmedOrders
          .where(
            (o) =>
                o.dateTime.day == date.day &&
                o.dateTime.month == date.month &&
                o.dateTime.year == date.year,
          )
          .fold(0.0, (sum, o) => sum + o.totalAmount);
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: dailyTotal,
              color: const Color(0xFF1E2736),
              width: 16,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            padding: const EdgeInsets.all(16),
            childAspectRatio: 1.25,
            children: [
              SummaryCard(
                title: 'ยอดขายวันนี้',
                value: '฿${todaySales.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                backgroundColor: const Color.fromARGB(255, 196, 243, 220),
                iconColor: const Color.fromARGB(255, 37, 179, 42),
              ),
              SummaryCard(
                title: 'ยอดขายเดือนนี้',
                value: '฿${monthSales.toStringAsFixed(0)}',
                icon: Icons.trending_up,
                backgroundColor: const Color.fromARGB(255, 194, 217, 255),
                iconColor: const Color.fromARGB(255, 15, 72, 119),
              ),
              SummaryCard(
                title: 'สินค้าใกล้หมด',
                value: productProvider.lowStockCount.toString(),
                icon: Icons.warning_amber_outlined,
                backgroundColor: const Color.fromARGB(255, 252, 227, 194),
                iconColor: const Color.fromARGB(255, 218, 128, 10),
              ),
              SummaryCard(
                title: 'ลูกหนี้คงค้าง',
                value: '฿${totalDebt.toStringAsFixed(0)}',
                icon: Icons.credit_card,
                backgroundColor: const Color.fromARGB(255, 255, 205, 205),
                iconColor: const Color.fromARGB(255, 223, 47, 34),
              ),
            ],
          ),
          _buildChartSection('ยอดขาย 7 วันล่าสุด', barGroups, days),
        ],
      ),
    );
  }
}

class PurchasesDashboardTab extends StatelessWidget {
  const PurchasesDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    // ในอนาคตสามารถนำข้อมูลจากฐานข้อมูลใบสั่งซื้อมาแสดงได้
    // ตอนนี้ใช้ตัวเลขสมมติเพื่อให้เห็นดีไซน์
    return SingleChildScrollView(
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            padding: const EdgeInsets.all(16),
            childAspectRatio: 1.25,
            children: [
              SummaryCard(
                title: 'งบลงทุนวันนี้',
                value: '฿0',
                icon: Icons.shopping_cart_checkout,
                backgroundColor: const Color.fromARGB(255, 230, 245, 255),
                iconColor: Colors.blue,
              ),
              SummaryCard(
                title: 'งบลงทุนเดือนนี้',
                value: '฿0',
                icon: Icons.account_balance_wallet_outlined,
                backgroundColor: const Color.fromARGB(255, 240, 230, 255),
                iconColor: Colors.purple,
              ),
              SummaryCard(
                title: 'ยอดค้างชำระ',
                value: '฿0',
                icon: Icons.assignment_late_outlined,
                backgroundColor: const Color.fromARGB(255, 255, 245, 230),
                iconColor: Colors.orange,
              ),
              SummaryCard(
                title: 'จำนวนบิลสั่งซื้อ',
                value: '0',
                icon: Icons.receipt_long,
                backgroundColor: const Color.fromARGB(255, 240, 240, 240),
                iconColor: Colors.grey[700]!,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีข้อมูลการจัดซื้อ',
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ข้อมูลจะปรากฏที่นี่เมื่อมีการทำรายการใบสั่งซื้อ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildChartSection(
  String title,
  List<BarChartGroupData> groups,
  List<String> days,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    height: 320,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: groups.isEmpty || groups.every((g) => g.barRods[0].toY == 0)
                  ? 100
                  : (groups
                            .map((g) => g.barRods[0].toY)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      return index >= 0 && index < days.length
                          ? Text(
                              days[index],
                              style: GoogleFonts.prompt(fontSize: 10),
                            )
                          : const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: groups,
            ),
          ),
        ),
      ],
    ),
  );
}

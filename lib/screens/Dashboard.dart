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
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    // คำนวณยอดขายวันนี้
    final now = DateTime.now();
    final todaySales = cartProvider.orders
        .where(
          (o) =>
              o.dateTime.day == now.day &&
              o.dateTime.month == now.month &&
              o.dateTime.year == now.year,
        )
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    // คำนวณยอดขายเดือนนี้
    final monthSales = cartProvider.orders
        .where(
          (o) => o.dateTime.month == now.month && o.dateTime.year == now.year,
        )
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    // คำนวณยอดหนี้คงค้าง
    final totalDebt = cartProvider.unpaidOrders.fold(
      0.0,
      (sum, o) => sum + o.totalAmount,
    );

    // เตรียมข้อมูลกราฟ 7 วันล่าสุด
    final List<BarChartGroupData> barGroups = [];
    final List<String> days = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayLabel = DateFormat('E').format(date); // Mon, Tue, ...
      days.add(dayLabel);

      final dailyTotal = cartProvider.orders
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
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          "ร้านเกษตรภัณฑ์",
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              padding: const EdgeInsets.all(16),
              childAspectRatio: 1.2,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      39,
                      39,
                      39,
                    ).withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ยอดขาย 7 วันล่าสุด',
                    style: GoogleFonts.prompt(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'สรุปภาพรวมรายวัน',
                    style: GoogleFonts.prompt(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: barGroups.isEmpty
                            ? 100
                            : (barGroups
                                      .map((g) => g.barRods[0].toY)
                                      .reduce((a, b) => a > b ? a : b) *
                                  1.2),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '฿${rod.toY.toStringAsFixed(0)}',
                                GoogleFonts.prompt(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < days.length) {
                                  return Text(
                                    days[index],
                                    style: GoogleFonts.prompt(fontSize: 10),
                                  );
                                }
                                return const Text('');
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
                        barGroups: barGroups,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/purchase_order_provider.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'แดชบอร์ด',
            style: GoogleFonts.prompt(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          bottom: TabBar(
            labelColor: const Color(0xFF1E2736),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E2736),
            labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'สรุปการขาย', icon: Icon(Icons.analytics_outlined)),
              Tab(text: 'สรุปการซื้อ', icon: Icon(Icons.shopping_bag_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SalesDashboardTab(),
            PurchasesDashboardTab(),
          ],
        ),
      ),
    );
  }
}

class SalesDashboardTab extends StatelessWidget {
  const SalesDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final orders = cartProvider.orders.where((o) => o.orderStatus == 'Confirmed').toList();
    final now = DateTime.now();

    // คำนวณยอดขาย
    final todaySales = orders.where((o) {
      return o.dateTime.day == now.day && o.dateTime.month == now.month && o.dateTime.year == now.year;
    }).fold(0.0, (sum, o) => sum + o.totalAmount);

    final monthSales = orders.where((o) {
      return o.dateTime.month == now.month && o.dateTime.year == now.year;
    }).fold(0.0, (sum, o) => sum + o.totalAmount);

    // คำนวณยอดค้างชำระลูกหนี้ (เงินเข้า) จากยอดคงเหลือจริง
    final totalUnpaid = cartProvider.debtRecords
        .where((d) => d['DeptStatus'] == 'Pending' && d['DeptRecordStatus'] == 'Confirmed')
        .fold(0.0, (sum, d) => sum + (d['RemainingAmount'] as num).toDouble());

    final totalOrders = orders.length;

    // ข้อมูลสำหรับกราฟ 7 วันล่าสุด
    final List<BarChartGroupData> barGroups = [];
    final List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      days.add(DateFormat('E').format(date));
      final dailyTotal = orders.where((o) {
        return o.dateTime.day == date.day && o.dateTime.month == date.month && o.dateTime.year == date.year;
      }).fold(0.0, (sum, o) => sum + o.totalAmount);

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

    return RefreshIndicator(
      onRefresh: () async {
        await cartProvider.loadOrdersFromDatabase();
        await cartProvider.loadDebtRecords();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  icon: Icons.payments_outlined,
                  backgroundColor: const Color.fromARGB(255, 235, 250, 240),
                  iconColor: Colors.green,
                ),
                SummaryCard(
                  title: 'ยอดขายเดือนนี้',
                  value: '฿${monthSales.toStringAsFixed(0)}',
                  icon: Icons.calendar_month_outlined,
                  backgroundColor: const Color.fromARGB(255, 230, 245, 255),
                  iconColor: Colors.blue,
                ),
                SummaryCard(
                  title: 'ยอดลูกหนี้คงเหลือ',
                  value: '฿${totalUnpaid.toStringAsFixed(0)}',
                  icon: Icons.person_search_outlined,
                  backgroundColor: const Color.fromARGB(255, 255, 240, 240),
                  iconColor: Colors.red,
                ),
                SummaryCard(
                  title: 'จำนวนรายการขาย',
                  value: totalOrders.toString(),
                  icon: Icons.receipt_long_outlined,
                  backgroundColor: const Color.fromARGB(255, 240, 240, 240),
                  iconColor: Colors.grey[700]!,
                ),
              ],
            ),
            _buildChartSection('ยอดขาย 7 วันล่าสุด', barGroups, days),
          ],
        ),
      ),
    );
  }
}

class PurchasesDashboardTab extends StatelessWidget {
  const PurchasesDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final poProvider = Provider.of<PurchaseOrderProvider>(context);
    final history = poProvider.purchaseHistory;
    final now = DateTime.now();

    final confirmedPOs = history.where((po) => po['Status'] == 'Confirmed').toList();

    final todayInvestment = confirmedPOs.where((po) {
      final date = DateTime.parse(po['ReceiveDate']);
      return date.day == now.day && date.month == now.month && date.year == now.year;
    }).fold(0.0, (sum, po) => sum + (po['TotalCost'] as num).toDouble());

    final monthInvestment = confirmedPOs.where((po) {
      final date = DateTime.parse(po['ReceiveDate']);
      return date.month == now.month && date.year == now.year;
    }).fold(0.0, (sum, po) => sum + (po['TotalCost'] as num).toDouble());

    // คำนวณยอดค้างชำระเจ้าหนี้ (เงินออก) จากยอดคงเหลือจริง (TotalCost - PaidAmount)
    final totalPending = confirmedPOs.where((po) => po['PaymentStatus'] == 'Pending')
        .fold(0.0, (sum, po) => sum + ((po['TotalCost'] as num) - (po['PaidAmount'] as num)).toDouble());

    final totalBills = confirmedPOs.length;

    final List<BarChartGroupData> barGroups = [];
    final List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      days.add(DateFormat('E').format(date));
      final dailyTotal = confirmedPOs.where((po) {
        final d = DateTime.parse(po['ReceiveDate']);
        return d.day == date.day && d.month == date.month && d.year == date.year;
      }).fold(0.0, (sum, po) => sum + (po['TotalCost'] as num).toDouble());

      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: dailyTotal,
              color: Colors.blue[700]!,
              width: 16,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => poProvider.loadPurchaseHistory(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  value: '฿${todayInvestment.toStringAsFixed(0)}',
                  icon: Icons.shopping_cart_checkout,
                  backgroundColor: const Color.fromARGB(255, 230, 245, 255),
                  iconColor: Colors.blue,
                ),
                SummaryCard(
                  title: 'งบลงทุนเดือนนี้',
                  value: '฿${monthInvestment.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                  backgroundColor: const Color.fromARGB(255, 240, 230, 255),
                  iconColor: Colors.purple,
                ),
                SummaryCard(
                  title: 'ยอดเจ้าหนี้คงเหลือ',
                  value: '฿${totalPending.toStringAsFixed(0)}',
                  icon: Icons.assignment_late_outlined,
                  backgroundColor: const Color.fromARGB(255, 255, 245, 230),
                  iconColor: Colors.orange,
                ),
                SummaryCard(
                  title: 'จำนวนบิลสั่งซื้อ',
                  value: totalBills.toString(),
                  icon: Icons.receipt_long,
                  backgroundColor: const Color.fromARGB(255, 240, 240, 240),
                  iconColor: Colors.grey[700]!,
                ),
              ],
            ),
            if (confirmedPOs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[200]),
                      const SizedBox(height: 16),
                      Text('ยังไม่มีข้อมูลการจัดซื้อ', 
                        style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              _buildChartSection('งบลงทุน 7 วันล่าสุด', barGroups, days),
          ],
        ),
      ),
    );
  }
}

Widget _buildChartSection(String title, List<BarChartGroupData> groups, List<String> days) {
  double calculatedMaxY = groups.fold(0.0, (max, g) => g.barRods[0].toY > max ? g.barRods[0].toY : max);
  // ป้องกัน maxY เป็น 0 และเผื่อพื้นที่ด้านบน 20%
  double maxY = calculatedMaxY == 0 ? 100 : calculatedMaxY * 1.2;

  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        SizedBox(
          height: 220, // เพิ่มความสูงเล็กน้อยเพื่อให้เห็นตัวเลขชัดขึ้น
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max) return Container(); // ไม่แสดงค่าสูงสุดที่ขอบบนสุด
                      String text = '';
                      if (value >= 1000000) {
                        text = '${(value / 1000000).toStringAsFixed(1)}M';
                      } else if (value >= 1000) {
                        text = '${(value / 1000).toStringAsFixed(0)}K';
                      } else {
                        text = value.toInt().toString();
                      }
                      return Text(text, style: GoogleFonts.prompt(fontSize: 10, color: Colors.grey));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= days.length) return Container();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(days[index], style: GoogleFonts.prompt(fontSize: 10, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4, // แบ่งเส้นตารางเป็น 4 ส่วน
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: groups,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E2736),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '฿${NumberFormat('#,###').format(rod.toY)}',
                      GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

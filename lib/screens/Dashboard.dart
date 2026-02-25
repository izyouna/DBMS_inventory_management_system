import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
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
                      value: '฿0',
                      icon: Icons.attach_money,
                      backgroundColor: const Color.fromARGB(255, 196, 243, 220),
                      iconColor: const Color.fromARGB(255, 37, 179, 42),
                    ),
                    SummaryCard(
                      title: 'ยอดขายเดือนนี้',
                      value: '฿0',
                      icon: Icons.trending_up,
                      backgroundColor: const Color.fromARGB(255, 194, 217, 255),
                      iconColor: const Color.fromARGB(255, 15, 72, 119),
                    ),
                    SummaryCard(
                      title: 'สินค้าใกล้หมด',
                      value: provider.lowStockCount.toString(),
                      icon: Icons.warning_amber_outlined,
                      backgroundColor: const Color.fromARGB(255, 252, 227, 194),
                      iconColor: const Color.fromARGB(255, 218, 128, 10),
                    ),
                    SummaryCard(
                      title: 'ลูกหนี้คงค้าง',
                      value: '฿0',
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
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color.fromARGB(255, 39, 39, 39).withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยอดขายรายวัน',
                        style: GoogleFonts.prompt(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'สรุปยอดขายของวันนี้',
                        style: GoogleFonts.prompt(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: Text(
                            'กราฟแสดงยอดขาย (placeholder)',
                            style: GoogleFonts.prompt(
                              color: Colors.grey[500],
                            ),
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
      },
    );
  }
}
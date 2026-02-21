import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DebtorsScreen extends StatelessWidget {
  const DebtorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final debtors = [
      {'name': 'คุณสมชาย ใจดี', 'amount': 1500.0, 'days': 3},
      {'name': 'คุณสมหญิง รักสวย', 'amount': 3200.0, 'days': 7},
      {'name': 'ร้านค้าตัวอย่าง', 'amount': 850.0, 'days': 1},
    ];

    final totalDebt = debtors.fold<double>(
      0,
      (sum, d) => sum + (d['amount'] as double),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_off,
                            color: Color(0xFFDC2626),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ลูกค้าค้างชำระ',
                                style: GoogleFonts.prompt(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'สรุปยอดค้างชำระทั้งหมด',
                                style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFDC2626),
                            const Color(0xFFDC2626).withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ยอดค้างชำระรวม',
                                style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white54,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '฿${totalDebt.toStringAsFixed(0)}',
                            style: GoogleFonts.prompt(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final debtor = debtors[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DebtorCard(debtor: debtor),
                    );
                  },
                  childCount: debtors.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtorCard extends StatelessWidget {
  final Map<String, dynamic> debtor;

  const _DebtorCard({required this.debtor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFDC2626).withOpacity(0.1),
            child: Text(
              debtor['name'].toString().substring(0, 1),
              style: GoogleFonts.prompt(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debtor['name'],
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ค้างชำระ ${debtor['days']} วัน',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '฿${(debtor['amount'] as double).toStringAsFixed(0)}',
                style: GoogleFonts.prompt(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {},
                child: Text(
                  'ติดต่อ',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

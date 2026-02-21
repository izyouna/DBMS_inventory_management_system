import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'ทั้งหมด';

  final List<Map<String, dynamic>> _history = [
    {
      'type': 'ขาย',
      'desc': 'ขายสินค้า A - 10 ชิ้น',
      'amount': 990.0,
      'date': '21 ก.พ. 2025',
      'time': '14:30',
      'isIncome': true,
    },
    {
      'type': 'ซื้อ',
      'desc': 'จัดซื้อสินค้า C - 5 ชุด',
      'amount': 1495.0,
      'date': '20 ก.พ. 2025',
      'time': '11:00',
      'isIncome': false,
    },
    {
      'type': 'ขาย',
      'desc': 'ขายสินค้า B - 2 กล่อง',
      'amount': 300.0,
      'date': '20 ก.พ. 2025',
      'time': '09:15',
      'isIncome': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == 'ทั้งหมด') return _history;
    return _history.where((item) => item['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                            color: const Color(0xFF0891B2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Color(0xFF0891B2),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ประวัติ',
                                style: GoogleFonts.prompt(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'ประวัติการทำธุรกรรม',
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _FilterChip(
                            label: 'ทั้งหมด',
                            selected: _selectedFilter == 'ทั้งหมด',
                            onSelected: () => setState(() => _selectedFilter = 'ทั้งหมด'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'ขาย',
                            selected: _selectedFilter == 'ขาย',
                            onSelected: () => setState(() => _selectedFilter = 'ขาย'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'ซื้อ',
                            selected: _selectedFilter == 'ซื้อ',
                            onSelected: () => setState(() => _selectedFilter = 'ซื้อ'),
                          ),
                        ),
                      ],
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
                    final item = _filteredHistory[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HistoryCard(item: item),
                    );
                  },
                  childCount: _filteredHistory.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.prompt(fontSize: 13)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFF0891B2).withOpacity(0.2),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF0891B2) : Colors.grey[300]!,
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isIncome = item['isIncome'] as bool;

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['type'],
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['desc'],
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['date']} · ${item['time']}',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}฿${(item['amount'] as double).toStringAsFixed(0)}',
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

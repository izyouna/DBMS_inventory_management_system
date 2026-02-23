import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'ปุ๋ยอินทรีย์ 50kg',
      'price': 450.0,
      'category': 'ปุ๋ย',
    },
    {
      'id': '2',
      'name': 'ยาฆ่าแมลง 1L',
      'price': 250.0,
      'category': 'ยา',
    },
    {
      'id': '3',
      'name': 'เมล็ดข้าวโพด 5kg',
      'price': 320.0,
      'category': 'เมล็ดพันธุ์',
    },
    {
      'id': '4',
      'name': 'เมล็ดข้าวหอมมะลิ 5kg',
      'price': 350.0,
      'category': 'เมล็ดพันธุ์',
    },
    {
      'id': '5',
      'name': 'อุปกรณ์ฉีดพ่น',
      'price': 890.0,
      'category': 'อุปกรณ์',
    },
  ];

  final Map<String, int> _cart = {};
  String _search = '';
  String _selectedCategory = 'ทั้งหมด';

  double get _total {
    double sum = 0;
    _cart.forEach((id, qty) {
      final p = _products.firstWhere((e) => e['id'] == id);
      sum += (p['price'] as double) * qty;
    });
    return sum;
  }

  List<String> get _categories {
    final set = <String>{'ทั้งหมด'};
    for (final p in _products) {
      set.add(p['category'] as String);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((p) {
      final matchesSearch = p['name']
          .toString()
          .toLowerCase()
          .contains(_search.toLowerCase());
      final matchesCat = _selectedCategory == 'ทั้งหมด'
          ? true
          : p['category'] == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ขายสินค้า',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            color: Colors.black,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้า...',
                hintStyle: GoogleFonts.prompt(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat, style: GoogleFonts.prompt()),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor:
                      const Color.fromARGB(255, 30, 39, 54).withOpacity(0.9),
                  labelStyle: GoogleFonts.prompt(
                    color: selected ? Colors.white : Colors.black,
                  ),
                  backgroundColor: Colors.white,
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _categories.length,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final p = filtered[index];
                final id = p['id'] as String;
                final inCart = _cart[id] ?? 0;
                return Container(
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 226, 232, 240),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.shopping_basket_outlined,
                              size: 32, color: Color(0xFF1E2736)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p['name'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '฿${(p['price'] as double).toStringAsFixed(0)}',
                        style: GoogleFonts.prompt(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E2736),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (inCart > 0)
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20),
                                  onPressed: () {
                                    setState(() {
                                      final current = _cart[id] ?? 0;
                                      if (current <= 1) {
                                        _cart.remove(id);
                                      } else {
                                        _cart[id] = current - 1;
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  inCart.toString(),
                                  style: GoogleFonts.prompt(
                                      fontWeight: FontWeight.w600),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _cart[id] = (inCart) + 1;
                                    });
                                  },
                                ),
                              ],
                            )
                          else
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _cart[id] = 1;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(255, 30, 39, 54),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'เพิ่ม',
                                style: GoogleFonts.prompt(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ตะกร้าสินค้า',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'จำนวน ${_cart.values.fold<int>(0, (s, q) => s + q)} ชิ้น',
                        style: GoogleFonts.prompt(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '฿${_total.toStringAsFixed(0)}',
                  style: GoogleFonts.prompt(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _cart.isEmpty ? null : () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2736),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'ชำระเงิน',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
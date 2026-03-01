import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../models/order.dart';
import '../services/pdf_service.dart';

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

    final confirmedOrders = cartProvider.orders.where((o) => o.orderStatus == 'Confirmed').toList();

    final todayOrders = confirmedOrders.where((o) => 
        o.dateTime.day == now.day && 
        o.dateTime.month == now.month && 
        o.dateTime.year == now.year).toList();

    final monthOrders = confirmedOrders.where((o) => 
        o.dateTime.month == now.month && 
        o.dateTime.year == now.year).toList();

    final todaySales = todayOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final monthSales = monthOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    
    // คำนวณยอดค้างชำระเฉพาะบิลที่ยังไม่ถูกยกเลิก
    final unpaidTotal = cartProvider.unpaidOrders
        .where((o) => o.orderStatus == 'Confirmed')
        .fold(0.0, (sum, o) => sum + o.totalAmount);

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
                  ...filteredOrders.map((order) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showOrderDetails(context, order),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '฿${order.totalAmount.toStringAsFixed(2)}',
                                  style: GoogleFonts.prompt(
                                    fontWeight: FontWeight.bold,
                                    color: order.orderStatus == 'Cancelled' 
                                        ? Colors.grey 
                                        : (order.isPaid ? Colors.green : Colors.red),
                                    decoration: order.orderStatus == 'Cancelled' 
                                        ? TextDecoration.lineThrough 
                                        : null,
                                  ),
                                ),
                                Text(
                                  order.orderStatus == 'Cancelled' 
                                      ? 'บิลถูกยกเลิก' 
                                      : (order.isPaid ? 'ชำระแล้ว' : 'ค้างชำระ'),
                                  style: GoogleFonts.prompt(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (order.orderStatus == 'Confirmed') ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.print, size: 20, color: Colors.blueGrey),
                                onPressed: () => PdfService.printOrder(order),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, size: 20, color: Colors.redAccent),
                                onPressed: () => _confirmCancel(context, order),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ] else
                              Container(
                                margin: const EdgeInsets.only(left: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Cancelled',
                                  style: GoogleFonts.prompt(
                                    color: Colors.red[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
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

  void _confirmCancel(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการยกเลิกบิล', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการยกเลิกบิล ${order.id} และคืนสต็อกสินค้าใช่หรือไม่?', style: GoogleFonts.prompt()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ไม่ใช่', style: GoogleFonts.prompt(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // ปิด Dialog ยืนยัน
              
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              
              // แสดง Loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );

              final success = await cartProvider.cancelOrder(order.id);
              
              if (context.mounted) {
                Navigator.pop(context); // ปิด Loading
                
                if (success) {
                  // รีโหลดสต็อกในหน้าสินค้าด้วย
                  await productProvider.loadProductsFromDatabase();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ยกเลิกบิลและคืนสต็อกสำเร็จ', style: GoogleFonts.prompt()), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ไม่สามารถยกเลิกบิลได้', style: GoogleFonts.prompt()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('ใช่, ยกเลิกบิล', style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // แสดงตัวโหลดขณะดึงข้อมูล
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // ดึงรายการสินค้าจริงจาก Database
    final items = await cartProvider.getOrderItemsFromDb(order.id);
    
    if (!context.mounted) return;
    Navigator.pop(context); // ปิดตัวโหลด

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รายละเอียดบิล', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
            Text(order.id, style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('ไม่พบรายการสินค้า', style: GoogleFonts.prompt(color: Colors.grey)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('฿${item.product.price.toStringAsFixed(2)} / ${item.product.unit.label}', 
                                    style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('x${item.quantity}', style: GoogleFonts.prompt(fontSize: 14), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('฿${item.total.toStringAsFixed(2)}', 
                                style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ยอดรวมทั้งสิ้น', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('฿${order.totalAmount.toStringAsFixed(2)}', 
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('การชำระเงิน', style: GoogleFonts.prompt(fontSize: 14)),
                  Text(order.paymentMethod, style: GoogleFonts.prompt(fontSize: 14, color: Colors.blueGrey)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
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

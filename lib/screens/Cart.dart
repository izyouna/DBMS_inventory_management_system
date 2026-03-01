import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/pdf_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildCustomerForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ข้อมูลลูกค้า (จำเป็นสำหรับขายเชื่อ)', 
            style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('ชื่อ-นามสกุล'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('เบอร์โทรศัพท์'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('ตะกร้าสินค้า', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCustomerForm(),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final item = cart.items.values.toList()[i];
                return ListTile(
                  title: Text(item.product.name, style: GoogleFonts.prompt()),
                  subtitle: Text('${item.quantity} x ฿${item.product.price}', style: GoogleFonts.prompt()),
                  trailing: Text('฿${item.total}', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                  leading: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => cart.removeSingleItem(item.product.id),
                  ),
                );
              },
            ),
          ),
          _buildSummary(context, cart),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10, 
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ยอดรวมทั้งหมด', style: GoogleFonts.prompt(fontSize: 18)),
              Text('฿${cart.totalAmount}', style: GoogleFonts.prompt(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: cart.itemCount == 0 ? null : () => _showPaymentSheet(context, cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2736),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('ชำระเงิน', style: GoogleFonts.prompt(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('เลือกวิธีชำระเงิน', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.money),
              title: Text('เงินสด', style: GoogleFonts.prompt()),
              onTap: () => _processCheckout(context, cart, CashPayment()),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text('QR Code', style: GoogleFonts.prompt()),
              onTap: () => _processCheckout(context, cart, QRPayment()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history_edu, color: Colors.orange),
              title: Text('ขายเชื่อ (ออกใบแจ้งหนี้)', style: GoogleFonts.prompt(color: Colors.orange[800])),
              onTap: () => _processCheckout(context, cart, CreditPayment()),
            ),
          ],
        ),
      ),
    );
  }

  void _processCheckout(BuildContext context, CartProvider cart, PaymentMethod method) async {
    // 1. ปิด Bottom Sheet ทันทีเพื่อให้ UI ตอบสนองเร็ว
    Navigator.pop(context);

    // Validation: ถ้าเป็นขายเชื่อ ต้องมีข้อมูลลูกค้า
    if (method is CreditPayment && (_nameController.text.isEmpty || _phoneController.text.isEmpty)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกข้อมูลลูกค้าก่อนทำการขายเชื่อ', style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Customer? customer;
    if (_nameController.text.isNotEmpty) {
      customer = Customer(
        id: DateTime.now().toString(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }

    // 2. แสดง Loading โดยรอให้ Animation เดิมจบก่อนเล็กน้อย
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );

    try {
      // 3. ปล่อยให้ UI แสดง Spinner ก่อนเริ่มงานหนัก
      await Future.delayed(const Duration(milliseconds: 300));

      // 4. บันทึกข้อมูล (Heavy Task)
      final order = await cart.checkout(method, customer: customer);
      
      if (!context.mounted) return;
      Navigator.pop(context); // ปิด Loading ทันทีที่บันทึกเสร็จ
      
      _nameController.clear();
      _phoneController.clear();
      
      // 5. แสดง Success Dialog
      if (!context.mounted) return;
      _showSuccessDialog(context, order);

      // 6. โหลดข้อมูลสต็อกใหม่แบบ Background (ไม่ให้ขวาง UI หน้าความสำเร็จ)
      Future.microtask(() async {
        if (!context.mounted) return;
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        await productProvider.loadProductsFromDatabase();
      });

    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // ปิด Loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt())),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ดำเนินการสำเร็จ', style: GoogleFonts.prompt()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ประเภทเอกสาร: ${order.documentName}', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
            if (order.customer != null) Text('ลูกค้า: ${order.customer!.name}', style: GoogleFonts.prompt()),
            const Divider(),
            Text('ยอดรวม: ฿${order.totalAmount}', style: GoogleFonts.prompt()),
            Text('วิธีชำระ: ${order.paymentMethod}', style: GoogleFonts.prompt()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => PdfService.printOrder(order),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.print, size: 18),
                const SizedBox(width: 8),
                Text('พิมพ์${order.documentName}', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // ปิดหน้าต่าง Dialog
              Navigator.pop(context); // ปิดหน้าตะกร้าสินค้าเพื่อกลับไปหน้าขายสินค้า
            },
            child: Text('ตกลง', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

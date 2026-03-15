import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/pdf_service.dart';
import '../services/database_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));
  Customer? _existingCustomer;
  bool _isLoadingCustomer = false;
  bool _isProcessing = false;
  final double _defaultCreditLimit = 1000.0;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    if (phone.length >= 9) {
      _fetchCustomerInfo(phone);
    } else if (phone.isEmpty && _existingCustomer != null) {
      setState(() {
        _existingCustomer = null;
        _nameController.clear();
      });
    }
  }

  Future<void> _fetchCustomerInfo(String phone) async {
    if (_isLoadingCustomer) return;
    setState(() => _isLoadingCustomer = true);
    try {
      final data = await DatabaseService.instance.getCustomerByPhone(phone);
      if (data != null) {
        setState(() {
          _existingCustomer = Customer.fromMap(data);
          if (_nameController.text.isEmpty) {
            _nameController.text = _existingCustomer!.name;
          }
        });
      } else {
        setState(() => _existingCustomer = null);
      }
    } catch (e) {
      debugPrint("Error fetching customer: $e");
    } finally {
      setState(() => _isLoadingCustomer = false);
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
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
          Text('ข้อมูลลูกค้า (บันทึกข้อมูลลูกค้าลงฐานข้อมูล)', 
            style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('เบอร์โทรศัพท์').copyWith(
              suffixIcon: _isLoadingCustomer 
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) 
                  : (_existingCustomer != null ? const Icon(Icons.check_circle, color: Colors.green) : null),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('ชื่อ-นามสกุล'),
          ),
          if (_existingCustomer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                children: [
                  _buildCreditRow('วงเงินเครดิต:', '฿${_existingCustomer!.creditLimit.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _buildCreditRow('หนี้คงค้างปัจจุบัน:', '฿${_existingCustomer!.totalDebt.toStringAsFixed(2)}', valueColor: Colors.red),
                  const Divider(),
                  _buildCreditRow(
                    'คงเหลือคงเหลือ:', 
                    '฿${(_existingCustomer!.creditLimit - _existingCustomer!.totalDebt).toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: (_existingCustomer!.creditLimit - _existingCustomer!.totalDebt) > 0 ? Colors.green[700] : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.prompt(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: GoogleFonts.prompt(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor)),
      ],
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
      body: Stack(
        children: [
          Column(
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
                        onPressed: _isProcessing ? null : () => cart.removeSingleItem(item.product.id),
                      ),
                    );
                  },
                ),
              ),
              _buildSummary(context, cart),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
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
            color: Colors.black.withOpacity(0.1),
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
              onPressed: (cart.itemCount == 0 || _isProcessing) ? null : () => _showPaymentSheet(context, cart),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('เลือกวิธีชำระเงิน', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.money, color: Colors.green),
                  title: Text('เงินสด', style: GoogleFonts.prompt()),
                  onTap: () => _processCheckout(context, cart, CashPayment()),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                  title: Text('QR Code', style: GoogleFonts.prompt()),
                  onTap: () => _processCheckout(context, cart, QRPayment()),
                ),
                const Divider(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.history_edu, color: Colors.orange),
                    title: Text('ขายเชื่อ (ออกใบแจ้งหนี้)', 
                      style: GoogleFonts.prompt(color: Colors.orange[800], fontWeight: FontWeight.bold)),
                    subtitle: Text('ครบกำหนด: ${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}', 
                      style: GoogleFonts.prompt(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => _selectedDueDate = picked);
                          setState(() {});
                        }
                      },
                    ),
                    onTap: () => _processCheckout(context, cart, CreditPayment()),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  void _processCheckout(BuildContext context, CartProvider cart, PaymentMethod method) async {
    final String customerNameText = _nameController.text.trim();
    final String customerPhoneText = _phoneController.text.trim();

    if (method is CreditPayment && (customerNameText.isEmpty || customerPhoneText.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อมูลลูกค้าก่อนทำการขายเชื่อ', style: GoogleFonts.prompt()), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.of(context).pop(); // ปิด Bottom Sheet
    setState(() => _isProcessing = true);

    try {
      if (method is CreditPayment) {
        final customerData = await DatabaseService.instance.getCustomerByPhone(customerPhoneText);
        double limit = _defaultCreditLimit;
        double currentDebt = 0.0;
        if (customerData != null) {
          limit = (customerData['credit_limit'] ?? 0.0).toDouble();
          currentDebt = (customerData['total_debt'] ?? 0.0).toDouble();
        }
        if (currentDebt + cart.totalAmount > limit) {
          setState(() => _isProcessing = false);
          if (context.mounted) _showCreditExceededDialog(context, limit, currentDebt, cart.totalAmount);
          return;
        }
      }

      // สร้างหรือใช้ Customer object โดยใช้ค่าล่าสุดจาก UI เสมอ
      Customer? customer;
      if (customerNameText.isNotEmpty) {
        customer = Customer(
          id: _existingCustomer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: customerNameText,
          phone: customerPhoneText,
          creditLimit: _existingCustomer?.creditLimit ?? _defaultCreditLimit,
        );
      }

      final order = await cart.checkout(
        method, 
        customer: customer,
        dueDate: method is CreditPayment ? _selectedDueDate.toIso8601String() : null,
      ).timeout(const Duration(seconds: 45));
      
      // บันทึกสำเร็จ: ล้างค่า
      _nameController.clear();
      _phoneController.clear();
      _existingCustomer = null;
      setState(() => _isProcessing = false);

      if (context.mounted) {
        _showSuccessDialog(context, order);
      }

      // โหลดสต็อกใหม่
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Provider.of<ProductProvider>(context, listen: false).loadProductsFromDatabase(force: true);
      });

    } catch (e) {
      debugPrint("Checkout Error: $e");
      setState(() => _isProcessing = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e', style: GoogleFonts.prompt()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreditExceededDialog(BuildContext context, double limit, double currentDebt, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('วงเงินเครดิตไม่พอ', style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('ลูกค้ามีวงเงินไม่เพียงพอสำหรับยอดซื้อครั้งนี้\nวงเงินคงเหลือ: ฿${(limit - currentDebt).toStringAsFixed(2)}', style: GoogleFonts.prompt()),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2736)),
            child: Text('ตกลง', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              Navigator.of(ctx).pop(); // ปิด Dialog
              Navigator.of(context).pop(); // ปิด Cart Screen
            },
            child: Text('ตกลง', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

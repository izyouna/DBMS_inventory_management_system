import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../models/customer.dart';

class CustomerCreditScreen extends StatefulWidget {
  const CustomerCreditScreen({super.key});

  @override
  State<CustomerCreditScreen> createState() => _CustomerCreditScreenState();
}

class _CustomerCreditScreenState extends State<CustomerCreditScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseService.instance.getCustomers();
      setState(() {
        _customers = data.map((m) => Customer.fromMap(m)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showEditCreditDialog(Customer customer) {
    final controller = TextEditingController(text: customer.creditLimit.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ตั้งค่าวงเงิน: ${customer.name}', 
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ระบุวงเงินเครดิตสูงสุดที่ลูกค้าสามารถค้างชำระได้', 
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'วงเงินเครดิต (บาท)',
                labelStyle: GoogleFonts.prompt(),
                prefixText: '฿ ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('ยกเลิก', style: GoogleFonts.prompt())
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2736)),
            onPressed: () async {
              final newLimit = double.tryParse(controller.text) ?? 0.0;
              await DatabaseService.instance.updateCustomerCreditLimit(
                int.parse(customer.id), 
                newLimit
              );
              if (mounted) {
                Navigator.pop(ctx);
                _fetchCustomers(); // รีโหลดข้อมูล
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('อัปเดตวงเงินของ ${customer.name} สำเร็จ', style: GoogleFonts.prompt()))
                );
              }
            },
            child: Text('บันทึก', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _customers.where((c) => 
      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      c.phone.contains(_searchQuery)
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text('จัดการวงเงินลูกค้า', 
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ส่วนค้นหา
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อหรือเบอร์โทรลูกค้า...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filteredCustomers.isEmpty 
                ? Center(child: Text('ไม่พบข้อมูลลูกค้า', style: GoogleFonts.prompt()))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final customer = filteredCustomers[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[50],
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(customer.name, 
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.phone, style: GoogleFonts.prompt(fontSize: 12)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.credit_card, size: 14, color: Colors.orange[800]),
                                  const SizedBox(width: 4),
                                  Text('วงเงิน: ฿${customer.creditLimit.toStringAsFixed(0)}', 
                                    style: GoogleFonts.prompt(
                                      fontSize: 13, 
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w600
                                    )),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_note, color: Color(0xFF1E2736)),
                            onPressed: () => _showEditCreditDialog(customer),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

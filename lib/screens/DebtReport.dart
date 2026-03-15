import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/purchase_order_provider.dart';
import '../services/database_service.dart';

class DebtReportScreen extends StatefulWidget {
  const DebtReportScreen({super.key});

  @override
  State<DebtReportScreen> createState() => _DebtReportScreenState();
}

class _DebtReportScreenState extends State<DebtReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadOrdersFromDatabase();
      Provider.of<CartProvider>(context, listen: false).loadDebtRecords();
      Provider.of<PurchaseOrderProvider>(context, listen: false).loadPurchaseHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text('บริหารรายการค้างชำระ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF1E2736),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E2736),
            labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'ลูกหนี้ (เงินเข้า)', icon: Icon(Icons.person_pin_outlined)),
              Tab(text: 'เจ้าหนี้ (เงินออก)', icon: Icon(Icons.account_balance_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DebtorListView(),
            CreditorListView(),
          ],
        ),
      ),
    );
  }
}

class DebtorListView extends StatelessWidget {
  const DebtorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final debtRecords = cartProvider.debtRecords.where((d) => d['debtstatus'] == 'Pending').toList();

    // จัดเรียง: เกินกำหนดขึ้นก่อน ตามด้วยใกล้ถึงกำหนด
    debtRecords.sort((a, b) {
      final dueA = a['due_date'] != null ? DateTime.parse(a['due_date']) : DateTime.now().add(const Duration(days: 365));
      final dueB = b['due_date'] != null ? DateTime.parse(b['due_date']) : DateTime.now().add(const Duration(days: 365));
      return dueA.compareTo(dueB);
    });

    return RefreshIndicator(
      onRefresh: () => cartProvider.loadDebtRecords(),
      child: debtRecords.isEmpty
          ? Center(child: Text('ไม่มีรายการลูกหนี้ค้างชำระ', style: GoogleFonts.prompt()))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: debtRecords.length,
              itemBuilder: (ctx, i) {
                final debt = debtRecords[i];
                final startDate = DateTime.parse(debt['startdate']);
                final dueDate = debt['due_date'] != null ? DateTime.parse(debt['due_date']) : null;
                final total = (debt['originalamount'] as num).toDouble();
                final balance = (debt['remainingamount'] as num).toDouble();
                final paid = total - balance;
                final customer = debt['customer'];
                
                final bool isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && balance > 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.transparent, width: 1),
                  ),
                  child: Column(
                    children: [
                      if (isOverdue)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Text('เกินกำหนดชำระ', 
                            textAlign: TextAlign.center,
                            style: GoogleFonts.prompt(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        onTap: () => _showDebtPaymentHistory(context, debt['debtid'], cartProvider),
                        title: Row(
                          children: [
                            Text(customer?['customername'] ?? 'ไม่ระบุชื่อลูกค้า', 
                              style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            if (isOverdue) const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('โทร: ${customer?['customerphone'] ?? '-'}', style: GoogleFonts.prompt(fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('วันที่ขาย: ${startDate.day}/${startDate.month}/${startDate.year}', 
                                  style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                            if (dueDate != null)
                              Row(
                                children: [
                                  Icon(Icons.event_available, size: 12, color: isOverdue ? Colors.red : Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text('ครบกำหนด: ${dueDate.day}/${dueDate.month}/${dueDate.year}', 
                                    style: GoogleFonts.prompt(
                                      fontSize: 11, 
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                      color: isOverdue ? Colors.red : Colors.green[700])),
                                ],
                              ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: total > 0 ? (paid / total) : 0,
                                backgroundColor: Colors.grey[100],
                                color: isOverdue ? Colors.red[400] : Colors.blue,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('฿${balance.toStringAsFixed(2)}', 
                              style: GoogleFonts.prompt(
                                color: isOverdue ? Colors.red : const Color(0xFF1E2736), 
                                fontWeight: FontWeight.bold, 
                                fontSize: 18)),
                            Text('ค้างชำระ', style: GoogleFonts.prompt(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ยอดเดิม: ฿${total.toStringAsFixed(2)}', 
                              style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600])),
                            ElevatedButton.icon(
                              onPressed: () => _showDebtPaymentDialog(context, debt['debtid'], balance, cartProvider),
                              icon: const Icon(Icons.payments_outlined, size: 16),
                              label: Text('รับชำระหนี้', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOverdue ? Colors.red[50] : Colors.green[50],
                                foregroundColor: isOverdue ? Colors.red : Colors.green[800],
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showDebtPaymentDialog(BuildContext context, String debtId, double balance, CartProvider provider) {
    final amountController = TextEditingController();
    XFile? pickedFile;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('บันทึกการรับชำระหนี้', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Debt ID: $debtId', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'จำนวนเงินที่รับ (คงค้าง ฿${balance.toStringAsFixed(2)})',
                    labelStyle: GoogleFonts.prompt(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixText: '฿ ',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (result != null) {
                      setDialogState(() => pickedFile = result);
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: pickedFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb 
                                ? Image.network(pickedFile!.path, fit: BoxFit.cover)
                                : Image.file(File(pickedFile!.path), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                              Text('แนบหลักฐานการโอน (ถ้ามี)', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2736),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0 || amount > (balance + 0.01)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('กรุณากรอกจำนวนเงินให้ถูกต้อง', style: GoogleFonts.prompt())),
                  );
                  return;
                }

                await provider.addDebtPayment(
                  debtId: debtId,
                  amount: amount,
                  image: pickedFile,
                );

                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกการรับชำระสำเร็จ', style: GoogleFonts.prompt()), backgroundColor: Colors.green),
                );
              },
              child: Text('ยืนยันรับชำระ', style: GoogleFonts.prompt(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebtPaymentHistory(BuildContext context, String debtId, CartProvider provider) async {
    final history = await provider.getDebtPaymentHistory(debtId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ประวัติการรับชำระเงิน', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Debt ID: $debtId', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            Expanded(
              child: history.isEmpty
                  ? Center(child: Text('ยังไม่มีประวัติการรับชำระเงิน', style: GoogleFonts.prompt()))
                  : ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (c, i) {
                        final item = history[i];
                        final date = DateTime.parse(item['paiddate']);
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.account_balance_wallet, color: Colors.blue[700]),
                          ),
                          title: Text('฿${(item['amountpaid'] as num).toStringAsFixed(2)}', 
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                          subtitle: Text('วันที่: ${date.toString().split('.')[0]}', style: GoogleFonts.prompt(fontSize: 12)),
                          trailing: item['deptpaidimagepath'] != null
                              ? IconButton(
                                  icon: const Icon(Icons.image_outlined, color: Colors.blue),
                                  onPressed: () async {
                                    final url = await DatabaseService.instance.getSignedUrl(item['deptpaidimagepath']);
                                    if (context.mounted && url != null) {
                                      _showFullScreenImage(context, url);
                                    }
                                  },
                                )
                              : null,
                        );
                      },

                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: (imagePath.startsWith('http') || imagePath.startsWith('blob:'))
                  ? Image.network(imagePath)
                  : Image.file(File(imagePath)),
            ),
            Positioned(
              top: 0, 
              right: 0, 
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx))
              )
            ),
          ],
        ),
      ),
    );
  }
}

class CreditorListView extends StatelessWidget {
  const CreditorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final poProvider = Provider.of<PurchaseOrderProvider>(context);
    final unpaidPOs = poProvider.purchaseHistory
        .where((po) => po['status'] == 'Confirmed' && po['paymentstatus'] == 'Pending')
        .toList();

    // จัดเรียง: เกินกำหนดขึ้นก่อน
    unpaidPOs.sort((a, b) {
      final dueA = a['due_date'] != null ? DateTime.parse(a['due_date']) : DateTime.now().add(const Duration(days: 365));
      final dueB = b['due_date'] != null ? DateTime.parse(b['due_date']) : DateTime.now().add(const Duration(days: 365));
      return dueA.compareTo(dueB);
    });

    return RefreshIndicator(
      onRefresh: () => poProvider.loadPurchaseHistory(),
      child: unpaidPOs.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่มีรายการเจ้าหนี้ค้างชำระ',
                        style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: unpaidPOs.length,
              itemBuilder: (ctx, i) {
                final po = unpaidPOs[i];
                final date = DateTime.parse(po['receivedate']);
                final dueDate = po['due_date'] != null ? DateTime.parse(po['due_date']) : null;
                final total = (po['totalcost'] as num).toDouble();
                final paid = (po['paidamount'] as num).toDouble();
                final balance = total - paid;
                
                final bool isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && balance > 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.transparent, width: 1),
                  ),
                  child: Column(
                    children: [
                      if (isOverdue)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Text('เกินกำหนดชำระให้ Supplier', 
                            textAlign: TextAlign.center,
                            style: GoogleFonts.prompt(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        onTap: () => _showPaymentHistory(context, po['poid'], poProvider),
                        title: Text('PO ID: ${po['poid']}', 
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ผู้จัดจำหน่าย: ${po['supplier']?['supplier_name'] ?? 'ไม่ระบุ'}', 
                              style: GoogleFonts.prompt(fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('วันที่รับ: ${date.day}/${date.month}/${date.year}', 
                                  style: GoogleFonts.prompt(fontSize: 11)),
                              ],
                            ),
                            if (dueDate != null)
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 12, color: isOverdue ? Colors.red : Colors.blue),
                                  const SizedBox(width: 4),
                                  Text('ต้องจ่ายภายใน: ${dueDate.day}/${dueDate.month}/${dueDate.year}', 
                                    style: GoogleFonts.prompt(
                                      fontSize: 11, 
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                      color: isOverdue ? Colors.red : Colors.blue)),
                                ],
                              ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: total > 0 ? (paid / total) : 0,
                                backgroundColor: Colors.grey[100],
                                color: Colors.green,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('฿${balance.toStringAsFixed(2)}', 
                              style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('จ่ายแล้ว: ฿${paid.toStringAsFixed(2)}', 
                              style: GoogleFonts.prompt(fontSize: 10, color: Colors.green[700])),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showPaymentDialog(context, po['poid'], balance, poProvider),
                              icon: const Icon(Icons.add_card, size: 16),
                              label: Text('ชำระเงิน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E2736),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showPaymentDialog(BuildContext context, String poId, double balance, PurchaseOrderProvider provider) {
    final amountController = TextEditingController();
    XFile? pickedFile;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('บันทึกการชำระเงิน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PO ID: $poId', style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'จำนวนเงินที่ชำระ (คงค้าง ฿${balance.toStringAsFixed(2)})',
                    labelStyle: GoogleFonts.prompt(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixText: '฿ ',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (result != null) {
                      setDialogState(() => pickedFile = result);
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: pickedFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb 
                                ? Image.network(pickedFile!.path, fit: BoxFit.cover)
                                : Image.file(File(pickedFile!.path), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                              Text('แนบสลิป/หลักฐาน (ถ้ามี)', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2736),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0 || amount > (balance + 0.01)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('กรุณากรอกจำนวนเงินให้ถูกต้อง', style: GoogleFonts.prompt())),
                  );
                  return;
                }

                await provider.addPayment(
                  poId: poId,
                  amount: amount,
                  image: pickedFile,
                );

                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกการชำระเงินสำเร็จ', style: GoogleFonts.prompt()), backgroundColor: Colors.green),
                );
              },
              child: Text('ยืนยันชำระ', style: GoogleFonts.prompt(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentHistory(BuildContext context, String poId, PurchaseOrderProvider provider) async {
    final history = await provider.getPaymentHistory(poId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ประวัติการชำระเงิน', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('PO ID: $poId', style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            Expanded(
              child: history.isEmpty
                  ? Center(child: Text('ยังไม่มีประวัติการชำระเงิน', style: GoogleFonts.prompt()))
                  : ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (c, i) {
                        final item = history[i];
                        final date = DateTime.parse(item['paiddate']);
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.check, color: Colors.green[700]),
                          ),
                          title: Text('฿${(item['amountpaid'] as num).toStringAsFixed(2)}', 
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                          subtitle: Text('วันที่: ${date.toString().split('.')[0]}', style: GoogleFonts.prompt(fontSize: 12)),
                          trailing: item['paidimagepath'] != null
                              ? IconButton(
                                  icon: const Icon(Icons.image_outlined, color: Colors.blue),
                                  onPressed: () async {
                                    final url = await DatabaseService.instance.getSignedUrl(item['paidimagepath']);
                                    if (context.mounted && url != null) {
                                      _showFullScreenImage(context, url);
                                    }
                                  },
                                )
                              : null,
                        );
                      },

                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: (imagePath.startsWith('http') || imagePath.startsWith('blob:'))
                  ? Image.network(imagePath)
                  : Image.file(File(imagePath)),
            ),
            Positioned(
              top: 0, 
              right: 0, 
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx))
              )
            ),
          ],
        ),
      ),
    );
  }
}

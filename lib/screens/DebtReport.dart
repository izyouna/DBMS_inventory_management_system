import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/purchase_order_provider.dart';

class DebtReportScreen extends StatefulWidget {
  const DebtReportScreen({super.key});

  @override
  State<DebtReportScreen> createState() => _DebtReportScreenState();
}

class _DebtReportScreenState extends State<DebtReportScreen> {
  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลล่าสุดเมื่อเข้าหน้าจอ
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
          title: Text('รายการค้างชำระ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF1E2736),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E2736),
            labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'ลูกหนี้ (เงินเข้า)', icon: Icon(Icons.person_outline)),
              Tab(text: 'เจ้าหนี้ (เงินออก)', icon: Icon(Icons.business_outlined)),
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
    final debtRecords = cartProvider.debtRecords.where((d) => d['DeptStatus'] == 'Pending').toList();

    // จัดเรียงตามชื่อ CustomerName (ก-ฮ, A-Z)
    debtRecords.sort((a, b) {
      String nameA = (a['CustomerName'] ?? '').toString();
      String nameB = (b['CustomerName'] ?? '').toString();
      return nameA.compareTo(nameB);
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
                final date = DateTime.parse(debt['StartDate']);
                final total = (debt['OriginalAmount'] as num).toDouble();
                final balance = (debt['RemainingAmount'] as num).toDouble();
                final paid = total - balance;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => _showDebtPaymentHistory(context, debt['DebtID'], cartProvider),
                        title: Text(debt['CustomerName'] ?? 'ไม่ระบุชื่อ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('โทร: ${debt['Phone'] ?? '-'}', style: GoogleFonts.prompt(fontSize: 12)),
                            Text('วันที่: ${date.toString().split('.')[0]}', style: GoogleFonts.prompt(fontSize: 12)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: total > 0 ? (paid / total) : 0,
                                backgroundColor: Colors.grey[200],
                                color: Colors.blue,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('ยอดคงค้าง: ฿${balance.toStringAsFixed(2)}', 
                              style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold)),
                            Text('ยอดเดิม: ฿${total.toStringAsFixed(2)}', 
                              style: GoogleFonts.prompt(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showDebtPaymentDialog(context, debt['DebtID'], balance, cartProvider),
                              icon: const Icon(Icons.payments_outlined, size: 18),
                              label: Text('รับชำระหนี้', style: GoogleFonts.prompt()),
                              style: TextButton.styleFrom(foregroundColor: Colors.green[800]),
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
    File? pickedImage;
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
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (pickedFile != null) {
                      setDialogState(() => pickedImage = File(pickedFile.path));
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
                    child: pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(pickedImage!, fit: BoxFit.cover),
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
                backgroundColor: Colors.green[700],
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
                  imagePath: pickedImage?.path,
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
                        final date = DateTime.parse(item['PaidDate']);
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.account_balance_wallet, color: Colors.blue[700]),
                          ),
                          title: Text('฿${(item['AmountPaid'] as num).toStringAsFixed(2)}', 
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                          subtitle: Text('วันที่: ${date.toString().split('.')[0]}', style: GoogleFonts.prompt(fontSize: 12)),
                          trailing: item['DeptPaidImagePath'] != null
                              ? IconButton(
                                  icon: const Icon(Icons.image_outlined, color: Colors.blue),
                                  onPressed: () => _showFullScreenImage(context, item['DeptPaidImagePath']),
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
            InteractiveViewer(child: Image.file(File(imagePath))),
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
        .where((po) => po['Status'] == 'Confirmed' && po['PaymentStatus'] == 'Pending')
        .toList();

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
                final date = DateTime.parse(po['ReceiveDate']);
                final total = (po['TotalCost'] as num).toDouble();
                final paid = (po['PaidAmount'] as num).toDouble();
                final balance = total - paid;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => _showPaymentHistory(context, po['POID'], poProvider),
                        title: Text('PO ID: ${po['POID']}', 
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('วันที่: ${date.toString().split('.')[0]}', style: GoogleFonts.prompt(fontSize: 12)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: total > 0 ? (paid / total) : 0,
                                backgroundColor: Colors.grey[200],
                                color: Colors.green,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('คงค้าง: ฿${balance.toStringAsFixed(2)}', 
                              style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold)),
                            Text('จ่ายแล้ว: ฿${paid.toStringAsFixed(2)}', 
                              style: GoogleFonts.prompt(fontSize: 10, color: Colors.green[700])),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showPaymentDialog(context, po['POID'], balance, poProvider),
                              icon: const Icon(Icons.add_card, size: 18),
                              label: Text('ชำระเงินรายครั้ง', style: GoogleFonts.prompt()),
                              style: TextButton.styleFrom(foregroundColor: Colors.blue[800]),
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
    File? pickedImage;
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
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (pickedFile != null) {
                      setDialogState(() => pickedImage = File(pickedFile.path));
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
                    child: pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(pickedImage!, fit: BoxFit.cover),
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
                  imagePath: pickedImage?.path,
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
                        final date = DateTime.parse(item['PaidDate']);
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.check, color: Colors.green[700]),
                          ),
                          title: Text('฿${(item['AmountPaid'] as num).toStringAsFixed(2)}', 
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                          subtitle: Text('วันที่: ${date.toString().split('.')[0]}', style: GoogleFonts.prompt(fontSize: 12)),
                          trailing: item['PaidImagePath'] != null
                              ? IconButton(
                                  icon: const Icon(Icons.image_outlined, color: Colors.blue),
                                  onPressed: () => _showFullScreenImage(context, item['PaidImagePath']),
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
            InteractiveViewer(child: Image.file(File(imagePath))),
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

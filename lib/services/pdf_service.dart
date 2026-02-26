import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class PdfService {
  static Future<void> printOrder(Order order) async {
    final doc = pw.Document();
    
    // โหลดฟอนต์จาก Assets โดยตรง (ต้องมั่นใจว่ามีไฟล์ THSarabunNew.ttf ใน assets/fonts แล้ว)
    final fontData = await rootBundle.load("assets/fonts/THSarabunNew.ttf");
    final fontBoldData = await rootBundle.load("assets/fonts/THSarabunNew Bold.ttf");
    final font = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.dateTime);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final baseStyle = pw.TextStyle(font: font, fontSize: 14);
          final boldStyle = pw.TextStyle(font: fontBold, fontSize: 14);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  order.documentName,
                  style: boldStyle.copyWith(fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('เลขที่บิล: ${order.id}', style: baseStyle),
                  pw.Text('วันที่: $dateStr', style: baseStyle),
                ],
              ),
              
              if (order.customer != null) ...[
                pw.SizedBox(height: 5),
                pw.Text('ลูกค้า: ${order.customer!.name}', style: baseStyle),
                pw.Text('เบอร์โทร: ${order.customer!.phone}', style: baseStyle),
              ],
              
              pw.SizedBox(height: 20),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('รายการ', style: boldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('จำนวน', style: boldStyle, textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ราคา/หน่วย', style: boldStyle, textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('รวม', style: boldStyle, textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...order.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.product.name, style: baseStyle)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.quantity} ${item.product.unit.label}', style: baseStyle, textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(NumberFormat('#,##0.00').format(item.product.price), style: baseStyle, textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(NumberFormat('#,##0.00').format(item.total), style: baseStyle, textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ยอดรวมทั้งสิ้น: ${NumberFormat('#,##0.00').format(order.totalAmount)} บาท',
                        style: boldStyle.copyWith(fontSize: 18),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('ชำระโดย: ${order.paymentMethod}', style: baseStyle),
                      pw.Text(
                        'สถานะ: ${order.isPaid ? "ชำระเงินเรียบร้อย" : "ยังไม่ได้ชำระเงิน (ค้างหนี้)"}',
                        style: boldStyle,
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Spacer(),
              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text('ขอบคุณที่อุดหนุน "ร้านเกษตรภัณฑ์"', style: baseStyle.copyWith(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${order.documentName}_${order.id}',
    );
  }
}

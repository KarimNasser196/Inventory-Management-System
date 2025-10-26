// lib/services/invoice_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class InvoiceService {
  /// إنشاء فاتورة PDF
  static Future<pw.Document> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // تحميل خط عربي (من الضروري للنصوص العربية)
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(invoice),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Invoice Info
              _buildInvoiceInfo(invoice),
              pw.SizedBox(height: 20),

              // Items Table
              _buildItemsTable(invoice),
              pw.SizedBox(height: 20),

              // Totals
              _buildTotals(invoice),

              pw.Spacer(),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// عرض فاتورة للطباعة
  static Future<void> printInvoice(Invoice invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'فاتورة_${invoice.invoiceNumber}.pdf',
    );
  }

  /// حفظ فاتورة كملف PDF
  static Future<void> saveInvoice(Invoice invoice, String path) async {
    final pdf = await generateInvoicePdf(invoice);
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
  }

  /// بناء رأس الفاتورة
  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#2196F3'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'نظام إدارة المخزون',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'فاتورة مبيعات',
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#2196F3'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء معلومات الفاتورة
  static pw.Widget _buildInvoiceInfo(Invoice invoice) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm', 'ar');

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow('رقم الفاتورة:', invoice.invoiceNumber),
              pw.SizedBox(height: 8),
              _buildInfoRow(
                'التاريخ:',
                dateFormat.format(invoice.invoiceDate),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow('اسم العميل:', invoice.customerName),
              if (invoice.notes != null) ...[
                pw.SizedBox(height: 8),
                _buildInfoRow('ملاحظات:', invoice.notes!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// بناء صف معلومات
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// بناء جدول المنتجات
  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#2196F3'),
          ),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('المنتج'),
            _buildTableHeader('الكمية'),
            _buildTableHeader('سعر الوحدة'),
            _buildTableHeader('الإجمالي'),
          ],
        ),

        // Data Rows
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell(index.toString()),
              _buildTableCell(item.productName),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell('${item.unitPrice.toStringAsFixed(2)} ج'),
              _buildTableCell('${item.total.toStringAsFixed(2)} ج'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// بناء رأس الجدول
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// بناء خلية الجدول
  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// بناء المجاميع
  static pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('المجموع الفرعي:', invoice.subtotal, false),
          if (invoice.tax > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('الضريبة:', invoice.tax, false),
          ],
          if (invoice.discount > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('الخصم:', invoice.discount, false),
          ],
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 12),
          _buildTotalRow('الإجمالي النهائي:', invoice.total, true),
        ],
      ),
    );
  }

  /// بناء صف المجموع
  static pw.Widget _buildTotalRow(String label, double amount, bool isFinal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isFinal ? 16 : 14,
            fontWeight: isFinal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          '${amount.toStringAsFixed(2)} جنيه',
          style: pw.TextStyle(
            fontSize: isFinal ? 18 : 14,
            fontWeight: pw.FontWeight.bold,
            color: isFinal ? PdfColor.fromHex('#2196F3') : PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// بناء تذييل الفاتورة
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'شكراً لتعاملكم معنا',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'للاستفسارات: اتصل بنا',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}

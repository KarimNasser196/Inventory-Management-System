// lib/services/invoice_service.dart (FIXED)

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

    // تحميل خط عربي مع معالجة الأخطاء
    pw.Font? arabicFont;
    pw.Font? arabicFontBold;

    try {
      arabicFont = await PdfGoogleFonts.cairoRegular();
      arabicFontBold = await PdfGoogleFonts.cairoBold();
    } catch (e) {
      print('Error loading Arabic fonts: $e');
      // استخدام الخط الافتراضي في حالة الفشل
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: arabicFont != null && arabicFontBold != null
            ? pw.ThemeData.withFont(
                base: arabicFont,
                bold: arabicFontBold,
              )
            : pw.ThemeData.base(),
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

              // Signature
              _buildSignature(),

              pw.SizedBox(height: 10),

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
    try {
      final pdf = await generateInvoicePdf(invoice);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'invoice_${invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      print('Error printing invoice: $e');
      rethrow;
    }
  }

  /// حفظ فاتورة كملف PDF
  static Future<void> saveInvoice(Invoice invoice, String path) async {
    try {
      final pdf = await generateInvoicePdf(invoice);
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
    } catch (e) {
      print('Error saving invoice: $e');
      rethrow;
    }
  }

  /// بناء رأس الفاتورة
  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#2196F3'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Reyad Soft Company',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Sales Invoice',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء معلومات الفاتورة
  static pw.Widget _buildInvoiceInfo(Invoice invoice) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Invoice #:', invoice.invoiceNumber),
              pw.SizedBox(height: 8),
              _buildInfoRow(
                'Date:',
                dateFormat.format(invoice.invoiceDate),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Customer:', invoice.customerName),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _buildInfoRow('Notes:', invoice.notes!),
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
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// بناء جدول المنتجات
  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey800, width: 1.5),
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#2196F3'),
          ),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('Product'),
            _buildTableHeader('Qty'),
            _buildTableHeader('Price'),
            _buildTableHeader('Total'),
          ],
        ),

        // Data Rows
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 0
                  ? PdfColors.white
                  : PdfColor.fromHex('#F5F5F5'),
            ),
            children: [
              _buildTableCell(index.toString()),
              _buildTableCell(item.productName),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell('${item.unitPrice.toStringAsFixed(2)} EGP'),
              _buildTableCell('${item.total.toStringAsFixed(2)} EGP'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// بناء رأس الجدول
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 14,
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
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// بناء المجاميع
  static pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey800, width: 1.5),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('Subtotal:', invoice.subtotal, false),
          if (invoice.discount > 0) ...[
            pw.SizedBox(height: 10),
            _buildTotalRow('Discount:', invoice.discount, false,
                isDiscount: true),
          ],
          if (invoice.tax > 0) ...[
            pw.SizedBox(height: 10),
            _buildTotalRow('Tax:', invoice.tax, false),
          ],
          pw.SizedBox(height: 15),
          pw.Divider(thickness: 2, color: PdfColors.grey800),
          pw.SizedBox(height: 15),
          _buildTotalRow('TOTAL:', invoice.finalTotal, true),
        ],
      ),
    );
  }

  /// بناء صف المجموع
  static pw.Widget _buildTotalRow(
    String label,
    double amount,
    bool isFinal, {
    bool isDiscount = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isFinal ? 18 : 15,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          '${amount.toStringAsFixed(2)} EGP',
          style: pw.TextStyle(
            fontSize: isFinal ? 20 : 15,
            fontWeight: pw.FontWeight.bold,
            color: isFinal
                ? PdfColor.fromHex('#2196F3')
                : isDiscount
                    ? PdfColor.fromHex('#F44336')
                    : PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// بناء التوقيع
  static pw.Widget _buildSignature() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Seller Signature',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                width: 150,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Customer Signature',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                width: 150,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء تذييل الفاتورة
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey800, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Contact us | Reyad Soft Company',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// lib/services/invoice_service.dart (UPDATED - Enhanced for B&W Printing)

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class InvoiceService {
  /// إنشاء فاتورة PDF محسنة للطباعة بالأبيض والأسود
  static Future<pw.Document> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // تحميل خط عربي
    pw.Font? arabicFont;
    pw.Font? arabicFontBold;

    try {
      arabicFont = await PdfGoogleFonts.cairoRegular();
      arabicFontBold = await PdfGoogleFonts.cairoBold();
    } catch (e) {
      print('Error loading Arabic fonts: $e');
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
              // Header with Company Info and Barcode
              _buildHeaderWithBarcode(invoice),
              pw.SizedBox(height: 15),
              pw.Container(
                width: double.infinity,
                height: 2,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 15),

              // Invoice Info
              _buildInvoiceInfo(invoice),
              pw.SizedBox(height: 15),

              // Items Table
              _buildItemsTable(invoice),
              pw.SizedBox(height: 15),

              // Totals
              _buildTotals(invoice),

              pw.Spacer(),

              // Warranty Text
              _buildWarrantyText(),
              pw.SizedBox(height: 15),

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

  /// بناء رأس الفاتورة مع الباركود
  static pw.Widget _buildHeaderWithBarcode(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Info (Right Side)
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Riad Soft Company',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '01019187734',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'Sales Invoice',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Barcode (Left Side)
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                width: 150,
                height: 60,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: invoice.invoiceNumber,
                  drawText: false,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                invoice.invoiceNumber,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء معلومات الفاتورة
  static pw.Widget _buildInvoiceInfo(Invoice invoice) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Invoice #:', invoice.invoiceNumber),
              pw.SizedBox(height: 6),
              _buildInfoRow('Date:', dateFormat.format(invoice.invoiceDate)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Customer:', invoice.customerName),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 6),
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
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// بناء جدول المنتجات
  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.2),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('Product'),
            _buildTableHeader('Qty'),
            _buildTableHeader('Price'),
            _buildTableHeader('Discount'),
            _buildTableHeader('Total'),
            _buildTableHeader('Profit'),
          ],
        ),

        // Data Rows
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell(index.toString()),
              _buildTableCell(item.productName, align: pw.TextAlign.right),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell('${item.unitPrice.toStringAsFixed(2)}'),
              _buildTableCell(item.discount > 0
                  ? '${item.discount.toStringAsFixed(2)}'
                  : '-'),
              _buildTableCell('${item.total.toStringAsFixed(2)}'),
              _buildTableCell('${item.profit.toStringAsFixed(2)}',
                  color: item.profit > 0 ? PdfColors.black : PdfColors.grey800),
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
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// بناء خلية الجدول
  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: color ?? PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }

  /// بناء المجاميع
  static pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('Subtotal:', invoice.subtotal, false),
          if (invoice.discount > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('Discount:', invoice.discount, false,
                isDiscount: true),
          ],
          if (invoice.tax > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('Tax:', invoice.tax, false),
          ],
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            height: 2,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 10),
          _buildTotalRow('TOTAL:', invoice.finalTotal, true),
          pw.SizedBox(height: 8),
          _buildTotalRow('Total Profit:', invoice.totalProfit, false,
              isProfit: true),
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
    bool isProfit = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isFinal ? 16 : 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          '${amount.toStringAsFixed(2)} EGP',
          style: pw.TextStyle(
            fontSize: isFinal ? 18 : 13,
            fontWeight: pw.FontWeight.bold,
            decoration: isFinal ? pw.TextDecoration.underline : null,
          ),
        ),
      ],
    );
  }

  /// بناء نص الضمان (من الصورة)
  static pw.Widget _buildWarrantyText() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Warranty Terms and Conditions:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '• Software warranty period is one week from purchase date.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Hardware warranty is subject to manufacturer terms.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Hardware returns are not accepted (exchanges only).',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• This invoice must be presented for warranty claims.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Products with physical damage void the warranty.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// بناء التوقيع
  static pw.Widget _buildSignature() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 15),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Seller Signature',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 25),
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
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 25),
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
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'For inquiries: 01019187734 | Riad Soft Company',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}

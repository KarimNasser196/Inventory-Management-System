// lib/services/invoice_service.dart (FINAL - Matches Screen Exactly + RTL Fix)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class InvoiceService {
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

    // تحميل صورة الباركود
    pw.ImageProvider? barcodeImage;
    try {
      final bytes = await rootBundle.load('assets/barcode.jpg');
      barcodeImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      print('Error loading barcode image: $e');
    }

    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    final timeFormat = DateFormat('hh:mm a', 'ar');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        textDirection: pw.TextDirection.rtl, // CRITICAL: RTL for Arabic
        theme: arabicFont != null && arabicFontBold != null
            ? pw.ThemeData.withFont(
                base: arabicFont,
                bold: arabicFontBold,
              )
            : pw.ThemeData.base(),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: const pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Riad Soft Company',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textDirection: pw.TextDirection.ltr,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            '01019187734',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textDirection: pw.TextDirection.ltr,
                          ),
                          pw.SizedBox(height: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                  color: PdfColors.black, width: 2),
                            ),
                            child: pw.Text(
                              'فاتورة مبيعات',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      children: [
                        if (barcodeImage != null)
                          pw.Container(
                            width: 120,
                            height: 50,
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Image(barcodeImage),
                          )
                        else
                          pw.Container(
                            width: 120,
                            height: 50,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                  color: PdfColors.black, width: 2),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                invoice.invoiceNumber,
                                style: const pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 2),

              // Invoice Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildInfoRow(
                              'رقم الفاتورة:', invoice.invoiceNumber),
                        ),
                        pw.Expanded(
                          child: _buildInfoRow('العميل:', invoice.customerName),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildInfoRow('التاريخ:',
                              dateFormat.format(invoice.invoiceDate)),
                        ),
                        pw.Expanded(
                          child: _buildInfoRow(
                              'الوقت:', timeFormat.format(invoice.invoiceDate)),
                        ),
                      ],
                    ),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      _buildInfoRow('ملاحظات:', invoice.notes!),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 2),

              // Items Table
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'المنتجات',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(
                          width: 1.5, color: PdfColors.grey400),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1.5),
                        1: const pw.FlexColumnWidth(1.5),
                        2: const pw.FlexColumnWidth(1),
                        3: const pw.FlexColumnWidth(3),
                        4: const pw.FlexColumnWidth(0.6),
                      },
                      children: [
                        // Header
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                          children: [
                            _buildTableHeader('الإجمالي'),
                            _buildTableHeader('السعر'),
                            _buildTableHeader('الكمية'),
                            _buildTableHeader('المنتج'),
                            _buildTableHeader('#'),
                          ],
                        ),

                        // Items
                        ...invoice.items.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final item = entry.value;
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: index.isEven
                                  ? PdfColors.grey50
                                  : PdfColors.white,
                            ),
                            children: [
                              _buildTableCell(
                                  '${item.total.toStringAsFixed(2)} جنيه',
                                  bold: true),
                              _buildTableCell(
                                  '${item.unitPrice.toStringAsFixed(2)}'),
                              _buildTableCell(item.quantity.toString()),
                              _buildTableCell(item.productName,
                                  align: pw.TextAlign.right),
                              _buildTableCell(index.toString()),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 2),

              // Totals
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 16),
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400, width: 2),
                ),
                child: pw.Column(
                  children: [
                    _buildTotalRow('المجموع الفرعي:', invoice.subtotal, false),
                    if (invoice.discount > 0) ...[
                      pw.SizedBox(height: 8),
                      _buildTotalRow('الخصم الإجمالي:', invoice.discount, false,
                          isDiscount: true),
                    ],
                    if (invoice.tax > 0) ...[
                      pw.SizedBox(height: 8),
                      _buildTotalRow('الضريبة:', invoice.tax, false),
                    ],
                    pw.SizedBox(height: 10),
                    pw.Container(height: 2, color: PdfColors.black),
                    pw.SizedBox(height: 10),
                    _buildTotalRow(
                        'الإجمالي النهائي:', invoice.finalTotal, true),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Warranty
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 16),
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'شروط وأحكام الضمان',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('• مدة ضمان البرامج أسبوع واحد من تاريخ الشراء',
                        style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 3),
                    pw.Text('• الضمان على الأجهزة حسب شروط الشركة المصنعة',
                        style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 3),
                    pw.Text('• لا يتم استرجاع الأجهزة (استبدال فقط)',
                        style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 3),
                    pw.Text('• يجب إحضار هذه الفاتورة عند المطالبة بالضمان',
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signature
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'توقيع البائع',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 25),
                    pw.Container(
                      width: 160,
                      height: 2,
                      color: PdfColors.black,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
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

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, bool isFinal,
      {bool isDiscount = false}) {
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
          '${amount.toStringAsFixed(2)} جنيه',
          style: pw.TextStyle(
            fontSize: isFinal ? 18 : 13,
            fontWeight: pw.FontWeight.bold,
            color: isDiscount ? PdfColors.red700 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static Future<void> printInvoice(Invoice invoice) async {
    try {
      final pdf = await generateInvoicePdf(invoice);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'فاتورة_${invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      print('Error printing invoice: $e');
      rethrow;
    }
  }

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
}

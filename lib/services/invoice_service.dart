// lib/services/invoice_service.dart (UPDATED - Real Barcode Image)

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

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
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
              // Header with real barcode
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 15),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Riad Soft Company',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '01019187734',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 2),
                            ),
                            child: pw.Text(
                              'Sales Invoice',
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
                            child: pw.Image(barcodeImage),
                          )
                        else
                          pw.Container(
                            width: 120,
                            height: 50,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                invoice.invoiceNumber,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.invoiceNumber,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Invoice Info
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoRow('Invoice #:', invoice.invoiceNumber),
                        _buildInfoRow('Customer:', invoice.customerName),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoRow(
                            'Date:', dateFormat.format(invoice.invoiceDate)),
                        _buildInfoRow(
                            'Time:', timeFormat.format(invoice.invoiceDate)),
                      ],
                    ),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      _buildInfoRow('Notes:', invoice.notes!),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Items Table (without profit)
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableHeader('#'),
                      _buildTableHeader('Product'),
                      _buildTableHeader('Qty'),
                      _buildTableHeader('Price'),
                      _buildTableHeader('Discount'),
                      _buildTableHeader('Total'),
                    ],
                  ),

                  // Items
                  ...invoice.items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell(index.toString()),
                        _buildTableCell(item.productName,
                            align: pw.TextAlign.right),
                        _buildTableCell(item.quantity.toString()),
                        _buildTableCell('${item.unitPrice.toStringAsFixed(2)}'),
                        _buildTableCell(
                          item.discount > 0
                              ? '${item.discount.toStringAsFixed(2)}'
                              : '-',
                        ),
                        _buildTableCell('${item.total.toStringAsFixed(2)}',
                            bold: true),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 15),

              // Totals
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                ),
                child: pw.Column(
                  children: [
                    _buildTotalRow('Subtotal:', invoice.subtotal, false),
                    if (invoice.discount > 0) ...[
                      pw.SizedBox(height: 6),
                      _buildTotalRow('Discount:', invoice.discount, false),
                    ],
                    if (invoice.tax > 0) ...[
                      pw.SizedBox(height: 6),
                      _buildTotalRow('Tax:', invoice.tax, false),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Container(height: 2, color: PdfColors.black),
                    pw.SizedBox(height: 8),
                    _buildTotalRow('TOTAL:', invoice.finalTotal, true),
                  ],
                ),
              ),

              pw.Spacer(),

              // Warranty
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Warranty Terms:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('• Software warranty: 1 week from purchase',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('• Hardware warranty per manufacturer terms',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('• No hardware returns (exchange only)',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('• Invoice required for warranty claims',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Seller Signature Only
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Seller Signature',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(width: 2),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your business',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'For inquiries: 01019187734 | Riad Soft Company',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
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
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, bool isFinal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isFinal ? 13 : 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          '${amount.toStringAsFixed(2)} EGP',
          style: pw.TextStyle(
            fontSize: isFinal ? 14 : 11,
            fontWeight: pw.FontWeight.bold,
            decoration: isFinal ? pw.TextDecoration.underline : null,
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
        name: 'invoice_${invoice.invoiceNumber}.pdf',
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

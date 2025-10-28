// lib/screens/invoice_screen.dart (UPDATED - B&W Optimized with Real Barcode)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    final timeFormat = DateFormat('hh:mm a', 'ar');

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفاتورة'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
            tooltip: 'طباعة',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header - Black and White optimized
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Riad Soft Company',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '01019187734',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: const Text(
                                    'فاتورة مبيعات',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                // Barcode placeholder - سيتم استبداله بالصورة الحقيقية في PDF
                                Container(
                                  width: 150,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black, width: 1),
                                  ),
                                  child: Image.asset(
                                    'assets/barcode.jpg',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.qr_code, size: 30),
                                            Text(
                                              invoice.invoiceNumber,
                                              style:
                                                  const TextStyle(fontSize: 8),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  invoice.invoiceNumber,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Invoice Info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.grey[400]!, width: 1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoItem(
                                    'رقم الفاتورة:', invoice.invoiceNumber),
                                _buildInfoItem('العميل:', invoice.customerName),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoItem(
                                  'التاريخ:',
                                  dateFormat.format(invoice.invoiceDate),
                                ),
                                _buildInfoItem(
                                  'الوقت:',
                                  timeFormat.format(invoice.invoiceDate),
                                ),
                              ],
                            ),
                            if (invoice.notes != null &&
                                invoice.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoItem('ملاحظات:', invoice.notes!),
                            ],
                          ],
                        ),
                      ),

                      // Items Table - Without profit column
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Table(
                          border:
                              TableBorder.all(color: Colors.black, width: 1),
                          columnWidths: const {
                            0: FlexColumnWidth(0.5),
                            1: FlexColumnWidth(3),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1.5),
                            4: FlexColumnWidth(1.2),
                            5: FlexColumnWidth(1.5),
                          },
                          children: [
                            // Header
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                              ),
                              children: const [
                                _TableHeader('#'),
                                _TableHeader('المنتج'),
                                _TableHeader('الكمية'),
                                _TableHeader('السعر'),
                                _TableHeader('خصم'),
                                _TableHeader('الإجمالي'),
                              ],
                            ),
                            // Items
                            ...invoice.items.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final item = entry.value;
                              return TableRow(
                                children: [
                                  _TableCell(index.toString()),
                                  _TableCell(item.productName,
                                      align: TextAlign.right),
                                  _TableCell(item.quantity.toString()),
                                  _TableCell(
                                      '${item.unitPrice.toStringAsFixed(2)}'),
                                  _TableCell(
                                    item.discount > 0
                                        ? '${item.discount.toStringAsFixed(2)}'
                                        : '-',
                                  ),
                                  _TableCell(
                                    '${item.total.toStringAsFixed(2)}',
                                    bold: true,
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      // Totals
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Column(
                            children: [
                              _buildTotalRow(
                                  'المجموع الفرعي:', invoice.subtotal),
                              if (invoice.discount > 0) ...[
                                const SizedBox(height: 8),
                                _buildTotalRow('الخصم:', invoice.discount,
                                    isDiscount: true),
                              ],
                              if (invoice.tax > 0) ...[
                                const SizedBox(height: 8),
                                _buildTotalRow('الضريبة:', invoice.tax),
                              ],
                              const SizedBox(height: 8),
                              const Divider(color: Colors.black, thickness: 2),
                              const SizedBox(height: 8),
                              _buildTotalRow(
                                'الإجمالي النهائي:',
                                invoice.finalTotal,
                                isFinal: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Warranty Terms
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'شروط وأحكام الضمان',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                                '• مدة ضمان البرامج أسبوع واحد من تاريخ الشراء',
                                style: TextStyle(fontSize: 12)),
                            const Text(
                                '• الضمان على الأجهزة حسب شروط الشركة المصنعة',
                                style: TextStyle(fontSize: 12)),
                            const Text('• لا يتم استرجاع الأجهزة (استبدال فقط)',
                                style: TextStyle(fontSize: 12)),
                            const Text(
                                '• يجب إحضار هذه الفاتورة عند المطالبة بالضمان',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Seller Signature Only
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'توقيع البائع',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              width: 200,
                              height: 2,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'شكراً لتعاملكم معنا',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'للاستفسارات: 01019187734 | Riad Soft Company',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _printInvoice(context),
        icon: const Icon(Icons.print),
        label: const Text('طباعة الفاتورة'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isFinal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isFinal ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} جنيه',
          style: TextStyle(
            fontSize: isFinal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.red : Colors.black,
            decoration: isFinal ? TextDecoration.underline : null,
          ),
        ),
      ],
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري تجهيز الفاتورة للطباعة...'),
            ],
          ),
        ),
      );

      await InvoiceService.printInvoice(invoice);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم فتح نافذة الطباعة'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الطباعة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  final bool bold;

  const _TableCell(
    this.text, {
    this.align = TextAlign.center,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}

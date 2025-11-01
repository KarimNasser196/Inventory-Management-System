// lib/screens/invoice_screen.dart (FINAL - Simple Clean Design)

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
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
            tooltip: 'طباعة',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Riad Soft Company',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '01019187734',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: const Text(
                                'فاتورة مبيعات',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: 140,
                            height: 60,
                            child: Image.asset(
                              'assets/barcode.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    invoice.invoiceNumber,
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
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
                      bottom: BorderSide(color: Colors.grey[300]!, width: 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                                'رقم الفاتورة:', invoice.invoiceNumber),
                          ),
                          Expanded(
                            child:
                                _buildInfoRow('العميل:', invoice.customerName),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow('التاريخ:',
                                dateFormat.format(invoice.invoiceDate)),
                          ),
                          Expanded(
                            child: _buildInfoRow('الوقت:',
                                timeFormat.format(invoice.invoiceDate)),
                          ),
                        ],
                      ),
                      if (invoice.notes != null &&
                          invoice.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow('ملاحظات:', invoice.notes!),
                      ],
                    ],
                  ),
                ),

                // Items Table
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المنتجات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Table(
                        border: TableBorder.all(
                            color: Colors.grey[400]!, width: 1.5),
                        columnWidths: const {
                          0: FlexColumnWidth(0.6),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1.5),
                          4: FlexColumnWidth(1.5),
                        },
                        children: [
                          // Header
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                            ),
                            children: const [
                              _TableHeader('#'),
                              _TableHeader('المنتج'),
                              _TableHeader('الكمية'),
                              _TableHeader('السعر'),
                              _TableHeader('الإجمالي'),
                            ],
                          ),
                          // Items
                          ...invoice.items.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final item = entry.value;
                            return TableRow(
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? Colors.grey[50]
                                    : Colors.white,
                              ),
                              children: [
                                _TableCell(index.toString()),
                                _TableCell(item.productName,
                                    align: TextAlign.right),
                                _TableCell(item.quantity.toString()),
                                _TableCell(item.unitPrice.toStringAsFixed(2)),
                                _TableCell(
                                    '${item.total.toStringAsFixed(2)} جنيه',
                                    bold: true),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // Totals
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: Column(
                    children: [
                      _buildTotalRow('المجموع الفرعي:', invoice.subtotal),
                      if (invoice.discount > 0) ...[
                        const SizedBox(height: 10),
                        _buildTotalRow('الخصم الإجمالي:', invoice.discount,
                            isDiscount: true),
                      ],
                      if (invoice.tax > 0) ...[
                        const SizedBox(height: 10),
                        _buildTotalRow('الضريبة:', invoice.tax),
                      ],
                      const SizedBox(height: 12),
                      const Divider(color: Colors.black, thickness: 2),
                      const SizedBox(height: 12),
                      _buildTotalRow('الإجمالي النهائي:', invoice.finalTotal,
                          isFinal: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Warranty
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWarrantyItem(
                          '• ضمان الاوريجنال لمدة شهر من تاريخ الشراء'),
                      _buildWarrantyItem(
                          '• ضمان جميع الفلاشات 6 شهور من تاريخ الشراء'),
                      _buildWarrantyItem(
                          '• جميع الاكسسوارات بدون ضمان (ضمان تجربة فقط)'),
                      _buildWarrantyItem(
                          '• فترة اختبار المنتج يومان من الاستلام'),
                      _buildWarrantyItem(
                        '• استلام الفاتورة يُعتبر إقرارًا من العميل باستلام المنتج بالمواصفات الموضحة بالفاتورة',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Signature
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _printInvoice(context),
        icon: const Icon(Icons.print),
        label: const Text('طباعة'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
      ),
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
            fontSize: isFinal ? 18 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} جنيه',
          style: TextStyle(
            fontSize: isFinal ? 20 : 15,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.red[700] : Colors.black,
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
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
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
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}

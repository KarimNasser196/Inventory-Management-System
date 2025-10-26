// lib/models/invoice.dart

class Invoice {
  final int? id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? notes;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.items,
    this.tax = 0,
    this.discount = 0,
    this.notes,
  })  : subtotal = items.fold<double>(0.0, (sum, item) => sum + item.total),
        total = items.fold<double>(0.0, (sum, item) => sum + item.total) +
            tax -
            discount;

  // حساب الإجمالي مع الضريبة والخصم
  double get finalTotal => subtotal + tax - discount;

  // توليد رقم فاتورة فريد
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
  }
}

class InvoiceItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  }) : total = quantity * unitPrice;
}

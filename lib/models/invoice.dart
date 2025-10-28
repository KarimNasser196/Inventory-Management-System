// lib/models/invoice.dart (UPDATED - With Discount & Purchase Price)

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
  })  : subtotal = items.fold<double>(0.0, (sum, item) => sum + item.subtotal),
        total = items.fold<double>(0.0, (sum, item) => sum + item.total) + tax;

  // حساب الإجمالي مع الضريبة
  double get finalTotal => subtotal - discount + tax;

  // حساب إجمالي الربح
  double get totalProfit => items.fold<double>(
      0.0,
      (sum, item) =>
          sum +
          ((item.unitPrice -
                  item.discount / item.quantity -
                  item.purchasePrice) *
              item.quantity));

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
  final double discount; // خصم المنتج
  final double purchasePrice; // سعر الشراء للحساب الربح
  final double subtotal;
  final double total;

  InvoiceItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.purchasePrice = 0,
  })  : subtotal = quantity * unitPrice,
        total = (quantity * unitPrice) - discount;

  double get profit =>
      ((unitPrice - discount / quantity) - purchasePrice) * quantity;
}

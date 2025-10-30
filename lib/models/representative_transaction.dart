// lib/models/representative_transaction.dart

class RepresentativeTransaction {
  final int? id;
  final int representativeId;
  final String representativeName;
  final String type; // 'بيع', 'دفعة', 'مرتجع'
  final double amount; // المبلغ الإجمالي
  final double paidAmount; // المبلغ المدفوع
  final double remainingDebt; // المتبقي
  final String? productsSummary; // ملخص المنتجات
  final DateTime dateTime;
  final String? notes;
  final String? invoiceNumber;
  final String? saleIds; // IDs المبيعات المرتبطة (مفصولة بفاصلة)

  RepresentativeTransaction({
    this.id,
    required this.representativeId,
    required this.representativeName,
    required this.type,
    required this.amount,
    this.paidAmount = 0.0,
    this.remainingDebt = 0.0,
    this.productsSummary,
    DateTime? dateTime,
    this.notes,
    this.invoiceNumber,
    this.saleIds,
  }) : dateTime = dateTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'representativeId': representativeId,
      'representativeName': representativeName,
      'type': type,
      'amount': amount,
      'paidAmount': paidAmount,
      'remainingDebt': remainingDebt,
      'productsSummary': productsSummary,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
      'invoiceNumber': invoiceNumber,
      'saleIds': saleIds,
    };
  }

  factory RepresentativeTransaction.fromMap(Map<String, dynamic> map) {
    return RepresentativeTransaction(
      id: map['id'] as int?,
      representativeId: map['representativeId'] as int,
      representativeName: map['representativeName'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingDebt: (map['remainingDebt'] as num?)?.toDouble() ?? 0.0,
      productsSummary: map['productsSummary'] as String?,
      dateTime: DateTime.parse(map['dateTime'] as String),
      notes: map['notes'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      saleIds: map['saleIds'] as String?,
    );
  }

  String getFormattedDateTime() {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String getTypeInArabic() {
    switch (type) {
      case 'بيع':
        return 'عملية بيع';
      case 'دفعة':
        return 'دفعة نقدية';
      case 'مرتجع':
        return 'مرتجع بضاعة';
      default:
        return type;
    }
  }
}

// lib/models/representative_transaction.dart

class RepresentativeTransaction {
  final int? id;
  final int representativeId;
  final String representativeName;
  final String type; // 'sale' أو 'payment' أو 'return'
  final double amount;
  final double remainingDebt;
  final List<String> products; // أسماء المنتجات
  final DateTime dateTime;
  final String? notes;
  final String? invoiceNumber;

  RepresentativeTransaction({
    this.id,
    required this.representativeId,
    required this.representativeName,
    required this.type,
    required this.amount,
    required this.remainingDebt,
    required this.products,
    DateTime? dateTime,
    this.notes,
    this.invoiceNumber,
  }) : dateTime = dateTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'representativeId': representativeId,
      'representativeName': representativeName,
      'type': type,
      'amount': amount,
      'remainingDebt': remainingDebt,
      'products': products.join(','),
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
      'invoiceNumber': invoiceNumber,
    };
  }

  factory RepresentativeTransaction.fromMap(Map<String, dynamic> map) {
    return RepresentativeTransaction(
      id: map['id'] as int?,
      representativeId: map['representativeId'] as int,
      representativeName: map['representativeName'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      remainingDebt: (map['remainingDebt'] as num).toDouble(),
      products: (map['products'] as String).split(',').where((e) => e.isNotEmpty).toList(),
      dateTime: DateTime.parse(map['dateTime'] as String),
      notes: map['notes'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
    );
  }
}

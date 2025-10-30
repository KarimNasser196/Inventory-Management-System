// lib/models/return_detail.dart

class ReturnDetail {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final int quantityReturned;
  final double unitPrice;
  final double totalAmount;
  final DateTime returnDateTime;
  final String? reason;
  final String? representativeId;

  ReturnDetail({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantityReturned,
    required this.unitPrice,
    required this.totalAmount,
    DateTime? returnDateTime,
    this.reason,
    this.representativeId,
  }) : returnDateTime = returnDateTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'quantityReturned': quantityReturned,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'returnDateTime': returnDateTime.toIso8601String(),
      'reason': reason,
      'representativeId': representativeId,
    };
  }

  factory ReturnDetail.fromMap(Map<String, dynamic> map) {
    return ReturnDetail(
      id: map['id'] as int?,
      saleId: map['saleId'] as int,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      quantityReturned: map['quantityReturned'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      returnDateTime: DateTime.parse(map['returnDateTime'] as String),
      reason: map['reason'] as String?,
      representativeId: map['representativeId'] as String?,
    );
  }

  String getFormattedDateTime() {
    return '${returnDateTime.year}-${returnDateTime.month.toString().padLeft(2, '0')}-${returnDateTime.day.toString().padLeft(2, '0')} ${returnDateTime.hour.toString().padLeft(2, '0')}:${returnDateTime.minute.toString().padLeft(2, '0')}';
  }
}

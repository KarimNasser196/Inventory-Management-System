// lib/models/sale_transaction.dart (UPDATED WITH REPRESENTATIVES & PAYMENTS)

import 'package:flutter/foundation.dart';

class SaleTransaction {
  int? id;
  int productId;
  String productName;
  String priceType;
  double unitPrice;
  double purchasePrice;
  int quantitySold;
  int quantityRemainingInStock;
  String customerName;
  String supplierName;
  DateTime saleDateTime;
  String? notes;
  
  // ⭐ حقول جديدة للمندوبين والدفعات
  String? representativeId;
  String paymentType; // 'نقد' أو 'آجل'
  double paidAmount; // المبلغ المدفوع
  double remainingAmount; // المتبقي

  double get totalAmount => (unitPrice * quantitySold).toDouble();
  
  bool get isFullyPaid => remainingAmount <= 0;
  
  bool get isDeferred => paymentType == 'آجل';

  SaleTransaction({
    this.id,
    required this.productId,
    required this.productName,
    required this.priceType,
    required this.unitPrice,
    required this.purchasePrice,
    required this.quantitySold,
    required this.quantityRemainingInStock,
    required this.customerName,
    required this.supplierName,
    DateTime? saleDateTime,
    this.notes,
    this.representativeId,
    this.paymentType = 'نقد',
    double? paidAmount,
    double? remainingAmount,
  })  : saleDateTime = saleDateTime ?? DateTime.now(),
        paidAmount = paidAmount ?? 0.0,
        remainingAmount = remainingAmount ?? 0.0 {
    if (unitPrice < 0 || quantitySold < 0) {
      throw ArgumentError('Unit price and quantity must be non-negative');
    }
  }

  factory SaleTransaction.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(map['saleDateTime'] as String);
    } catch (e) {
      debugPrint('Error parsing date: $e, using current time');
      parsedDate = DateTime.now();
    }

    return SaleTransaction(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      priceType: map['priceType'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      quantitySold: map['quantitySold'] as int,
      quantityRemainingInStock: map['quantityRemainingInStock'] as int,
      customerName: map['customerName'] as String,
      supplierName: map['supplierName'] as String,
      saleDateTime: parsedDate,
      notes: map['notes'] as String?,
      representativeId: map['representativeId'] as String?,
      paymentType: map['paymentType'] as String? ?? 'نقد',
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'priceType': priceType,
      'unitPrice': unitPrice,
      'purchasePrice': purchasePrice,
      'quantitySold': quantitySold,
      'quantityRemainingInStock': quantityRemainingInStock,
      'totalAmount': totalAmount,
      'customerName': customerName,
      'supplierName': supplierName,
      'saleDateTime': saleDateTime.toIso8601String(),
      'notes': notes,
      'representativeId': representativeId,
      'paymentType': paymentType,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
    };
  }

  SaleTransaction copyWith({
    int? id,
    int? productId,
    String? productName,
    String? priceType,
    double? unitPrice,
    double? purchasePrice,
    int? quantitySold,
    int? quantityRemainingInStock,
    String? customerName,
    String? supplierName,
    DateTime? saleDateTime,
    String? notes,
    String? representativeId,
    String? paymentType,
    double? paidAmount,
    double? remainingAmount,
  }) {
    return SaleTransaction(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      priceType: priceType ?? this.priceType,
      unitPrice: unitPrice ?? this.unitPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      quantitySold: quantitySold ?? this.quantitySold,
      quantityRemainingInStock:
          quantityRemainingInStock ?? this.quantityRemainingInStock,
      customerName: customerName ?? this.customerName,
      supplierName: supplierName ?? this.supplierName,
      saleDateTime: saleDateTime ?? this.saleDateTime,
      notes: notes ?? this.notes,
      representativeId: representativeId ?? this.representativeId,
      paymentType: paymentType ?? this.paymentType,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
    );
  }

  String getFormattedDateTime() {
    return '${saleDateTime.year}-${saleDateTime.month.toString().padLeft(2, '0')}-${saleDateTime.day.toString().padLeft(2, '0')} ${saleDateTime.hour.toString().padLeft(2, '0')}:${saleDateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String getPaymentStatus() {
    if (paymentType == 'نقد') {
      return 'نقد';
    } else {
      if (isFullyPaid) {
        return 'مسدد';
      } else if (paidAmount > 0) {
        return 'دفعة جزئية';
      } else {
        return 'آجل';
      }
    }
  }
}

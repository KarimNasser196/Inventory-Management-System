// lib/models/sale_transaction.dart (FULLY FIXED)

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

  // FIX: Make totalAmount a getter so it always reflects current values
  double get totalAmount => (unitPrice * quantitySold).toDouble();

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
  }) : saleDateTime = saleDateTime ?? DateTime.now() {
    // Validate inputs
    if (unitPrice < 0 || quantitySold < 0) {
      throw ArgumentError('Unit price and quantity must be non-negative');
    }
  }

  factory SaleTransaction.fromMap(Map<String, dynamic> map) {
    // FIX: Safe DateTime parsing
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
    );
  }

  String getFormattedDateTime() {
    return '${saleDateTime.year}-${saleDateTime.month.toString().padLeft(2, '0')}-${saleDateTime.day.toString().padLeft(2, '0')} ${saleDateTime.hour.toString().padLeft(2, '0')}:${saleDateTime.minute.toString().padLeft(2, '0')}';
  }
}

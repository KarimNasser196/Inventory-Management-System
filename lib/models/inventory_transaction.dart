// lib/models/inventory_transaction.dart (FIXED & COMPLETE)

import 'package:flutter/foundation.dart';

class InventoryTransaction {
  int? id;
  int productId;
  String productName;
  String transactionType; // 'إضافة', 'بيع', 'استرجاع من بيع', 'إلغاء بيع'
  int quantityChange;
  int quantityAfter;
  DateTime dateTime;
  String? relatedSaleId; // ⭐ مهم: لربط الاسترجاع بالبيع الأصلي
  String? notes;

  InventoryTransaction({
    this.id,
    required this.productId,
    required this.productName,
    required this.transactionType,
    required this.quantityChange,
    required this.quantityAfter,
    DateTime? dateTime,
    this.relatedSaleId,
    this.notes,
  }) : dateTime = dateTime ?? DateTime.now();

  // ═══════════════════════════════════════════════════════════════
  // تحويل من Map إلى Object (مع معالجة آمنة للتاريخ)
  // ═══════════════════════════════════════════════════════════════

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    // FIX: Safe DateTime parsing with error handling
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(map['dateTime'] as String);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date: $e, using current time');
      }
      parsedDate = DateTime.now();
    }

    return InventoryTransaction(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      transactionType: map['transactionType'] as String,
      quantityChange: map['quantityChange'] as int,
      quantityAfter: map['quantityAfter'] as int,
      dateTime: parsedDate,
      relatedSaleId: map['relatedSaleId'] as String?,
      notes: map['notes'] as String?,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // تحويل من Object إلى Map (للحفظ في قاعدة البيانات)
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'transactionType': transactionType,
      'quantityChange': quantityChange,
      'quantityAfter': quantityAfter,
      'dateTime': dateTime.toIso8601String(),
      'relatedSaleId': relatedSaleId,
      'notes': notes,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // نسخ الكائن مع تعديل بعض القيم
  // ═══════════════════════════════════════════════════════════════

  InventoryTransaction copyWith({
    int? id,
    int? productId,
    String? productName,
    String? transactionType,
    int? quantityChange,
    int? quantityAfter,
    DateTime? dateTime,
    String? relatedSaleId,
    String? notes,
  }) {
    return InventoryTransaction(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      transactionType: transactionType ?? this.transactionType,
      quantityChange: quantityChange ?? this.quantityChange,
      quantityAfter: quantityAfter ?? this.quantityAfter,
      dateTime: dateTime ?? this.dateTime,
      relatedSaleId: relatedSaleId ?? this.relatedSaleId,
      notes: notes ?? this.notes,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════════════════════════

  /// هل هذه عملية استرجاع؟
  bool get isReturn => transactionType == 'استرجاع من بيع';

  /// هل هذه عملية بيع؟
  bool get isSale => transactionType == 'بيع';

  /// هل هذه عملية إضافة للمخزون؟
  bool get isAddition => transactionType == 'إضافة';

  /// هل هذه عملية إلغاء بيع؟
  bool get isCancellation => transactionType == 'إلغاء بيع';

  /// هل هذه المعاملة مرتبطة ببيع؟
  bool get hasRelatedSale => relatedSaleId != null && relatedSaleId!.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════
  // تحويل لـ JSON (للتصدير أو API)
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'transactionType': transactionType,
      'quantityChange': quantityChange,
      'quantityAfter': quantityAfter,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
      'relatedSaleId': relatedSaleId,
    };
  }

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['dateTime']);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing JSON date: $e');
      }
      parsedDate = DateTime.now();
    }

    return InventoryTransaction(
      id: json['id'] as int?,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      transactionType: json['transactionType'] as String,
      quantityChange: json['quantityChange'] as int,
      quantityAfter: json['quantityAfter'] as int,
      dateTime: parsedDate,
      notes: json['notes'] as String?,
      relatedSaleId: json['relatedSaleId'] as String?,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // toString للتصحيح
  // ═══════════════════════════════════════════════════════════════

  @override
  String toString() {
    return 'InventoryTransaction('
        'id: $id, '
        'productName: $productName, '
        'type: $transactionType, '
        'change: $quantityChange, '
        'after: $quantityAfter, '
        'date: $dateTime, '
        'relatedSale: $relatedSaleId'
        ')';
  }

  // ═══════════════════════════════════════════════════════════════
  // مقارنة الكائنات
  // ═══════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryTransaction &&
        other.id == id &&
        other.productId == productId &&
        other.transactionType == transactionType &&
        other.dateTime == dateTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        productId.hashCode ^
        transactionType.hashCode ^
        dateTime.hashCode;
  }
}

// ═══════════════════════════════════════════════════════════════
// أنواع المعاملات (Constants & Helper)
// ═══════════════════════════════════════════════════════════════

class TransactionTypes {
  static const String addition = 'إضافة';
  static const String sale = 'بيع';
  static const String returnFromSale = 'استرجاع من بيع';
  static const String saleCancellation = 'إلغاء بيع';
  static const String adjustment = 'تعديل';
  static const String damage = 'تالف';
  static const String transfer = 'نقل';

  static List<String> get allTypes => [
        addition,
        sale,
        returnFromSale,
        saleCancellation,
        adjustment,
        damage,
        transfer,
      ];

  /// الحصول على أيقونة حسب نوع المعاملة
  static String getIcon(String type) {
    switch (type) {
      case addition:
        return '➕';
      case sale:
        return '💰';
      case returnFromSale:
        return '↩️';
      case saleCancellation:
        return '❌';
      case adjustment:
        return '⚙️';
      case damage:
        return '⚠️';
      case transfer:
        return '🔄';
      default:
        return '📦';
    }
  }

  /// الحصول على لون حسب نوع المعاملة
  static int getColor(String type) {
    switch (type) {
      case addition:
        return 0xFF4CAF50; // Green
      case sale:
        return 0xFF2196F3; // Blue
      case returnFromSale:
        return 0xFFFF9800; // Orange
      case saleCancellation:
        return 0xFFF44336; // Red
      case adjustment:
        return 0xFF9C27B0; // Purple
      case damage:
        return 0xFFFF5722; // Deep Orange
      case transfer:
        return 0xFF00BCD4; // Cyan
      default:
        return 0xFF757575; // Gray
    }
  }
}

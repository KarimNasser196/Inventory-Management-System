// lib/models/inventory_transaction.dart (FIXED)

class InventoryTransaction {
  int? id;
  int productId;
  String productName;
  String transactionType;
  int quantityChange;
  int quantityAfter;
  DateTime dateTime;
  String? relatedSaleId;
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

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    // FIX: Safe DateTime parsing with error handling
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(map['dateTime'] as String);
    } catch (e) {
      print('Error parsing date: $e, using current time');
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
}

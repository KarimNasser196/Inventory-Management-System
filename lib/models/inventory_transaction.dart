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
    return InventoryTransaction(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      transactionType: map['transactionType'],
      quantityChange: map['quantityChange'],
      quantityAfter: map['quantityAfter'],
      dateTime: DateTime.parse(map['dateTime']),
      relatedSaleId: map['relatedSaleId'],
      notes: map['notes'],
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

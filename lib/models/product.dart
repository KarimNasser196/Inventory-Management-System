class Product {
  final int? id;
  final String name;
  final String? category;
  final String? warehouse;
  final String? specifications;
  final double purchasePrice;
  final double retailPrice;
  final double wholesalePrice;
  final double bulkWholesalePrice;
  final String supplierName;
  final int quantity;
  final DateTime dateAdded;
  final String? notes;

  Product({
    this.id,
    required this.name,
    this.category,
    this.warehouse,

    this.specifications,
    required this.purchasePrice,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.bulkWholesalePrice,
    required this.supplierName,
    required this.quantity,
    DateTime? dateAdded,
    this.notes,
  }) : dateAdded = dateAdded ?? DateTime.now();

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String?,
      warehouse: map['warehouse'] as String?,

      specifications: map['specifications'] as String?,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      retailPrice: (map['retailPrice'] as num).toDouble(),
      wholesalePrice: (map['wholesalePrice'] as num).toDouble(),
      bulkWholesalePrice: (map['bulkWholesalePrice'] as num).toDouble(),
      supplierName: map['supplierName'] as String,
      quantity: map['quantity'] as int,
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'warehouse': warehouse,

      'specifications': specifications,
      'purchasePrice': purchasePrice,
      'retailPrice': retailPrice,
      'wholesalePrice': wholesalePrice,
      'bulkWholesalePrice': bulkWholesalePrice,
      'supplierName': supplierName,
      'quantity': quantity,
      'dateAdded': dateAdded.toIso8601String(),
      'notes': notes,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? category,
    String? warehouse,
    String? model,
    String? specifications,
    double? purchasePrice,
    double? retailPrice,
    double? wholesalePrice,
    double? bulkWholesalePrice,
    String? supplierName,
    int? quantity,
    DateTime? dateAdded,
    String? notes,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      warehouse: warehouse ?? this.warehouse,

      specifications: specifications ?? this.specifications,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      bulkWholesalePrice: bulkWholesalePrice ?? this.bulkWholesalePrice,
      supplierName: supplierName ?? this.supplierName,
      quantity: quantity ?? this.quantity,
      dateAdded: dateAdded ?? this.dateAdded,
      notes: notes ?? this.notes,
    );
  }

  String getPriceType(int quantity) {
    if (quantity >= 50) return 'جملة جملة';
    if (quantity >= 10) return 'جملة';
    return 'فردي';
  }

  double getPrice(int quantity) {
    if (quantity >= 50) return bulkWholesalePrice;
    if (quantity >= 10) return wholesalePrice;
    return retailPrice;
  }
}

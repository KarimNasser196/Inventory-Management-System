// lib/models/customer.dart

class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double totalPurchases; // إجمالي المشتريات
  final DateTime createdAt;
  final String? notes;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.totalPurchases = 0.0,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'totalPurchases': totalPurchases,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      totalPurchases: (map['totalPurchases'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      notes: map['notes'] as String?,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? totalPurchases,
    DateTime? createdAt,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

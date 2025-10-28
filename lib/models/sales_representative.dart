// lib/models/sales_representative.dart

class SalesRepresentative {
  final int? id;
  final String name;
  final String? phone;
  final double totalDebt; // إجمالي الديون
  final double totalPaid; // إجمالي المدفوع
  final DateTime createdAt;
  final String? notes;

  SalesRepresentative({
    this.id,
    required this.name,
    this.phone,
    this.totalDebt = 0.0,
    this.totalPaid = 0.0,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingDebt => totalDebt - totalPaid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'totalDebt': totalDebt,
      'totalPaid': totalPaid,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory SalesRepresentative.fromMap(Map<String, dynamic> map) {
    return SalesRepresentative(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      totalDebt: (map['totalDebt'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      notes: map['notes'] as String?,
    );
  }

  SalesRepresentative copyWith({
    int? id,
    String? name,
    String? phone,
    double? totalDebt,
    double? totalPaid,
    DateTime? createdAt,
    String? notes,
  }) {
    return SalesRepresentative(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalDebt: totalDebt ?? this.totalDebt,
      totalPaid: totalPaid ?? this.totalPaid,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

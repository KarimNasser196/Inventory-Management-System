// lib/models/representative.dart

class Representative {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String type; // 'مندوب' أو 'عميل'
  final double totalDebt;
  final double totalPaid;
  final DateTime createdAt;
  final String? notes;

  Representative({
    this.id,
    required this.name,
    this.phone,
    this.address,
    required this.type,
    this.totalDebt = 0.0,
    this.totalPaid = 0.0,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingDebt => totalDebt - totalPaid;

  bool get hasDebt => remainingDebt > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'type': type,
      'totalDebt': totalDebt,
      'totalPaid': totalPaid,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Representative.fromMap(Map<String, dynamic> map) {
    return Representative(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      type: map['type'] as String,
      totalDebt: (map['totalDebt'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      notes: map['notes'] as String?,
    );
  }

  Representative copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? type,
    double? totalDebt,
    double? totalPaid,
    DateTime? createdAt,
    String? notes,
  }) {
    return Representative(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      type: type ?? this.type,
      totalDebt: totalDebt ?? this.totalDebt,
      totalPaid: totalPaid ?? this.totalPaid,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

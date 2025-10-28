// lib/models/warehouse.dart

class Warehouse {
  final int? id;
  final String name;
  final String? location;
  final String? notes;
  final DateTime createdAt;

  Warehouse({
    this.id,
    required this.name,
    this.location,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

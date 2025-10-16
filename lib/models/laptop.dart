class Laptop {
  int? id;
  String name;
  String serialNumber;
  String model;
  double price;
  String status; // متاح / مباع / مرتجع
  String? customer;
  DateTime? date;
  String? notes;

  Laptop({
    this.id,
    required this.name,
    required this.serialNumber,
    required this.model,
    required this.price,
    required this.status,
    this.customer,
    this.date,
    this.notes,
  });

  factory Laptop.fromMap(Map<String, dynamic> map) {
    return Laptop(
      id: map['id'],
      name: map['name'],
      serialNumber: map['serialNumber'],
      model: map['model'],
      price: map['price'],
      status: map['status'],
      customer: map['customer'],
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'serialNumber': serialNumber,
      'model': model,
      'price': price,
      'status': status,
      'customer': customer,
      'date': date?.toIso8601String(),
      'notes': notes,
    };
  }

  Laptop copyWith({
    int? id,
    String? name,
    String? serialNumber,
    String? model,
    double? price,
    String? status,
    String? customer,
    DateTime? date,
    String? notes,
  }) {
    return Laptop(
      id: id ?? this.id,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      model: model ?? this.model,
      price: price ?? this.price,
      status: status ?? this.status,
      customer: customer ?? this.customer,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}

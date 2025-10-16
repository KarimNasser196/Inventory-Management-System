class Sale {
  int? id;
  int laptopId;
  String customerName;
  double price;
  DateTime date;
  String? notes;

  Sale({
    this.id,
    required this.laptopId,
    required this.customerName,
    required this.price,
    required this.date,
    this.notes,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      laptopId: map['laptopId'],
      customerName: map['customerName'],
      price: map['price'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'laptopId': laptopId,
      'customerName': customerName,
      'price': price,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}

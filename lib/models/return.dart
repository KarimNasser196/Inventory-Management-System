class Return {
  int? id;
  int laptopId;
  DateTime date;
  String reason;

  Return({
    this.id,
    required this.laptopId,
    required this.date,
    required this.reason,
  });

  factory Return.fromMap(Map<String, dynamic> map) {
    return Return(
      id: map['id'],
      laptopId: map['laptopId'],
      date: DateTime.parse(map['date']),
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'laptopId': laptopId,
      'date': date.toIso8601String(),
      'reason': reason,
    };
  }
}

// lib/models/maintenance_record.dart (محدث مع رقم الهاتف)

import 'dart:math';

class MaintenanceRecord {
  int? id;
  String deviceType; // نوع الجهاز
  String customerName; // اسم العميل
  String customerPhone; // رقم هاتف العميل
  String problemDescription; // وصف المشكلة
  String status; // الحالة: "قيد الإصلاح", "جاهز للاستلام", "تم التسليم", "ملغي"
  double cost; // التكلفة
  double paidAmount; // المبلغ المدفوع
  DateTime receivedDate; // تاريخ الاستلام
  DateTime? deliveryDate; // تاريخ التسليم الفعلي
  String repairCode; // كود الصيانة (6 أرقام)

  MaintenanceRecord({
    this.id,
    required this.deviceType,
    required this.customerName,
    required this.customerPhone,
    required this.problemDescription,
    this.status = 'قيد الإصلاح',
    this.cost = 0,
    this.paidAmount = 0,
    DateTime? receivedDate,
    this.deliveryDate,
    String? repairCode,
  })  : receivedDate = receivedDate ?? DateTime.now(),
        repairCode = repairCode ?? _generateRepairCode();

  // توليد كود صيانة عشوائي مكون من 6 أرقام
  static String _generateRepairCode() {
    final random = Random();
    final code = random.nextInt(900000) + 100000; // رقم من 100000 إلى 999999
    return code.toString();
  }

  // الباقي من المبلغ
  double get remainingAmount => cost - paidAmount;

  // هل تم الدفع بالكامل
  bool get isFullyPaid => remainingAmount <= 0;

  // حالة الدفع
  String get paymentStatus {
    if (paidAmount == 0) return 'لم يدفع';
    if (isFullyPaid) return 'مدفوع بالكامل';
    return 'دفع جزئي';
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    DateTime parsedReceivedDate;
    try {
      parsedReceivedDate = DateTime.parse(map['receivedDate'] as String);
    } catch (e) {
      parsedReceivedDate = DateTime.now();
    }

    DateTime? parsedDeliveryDate;
    if (map['deliveryDate'] != null) {
      try {
        parsedDeliveryDate = DateTime.parse(map['deliveryDate'] as String);
      } catch (e) {
        parsedDeliveryDate = null;
      }
    }

    return MaintenanceRecord(
      id: map['id'] as int?,
      deviceType: map['deviceType'] as String,
      customerName: map['customerName'] as String,
      customerPhone:
          map['customerPhone'] as String? ?? '', // دعم السجلات القديمة
      problemDescription: map['problemDescription'] as String,
      status: map['status'] as String,
      cost: (map['cost'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      receivedDate: parsedReceivedDate,
      deliveryDate: parsedDeliveryDate,
      repairCode: map['repairCode'] as String? ?? _generateRepairCode(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceType': deviceType,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'problemDescription': problemDescription,
      'status': status,
      'cost': cost,
      'paidAmount': paidAmount,
      'receivedDate': receivedDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'repairCode': repairCode,
    };
  }

  MaintenanceRecord copyWith({
    int? id,
    String? deviceType,
    String? customerName,
    String? customerPhone,
    String? problemDescription,
    String? status,
    double? cost,
    double? paidAmount,
    DateTime? receivedDate,
    DateTime? deliveryDate,
    String? repairCode,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      deviceType: deviceType ?? this.deviceType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      problemDescription: problemDescription ?? this.problemDescription,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      paidAmount: paidAmount ?? this.paidAmount,
      receivedDate: receivedDate ?? this.receivedDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      repairCode: repairCode ?? this.repairCode,
    );
  }
}

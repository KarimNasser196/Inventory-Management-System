// lib/models/maintenance_record.dart

class MaintenanceRecord {
  int? id;
  String deviceType; // نوع الجهاز (لابتوب، كمبيوتر، طابعة، إلخ)
  String deviceBrand; // الماركة
  String deviceModel; // الموديل
  String? serialNumber; // الرقم التسلسلي
  String customerName;
  String customerPhone;
  String problemDescription; // وصف المشكلة
  String
  status; // الحالة: "قيد الفحص", "قيد الإصلاح", "جاهز للاستلام", "تم التسليم", "ملغي"
  double estimatedCost; // التكلفة المتوقعة
  double actualCost; // التكلفة الفعلية
  double paidAmount; // المبلغ المدفوع
  DateTime receivedDate; // تاريخ الاستلام
  DateTime? expectedDeliveryDate; // تاريخ التسليم المتوقع
  DateTime? actualDeliveryDate; // تاريخ التسليم الفعلي
  String? technicianNotes; // ملاحظات الفني
  String? usedParts; // القطع المستخدمة
  String? customerNotes; // ملاحظات العميل
  bool isWarranty; // هل تحت الضمان
  int? warrantyDays; // عدد أيام الضمان

  MaintenanceRecord({
    this.id,
    required this.deviceType,
    required this.deviceBrand,
    required this.deviceModel,
    this.serialNumber,
    required this.customerName,
    required this.customerPhone,
    required this.problemDescription,
    this.status = 'قيد الفحص',
    this.estimatedCost = 0,
    this.actualCost = 0,
    this.paidAmount = 0,
    DateTime? receivedDate,
    this.expectedDeliveryDate,
    this.actualDeliveryDate,
    this.technicianNotes,
    this.usedParts,
    this.customerNotes,
    this.isWarranty = false,
    this.warrantyDays,
  }) : receivedDate = receivedDate ?? DateTime.now();

  // الباقي من المبلغ
  double get remainingAmount => actualCost - paidAmount;

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

    DateTime? parsedExpectedDate;
    if (map['expectedDeliveryDate'] != null) {
      try {
        parsedExpectedDate = DateTime.parse(
          map['expectedDeliveryDate'] as String,
        );
      } catch (e) {
        parsedExpectedDate = null;
      }
    }

    DateTime? parsedActualDate;
    if (map['actualDeliveryDate'] != null) {
      try {
        parsedActualDate = DateTime.parse(map['actualDeliveryDate'] as String);
      } catch (e) {
        parsedActualDate = null;
      }
    }

    return MaintenanceRecord(
      id: map['id'] as int?,
      deviceType: map['deviceType'] as String,
      deviceBrand: map['deviceBrand'] as String,
      deviceModel: map['deviceModel'] as String,
      serialNumber: map['serialNumber'] as String?,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      problemDescription: map['problemDescription'] as String,
      status: map['status'] as String,
      estimatedCost: (map['estimatedCost'] as num).toDouble(),
      actualCost: (map['actualCost'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      receivedDate: parsedReceivedDate,
      expectedDeliveryDate: parsedExpectedDate,
      actualDeliveryDate: parsedActualDate,
      technicianNotes: map['technicianNotes'] as String?,
      usedParts: map['usedParts'] as String?,
      customerNotes: map['customerNotes'] as String?,
      isWarranty: (map['isWarranty'] as int) == 1,
      warrantyDays: map['warrantyDays'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceType': deviceType,
      'deviceBrand': deviceBrand,
      'deviceModel': deviceModel,
      'serialNumber': serialNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'problemDescription': problemDescription,
      'status': status,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'paidAmount': paidAmount,
      'receivedDate': receivedDate.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'actualDeliveryDate': actualDeliveryDate?.toIso8601String(),
      'technicianNotes': technicianNotes,
      'usedParts': usedParts,
      'customerNotes': customerNotes,
      'isWarranty': isWarranty ? 1 : 0,
      'warrantyDays': warrantyDays,
    };
  }

  MaintenanceRecord copyWith({
    int? id,
    String? deviceType,
    String? deviceBrand,
    String? deviceModel,
    String? serialNumber,
    String? customerName,
    String? customerPhone,
    String? problemDescription,
    String? status,
    double? estimatedCost,
    double? actualCost,
    double? paidAmount,
    DateTime? receivedDate,
    DateTime? expectedDeliveryDate,
    DateTime? actualDeliveryDate,
    String? technicianNotes,
    String? usedParts,
    String? customerNotes,
    bool? isWarranty,
    int? warrantyDays,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      serialNumber: serialNumber ?? this.serialNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      problemDescription: problemDescription ?? this.problemDescription,
      status: status ?? this.status,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      paidAmount: paidAmount ?? this.paidAmount,
      receivedDate: receivedDate ?? this.receivedDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      usedParts: usedParts ?? this.usedParts,
      customerNotes: customerNotes ?? this.customerNotes,
      isWarranty: isWarranty ?? this.isWarranty,
      warrantyDays: warrantyDays ?? this.warrantyDays,
    );
  }
}

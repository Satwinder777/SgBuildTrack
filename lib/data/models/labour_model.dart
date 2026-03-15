import 'package:equatable/equatable.dart';
import '../../../core/helper_functions/calculation_helpers.dart';

enum LabourType {
  mason,
  bricklayer,
  helper,
  painter,
  carpenter,
  electrician,
  plumber,
  generalLabour,
}

extension LabourTypeX on LabourType {
  String get displayName {
    switch (this) {
      case LabourType.mason:
        return 'Mason';
      case LabourType.bricklayer:
        return 'Bricklayer';
      case LabourType.helper:
        return 'Helper';
      case LabourType.painter:
        return 'Painter';
      case LabourType.carpenter:
        return 'Carpenter';
      case LabourType.electrician:
        return 'Electrician';
      case LabourType.plumber:
        return 'Plumber';
      case LabourType.generalLabour:
        return 'General Labour';
    }
  }

  static LabourType fromString(String value) {
    final v = value.trim().toLowerCase().replaceAll(' ', '_');
    if (v == 'general_labour') return LabourType.generalLabour;
    return LabourType.values.firstWhere(
      (e) => e.name == value || e.displayName.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => LabourType.helper,
    );
  }
}

/// Payment mode: hourly (work_hours × hourly_rate) or fixed (fixed_day_rate).
enum LabourPaymentMode { hourly, fixed }

class LabourModel extends Equatable {
  const LabourModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    required this.labourType,
    this.hourlyRate,
    this.fixedDayRate,
    this.workHours,
    required this.paymentMode,
    required this.totalPayment,
    this.date,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final LabourType labourType;
  final double? hourlyRate;
  final double? fixedDayRate;
  final double? workHours;
  final LabourPaymentMode paymentMode;
  final double totalPayment;
  final DateTime? date;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LabourModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    LabourType? labourType,
    double? hourlyRate,
    double? fixedDayRate,
    double? workHours,
    LabourPaymentMode? paymentMode,
    double? totalPayment,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabourModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      labourType: labourType ?? this.labourType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      fixedDayRate: fixedDayRate ?? this.fixedDayRate,
      workHours: workHours ?? this.workHours,
      paymentMode: paymentMode ?? this.paymentMode,
      totalPayment: totalPayment ?? this.totalPayment,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Recalculate total based on payment mode.
  LabourModel recalculateTotal() {
    double total;
    if (paymentMode == LabourPaymentMode.hourly) {
      total = CalculationHelpers.calculateLabourHourly(workHours ?? 0, hourlyRate ?? 0);
    } else {
      total = CalculationHelpers.calculateLabourFixed(fixedDayRate ?? 0);
    }
    return copyWith(totalPayment: total);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'labourType': labourType.name,
      'hourlyRate': hourlyRate,
      'fixedDayRate': fixedDayRate,
      'workHours': workHours,
      'paymentMode': paymentMode.name,
      'totalPayment': totalPayment,
      'date': date?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LabourModel.fromFirestore(Map<String, dynamic> map) {
    final date = map['date'];
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];
    return LabourModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      labourType: LabourTypeX.fromString((map['labourType'] as String?) ?? 'helper'),
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble(),
      fixedDayRate: (map['fixedDayRate'] as num?)?.toDouble(),
      workHours: (map['workHours'] as num?)?.toDouble(),
      paymentMode: map['paymentMode'] == 'fixed' ? LabourPaymentMode.fixed : LabourPaymentMode.hourly,
      totalPayment: (map['totalPayment'] as num?)?.toDouble() ?? 0,
      date: date != null ? DateTime.tryParse(date.toString()) : null,
      notes: map['notes'] as String?,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt.toString()) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt.toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, name, labourType, totalPayment, date];
}

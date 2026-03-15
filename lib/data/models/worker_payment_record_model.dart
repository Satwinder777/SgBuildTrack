import 'package:equatable/equatable.dart';

/// A single payment made to a worker (labour). Links to workerId (labour id).
class WorkerPaymentRecordModel extends Equatable {
  const WorkerPaymentRecordModel({
    required this.id,
    required this.workerId,
    required this.amountPaid,
    required this.paymentDate,
    this.paymentType,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String workerId;
  final double amountPaid;
  final DateTime paymentDate;
  final String? paymentType;
  final String? notes;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'workerId': workerId,
      'amountPaid': amountPaid,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentType': paymentType,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory WorkerPaymentRecordModel.fromFirestore(Map<String, dynamic> map) {
    final paymentDate = map['paymentDate'];
    final createdAt = map['createdAt'];
    return WorkerPaymentRecordModel(
      id: map['id'] as String? ?? '',
      workerId: map['workerId'] as String? ?? '',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0,
      paymentDate: paymentDate != null ? DateTime.tryParse(paymentDate.toString()) ?? DateTime.now() : DateTime.now(),
      paymentType: map['paymentType'] as String?,
      notes: map['notes'] as String?,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt.toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, workerId, amountPaid, paymentDate];
}

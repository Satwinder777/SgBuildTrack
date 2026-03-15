import 'package:equatable/equatable.dart';

/// Day-wise attendance status: Present or Absent only.
enum AttendanceStatus {
  present,
  absent,
}

extension AttendanceStatusX on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  static AttendanceStatus fromString(String? value) {
    if (value == null || value.isEmpty) return AttendanceStatus.present;
    return value.trim().toLowerCase() == 'absent' ? AttendanceStatus.absent : AttendanceStatus.present;
  }
}

/// Attendance type for a worker's day.
/// fullDay = 8h, halfDay = 4h, absent/leave = 0h, present = from checkIn/checkOut, overtime = present with hours > 8.
enum AttendanceType {
  fullDay,
  halfDay,
  absent,
  leave,
  present,
  overtime,
}

extension AttendanceTypeX on AttendanceType {
  String get displayName {
    switch (this) {
      case AttendanceType.fullDay:
        return 'Full Day';
      case AttendanceType.halfDay:
        return 'Half Day';
      case AttendanceType.absent:
        return 'Absent';
      case AttendanceType.leave:
        return 'Leave';
      case AttendanceType.present:
        return 'Present';
      case AttendanceType.overtime:
        return 'Overtime';
    }
  }

  /// Default hours for type when no check-in/out: fullDay=8, halfDay=4, else 0.
  double get defaultHours {
    switch (this) {
      case AttendanceType.fullDay:
        return 8;
      case AttendanceType.halfDay:
        return 4;
      case AttendanceType.absent:
      case AttendanceType.leave:
        return 0;
      case AttendanceType.present:
      case AttendanceType.overtime:
        return 8;
    }
  }

  static AttendanceType fromString(String? value) {
    if (value == null || value.isEmpty) return AttendanceType.fullDay;
    switch (value.trim().toLowerCase()) {
      case 'full_day':
      case 'fullday':
        return AttendanceType.fullDay;
      case 'half_day':
      case 'halfday':
        return AttendanceType.halfDay;
      case 'absent':
        return AttendanceType.absent;
      case 'leave':
        return AttendanceType.leave;
      case 'overtime':
        return AttendanceType.overtime;
      case 'present':
        return AttendanceType.present;
      default:
        return AttendanceType.fullDay;
    }
  }
}

/// Single day attendance record for a worker. workerId = Labour document id.
/// One record per worker per day (enforced in controller/repository).
class AttendanceModel extends Equatable {
  const AttendanceModel({
    required this.id,
    required this.workerId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.hoursWorked,
    this.overtimeHours = 0,
    required this.attendanceType,
    this.attendanceStatus,
    this.overtimeEnabled = false,
    this.overtimeAmount = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String workerId;
  final DateTime date;
  final String? checkInTime;
  final String? checkOutTime;
  /// Regular hours (1-12 for present). For day-wise flow.
  final double hoursWorked;
  /// Hours beyond 8 (legacy). Payment: overtimeHours × hourlyRate.
  final double overtimeHours;
  final AttendanceType attendanceType;
  /// Day-wise status: present | absent. When set, used for pending/present/absent lists.
  final AttendanceStatus? attendanceStatus;
  /// Day-wise: overtime toggle in Add Work Details.
  final bool overtimeEnabled;
  /// Day-wise: overtime amount (currency) when overtimeEnabled.
  final double overtimeAmount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get totalHours => hoursWorked + overtimeHours;

  /// True if this record is "present" for day-wise UI.
  bool get isPresent => attendanceStatus == AttendanceStatus.present ||
      (attendanceStatus == null && attendanceType != AttendanceType.absent && attendanceType != AttendanceType.leave);
  /// True if this record is "absent" for day-wise UI.
  bool get isAbsent => attendanceStatus == AttendanceStatus.absent ||
      (attendanceStatus == null && (attendanceType == AttendanceType.absent || attendanceType == AttendanceType.leave));

  AttendanceModel copyWith({
    String? id,
    String? workerId,
    DateTime? date,
    String? checkInTime,
    String? checkOutTime,
    double? hoursWorked,
    double? overtimeHours,
    AttendanceType? attendanceType,
    AttendanceStatus? attendanceStatus,
    bool? overtimeEnabled,
    double? overtimeAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      attendanceType: attendanceType ?? this.attendanceType,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      overtimeEnabled: overtimeEnabled ?? this.overtimeEnabled,
      overtimeAmount: overtimeAmount ?? this.overtimeAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'workerId': workerId,
      'date': _dateToYyyyMmDd(date),
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'hoursWorked': hoursWorked,
      'overtimeHours': overtimeHours,
      'attendanceType': attendanceType.name,
      'attendanceStatus': attendanceStatus?.name,
      'overtimeEnabled': overtimeEnabled,
      'overtimeAmount': overtimeAmount,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _dateToYyyyMmDd(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  factory AttendanceModel.fromFirestore(Map<String, dynamic> map) {
    final dateStr = map['date'] as String?;
    final date = dateStr != null
        ? DateTime.tryParse(dateStr.length == 10 ? '$dateStr 00:00:00' : dateStr) ?? DateTime.now()
        : DateTime.now();
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];
    final statusStr = map['attendanceStatus'] as String?;
    return AttendanceModel(
      id: map['id'] as String? ?? '',
      workerId: map['workerId'] as String? ?? '',
      date: date,
      checkInTime: map['checkInTime'] as String?,
      checkOutTime: map['checkOutTime'] as String?,
      hoursWorked: (map['hoursWorked'] as num?)?.toDouble() ?? 0,
      overtimeHours: (map['overtimeHours'] as num?)?.toDouble() ?? 0,
      attendanceType: AttendanceTypeX.fromString(map['attendanceType'] as String?),
      attendanceStatus: statusStr != null ? AttendanceStatusX.fromString(statusStr) : null,
      overtimeEnabled: map['overtimeEnabled'] as bool? ?? false,
      overtimeAmount: (map['overtimeAmount'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt.toString()) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt.toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, workerId, date, hoursWorked, overtimeHours, attendanceType, attendanceStatus];
}

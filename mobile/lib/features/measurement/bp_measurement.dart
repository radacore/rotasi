import 'package:uuid/uuid.dart';

import 'bp_status.dart';

/// Satu sesi pengukuran tekanan darah (FR-03).
///
/// Protokol AHA 2025: dua kali pengukuran (jarak 1–2 menit) yang
/// dirata-ratakan otomatis, lalu diklasifikasi ke status warna (FR-04).
class BpMeasurement {
  const BpMeasurement({
    required this.uuid,
    required this.patientUuid,
    required this.measuredAt,
    required this.sessionCode,
    required this.systolic1,
    required this.diastolic1,
    required this.systolic2,
    required this.diastolic2,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.status,
    this.synced = false,
  });

  final String uuid;
  final String patientUuid;
  final DateTime measuredAt;
  final SessionCode sessionCode;
  final int systolic1;
  final int diastolic1;
  final int systolic2;
  final int diastolic2;
  final int avgSystolic;
  final int avgDiastolic;
  final BpStatus status;
  final bool synced;

  /// Membuat record baru, menghitung rata-rata & status otomatis.
  factory BpMeasurement.record({
    required String patientUuid,
    required DateTime measuredAt,
    required SessionCode sessionCode,
    required int systolic1,
    required int diastolic1,
    required int systolic2,
    required int diastolic2,
  }) {
    final avgSys = ((systolic1 + systolic2) / 2).round();
    final avgDia = ((diastolic1 + diastolic2) / 2).round();
    return BpMeasurement(
      uuid: const Uuid().v4(),
      patientUuid: patientUuid,
      measuredAt: measuredAt,
      sessionCode: sessionCode,
      systolic1: systolic1,
      diastolic1: diastolic1,
      systolic2: systolic2,
      diastolic2: diastolic2,
      avgSystolic: avgSys,
      avgDiastolic: avgDia,
      status: BpStatus.classify(avgSys, avgDia),
    );
  }

  factory BpMeasurement.fromMap(Map<String, dynamic> map) {
    return BpMeasurement(
      uuid: map['uuid'] as String,
      patientUuid: map['patient_uuid'] as String,
      measuredAt: DateTime.parse(map['measured_at'] as String),
      sessionCode: SessionCode.fromValue(map['session_code'] as String?),
      systolic1: (map['systolic_1'] as num).toInt(),
      diastolic1: (map['diastolic_1'] as num).toInt(),
      systolic2: (map['systolic_2'] as num).toInt(),
      diastolic2: (map['diastolic_2'] as num).toInt(),
      avgSystolic: (map['avg_systolic'] as num).toInt(),
      avgDiastolic: (map['avg_diastolic'] as num).toInt(),
      status: BpStatus.fromCode(map['status_color'] as String?),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'patient_uuid': patientUuid,
      'measured_at': measuredAt.toIso8601String(),
      'session_code': sessionCode.value,
      'systolic_1': systolic1,
      'diastolic_1': diastolic1,
      'systolic_2': systolic2,
      'diastolic_2': diastolic2,
      'avg_systolic': avgSystolic,
      'avg_diastolic': avgDiastolic,
      'status_color': status.code,
      'synced': synced ? 1 : 0,
    };
  }

  /// Payload untuk `POST /api/v1/sync/bp`.
  Map<String, dynamic> toSyncPayload() {
    return {
      'patient_uuid': patientUuid,
      'uuid': uuid,
      'measured_at': measuredAt.toIso8601String(),
      'session_code': sessionCode.value,
      'systolic_1': systolic1,
      'diastolic_1': diastolic1,
      'systolic_2': systolic2,
      'diastolic_2': diastolic2,
      'avg_systolic': avgSystolic,
      'avg_diastolic': avgDiastolic,
      'status_color': status.code,
    };
  }
}

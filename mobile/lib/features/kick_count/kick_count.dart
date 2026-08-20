import 'package:uuid/uuid.dart';

/// Sesi penghitungan gerakan janin (FR-07).
///
/// Pengamatan 30 menit; setiap ketukan menambah `kickCount`. Status aktif
/// bila minimal 3 gerakan dalam 30 menit. Sinkron ke `POST /api/v1/sync/kick`.
class KickCount {
  const KickCount({
    required this.uuid,
    required this.patientUuid,
    required this.startedAt,
    this.endedAt,
    this.kickCount = 0,
    this.isActive = false,
    this.synced = false,
  });

  final String uuid;
  final String patientUuid;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int kickCount;
  final bool isActive;
  final bool synced;

  static const int observationMinutes = 30;
  static const int activeThreshold = 3;

  /// Mulai pengamatan baru.
  factory KickCount.start({required String patientUuid, DateTime? startedAt}) {
    return KickCount(
      uuid: const Uuid().v4(),
      patientUuid: patientUuid,
      startedAt: startedAt ?? DateTime.now(),
    );
  }

  /// Selesaikan pengamatan pada waktu tertentu.
  KickCount complete({DateTime? endedAt}) {
    final end = endedAt ?? DateTime.now();
    return KickCount(
      uuid: uuid,
      patientUuid: patientUuid,
      startedAt: startedAt,
      endedAt: end,
      kickCount: kickCount,
      isActive: kickCount >= activeThreshold,
      synced: synced,
    );
  }

  /// Status aktif: minimal [activeThreshold] gerakan per 30 menit.
  static bool evaluateActive(int kickCount) => kickCount >= activeThreshold;

  factory KickCount.fromMap(Map<String, dynamic> map) {
    return KickCount(
      uuid: map['uuid'] as String,
      patientUuid: map['patient_uuid'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.parse(map['ended_at'] as String),
      kickCount: (map['kick_count'] as num).toInt(),
      isActive: (map['is_active'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'patient_uuid': patientUuid,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'kick_count': kickCount,
      'is_active': isActive ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  /// Payload untuk `POST /api/v1/sync/kick`.
  Map<String, dynamic> toSyncPayload() {
    return {
      'patient_uuid': patientUuid,
      'uuid': uuid,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'kick_count': kickCount,
      'is_active': isActive,
    };
  }
}

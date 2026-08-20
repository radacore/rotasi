import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/kick_count/kick_count.dart';

void main() {
  const patientUuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  group('KickCount', () {
    test('start membuat uuid baru dengan kick_count 0', () {
      final k = KickCount.start(
        patientUuid: patientUuid,
        startedAt: DateTime(2026, 8, 20, 10),
      );
      expect(k.uuid, isNotEmpty);
      expect(k.kickCount, 0);
      expect(k.endedAt, isNull);
      expect(k.isActive, false);
    });

    test('complete: 3+ gerakan -> aktif', () {
      final k = KickCount.start(
        patientUuid: patientUuid,
        startedAt: DateTime(2026, 8, 20, 10),
      );
      final completed = KickCount.fromMap({
        ...k.toMap(),
        'kick_count': 4,
        'ended_at': DateTime(2026, 8, 20, 10, 30).toIso8601String(),
      }).complete();
      expect(completed.endedAt, isNotNull);
      expect(completed.kickCount, 4);
      expect(completed.isActive, true);
    });

    test('complete: kurang dari 3 gerakan -> tidak aktif', () {
      final k = KickCount.start(
        patientUuid: patientUuid,
        startedAt: DateTime(2026, 8, 20, 10),
      );
      final completed = KickCount.fromMap({
        ...k.toMap(),
        'kick_count': 2,
        'ended_at': DateTime(2026, 8, 20, 10, 30).toIso8601String(),
      }).complete();
      expect(completed.isActive, false);
    });

    test('evaluateActive ambang 3', () {
      expect(KickCount.evaluateActive(3), true);
      expect(KickCount.evaluateActive(2), false);
    });

    test('toMap/fromMap roundtrip', () {
      final k = KickCount.start(
        patientUuid: patientUuid,
        startedAt: DateTime(2026, 8, 20, 10),
      );
      final completed = KickCount.fromMap({
        ...k.toMap(),
        'kick_count': 5,
        'ended_at': DateTime(2026, 8, 20, 10, 30).toIso8601String(),
        'is_active': 1,
      }).complete();
      final restored = KickCount.fromMap(completed.toMap());
      expect(restored.uuid, completed.uuid);
      expect(restored.patientUuid, patientUuid);
      expect(restored.startedAt, completed.startedAt);
      expect(restored.endedAt, completed.endedAt);
      expect(restored.kickCount, 5);
      expect(restored.isActive, true);
      expect(restored.synced, false);
    });

    test('toSyncPayload sesuai kontrak /sync/kick', () {
      final k = KickCount.start(
        patientUuid: patientUuid,
        startedAt: DateTime(2026, 8, 20, 10),
      );
      final completed = KickCount.fromMap({
        ...k.toMap(),
        'kick_count': 3,
        'ended_at': DateTime(2026, 8, 20, 10, 30).toIso8601String(),
      }).complete();
      final payload = completed.toSyncPayload();
      expect(payload['patient_uuid'], patientUuid);
      expect(payload['uuid'], completed.uuid);
      expect(payload['started_at'], completed.startedAt.toIso8601String());
      expect(payload['ended_at'], completed.endedAt!.toIso8601String());
      expect(payload['kick_count'], 3);
      expect(payload['is_active'], true);
    });
  });
}

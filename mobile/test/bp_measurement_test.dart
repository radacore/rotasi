import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/measurement/bp_measurement.dart';
import 'package:rotasi_mobile/features/measurement/bp_status.dart';

void main() {
  const patientUuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  group('BpMeasurement.record', () {
    test('menghitung rata-rata dibulatkan', () {
      final m = BpMeasurement.record(
        patientUuid: patientUuid,
        measuredAt: DateTime(2026, 8, 20, 8, 30),
        sessionCode: SessionCode.pagi,
        systolic1: 120,
        diastolic1: 80,
        systolic2: 124,
        diastolic2: 78,
      );
      expect(m.avgSystolic, 122); // (120+124)/2
      expect(m.avgDiastolic, 79); // (80+78)/2
      expect(m.synced, false);
    });

    test('status dari rata-rata', () {
      final m = BpMeasurement.record(
        patientUuid: patientUuid,
        measuredAt: DateTime(2026, 8, 20, 8, 30),
        sessionCode: SessionCode.pagi,
        systolic1: 120,
        diastolic1: 80,
        systolic2: 124,
        diastolic2: 78,
      );
      // Rata-rata 122/79 => SYS >=120 (<130) & DIA <80 => Waspada (kuning).
      expect(m.avgSystolic, 122);
      expect(m.avgDiastolic, 79);
      expect(m.status, BpStatus.elevated);
    });
  });

  test('classify tepat untuk rata-rata 122/79', () {
    // sys 122 (>=120, <130) & dia 79 (<80) => Waspada (kuning).
    expect(BpStatus.classify(122, 79), BpStatus.elevated);
  });

  group('serialisasi', () {
    final m = BpMeasurement.record(
      patientUuid: patientUuid,
      measuredAt: DateTime.utc(2026, 8, 20, 8, 30),
      sessionCode: SessionCode.pagi,
      systolic1: 120,
      diastolic1: 80,
      systolic2: 124,
      diastolic2: 78,
    );

    test('toMap/fromMap roundtrip', () {
      final restored = BpMeasurement.fromMap(m.toMap());
      expect(restored.uuid, m.uuid);
      expect(restored.patientUuid, m.patientUuid);
      expect(restored.measuredAt, m.measuredAt);
      expect(restored.sessionCode, SessionCode.pagi);
      expect(restored.systolic1, 120);
      expect(restored.diastolic2, 78);
      expect(restored.avgSystolic, 122);
      expect(restored.avgDiastolic, 79);
      expect(restored.status, BpStatus.elevated);
      expect(restored.synced, false);
    });

    test('toSyncPayload sesuai kontrak /sync/bp', () {
      final payload = m.toSyncPayload();
      expect(payload['patient_uuid'], patientUuid);
      expect(payload['uuid'], m.uuid);
      expect(payload['measured_at'], m.measuredAt.toIso8601String());
      expect(payload['session_code'], 'pagi');
      expect(payload['systolic_1'], 120);
      expect(payload['diastolic_1'], 80);
      expect(payload['systolic_2'], 124);
      expect(payload['diastolic_2'], 78);
      expect(payload['avg_systolic'], 122);
      expect(payload['avg_diastolic'], 79);
      expect(payload['status_color'], 'yellow');
    });
  });
}

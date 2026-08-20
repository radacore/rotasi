import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/symptom_check/symptom_check.dart';

void main() {
  const patientUuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  group('SymptomCheck', () {
    test('daily membentuk uuid + nilai sesuai input', () {
      final s = SymptomCheck.daily(
        patientUuid: patientUuid,
        checkedAt: DateTime(2026, 8, 20, 9),
        headache: true,
        blurredVision: false,
        epigastricPain: true,
        shortnessOfBreath: false,
      );
      expect(s.uuid, isNotEmpty);
      expect(s.hasAny, true);
      expect(s.valueOf(DangerSymptom.headache), true);
      expect(s.valueOf(DangerSymptom.blurredVision), false);
      expect(s.valueOf(DangerSymptom.epigastricPain), true);
      expect(s.valueOf(DangerSymptom.shortnessOfBreath), false);
    });

    test('hasAny false bila semua gejala tidak ada', () {
      final s = SymptomCheck.daily(
        patientUuid: patientUuid,
        checkedAt: DateTime(2026, 8, 20, 9),
        headache: false,
        blurredVision: false,
        epigastricPain: false,
        shortnessOfBreath: false,
      );
      expect(s.hasAny, false);
    });

    test('toMap/fromMap roundtrip', () {
      final s = SymptomCheck.daily(
        patientUuid: patientUuid,
        checkedAt: DateTime(2026, 8, 20, 9, 30),
        headache: true,
        blurredVision: true,
        epigastricPain: false,
        shortnessOfBreath: true,
      );
      final restored = SymptomCheck.fromMap(s.toMap());
      expect(restored.uuid, s.uuid);
      expect(restored.patientUuid, patientUuid);
      expect(restored.checkedAt, s.checkedAt);
      expect(restored.headache, true);
      expect(restored.blurredVision, true);
      expect(restored.epigastricPain, false);
      expect(restored.shortnessOfBreath, true);
      expect(restored.synced, false);
    });

    test('toSyncPayload sesuai kontrak /sync/symptom', () {
      final s = SymptomCheck.daily(
        patientUuid: patientUuid,
        checkedAt: DateTime(2026, 8, 20, 9),
        headache: true,
        blurredVision: false,
        epigastricPain: false,
        shortnessOfBreath: true,
      );
      final payload = s.toSyncPayload();
      expect(payload['patient_uuid'], patientUuid);
      expect(payload['uuid'], s.uuid);
      expect(payload['checked_at'], s.checkedAt.toIso8601String());
      expect(payload['headache'], true);
      expect(payload['blurred_vision'], false);
      expect(payload['epigastric_pain'], false);
      expect(payload['shortness_of_breath'], true);
    });
  });
}

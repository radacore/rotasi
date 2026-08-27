import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/registration/patient.dart';

void main() {
  group('computeRiskLevel', () {
    test('belum ada tensi -> unknown', () {
      expect(
        Patient.computeRiskLevel(age: 25, historyType: HistoryType.none),
        RiskLevel.unknown,
      );
      expect(
        Patient.computeRiskLevel(
            age: 40, historyType: HistoryType.priorPreeclampsia, bmi: 36),
        RiskLevel.unknown,
      );
    });

    test('tanpa riwayat dan usia muda -> low (setelah tensi)', () {
      expect(
        Patient.computeRiskLevel(age: 25, historyType: HistoryType.none, hasMeasurement: true),
        RiskLevel.low,
      );
    });

    test('hipertensi -> high (hipertensi kronis)', () {
      expect(
        Patient.computeRiskLevel(age: 25, historyType: HistoryType.hypertension, hasMeasurement: true),
        RiskLevel.high,
      );
    });

    test('riwayat turunan -> medium', () {
      expect(
        Patient.computeRiskLevel(age: 25, historyType: HistoryType.family, hasMeasurement: true),
        RiskLevel.medium,
      );
    });

    test('pernah preeklamsia -> high', () {
      expect(
        Patient.computeRiskLevel(
          age: 25,
          historyType: HistoryType.priorPreeclampsia,
          hasMeasurement: true,
        ),
        RiskLevel.high,
      );
    });

    test('usia di atas 35 -> medium', () {
      expect(
        Patient.computeRiskLevel(age: 37, historyType: HistoryType.none, hasMeasurement: true),
        RiskLevel.medium,
      );
    });

    test('usia 40+ -> high', () {
      expect(
        Patient.computeRiskLevel(age: 40, historyType: HistoryType.none, hasMeasurement: true),
        RiskLevel.high,
      );
    });

    test('IMT > 30 -> medium (tanpa riwayat, usia muda)', () {
      expect(
        Patient.computeRiskLevel(
          age: 25,
          historyType: HistoryType.none,
          bmi: 32,
          hasMeasurement: true,
        ),
        RiskLevel.medium,
      );
    });

    test('IMT >= 35 -> high', () {
      expect(
        Patient.computeRiskLevel(
          age: 25,
          historyType: HistoryType.none,
          bmi: 36,
          hasMeasurement: true,
        ),
        RiskLevel.high,
      );
    });

    test('IMT <= 30 tidak menaikkan risiko', () {
      expect(
        Patient.computeRiskLevel(
          age: 25,
          historyType: HistoryType.none,
          bmi: 30,
          hasMeasurement: true,
        ),
        RiskLevel.low,
      );
    });
  });

  group('riskFactors & recommendation (FR-02)', () {
    test('belum ada tensi -> unknown + rekomendasi ukur tensi', () {
      final p = Patient.newLocal(
        name: 'Sitti',
        age: 25,
        heightCm: 160,
        weightKg: 55,
      );
      expect(p.riskLevel, RiskLevel.unknown);
      expect(p.recommendation, contains('Belum ada pengukuran'));
    });

    test('tidak ada faktor setelah tensi -> rendah', () {
      final p = Patient.newLocal(
        name: 'Sitti',
        age: 25,
        heightCm: 160,
        weightKg: 55,
        lastSystolic: 118,
        lastDiastolic: 76,
      );
      expect(p.riskLevel, RiskLevel.low);
      expect(p.riskFactors(), isEmpty);
      expect(p.recommendation, contains('Risiko rendah'));
    });

    test('usia 38 + IMT 33 -> faktor terdeteksi + risiko sedang (perlu tensi)', () {
      final p = Patient.newLocal(
        name: 'Nur',
        age: 38,
        heightCm: 155,
        weightKg: 80,
        lastSystolic: 120,
        lastDiastolic: 80,
      );
      // IMT 155cm/80kg = 33.3
      expect(p.riskLevel, RiskLevel.medium);
      expect(p.riskFactors(), contains('Usia > 35 tahun'));
      expect(p.riskFactors(), contains('IMT 33.3'));
      expect(p.recommendation, contains('Risiko sedang'));
    });

    test('riwayat preeklamsia -> faktor + rekomendasi tinggi (perlu tensi)', () {
      final p = Patient.newLocal(
        name: 'Ayu',
        age: 24,
        heightCm: 160,
        weightKg: 55,
        historyType: HistoryType.priorPreeclampsia,
        lastSystolic: 120,
        lastDiastolic: 80,
      );
      expect(p.riskLevel, RiskLevel.high);
      expect(p.riskFactors(), ['Pernah preeklamsia']);
      expect(p.recommendation, contains('Risiko tinggi'));
    });

    test('bmi dihitung otomatis dari tinggi & berat', () {
      final p = Patient.newLocal(
        name: 'Dewi',
        age: 27,
        heightCm: 160,
        weightKg: 64,
      );
      expect(p.bmi, closeTo(25.0, 0.1));
    });
  });

  group('Patient', () {
    test('toSyncPayload mengikuti kontrak backend', () {
      final patient = Patient.newLocal(
        name: 'Sitti',
        age: 28,
        heightCm: 155,
        weightKg: 52.5,
        gestationalWeeks: 24,
        lastSystolic: 118,
        lastDiastolic: 76,
        historyType: HistoryType.none,
        phone: '62812',
      );

      final payload = patient.toSyncPayload();

      expect(payload['patient_uuid'], patient.uuid);
      expect(payload['name'], 'Sitti');
      expect(payload['age'], 28);
      expect(payload['height_cm'], 155);
      expect(payload['weight_kg'], 52.5);
      expect(payload['gestational_weeks'], 24);
      expect(payload['due_date'], isNotNull);
      expect(payload['last_systolic'], 118);
      expect(payload['last_diastolic'], 76);
      expect(payload['history_type'], 'none');
      expect(payload['risk_level'], 'low');
      expect(payload['phone'], '62812');
    });

    test('uuid terisi dan risk_level dihitung otomatis', () {
      final patient = Patient.newLocal(
        name: 'Rahma',
        age: 24,
        heightCm: 160,
        weightKg: 55,
        historyType: HistoryType.hypertension,
        lastSystolic: 120,
        lastDiastolic: 80,
      );

      expect(patient.uuid, isNotEmpty);
      expect(patient.riskLevel, RiskLevel.high);
    });

    test('tanpa tensi -> unknown, bukan low', () {
      final patient = Patient.newLocal(
        name: 'Ani',
        age: 24,
        heightCm: 160,
        weightKg: 55,
      );
      expect(patient.riskLevel, RiskLevel.unknown);
      expect(patient.toSyncPayload()['risk_level'], 'unknown');
    });

    test('fromMap roundtrip mempertahankan nilai', () {
      final patient = Patient.newLocal(
        name: 'Sitti',
        age: 28,
        heightCm: 155,
        weightKg: 52.5,
        gestationalWeeks: 24,
        dueDate: DateTime(2027, 2, 1),
        lastSystolic: 118,
        lastDiastolic: 76,
        historyType: HistoryType.priorPreeclampsia,
        phone: '62812',
      );

      final restored = Patient.fromMap(patient.toMap());

      expect(restored.uuid, patient.uuid);
      expect(restored.name, 'Sitti');
      expect(restored.age, 28);
      expect(restored.heightCm, 155);
      expect(restored.weightKg, 52.5);
      expect(restored.gestationalWeeks, 24);
      expect(restored.lastSystolic, 118);
      expect(restored.lastDiastolic, 76);
      expect(restored.historyType, HistoryType.priorPreeclampsia);
      expect(restored.riskLevel, RiskLevel.high);
      expect(restored.phone, '62812');
    });
  });
}

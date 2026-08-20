import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/core/sync/sync_service.dart';
import 'package:rotasi_mobile/features/anc_check/anc_check.dart';
import 'package:rotasi_mobile/features/anc_check/anc_repository.dart';
import 'package:rotasi_mobile/features/kick_count/kick_count.dart';
import 'package:rotasi_mobile/features/kick_count/kick_repository.dart';
import 'package:rotasi_mobile/features/measurement/bp_measurement.dart';
import 'package:rotasi_mobile/features/measurement/bp_repository.dart';
import 'package:rotasi_mobile/features/measurement/bp_status.dart';
import 'package:rotasi_mobile/features/registration/patient.dart';
import 'package:rotasi_mobile/features/registration/patient_repository.dart';
import 'package:rotasi_mobile/features/symptom_check/symptom_check.dart';
import 'package:rotasi_mobile/features/symptom_check/symptom_repository.dart';

class _FakePatientRepo extends PatientRepository {
  _FakePatientRepo(this.items);
  final List<Patient> items;
  int sent = 0;
  bool ok = true;

  @override
  Future<List<Patient>> unsynced() async => items;
  @override
  Future<bool> sync(Patient patient) async {
    if (!ok) return false;
    sent++;
    return true;
  }
}

class _FakeBpRepo extends BpRepository {
  _FakeBpRepo(this.items);
  final List<BpMeasurement> items;
  int sent = 0;
  bool ok = true;

  @override
  Future<List<BpMeasurement>> unsynced() async => items;
  @override
  Future<bool> sync(BpMeasurement measurement) async {
    if (!ok) return false;
    sent++;
    return true;
  }
}

class _FakeSymptomRepo extends SymptomRepository {
  _FakeSymptomRepo(this.items);
  final List<SymptomCheck> items;
  int sent = 0;
  bool ok = true;

  @override
  Future<List<SymptomCheck>> unsynced() async => items;
  @override
  Future<bool> sync(SymptomCheck check) async {
    if (!ok) return false;
    sent++;
    return true;
  }
}

class _FakeKickRepo extends KickRepository {
  _FakeKickRepo(this.items);
  final List<KickCount> items;
  int sent = 0;
  bool ok = true;

  @override
  Future<List<KickCount>> unsynced() async => items;
  @override
  Future<bool> sync(KickCount kick) async {
    if (!ok) return false;
    sent++;
    return true;
  }
}

class _FakeAncRepo extends AncRepository {
  _FakeAncRepo(this.items);
  final List<AncCheck> items;
  int sent = 0;
  bool ok = true;

  @override
  Future<List<AncCheck>> unsynced() async => items;
  @override
  Future<bool> sync(AncCheck check) async {
    if (!ok) return false;
    sent++;
    return true;
  }
}

void main() {
  final patient = Patient(
    uuid: 'p1',
    name: 'Ibu Sari',
    age: 28,
    heightCm: 155,
    weightKg: 60,
    riskLevel: RiskLevel.low,
  );

  final bp = BpMeasurement.record(
    patientUuid: 'p1',
    measuredAt: DateTime(2026, 8, 1, 7),
    sessionCode: SessionCode.pagi,
    systolic1: 120,
    diastolic1: 80,
    systolic2: 124,
    diastolic2: 82,
  );

  final symptom = SymptomCheck.daily(
    patientUuid: 'p1',
    checkedAt: DateTime(2026, 8, 1, 20),
    headache: true,
    blurredVision: false,
    epigastricPain: false,
    shortnessOfBreath: false,
  );

  final kick = KickCount.start(
    patientUuid: 'p1',
    startedAt: DateTime(2026, 8, 1, 9),
  ).complete(endedAt: DateTime(2026, 8, 1, 9, 30));

  final anc = AncCheck.forDate(
    patientUuid: 'p1',
    visitedAt: DateTime(2026, 8, 1),
  );

  test('syncAll mengirim semua record belum sinkron dalam urutan yang benar',
      () async {
    final patients = _FakePatientRepo([patient]);
    final bpRepo = _FakeBpRepo([bp]);
    final symptoms = _FakeSymptomRepo([symptom]);
    final kicks = _FakeKickRepo([kick]);
    final ancRepo = _FakeAncRepo([anc]);

    final service = SyncService(
      patients: patients,
      bp: bpRepo,
      symptoms: symptoms,
      kicks: kicks,
      anc: ancRepo,
    );

    final summary = await service.syncAll();

    expect(summary.sent, 5);
    expect(summary.failed, 0);
    expect(summary.hasError, isFalse);
    expect(patients.sent, 1);
    expect(bpRepo.sent, 1);
    expect(symptoms.sent, 1);
    expect(kicks.sent, 1);
    expect(ancRepo.sent, 1);
  });

  test('record yang sudah sinkron tidak dikirim ulang (idempoten)', () async {
    final patients = _FakePatientRepo([]);
    final bpRepo = _FakeBpRepo([]);
    final symptoms = _FakeSymptomRepo([]);
    final kicks = _FakeKickRepo([]);
    final ancRepo = _FakeAncRepo([]);

    final service = SyncService(
      patients: patients,
      bp: bpRepo,
      symptoms: symptoms,
      kicks: kicks,
      anc: ancRepo,
    );

    final summary = await service.syncAll();

    expect(summary.sent, 0);
    expect(summary.failed, 0);
    expect(patients.sent, 0);
    expect(bpRepo.sent, 0);
    expect(symptoms.sent, 0);
    expect(kicks.sent, 0);
    expect(ancRepo.sent, 0);
  });

  test('record yang gagal dihitung failed, yang lain tetap terkirim', () async {
    final patients = _FakePatientRepo([patient])..ok = false;
    final bpRepo = _FakeBpRepo([bp]);
    final symptoms = _FakeSymptomRepo([symptom]);
    final kicks = _FakeKickRepo([kick]);
    final ancRepo = _FakeAncRepo([anc]);

    final service = SyncService(
      patients: patients,
      bp: bpRepo,
      symptoms: symptoms,
      kicks: kicks,
      anc: ancRepo,
    );

    final summary = await service.syncAll();

    expect(summary.sent, 4);
    expect(summary.failed, 1);
    expect(summary.hasError, isTrue);
    expect(patients.sent, 0);
    expect(bpRepo.sent, 1);
    expect(symptoms.sent, 1);
    expect(kicks.sent, 1);
    expect(ancRepo.sent, 1);
  });
}

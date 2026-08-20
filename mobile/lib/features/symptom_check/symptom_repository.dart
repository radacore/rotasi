import 'package:sqflite/sqflite.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import '../../core/db/app_database.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';
import 'symptom_check.dart';

/// Penyimpanan ceklis gejala bahaya harian: lokal + sinkron best-effort.
class SymptomRepository {
  SymptomRepository({ApiClient? api, PatientRepository? patientRepository})
      : _api = api ?? ApiClient(),
        _patientRepository = patientRepository ?? PatientRepository();

  final ApiClient _api;
  final PatientRepository _patientRepository;

  static String _dayOf(DateTime d) => d.toIso8601String().substring(0, 10);

  /// Simpan/mutakhirkan ceklis untuk tanggal tersebut (satu per hari).
  Future<void> saveForDate(SymptomCheck check) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'symptom_checks',
      where: "substr(checked_at, 1, 10) = ?",
      whereArgs: [_dayOf(check.checkedAt)],
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.insert(
        'symptom_checks',
        check.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }
    final existing = SymptomCheck.fromMap(rows.first);
    await db.update(
      'symptom_checks',
      {
        ...check.toMap(),
        'uuid': existing.uuid,
        'synced': 0,
      },
      where: 'uuid = ?',
      whereArgs: [existing.uuid],
    );
  }

  /// Ambil ceklis untuk tanggal tertentu (null bila belum diisi).
  Future<SymptomCheck?> getByDate(DateTime date) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'symptom_checks',
      where: "substr(checked_at, 1, 10) = ?",
      whereArgs: [_dayOf(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SymptomCheck.fromMap(rows.first);
  }

  /// Ceklis yang belum tersinkron (FR-13).
  Future<List<SymptomCheck>> unsynced() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'symptom_checks',
      where: 'synced = 0',
      orderBy: 'checked_at ASC',
    );
    return rows.map(SymptomCheck.fromMap).toList();
  }

  /// Sinkronkan satu ceklis ke server (`POST /api/v1/sync/symptom`).
  Future<bool> sync(SymptomCheck check) async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.post(
        ApiEndpoints.syncSymptom,
        body: check.toSyncPayload(),
      );
      if (res.statusCode >= 300) return false;
      await markSynced(check.uuid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSynced(String uuid) async {
    final db = await AppDatabase.instance;
    await db.update(
      'symptom_checks',
      {'synced': 1},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Profil pasien lokal (untuk mengisi `patient_uuid`).
  Future<Patient?> localPatient() => _patientRepository.getLocal();
}

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

  /// Simpan ceklis (satu baris per simpan, sinkron per timestamp).
  /// Web menyimpan per jam (17:56:21..18:06:14) 5/hari, jadi tidak upsert
  /// per hari — biar Riwayat mobile tampil semua seperti web.
  Future<void> saveForDate(SymptomCheck check) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'symptom_checks',
      check.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil ceklis terbaru untuk tanggal tertentu (untuk isi Form).
  Future<SymptomCheck?> getByDate(DateTime date) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'symptom_checks',
      where: "substr(checked_at, 1, 10) = ?",
      whereArgs: [_dayOf(date)],
      orderBy: 'checked_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SymptomCheck.fromMap(rows.first);
  }

  /// Riwayat ceklis urut terbaru di atas (offline-first, untuk tab Riwayat).
  Future<List<SymptomCheck>> history({int? limit}) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'symptom_checks',
      orderBy: 'checked_at DESC',
      limit: limit,
    );
    return rows.map(SymptomCheck.fromMap).toList();
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

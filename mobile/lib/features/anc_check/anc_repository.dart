import 'package:sqflite/sqflite.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import '../../core/db/app_database.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';
import 'anc_check.dart';

/// Penyimpanan kunjungan ANC 10T: lokal + sinkron best-effort.
class AncRepository {
  AncRepository({ApiClient? api, PatientRepository? patientRepository})
      : _api = api ?? ApiClient(),
        _patientRepository = patientRepository ?? PatientRepository();

  final ApiClient _api;
  final PatientRepository _patientRepository;

  Future<void> saveLocal(AncCheck check) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'anc_checks',
      check.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Satu kunjungan per tanggal kunjungan.
  Future<AncCheck?> getByVisitedAt(DateTime visitedAt) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'anc_checks',
      where: 'substr(visited_at, 1, 10) = ?',
      whereArgs: [_dateOnly(visitedAt)],
      orderBy: 'visited_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AncCheck.fromMap(rows.first);
  }

  /// Kunjungan yang belum tersinkron (FR-13).
  Future<List<AncCheck>> unsynced() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'anc_checks',
      where: 'synced = 0',
      orderBy: 'visited_at ASC',
    );
    return rows.map(AncCheck.fromMap).toList();
  }

  /// Sinkronkan satu kunjungan (`POST /api/v1/sync/anc`).
  Future<bool> sync(AncCheck check) async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.post(
        ApiEndpoints.syncAnc,
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
      'anc_checks',
      {'synced': 1},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Profil pasien lokal (untuk mengisi `patient_uuid`).
  Future<Patient?> localPatient() => _patientRepository.getLocal();

  static String _dateOnly(DateTime d) {
    final local = d.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

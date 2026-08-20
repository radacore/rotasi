import 'package:sqflite/sqflite.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import '../../core/db/app_database.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';
import 'kick_count.dart';

/// Penyimpanan sesi gerakan janin: lokal + sinkron best-effort.
class KickRepository {
  KickRepository({ApiClient? api, PatientRepository? patientRepository})
      : _api = api ?? ApiClient(),
        _patientRepository = patientRepository ?? PatientRepository();

  final ApiClient _api;
  final PatientRepository _patientRepository;

  Future<void> saveLocal(KickCount kick) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'kick_counts',
      kick.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<KickCount?> getByUuid(String uuid) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'kick_counts',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KickCount.fromMap(rows.first);
  }

  /// Sesi yang belum tersinkron (FR-13).
  Future<List<KickCount>> unsynced() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'kick_counts',
      where: 'synced = 0',
      orderBy: 'started_at ASC',
    );
    return rows.map(KickCount.fromMap).toList();
  }

  /// Sinkronkan satu sesi ke server (`POST /api/v1/sync/kick`).
  Future<bool> sync(KickCount kick) async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.post(
        ApiEndpoints.syncKick,
        body: kick.toSyncPayload(),
      );
      if (res.statusCode >= 300) return false;
      await markSynced(kick.uuid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSynced(String uuid) async {
    final db = await AppDatabase.instance;
    await db.update(
      'kick_counts',
      {'synced': 1},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Profil pasien lokal (untuk mengisi `patient_uuid`).
  Future<Patient?> localPatient() => _patientRepository.getLocal();
}

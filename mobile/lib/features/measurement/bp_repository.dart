import 'package:sqflite/sqflite.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import '../../core/db/app_database.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';
import 'bp_measurement.dart';

/// Penyimpanan catatan tensi: lokal (SQLite) + sinkronisasi best-effort.
class BpRepository {
  BpRepository({ApiClient? api, PatientRepository? patientRepository})
      : _api = api ?? ApiClient(),
        _patientRepository = patientRepository ?? PatientRepository();

  final ApiClient _api;
  final PatientRepository _patientRepository;

  /// Simpan sesi pengukuran ke SQLite lokal (offline-first).
  Future<void> saveLocal(BpMeasurement measurement) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'bp_measurements',
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil pengukuran terbaru (untuk roda status di beranda).
  Future<BpMeasurement?> last() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'bp_measurements',
      orderBy: 'measured_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BpMeasurement.fromMap(rows.first);
  }

  /// Riwayat pengukuran urut kronologis (untuk grafik tren, FR-05).
  Future<List<BpMeasurement>> history({int? limit}) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'bp_measurements',
      orderBy: 'measured_at ASC',
      limit: limit,
    );
    return rows.map(BpMeasurement.fromMap).toList();
  }

  /// Pengukuran yang belum tersinkron (FR-13).
  Future<List<BpMeasurement>> unsynced() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'bp_measurements',
      where: 'synced = 0',
      orderBy: 'measured_at ASC',
    );
    return rows.map(BpMeasurement.fromMap).toList();
  }

  /// Sinkronkan satu sesi ke server (`POST /api/v1/sync/bp`).
  ///
  /// Best-effort: gagal saat offline / profil belum tersinkron, data tetap
  /// tersimpan lokal dan dapat disinkronkan kemudian.
  Future<bool> sync(BpMeasurement measurement) async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.post(
        ApiEndpoints.syncBp,
        body: measurement.toSyncPayload(),
      );
      if (res.statusCode >= 300) return false;
      await markSynced(measurement.uuid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSynced(String uuid) async {
    final db = await AppDatabase.instance;
    await db.update(
      'bp_measurements',
      {'synced': 1},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Profil pasien lokal (untuk mengisi `patient_uuid`).
  Future<Patient?> localPatient() => _patientRepository.getLocal();
}

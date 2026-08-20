import 'package:sqflite/sqflite.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import '../../core/db/app_database.dart';
import 'patient.dart';

/// Penyimpanan profil ibu: lokal (SQLite) + sinkronisasi best-effort.
class PatientRepository {
  PatientRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// Simpan profil ke SQLite lokal (offline-first).
  Future<void> saveLocal(Patient patient) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'patients',
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil profil ibu (satu per perangkat). `null` jika belum ada.
  Future<Patient?> getLocal() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('patients', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return Patient.fromMap(rows.first);
  }

  /// Profil yang belum tersinkron ke server (FR-13).
  Future<List<Patient>> unsynced() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'patients',
      where: 'synced = 0',
      orderBy: 'id ASC',
    );
    return rows.map(Patient.fromMap).toList();
  }

  /// Sinkronkan profil ke server. `true` jika berhasil.
  ///
  /// Gagal saat offline — data tetap aman di lokal dan disinkronkan nanti.
  Future<bool> sync(Patient patient) async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.put(
        ApiEndpoints.patient,
        body: patient.toSyncPayload(),
      );
      if (res.statusCode >= 300) return false;
      await markSynced(patient.uuid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSynced(String uuid) async {
    final db = await AppDatabase.instance;
    await db.update(
      'patients',
      {'synced': 1},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }
}

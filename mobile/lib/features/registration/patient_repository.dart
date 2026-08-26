import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import '../../core/db/app_database.dart';
import 'patient.dart';

/// Hasil `GET /api/v1/patient/bmi` VPS.
class BmiResult {
  const BmiResult({
    required this.bmi,
    required this.category,
    required this.weightGainRange,
    this.advice,
    this.height,
    this.weight,
  });

  final double bmi;
  final String category;
  final String weightGainRange;
  final String? advice;
  final double? height;
  final double? weight;

  factory BmiResult.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] is Map) ? j['data'] as Map<String, dynamic> : j;
    return BmiResult(
      bmi: (data['bmi'] as num).toDouble(),
      category: data['category'] as String? ?? data['bmi_category'] as String? ?? 'normal',
      weightGainRange: data['weight_gain_range'] as String? ?? '-',
      advice: data['advice'] as String?,
      height: (data['height'] as num?)?.toDouble() ?? (data['pre_pregnancy_height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble() ?? (data['pre_pregnancy_weight'] as num?)?.toDouble(),
    );
  }
}

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

  /// Ambil biodata lengkap dari VPS `GET /api/v1/patient` lalu simpan lokal.
  Future<Patient?> fetchRemote() async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.get(ApiEndpoints.patient);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data == null || data is! Map<String, dynamic>) return null;
      // VPS kadang bungkus {patient:{...}} atau langsung {...}
      final m = (data['patient'] is Map<String, dynamic>)
          ? data['patient'] as Map<String, dynamic>
          : data;
      final local = await getLocal();
      final patient = Patient.fromApi(m, fallbackUuid: local?.uuid ?? '');
      if (patient.uuid.isEmpty) return null;
      await saveLocal(patient.copyWith());
      await markSynced(patient.uuid);
      return patient;
    } catch (_) {
      return null;
    }
  }

  /// `GET /api/v1/patient/bmi` — hitung BMI pra-hamil server. Fallback hitung lokal bila offline.
  Future<BmiResult?> fetchBmi() async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.get(ApiEndpoints.patientBmi);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return BmiResult.fromJson(body);
      }
      return null;
    } catch (_) {
      return null;
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

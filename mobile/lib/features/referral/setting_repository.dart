import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import 'referral_settings.dart';

/// Pengaturan global (FR-10) — diunduh saat online, dicache untuk offline.
class SettingRepository {
  SettingRepository({ApiClient? api}) : _api = api ?? ApiClient();

  static const _cacheKey = 'referral_settings_cache';
  static const _seedAsset = 'assets/data/referral_settings.json';

  final ApiClient _api;

  /// Ambil pengaturan dari server lalu simpan ke cache lokal.
  ///
  /// Mengembalikan null bila gagal / belum aktif; cache lama tetap terbaca.
  Future<ReferralSettings?> fetchRemote() async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.get(ApiEndpoints.settings);
      if (res.statusCode >= 300) {
        return await getLocal();
      }
      final data =
          (jsonDecode(res.body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
      final settings = ReferralSettings.fromJson(data);
      await _cache(settings);
      return settings;
    } catch (_) {
      return await getLocal();
    }
  }

  /// Isi cache dari asset bawaan bila cache masih kosong (offline-first).
  ///
  /// Mengembalikan pengaturan yang baru disemai, atau null bila cache sudah
  /// ada / asset gagal dimuat. Versi server akan menimpanya saat online.
  Future<ReferralSettings?> ensureSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_cacheKey) != null) return null;
    try {
      final raw = await rootBundle.loadString(_seedAsset);
      final settings =
          ReferralSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      await prefs.setString(_cacheKey, jsonEncode(settings.toJson()));
      return settings;
    } catch (_) {
      return null;
    }
  }

  /// Pengaturan yang tersimpan di perangkat (offline-first).
  Future<ReferralSettings?> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return ReferralSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(ReferralSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(settings.toJson()));
  }
}

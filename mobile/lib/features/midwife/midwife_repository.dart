import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import 'midwife.dart';

/// Daftar bidan aktif (FR-11) — diunduh saat online, dicache untuk offline.
class MidwifeRepository {
  MidwifeRepository({ApiClient? api}) : _api = api ?? ApiClient();

  static const _cacheKey = 'midwives_cache';
  static const _seedAsset = 'assets/data/midwives.json';

  final ApiClient _api;

  /// Ambil daftar bidan dari server lalu simpan ke cache lokal.
  Future<List<Midwife>> fetchRemote() async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.get(ApiEndpoints.midwives);
      if (res.statusCode >= 300) {
        return await getLocal();
      }
      final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
          as List<dynamic>;
      final midwives = data
          .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
          .toList();
      await _cache(midwives);
      return midwives;
    } catch (_) {
      return getLocal();
    }
  }

  /// Isi cache dari asset bawaan bila cache masih kosong (offline-first).
  ///
  /// Mengembalikan daftar yang baru disemai, atau null bila cache sudah ada /
  /// asset gagal dimuat. Versi server akan menimpanya saat online.
  Future<List<Midwife>?> ensureSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_cacheKey) != null) return null;
    try {
      final raw = await rootBundle.loadString(_seedAsset);
      final data = jsonDecode(raw) as List<dynamic>;
      final midwives = data
          .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
          .toList();
      await prefs.setString(
        _cacheKey,
        jsonEncode(midwives.map((m) => m.toJson()).toList()),
      );
      return midwives;
    } catch (_) {
      return null;
    }
  }

  /// Daftar bidan yang tersimpan di perangkat (offline-first).
  Future<List<Midwife>> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return const [];
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _cache(List<Midwife> midwives) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(midwives.map((m) => m.toJson()).toList()),
    );
  }
}

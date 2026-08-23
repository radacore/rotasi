import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      await DeviceRegistrar(_api)
          .ensureRegistered()
          .timeout(const Duration(seconds: 12));
      final res = await _api.get(ApiEndpoints.midwives);
      if (res.statusCode >= 300) {
        return await getLocal();
      }
      final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
          as List<dynamic>;
      final midwives = data
          .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
          .toList();
      // Jangan timpa seed valid dengan balasan kosong dari server (mis. admin menonaktifkan
      // semua bidan sementara / DB disiram). Seed tetap lebih berguna daripada kosong.
      if (midwives.isNotEmpty) {
        await _cache(midwives);
      } else {
        final local = await getLocal();
        if (local.isNotEmpty) return local;
      }
      return midwives.isNotEmpty ? midwives : await getLocal();
    } catch (e) {
      debugPrint('[MidwifeRepository.fetchRemote] $e');
      try {
        return await getLocal().timeout(const Duration(seconds: 2));
      } catch (_) {
        return const [];
      }
    }
  }

  Future<void> refreshInBackground() async {
    try {
      await fetchRemote().timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  /// Isi cache dari asset bawaan bila cache masih kosong / rusak (offline-first).
  ///
  /// Mengembalikan daftar yang baru disemai, atau null bila cache sudah valid.
  /// Versi server akan menimpanya saat online (hanya bila non-kosong).
  Future<List<Midwife>?> ensureSeeded() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[MidwifeRepository.ensureSeeded] prefs hang: $e');
      try {
        final raw = await rootBundle
            .loadString(_seedAsset)
            .timeout(const Duration(seconds: 2));
        final data = jsonDecode(raw) as List<dynamic>;
        return data
            .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e2) {
        debugPrint('[MidwifeRepository.ensureSeeded] asset failed: $e2');
        return null;
      }
    }
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as List<dynamic>;
        if (decoded.isNotEmpty) return null;
      } catch (_) {
        // cache corrupt / bukan list -> semai ulang di bawah
      }
      // cache berisi "[]" (racun dari sync pertama saat DB kosong) -> semai ulang
    }
    try {
      final raw = await rootBundle
          .loadString(_seedAsset)
          .timeout(const Duration(seconds: 2));
      final data = jsonDecode(raw) as List<dynamic>;
      final midwives = data
          .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
          .toList();
      if (midwives.isEmpty) return null;
      await prefs
          .setString(
            _cacheKey,
            jsonEncode(midwives.map((m) => m.toJson()).toList()),
          )
          .timeout(const Duration(seconds: 2));
      return midwives;
    } catch (e) {
      debugPrint('[MidwifeRepository.ensureSeeded] seed failed: $e');
      return null;
    }
  }

  /// Daftar bidan yang tersimpan di perangkat (offline-first).
  Future<List<Midwife>> getLocal() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[MidwifeRepository.getLocal] prefs hang: $e');
      try {
        final raw = await rootBundle
            .loadString(_seedAsset)
            .timeout(const Duration(seconds: 2));
        final data = jsonDecode(raw) as List<dynamic>;
        return data
            .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return const [];
      }
    }
    final raw = prefs.getString(_cacheKey);
    if (raw == null) {
      try {
        final assetRaw = await rootBundle
            .loadString(_seedAsset)
            .timeout(const Duration(seconds: 2));
        final data = jsonDecode(assetRaw) as List<dynamic>;
        return data
            .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return const [];
      }
    }
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[MidwifeRepository.getLocal] json corrupt: $e raw=$raw');
      try {
        final assetRaw = await rootBundle
            .loadString(_seedAsset)
            .timeout(const Duration(seconds: 2));
        final data = jsonDecode(assetRaw) as List<dynamic>;
        return data
            .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return const [];
      }
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

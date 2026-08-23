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
  static const _updatedAtKey = 'midwives_updated_at';
  static const _seedAsset = 'assets/data/midwives.json';
  static const _seedVersionKey = 'midwives_seed_version';
  static const _seedVersion = 2;

  final ApiClient _api;

  /// Ambil daftar bidan dari server lalu simpan ke cache lokal.
  ///
  /// Versi baru: pakai `updated_at` + `?since=` untuk hemat kuota; `304`
  /// berarti tidak ada perubahan — langsung pakai cache lokal.
  /// Kompatibel lama: bila server masih kirim List di `data` tanpa `updated_at`, tetap diparse.
  Future<List<Midwife>> fetchRemote() async {
    try {
      await DeviceRegistrar(_api)
          .ensureRegistered()
          .timeout(const Duration(seconds: 12));
      final prefs0 = await SharedPreferences.getInstance();
      final since = prefs0.getString(_updatedAtKey);
      final path = since == null || since.isEmpty
          ? ApiEndpoints.midwives
          : '${ApiEndpoints.midwives}?since=${Uri.encodeComponent(since)}';
      final res = await _api.get(path);
      if (res.statusCode == 304) return await getLocal();
      if (res.statusCode >= 300) return await getLocal();
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rawData = body['data'];
      // Backend baru: data = List, updated_at di top-level. Lama: juga List.
      final listJson = rawData is List ? rawData : (rawData is Map ? (rawData['items'] as List? ?? const []) : const []);
      final remoteUpdatedAt = body['updated_at'] as String?
          ?? (rawData is Map ? rawData['updated_at'] as String? : null);
      final midwives = (listJson)
          .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
          .toList();
      // Admin sengaja kosongkan semua → hormati: kosongkan cache agar HP ikut kosong.
      if (midwives.isEmpty) {
        // Bedakan: kosong karena admin vs kosong karena DB awal. Jika local pernah ada
        // dan server kirim 200 + updated_at baru, itu intent admin — cache jadi [].
        if (remoteUpdatedAt != null) {
          await _cache(midwives, updatedAt: remoteUpdatedAt);
          return midwives;
        }
        final local = await getLocal();
        if (local.isNotEmpty) return local;
        return midwives;
      }
      await _cache(midwives, updatedAt: remoteUpdatedAt);
      return midwives;
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
    // Migrasi seed v2: bila cache masih versi 1 (Lusi saja), segarkan ke asset terbaru
    // agar offline pertama langsung sesuai web produksi.
    final seededVer = prefs.getInt(_seedVersionKey);
    if (seededVer == null) {
      final cachedRaw = prefs.getString(_cacheKey);
      if (cachedRaw != null) {
        try {
          final d = jsonDecode(cachedRaw) as List<dynamic>;
          final looksLikeV1 = d.length == 1 &&
              (d.first as Map<String, dynamic>)['name'] == 'Lusi';
          if (looksLikeV1) {
            final updatedAt = prefs.getString(_updatedAtKey);
            if (updatedAt == null || updatedAt.isEmpty) {
              // Bukan intent admin — migrasi diam-diam ke seed terbaru
              try {
                final raw = await rootBundle
                    .loadString(_seedAsset)
                    .timeout(const Duration(seconds: 2));
                final data = jsonDecode(raw) as List<dynamic>;
                final midwives = data
                    .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
                    .toList();
                if (midwives.isNotEmpty && midwives.length > 1) {
                  await prefs
                      .setString(
                        _cacheKey,
                        jsonEncode(midwives.map((m) => m.toJson()).toList()),
                      )
                      .timeout(const Duration(seconds: 2));
                  await prefs.setInt(_seedVersionKey, _seedVersion);
                  // Bersihkan updated_at lama agar fetchRemote berikutnya pakai since baru
                  await prefs.remove(_updatedAtKey);
                  return midwives;
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
      // Tandai sudah lewat migrasi agar tidak cek tiap launch
      try {
        await prefs.setInt(_seedVersionKey, _seedVersion);
      } catch (_) {}
    }
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as List<dynamic>;
        if (decoded.isNotEmpty) return null;
        // decoded kosong [] — bedakan racun vs intent admin (updated_at ada)
        if (decoded.isEmpty) {
          final updatedAt = prefs.getString(_updatedAtKey);
          if (updatedAt != null && updatedAt.isNotEmpty) {
            // Admin sengaja kosongkan (versioned) — jangan semai ulang
            return null;
          }
        }
      } catch (_) {
        // cache corrupt / bukan list -> semai ulang di bawah
      }
      // cache berisi "[]" tanpa versi (racun dari sync pertama saat DB kosong) -> semai ulang
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
      await prefs.setInt(_seedVersionKey, _seedVersion);
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
      if (data.isEmpty) {
        final updatedAt = prefs.getString(_updatedAtKey);
        if (updatedAt != null && updatedAt.isNotEmpty) {
          // Admin sengaja kosongkan (versioned) — tetap kosong, jangan fallback asset
          return const [];
        }
        // Racun [] tanpa versi — fallback ke asset agar tidak kosong misterius
        try {
          final assetRaw = await rootBundle
              .loadString(_seedAsset)
              .timeout(const Duration(seconds: 2));
          final assetData = jsonDecode(assetRaw) as List<dynamic>;
          return assetData
              .map((e) => Midwife.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          return const [];
        }
      }
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

  Future<void> _cache(List<Midwife> midwives, {String? updatedAt}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(midwives.map((m) => m.toJson()).toList()),
    );
    if (updatedAt != null) {
      await prefs.setString(_updatedAtKey, updatedAt);
    }
  }
}

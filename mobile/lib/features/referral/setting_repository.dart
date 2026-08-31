import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  static const _seedVersionKey = 'referral_settings_seed_version';
  static const _seedVersion = 3;

  final ApiClient _api;

  /// Ambil pengaturan dari server lalu simpan ke cache lokal.
  ///
  /// Mengembalikan null bila gagal / belum aktif; cache lama tetap terbaca.
  /// Bila `updatedAt` sama dengan cache, tidak menulis ulang (hemat I/O).
  Future<ReferralSettings?> fetchRemote() async {
    try {
      await DeviceRegistrar(_api)
          .ensureRegistered()
          .timeout(const Duration(seconds: 12));
      // Kirim since agar server bisa 304 (hemat kuota) — panduan rujukan ikut versioning
      String? since;
      try {
        since = (await SharedPreferences.getInstance()).getString(_cacheKey) != null
            ? (await getLocal())?.updatedAt?.toIso8601String()
            : null;
      } catch (_) {}
      // Fallback: ambil langsung dari cache json bila getLocal berat
      if (since == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final raw = prefs.getString(_cacheKey);
          if (raw != null) {
            final m = jsonDecode(raw) as Map<String, dynamic>;
            since = m['updated_at'] as String?;
          }
        } catch (_) {}
      }
      final path = since == null || since.isEmpty
          ? ApiEndpoints.settings
          : '${ApiEndpoints.settings}?since=${Uri.encodeComponent(since)}';
      final res = await _api.get(path);
      if (res.statusCode == 304) return await getLocal();
      if (res.statusCode >= 300) {
        return await getLocal();
      }
      final data =
          (jsonDecode(res.body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
      final settings = ReferralSettings.fromJson(data);
      // Jangan timpa cache valid dengan balasan kosong (mis. settings disiram).
      final isEmpty = settings.appName.isEmpty &&
          settings.emergencyPhone.isEmpty &&
          settings.puskesmasName.isEmpty;
      if (!isEmpty) {
        final local = await getLocal();
        if (local?.updatedAt != null &&
            settings.updatedAt != null &&
            local!.updatedAt == settings.updatedAt) {
          return local;
        }
        await _cache(settings);
        return settings;
      }
      final local = await getLocal();
      return local ?? settings;
    } catch (e) {
      debugPrint('[SettingRepository.fetchRemote] $e');
      try {
        return await getLocal().timeout(const Duration(seconds: 2));
      } catch (_) {
        return null;
      }
    }
  }

  /// Tarik pengaturan terbaru di background tanpa throw — untuk AutoSync.
  Future<void> refreshInBackground() async {
    try {
      await fetchRemote().timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  /// Isi cache dari asset bawaan bila cache masih kosong / rusak (offline-first).
  ///
  /// Mengembalikan pengaturan yang baru disemai, atau null bila cache sudah
  /// valid. Versi server akan menimpanya saat online.
  Future<ReferralSettings?> ensureSeeded() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[SettingRepository.ensureSeeded] prefs hang: $e');
      // Tanpa prefs, tetap coba balikan asset agar spinner tidak hang.
      try {
        final raw = await rootBundle
            .loadString(_seedAsset)
            .timeout(const Duration(seconds: 2));
        return ReferralSettings.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (e2) {
        debugPrint('[SettingRepository.ensureSeeded] asset failed: $e2');
        return null;
      }
    }
    // Migrasi seed v3: nomor ambulans/homecare/puskesmas kosong → segarkan dari asset terbaru
    final seededVer = prefs.getInt(_seedVersionKey);
    if (seededVer == null || seededVer < _seedVersion) {
      final cachedRaw = prefs.getString(_cacheKey);
      if (cachedRaw != null) {
        try {
          final d = jsonDecode(cachedRaw) as Map<String, dynamic>;
          final existing = ReferralSettings.fromJson(d);
          final needsMigration = existing.ambulancePhone.isEmpty ||
              existing.homecarePhone.isEmpty ||
              existing.puskesmasPhone.isEmpty ||
              existing.puskesmasPhoneAlt.isEmpty ||
              existing.puskesmasAddress.isEmpty;
          if (needsMigration) {
            try {
              final raw = await rootBundle
                  .loadString(_seedAsset)
                  .timeout(const Duration(seconds: 2));
              final latest = ReferralSettings.fromJson(
                  jsonDecode(raw) as Map<String, dynamic>);
              final shouldRefresh = latest.puskesmasAddress.isNotEmpty ||
                  latest.ambulancePhone.isNotEmpty;
              if (shouldRefresh) {
                await prefs
                    .setString(_cacheKey, jsonEncode(latest.toJson()))
                    .timeout(const Duration(seconds: 2));
                await prefs.setInt(_seedVersionKey, _seedVersion);
                return latest;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
      try {
        await prefs.setInt(_seedVersionKey, _seedVersion);
      } catch (_) {}
    }
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final existing = ReferralSettings.fromJson(decoded);
        if (existing.appName.isNotEmpty ||
            existing.emergencyPhone.isNotEmpty ||
            existing.puskesmasName.isNotEmpty) {
          return null;
        }
      } catch (_) {
        // cache corrupt / "null" / bukan Map -> semai ulang di bawah
      }
      // cache berisi JSON kosong / rusak (mis. "{}" atau 'null') -> semai ulang
    }
    try {
      final raw = await rootBundle
          .loadString(_seedAsset)
          .timeout(const Duration(seconds: 2));
      final settings =
          ReferralSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      await prefs
          .setString(_cacheKey, jsonEncode(settings.toJson()))
          .timeout(const Duration(seconds: 2));
      await prefs.setInt(_seedVersionKey, _seedVersion);
      return settings;
    } catch (e) {
      debugPrint('[SettingRepository.ensureSeeded] seed failed: $e');
      return null;
    }
  }

  /// Pengaturan yang tersimpan di perangkat (offline-first).
  Future<ReferralSettings?> getLocal() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[SettingRepository.getLocal] prefs hang: $e');
      // fallback: coba asset langsung agar halaman tetap tampil
      try {
        final raw = await rootBundle
            .loadString(_seedAsset)
            .timeout(const Duration(seconds: 2));
        return ReferralSettings.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    final raw = prefs.getString(_cacheKey);
    if (raw == null) {
      // Belum pernah cache -> pakai asset langsung (tanpa tunggu seed)
      try {
        final assetRaw = await rootBundle
            .loadString(_seedAsset)
            .timeout(const Duration(seconds: 2));
        return ReferralSettings.fromJson(
            jsonDecode(assetRaw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    try {
      return ReferralSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SettingRepository.getLocal] json corrupt: $e raw=$raw');
      try {
        final assetRaw = await rootBundle
            .loadString(_seedAsset)
            .timeout(const Duration(seconds: 2));
        return ReferralSettings.fromJson(
            jsonDecode(assetRaw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _cache(ReferralSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(settings.toJson()));
  }
}

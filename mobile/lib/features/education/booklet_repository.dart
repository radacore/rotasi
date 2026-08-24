import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/device_registrar.dart';
import '../../core/constants.dart';
import '../../core/db/app_database.dart';
import 'booklet.dart';

/// Pustaka edukasi offline (FR-09).
///
/// Menyimpan booklet aktif beserta status unduhan masing-masing. Saat online,
/// [fetchAll] membandingkan versi server per booklet; bila berubah, [download]
/// mengambil PDF terbaru dan file lama tetap tersimpan.
class BookletRepository {
  BookletRepository({
    ApiClient? api,
    http.Client? httpClient,
    Future<Directory> Function()? directoryProvider,
  })  : _api = api ?? ApiClient(),
        _http = httpClient ?? http.Client(),
        _directoryProvider =
            directoryProvider ?? _defaultDocumentsDirectory;

  static const _seedAsset = 'assets/booklets/rotasi_edukasi_1.pdf';
  static const _updatedAtKey = 'booklets_updated_at';

  final ApiClient _api;
  final http.Client _http;
  final Future<Directory> Function() _directoryProvider;

  Future<List<Booklet>> getAllLocal() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('booklets', orderBy: 'id ASC');
    return rows.map(Booklet.fromMap).toList();
  }

  Future<void> saveMeta(Booklet booklet) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'booklets',
      booklet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Semai booklet bawaan (asset) ke penyimpanan bila belum ada (offline-first).
  ///
  /// Judul sama dengan server (`Booklet Edukasi Ibu Hamil`) agar tidak ganda
  /// secara tampilan. Seed dipakai offline-first; saat online server id berbeda
  /// (mis. id 5) akan disinkronkan oleh [fetchAll] dan seed yatim akan dibersihkan.
  Future<Booklet?> ensureSeeded() async {
    final existing = await getAllLocal();
    for (final b in existing) {
      final path = b.localPath;
      if (b.fileUrl != _seedAsset || path == null) continue;
      if (await File(path).exists()) return null;
    }
    try {
      final data = await rootBundle.load(_seedAsset);
      final dir = Directory(
        p.join((await _directoryProvider()).path, 'booklets'),
      );
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, 'rotasi_edukasi_1.pdf'));
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      final seeded = Booklet(
        id: 1,
        title: 'Booklet Edukasi Ibu Hamil',
        version: '0',
        fileUrl: _seedAsset,
        fileSize: data.lengthInBytes,
        localPath: file.path,
        downloadedAt: DateTime.now(),
      );
      await saveMeta(seeded);
      return seeded;
    } catch (_) {
      return null;
    }
  }

  /// Ambil daftar booklet aktif dari server beserta status unduhan tiap item.
  ///
  /// `needsDownload` berisi id booklet yang versi server-nya berubah atau file
  /// lokal belum ada. Saat offline (atau tak ada booklet aktif), memakai
  /// data lokal yang ada. Versi baru: pakai `?since=updated_at` + `304`
  /// hemat kuota; `updated_at` disimpan di prefs.
  Future<({List<Booklet> booklets, Set<int> needsDownload})> fetchAll() async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      String? since;
      try {
        since = (await SharedPreferences.getInstance()).getString(_updatedAtKey);
      } catch (_) {}
      final path = since == null || since.isEmpty
          ? ApiEndpoints.booklet
          : '${ApiEndpoints.booklet}?since=${Uri.encodeComponent(since)}';
      final res = await _api.get(path);
      if (res.statusCode == 304) {
        final local = await getAllLocal();
        return (booklets: local, needsDownload: <int>{});
      }
      if (res.statusCode == 404) {
        // 404 bisa membawa updated_at (backend versioned) — simpan agar tidak poll boros
        try {
          final body404 = jsonDecode(res.body) as Map<String, dynamic>;
          final u = body404['updated_at'] as String?;
          if (u != null && u.isNotEmpty) {
            try {
              (await SharedPreferences.getInstance()).setString(_updatedAtKey, u);
            } catch (_) {}
          }
        } catch (_) {}
        final local = await getAllLocal();
        return (booklets: local, needsDownload: <int>{});
      }
      if (res.statusCode >= 300) {
        final local = await getAllLocal();
        return (booklets: local, needsDownload: <int>{});
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final remoteUpdatedAt = body['updated_at'] as String?;
      if (remoteUpdatedAt != null && remoteUpdatedAt.isNotEmpty) {
        try {
          (await SharedPreferences.getInstance()).setString(_updatedAtKey, remoteUpdatedAt);
        } catch (_) {}
      }
      final data = (body['data'] as List<dynamic>? ?? const []);
      if (data.isEmpty) {
        final local = await getAllLocal();
        return (booklets: local, needsDownload: <int>{});
      }

      final remotes = data
          .map((e) => Booklet.fromRemote(e as Map<String, dynamic>))
          .toList();
      final locals = {
        for (final b in await getAllLocal()) b.id: b,
      };

      final booklets = <Booklet>[];
      final needsDownload = <int>{};
      for (final remote in remotes) {
        final local = locals[remote.id];
        final sameFile = local != null &&
            local.version == remote.version &&
            local.fileUrl == remote.fileUrl;
        final fileExists = sameFile &&
            local.localPath != null &&
            await File(local.localPath!).exists();

        final merged = sameFile
            ? remote.copyWith(
                localPath: local.localPath,
                downloadedAt: local.downloadedAt,
              )
            : remote;
        await saveMeta(merged);
        // Hapus file versi lama yang orphan bila versi/file berubah
        if (!sameFile && local?.localPath != null) {
          try {
            final old = File(local!.localPath!);
            if (await old.exists() && old.path != merged.localPath) {
              await old.delete();
            }
          } catch (_) {}
        }
        booklets.add(merged);
        if (!(sameFile && fileExists)) needsDownload.add(remote.id);
      }
      // Hapus booklet yatim yang tak ada di server. Seed yatim (id 1 _seedAsset) juga
      // dibersihkan bila server sudah kirim 1+ booklet (id berbeda, judul sama) — cegah 2 card duplikat.
      final remoteIds = remotes.map((e) => e.id).toSet();
      final shouldPurgeSeed = remoteIds.isNotEmpty;
      for (final id in locals.keys) {
        if (remoteIds.contains(id)) continue;
        final isSeed = locals[id]!.fileUrl == _seedAsset;
        if (isSeed && !shouldPurgeSeed) continue;
        try {
          final orphanPath = locals[id]!.localPath;
          final db = await AppDatabase.instance;
          await db.delete('booklets', where: 'id = ?', whereArgs: [id]);
          // Hapus file fisik yatim bila bukan seed yang masih dipakai offline (seed sudah dibersihkan di atas)
          if (orphanPath != null && isSeed) {
            try {
              final f = File(orphanPath);
              if (await f.exists()) await f.delete();
            } catch (_) {}
          }
        } catch (_) {}
      }
      return (booklets: booklets, needsDownload: needsDownload);
    } catch (_) {
      final local = await getAllLocal();
      return (booklets: local, needsDownload: <int>{});
    }
  }

  // Dihapus: offline/404/data-empty tidak boleh memicu auto-download berulang.

  bool _refreshing = false;

  /// Tarik metadata + unduh file yang dibutuhkan secara senyap (untuk AutoSync).
  ///
  /// Dipanggil dari [SyncService.pullRemoteConfig] saat online/resume. Tidak
  /// throw — gagal unduh akan dicoba lagi periode berikutnya. File yang sudah
  /// ada tidak diunduh ulang.
  Future<void> refreshInBackground() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final result = await fetchAll().timeout(const Duration(seconds: 15));
      for (final id in result.needsDownload) {
        try {
          final meta = result.booklets.firstWhere((b) => b.id == id);
          await download(meta).timeout(const Duration(seconds: 90));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[BookletRepository.refreshInBackground] $e');
    } finally {
      _refreshing = false;
    }
  }

  /// Unduh PDF [meta] dan simpan di `documents/booklets/`.
  ///
  /// Mengembalikan booklet dengan `localPath` baru, atau null saat gagal.
  Future<Booklet?> download(Booklet meta) async {
    try {
      final res = await _http
          .get(Uri.parse(_resolveUrl(meta.fileUrl)))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode >= 300) return null;
      final dir = Directory(p.join((await _directoryProvider()).path, 'booklets'));
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, meta.fileName));
      await file.writeAsBytes(res.bodyBytes, flush: true);
      final updated = meta.copyWith(
        localPath: file.path,
        downloadedAt: DateTime.now(),
      );
      await saveMeta(updated);
      return updated;
    } catch (_) {
      return null;
    }
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final origin = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
      path: '',
    );
    return origin.resolve(url).toString();
  }

  static Future<Directory> _defaultDocumentsDirectory() =>
      getApplicationDocumentsDirectory();
}

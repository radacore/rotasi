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

  /// Jika offline (seed) dan server file-nya sama (fileSize sama), hapus
  /// baris seed agar hanya 1 card tampil. File fisik tetap (dipakai booklet server).
  Future<void> purgeDuplicateSeedBySize() async {
    try {
      final db = await AppDatabase.instance;
      final rows = await db.query('booklets', orderBy: 'id ASC');
      final locals = rows.map(Booklet.fromMap).toList();
      Booklet? seed;
      for (final b in locals) {
        if (b.fileUrl == _seedAsset) {
          seed = b;
          break;
        }
      }
      if (seed == null || seed.fileSize == null || seed.localPath == null) return;
      if (!await File(seed.localPath!).exists()) return;
      for (final b in locals) {
        if (b.fileUrl == _seedAsset) continue;
        if (b.fileSize != null && b.fileSize == seed.fileSize) {
          await db.delete('booklets', where: 'id = ?', whereArgs: [seed.id]);
          break;
        }
      }
    } catch (_) {}
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
  /// Cegah seed ganda bila sudah ada booklet (hasil migrasi) yang filenya masih ada.
  Future<Booklet?> ensureSeeded() async {
    final existing = await getAllLocal();
    ByteData? assetData;
    try {
      assetData = await rootBundle.load(_seedAsset);
    } catch (_) {}
    if (assetData == null) return null;
    final assetSize = assetData.lengthInBytes;
    // Jika seed sudah ada dan ukuran sama -> tidak perlu buat ulang.
    // Jika ukuran beda (aset baru 9.6M vs lama 10M) -> timpa agar offline default == VPS.
    for (final b in existing) {
      final path = b.localPath;
      if (path == null) continue;
      if (b.fileUrl == _seedAsset && await File(path).exists()) {
        if (b.fileSize == assetSize) return null;
        // size beda -> break untuk timpa di bawah
        break;
      }
    }
    // Jika sudah ada booklet server yang filenya ada dan ukurannya sama dengan aset baru,
    // seed akan di-dedup di fetchAll (seedMatchesRemoteBySize) -> jangan buat seed ganda.
    // Tapi jika belum ada file server, tetap buat/overwrite seed agar offline tersedia.
    final hasServerFile = existing.any((b) => b.fileUrl != _seedAsset && b.localPath != null);
    if (hasServerFile) {
      // cek apakah ada server file yang sudah ada dan size-nya sama dengan aset baru -> tidak perlu seed baru
      // (fetchAll akan pakai file server). Jika tidak ada yang sama, tetap buat seed.
      bool serverMatchesAsset = false;
      for (final b in existing) {
        if (b.fileUrl == _seedAsset) continue;
        if (b.fileSize == assetSize && b.localPath != null && await File(b.localPath!).exists()) {
          serverMatchesAsset = true;
          break;
        }
      }
      if (serverMatchesAsset) {
        // Sudah ada server file dengan size sama -> seed tidak perlu (akan dedup)
        // Tapi jika seed lama beda size, tetap timpa seed agar konsisten
        Booklet? seed;
        for (final b in existing) {
          if (b.fileUrl == _seedAsset) {
            seed = b;
            break;
          }
        }
        if (seed != null && seed.fileSize == assetSize) return null;
      }
    }
    try {
      final data = assetData;
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

      // Dedup: seed offline vs server file sama (fileSize sama) -> anggap satu
      Booklet? seedLocal;
      for (final b in locals.values) {
        if (b.fileUrl == _seedAsset) {
          seedLocal = b;
          break;
        }
      }
      final remoteFileSizes = {
        for (final r in remotes) if (r.fileSize != null) r.fileSize!,
      };
      final seedMatchesRemoteBySize = seedLocal != null &&
          seedLocal.fileSize != null &&
          remoteFileSizes.contains(seedLocal.fileSize) &&
          seedLocal.localPath != null &&
          await File(seedLocal.localPath!).exists();

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

        // Jika file offline (seed) sama isinya dengan remote (fileSize sama),
        // tampilkan hanya 1 card: pakai file offline untuk remote (tanpa unduh ulang).
        // Tangani juga kasus remote sudah terunduh terpisah (2 file sama) -> cukup 1.
        final seedCoversRemote = seedMatchesRemoteBySize &&
            remote.fileSize != null &&
            remote.fileSize == seedLocal.fileSize;
        if (seedCoversRemote) {
          final localHasFile = local != null &&
              local.localPath != null &&
              await File(local.localPath!).exists();
          if (local == null || !localHasFile) {
            final migrated = remote.copyWith(
              localPath: seedLocal.localPath,
              downloadedAt: seedLocal.downloadedAt,
            );
            await saveMeta(migrated);
            booklets.add(migrated);
            continue;
          } else {
            // Remote sudah ada file sendiri dengan ukuran sama -> cukup pakai file remote,
            // seed akan dihapus di cleanup agar 1 card.
            final merged = remote.copyWith(
              localPath: local.localPath,
              downloadedAt: local.downloadedAt,
            );
            await saveMeta(merged);
            booklets.add(merged);
            continue;
          }
        }

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
        if (!(sameFile && fileExists)) {
          needsDownload.add(remote.id);
        }
      }
      // Hapus booklet yatim yang tak ada di server.
      // Seed dengan fileSize sama dengan server dianggap sudah ter-cover -> hapus agar 1 card.
      final remoteIds = remotes.map((e) => e.id).toSet();
      final shouldPurgeSeed = remoteIds.isNotEmpty;
      for (final id in locals.keys) {
        if (remoteIds.contains(id)) continue;
        final b = locals[id]!;
        final isSeed = b.fileUrl == _seedAsset;
        final seedSameAsServer =
            isSeed && b.fileSize != null && remoteFileSizes.contains(b.fileSize);
        if (seedSameAsServer) {
          try {
            final db = await AppDatabase.instance;
            await db.delete('booklets', where: 'id = ?', whereArgs: [id]);
            // file fisik seed sudah dipakai remote (migrated), jangan hapus
          } catch (_) {}
          continue;
        }
        if (isSeed && !shouldPurgeSeed) continue;
        try {
          final orphanPath = b.localPath;
          final db = await AppDatabase.instance;
          await db.delete('booklets', where: 'id = ?', whereArgs: [id]);
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

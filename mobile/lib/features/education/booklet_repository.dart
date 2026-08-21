import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
  /// Menyalin PDF yang dibundel ke folder dokumen lalu menyimpan metadata.
  /// Mengembalikan booklet yang disemai, atau null bila sudah ada / gagal.
  /// Versi server akan menimpanya (dan mengunduh PDF baru) saat online.
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
        title: 'Booklet Edukasi',
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
  /// data lokal yang ada.
  Future<({List<Booklet> booklets, Set<int> needsDownload})> fetchAll() async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.get(ApiEndpoints.booklet);
      if (res.statusCode >= 300) {
        final local = await getAllLocal();
        return (booklets: local, needsDownload: <int>{});
      }
      final data =
          (jsonDecode(res.body) as Map<String, dynamic>)['data'] as List<dynamic>;
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
        booklets.add(merged);
        if (!(sameFile && fileExists)) needsDownload.add(remote.id);
      }
      return (booklets: booklets, needsDownload: needsDownload);
    } catch (_) {
      final local = await getAllLocal();
      return (booklets: local, needsDownload: <int>{});
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

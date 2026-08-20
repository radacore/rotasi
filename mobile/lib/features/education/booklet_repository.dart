import 'dart:convert';
import 'dart:io';

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
/// Menyimpan satu booklet aktif beserta status unduhan. Saat online,
/// [fetchRemote] membandingkan versi server; bila berubah, [download]
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

  final ApiClient _api;
  final http.Client _http;
  final Future<Directory> Function() _directoryProvider;

  Future<Booklet?> getLocal() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('booklets', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return Booklet.fromMap(rows.first);
  }

  Future<void> saveMeta(Booklet booklet) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'booklets',
      booklet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil metadata booklet aktif dari server.
  ///
  /// Mengembalikan `needsDownload=true` bila versi server berubah atau file
  /// lokal belum ada. Saat offline, memakai data lokal yang ada.
  Future<({Booklet? meta, bool needsDownload})> fetchRemote() async {
    try {
      await DeviceRegistrar(_api).ensureRegistered();
      final res = await _api.get(ApiEndpoints.booklet);
      if (res.statusCode >= 300) {
        final local = await getLocal();
        return (meta: local, needsDownload: false);
      }
      final data =
          (jsonDecode(res.body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
      final remote = Booklet.fromRemote(data);
      final local = await getLocal();

      final sameVersion = local?.version == remote.version;
      final fileExists = local?.localPath != null &&
          await File(local!.localPath!).exists();

      final merged = sameVersion && local != null
          ? Booklet(
              title: remote.title,
              version: remote.version,
              fileUrl: remote.fileUrl,
              fileSize: remote.fileSize,
              uploadedAt: remote.uploadedAt,
              localPath: local.localPath,
              downloadedAt: local.downloadedAt,
            )
          : remote;
      await saveMeta(merged);
      return (meta: merged, needsDownload: !(sameVersion && fileExists));
    } catch (_) {
      final local = await getLocal();
      return (meta: local, needsDownload: false);
    }
  }

  /// Unduh PDF [meta] dan simpan di `documents/booklets/`.
  ///
  /// Mengembalikan booklet dengan `localPath` baru, atau null saat gagal.
  Future<Booklet?> download(Booklet meta) async {
    try {
      final res = await _http
          .get(Uri.parse(_resolveUrl(meta.fileUrl)))
          .timeout(const Duration(seconds: 15));
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

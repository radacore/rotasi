import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:rotasi_mobile/core/api/api_client.dart';
import 'package:rotasi_mobile/core/db/app_database.dart';
import 'package:rotasi_mobile/features/education/booklet.dart';
import 'package:rotasi_mobile/features/education/booklet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeApi extends ApiClient {
  _FakeApi(this.statusCode, this.body);

  int statusCode;
  String body;

  @override
  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
  }) async {
    return http.Response(body, statusCode);
  }
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this.statusCode, this.bytes);

  int statusCode;
  List<int> bytes;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stream = Stream<List<int>>.value(bytes);
    return http.StreamedResponse(stream, statusCode, contentLength: bytes.length);
  }
}

String _remoteJson({String version = '1.0'}) => jsonEncode({
      'success': true,
      'data': {
        'id': 1,
        'title': 'Panduan Ibu Hamil',
        'version': version,
        'file_url': 'http://x/storage/booklets/b.pdf',
        'file_size': 1024,
        'uploaded_at': '2026-08-01 10:00:00',
      },
    });

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.testDatabasePath = inMemoryDatabasePath;
    SharedPreferences.setMockInitialValues({'device_token': 'test-token'});
  });

  setUp(() async {
    await AppDatabase.reset();
    tempDir = Directory.systemTemp.createTempSync('booklet_test');
  });

  tearDown(() async {
    await AppDatabase.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  BookletRepository repo({_FakeApi? api, _FakeHttpClient? httpClient}) {
    return BookletRepository(
      api: api ?? _FakeApi(404, '{}'),
      httpClient: httpClient ?? _FakeHttpClient(200, [1, 2, 3]),
      directoryProvider: () async => tempDir,
    );
  }

  test('getLocal awalnya null', () async {
    expect(await repo().getLocal(), isNull);
  });

  test('ensureSeeded menyalin PDF bawaan & menyimpan metadata', () async {
    final r = repo();
    final seeded = await r.ensureSeeded();
    expect(seeded, isNotNull);
    expect(seeded!.isDownloaded, true);
    expect(File(seeded.localPath!).existsSync(), true);
    expect(p.basename(seeded.localPath!), 'rotasi_edukasi_1.pdf');

    final stored = await r.getLocal();
    expect(stored, isNotNull);
    expect(stored!.version, '1');
  });

  test('ensureSeeded tidak menimpa booklet yang sudah ada', () async {
    final r = repo();
    await r.ensureSeeded();
    final first = await r.getLocal();

    expect(await r.ensureSeeded(), isNull);
    final second = await r.getLocal();
    expect(second!.localPath, first!.localPath);
  });

  test('saveMeta + getLocal roundtrip', () async {
    final r = repo();
    final b = Booklet(
      title: 'Panduan',
      version: '1.0',
      fileUrl: 'http://x/b.pdf',
    );
    await r.saveMeta(b);
    final stored = await r.getLocal();
    expect(stored, isNotNull);
    expect(stored!.title, 'Panduan');
    expect(stored.version, '1.0');
  });

  test('fetchRemote versi baru -> needsDownload true', () async {
    final r = repo(api: _FakeApi(200, _remoteJson(version: '2.0')));
    final result = await r.fetchRemote();
    expect(result.meta, isNotNull);
    expect(result.meta!.version, '2.0');
    expect(result.needsDownload, true);

    final stored = await r.getLocal();
    expect(stored!.version, '2.0');
  });

  test('fetchRemote versi sama + file ada -> needsDownload false', () async {
    final r = repo(api: _FakeApi(200, _remoteJson(version: '1.0')));
    final existing = File('${tempDir.path}/rotasi_edukasi_1.0.pdf');
    existing.writeAsBytesSync([1, 2, 3]);

    await r.saveMeta(
      Booklet(
        title: 'Panduan',
        version: '1.0',
        fileUrl: 'http://x/b.pdf',
        localPath: existing.path,
        downloadedAt: DateTime(2026, 8, 1),
      ),
    );

    final result = await r.fetchRemote();
    expect(result.needsDownload, false);
    expect(result.meta!.localPath, existing.path);
  });

  test('download menulis file & memperbarui metadata', () async {
    final r = repo(httpClient: _FakeHttpClient(200, utf8.encode('%PDF-hello')));
    final meta = Booklet(
      title: 'Panduan',
      version: '1.0',
      fileUrl: 'http://x/b.pdf',
    );
    final updated = await r.download(meta);
    expect(updated, isNotNull);
    expect(updated!.isDownloaded, true);
    expect(updated.localPath, isNotNull);
    expect(File(updated.localPath!).existsSync(), true);
    expect(File(updated.localPath!).readAsStringSync(), '%PDF-hello');

    final stored = await r.getLocal();
    expect(stored!.localPath, updated.localPath);
  });

  test('download gagal saat server error -> null', () async {
    final r = repo(httpClient: _FakeHttpClient(500, []));
    final updated = await r.download(
      Booklet(title: 'Panduan', version: '1.0', fileUrl: 'http://x/b.pdf'),
    );
    expect(updated, isNull);
  });

  test('fetchRemote offline (gagal) -> memakai metadata lokal', () async {
    final r = repo();
    await r.saveMeta(
      Booklet(title: 'Panduan', version: '1.0', fileUrl: 'http://x/b.pdf'),
    );
    final result = await r.fetchRemote();
    expect(result.meta, isNotNull);
    expect(result.meta!.version, '1.0');
    expect(result.needsDownload, false);
  });
}

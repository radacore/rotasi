import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rotasi_mobile/core/api/api_client.dart';
import 'package:rotasi_mobile/features/midwife/midwife_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

String _json() => jsonEncode({
      'success': true,
      'data': [
        {'id': 1, 'name': 'Bidan Rini', 'role': 'Bidan Desa', 'phone': '08123'},
        {'id': 2, 'name': 'Bidan Sari', 'role': 'Bidan', 'phone': '08111'},
      ],
    });

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fetchRemote menyimpan cache lokal', () async {
    final repo = MidwifeRepository(api: _FakeApi(200, _json()));
    final remote = await repo.fetchRemote();
    expect(remote.length, 2);
    expect(remote.first.name, 'Bidan Rini');
    expect(remote.first.phone, '08123');

    final local = await repo.getLocal();
    expect(local.length, 2);
    expect(local.last.name, 'Bidan Sari');
  });

  test('fetchRemote gagal -> memakai cache lokal', () async {
    // Simpan cache dulu.
    final online = MidwifeRepository(api: _FakeApi(200, _json()));
    await online.fetchRemote();

    final offline = MidwifeRepository(api: _FakeApi(500, '{}'));
    final fromCache = await offline.fetchRemote();
    expect(fromCache.length, 2);
  });

  test('getLocal tanpa cache -> kosong', () async {
    final repo = MidwifeRepository(api: _FakeApi(500, '{}'));
    expect(await repo.getLocal(), isEmpty);
  });
}

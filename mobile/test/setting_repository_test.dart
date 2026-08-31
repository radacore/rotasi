import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rotasi_mobile/core/api/api_client.dart';
import 'package:rotasi_mobile/features/referral/setting_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi extends ApiClient {
  _FakeApi(this.statusCode, this.body);

  int statusCode;
  String body;

  @override
  Future<void> registerDevice({
    required String androidId,
    required String appVersion,
    String? deviceName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_token', 'fake-token');
  }

  @override
  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
  }) async {
    return http.Response(body, statusCode);
  }
}

String _json({String phone = '119'}) => jsonEncode({
      'success': true,
      'data': {
        'app_name': 'ROTASI',
        'emergency_phone': phone,
        'ambulance_phone': phone,
        'homecare_phone': '112',
        'puskesmas_phone': '081343677797',
        'puskesmas_phone_alt': '0812417777718',
        'puskesmas_name': 'Puskesmas Sehat',
        'puskesmas_address': 'Jl. Merdeka 1',
        'default_wa_message': 'Halo bidan',
        'referral_rules': {
          'persistent_colors': ['orange', 'red'],
          'symptom_check_trigger': true,
          'kick_threshold': 3,
        },
      },
    });

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fetchRemote menyimpan cache lokal', () async {
    final repo = SettingRepository(api: _FakeApi(200, _json()));
    final remote = await repo.fetchRemote();
    expect(remote, isNotNull);
    expect(remote!.emergencyPhone, '119');
    expect(remote.puskesmasName, 'Puskesmas Sehat');
    expect(remote.rules.kickThreshold, 3);

    final local = await repo.getLocal();
    expect(local, isNotNull);
    expect(local!.emergencyPhone, '119');
  });

  test('fetchRemote gagal -> memakai cache lokal', () async {
    SharedPreferences.setMockInitialValues({});
    final offline = SettingRepository(api: _FakeApi(500, '{}'));
    // offline tanpa cache -> fallback asset (bukan null) agar tidak blank
    expect(await offline.fetchRemote(), isNotNull);

    // Simpan cache dulu lalu offline.
    final online = SettingRepository(api: _FakeApi(200, _json(phone: '118')));
    await online.fetchRemote();

    final offline2 = SettingRepository(api: _FakeApi(500, '{}'));
    final fromCache = await offline2.fetchRemote();
    expect(fromCache, isNotNull);
    expect(fromCache!.emergencyPhone, '118');
  });

  test('getLocal tanpa cache -> fallback asset (anti hang spinner)', () async {
    final repo = SettingRepository(api: _FakeApi(500, '{}'));
    // getLocal sekarang fallback ke asset bila belum ada cache agar
    // halaman tidak stuck loading (lihat fix hang di TC-KM6).
    final local = await repo.getLocal();
    expect(local, isNotNull);
    expect(local!.emergencyPhone, '119');
  });

  test('ensureSeeded mengisi cache dari asset bawaan', () async {
    final repo = SettingRepository(api: _FakeApi(500, '{}'));
    final seeded = await repo.ensureSeeded();
    expect(seeded, isNotNull);
    expect(seeded!.emergencyPhone, '119');
    expect(seeded.puskesmasName, isNotEmpty);

    final local = await repo.getLocal();
    expect(local, isNotNull);
    expect(local!.emergencyPhone, '119');
  });

  test('ensureSeeded tidak menimpa cache yang sudah ada', () async {
    final online = SettingRepository(api: _FakeApi(200, _json(phone: '118')));
    await online.fetchRemote();

    final repo = SettingRepository(api: _FakeApi(500, '{}'));
    expect(await repo.ensureSeeded(), isNull);
    final local = await repo.getLocal();
    expect(local!.emergencyPhone, '118');
  });
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import 'api_client.dart';

/// Mendaftarkan perangkat sekali (install) ke backend ROTASI.
///
/// Menggunakan UUID persist lokal sebagai identitas perangkat (bukan
/// ANDROID_ID) agar privasi tetap terjaga dan bekerja tanpa izin tambahan.
class DeviceRegistrar {
  DeviceRegistrar(this._api);

  static const _installUuidKey = 'install_uuid';

  final ApiClient _api;

  /// Memastikan perangkat sudah terdaftar dan punya token Sanctum.
  Future<void> ensureRegistered() async {
    if (await _api.token() != null) return;

    final prefs = await SharedPreferences.getInstance();
    var installId = prefs.getString(_installUuidKey);
    if (installId == null) {
      installId = const Uuid().v4();
      await prefs.setString(_installUuidKey, installId);
    }

    await _api.registerDevice(
      androidId: installId,
      appVersion: AppConfig.appVersion,
    );
  }
}

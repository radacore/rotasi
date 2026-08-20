/// Konstanta global aplikasi ROTASI.
abstract final class AppConfig {
  /// URL dasar API. Ganti sesuai server backend (lihat DEPLOYMENT.md).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  /// Versi aplikasi yang dilaporkan saat registrasi perangkat.
  static const String appVersion = '0.1.0';

  /// Identitas untuk meminta UUID perangkat (Android ID / Device ID).
  static const String androidIdPlaceholder = 'unknown';
}

abstract final class ApiEndpoints {
  static const String deviceRegister = '/device/register';
  static const String patient = '/patient';
  static const String sync = '/sync';
  static const String syncBp = '/sync/bp';
  static const String syncSymptom = '/sync/symptom';
  static const String syncKick = '/sync/kick';
  static const String syncAnc = '/sync/anc';
  static const String booklet = '/booklet';
  static const String settings = '/settings';
  static const String midwives = '/midwives';
  static const String latestRelease = '/app/latest-release';
}

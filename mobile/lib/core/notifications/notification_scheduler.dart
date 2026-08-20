import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Penjadwal notifikasi lokal (FR-14).
///
/// Abstraksi agar mudah dipalsukan pada tes; implementasi nyata memakai
/// `flutter_local_notifications` (berjalan tanpa koneksi).
abstract class NotificationScheduler {
  /// Jadwalkan notifikasi harian pada [hour]:[minute] (waktu lokal).
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();
}

/// Implementasi nyata berbasis `flutter_local_notifications`.
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'pengingat_tensi';
  static const _channelName = 'Pengingat Pengukuran Tensi';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local));
    _initialized = true;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Pengingat pengukuran tekanan darah pagi & sore',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}

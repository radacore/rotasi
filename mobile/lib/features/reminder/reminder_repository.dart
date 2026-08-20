import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'reminder_settings.dart';

/// Penyimpanan pengaturan pengingat (SharedPreferences).
class ReminderRepository {
  static const _key = 'reminder_settings';

  /// Baca pengaturan tersimpan; `null` jika belum pernah disimpan.
  Future<ReminderSettings?> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

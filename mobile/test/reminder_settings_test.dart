import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/reminder/reminder_repository.dart';
import 'package:rotasi_mobile/features/reminder/reminder_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ReminderSettings', () {
    test('default pagi 07:00 dan sore 18:00, nonaktif', () {
      const settings = ReminderSettings();
      expect(settings.enabled, isFalse);
      expect(settings.morning.hour, 7);
      expect(settings.morning.minute, 0);
      expect(settings.evening.hour, 18);
      expect(settings.evening.minute, 0);
    });

    test('copyWith mengubah sebagian nilai saja', () {
      const settings = ReminderSettings(enabled: true);
      final updated =
          settings.copyWith(morning: const TimeOfDay(hour: 6, minute: 30));
      expect(updated.enabled, isTrue);
      expect(updated.morning, const TimeOfDay(hour: 6, minute: 30));
      expect(updated.evening, settings.evening);
    });

    test('toJson/fromJson round-trip', () {
      const settings = ReminderSettings(
        enabled: true,
        morning: TimeOfDay(hour: 6, minute: 30),
        evening: TimeOfDay(hour: 19, minute: 15),
      );
      final restored =
          ReminderSettings.fromJson(settings.toJson());
      expect(restored.enabled, isTrue);
      expect(restored.morning, const TimeOfDay(hour: 6, minute: 30));
      expect(restored.evening, const TimeOfDay(hour: 19, minute: 15));
    });

    test('fromJson tanpa data mengembalikan default', () {
      final restored = ReminderSettings.fromJson(const {});
      expect(restored.enabled, isFalse);
      expect(restored.morning, const TimeOfDay(hour: 7, minute: 0));
      expect(restored.evening, const TimeOfDay(hour: 18, minute: 0));
    });
  });

  group('ReminderRepository', () {
    test('belum tersimpan mengembalikan null', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ReminderRepository();
      expect(await repo.getLocal(), isNull);
    });

    test('save lalu getLocal mengembalikan pengaturan yang sama', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ReminderRepository();
      const settings = ReminderSettings(
        enabled: true,
        morning: TimeOfDay(hour: 6, minute: 30),
        evening: TimeOfDay(hour: 20, minute: 0),
      );

      await repo.save(settings);
      final restored = await repo.getLocal();

      expect(restored, isNotNull);
      expect(restored!.enabled, isTrue);
      expect(restored.morning, const TimeOfDay(hour: 6, minute: 30));
      expect(restored.evening, const TimeOfDay(hour: 20, minute: 0));
    });
  });
}

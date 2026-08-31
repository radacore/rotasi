import 'package:flutter/material.dart';

/// Pengaturan pengingat lokal pengukuran pagi & sore (FR-14) + ceklis 10T ANC harian.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.morning = const TimeOfDay(hour: 7, minute: 0),
    this.evening = const TimeOfDay(hour: 18, minute: 0),
    this.ancEnabled = false,
    this.ancTime = const TimeOfDay(hour: 8, minute: 0),
  });

  final bool enabled;
  final TimeOfDay morning;
  final TimeOfDay evening;
  final bool ancEnabled;
  final TimeOfDay ancTime;

  ReminderSettings copyWith({
    bool? enabled,
    TimeOfDay? morning,
    TimeOfDay? evening,
    bool? ancEnabled,
    TimeOfDay? ancTime,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      morning: morning ?? this.morning,
      evening: evening ?? this.evening,
      ancEnabled: ancEnabled ?? this.ancEnabled,
      ancTime: ancTime ?? this.ancTime,
    );
  }

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      enabled: (json['enabled'] as int? ?? 0) == 1,
      morning: TimeOfDay(
        hour: json['morning_hour'] as int? ?? 7,
        minute: json['morning_minute'] as int? ?? 0,
      ),
      evening: TimeOfDay(
        hour: json['evening_hour'] as int? ?? 18,
        minute: json['evening_minute'] as int? ?? 0,
      ),
      ancEnabled: (json['anc_enabled'] as int? ?? 0) == 1,
      ancTime: TimeOfDay(
        hour: json['anc_time_hour'] as int? ?? 8,
        minute: json['anc_time_minute'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled ? 1 : 0,
      'morning_hour': morning.hour,
      'morning_minute': morning.minute,
      'evening_hour': evening.hour,
      'evening_minute': evening.minute,
      'anc_enabled': ancEnabled ? 1 : 0,
      'anc_time_hour': ancTime.hour,
      'anc_time_minute': ancTime.minute,
    };
  }
}

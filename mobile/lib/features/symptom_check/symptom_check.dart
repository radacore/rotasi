import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Gejala bahaya kehamilan yang diceklis harian (FR-06).
enum DangerSymptom {
  headache('headache', 'Sakit kepala hebat', Icons.psychology),
  blurredVision('blurred_vision', 'Pandangan kabur', Icons.visibility_off),
  epigastricPain('epigastric_pain', 'Nyeri ulu hati', Icons.healing),
  shortnessOfBreath('shortness_of_breath', 'Sesak napas', Icons.air);

  const DangerSymptom(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

/// Ceklis gejala bahaya harian (FR-06).
///
/// Sinkron ke `POST /api/v1/sync/symptom` (idempoten berbasis UUID).
class SymptomCheck {
  const SymptomCheck({
    required this.uuid,
    required this.patientUuid,
    required this.checkedAt,
    this.headache = false,
    this.blurredVision = false,
    this.epigastricPain = false,
    this.shortnessOfBreath = false,
    this.synced = false,
  });

  final String uuid;
  final String patientUuid;
  final DateTime checkedAt;
  final bool headache;
  final bool blurredVision;
  final bool epigastricPain;
  final bool shortnessOfBreath;
  final bool synced;

  /// Membuat record baru untuk satu hari.
  factory SymptomCheck.daily({
    required String patientUuid,
    required DateTime checkedAt,
    required bool headache,
    required bool blurredVision,
    required bool epigastricPain,
    required bool shortnessOfBreath,
  }) {
    return SymptomCheck(
      uuid: const Uuid().v4(),
      patientUuid: patientUuid,
      checkedAt: checkedAt,
      headache: headache,
      blurredVision: blurredVision,
      epigastricPain: epigastricPain,
      shortnessOfBreath: shortnessOfBreath,
    );
  }

  bool valueOf(DangerSymptom symptom) {
    switch (symptom) {
      case DangerSymptom.headache:
        return headache;
      case DangerSymptom.blurredVision:
        return blurredVision;
      case DangerSymptom.epigastricPain:
        return epigastricPain;
      case DangerSymptom.shortnessOfBreath:
        return shortnessOfBreath;
    }
  }

  /// Minimal satu gejala bahaya tercentang.
  bool get hasAny =>
      headache || blurredVision || epigastricPain || shortnessOfBreath;

  factory SymptomCheck.fromMap(Map<String, dynamic> map) {
    return SymptomCheck(
      uuid: map['uuid'] as String,
      patientUuid: map['patient_uuid'] as String,
      checkedAt: DateTime.parse(map['checked_at'] as String),
      headache: (map['headache'] as int? ?? 0) == 1,
      blurredVision: (map['blurred_vision'] as int? ?? 0) == 1,
      epigastricPain: (map['epigastric_pain'] as int? ?? 0) == 1,
      shortnessOfBreath: (map['shortness_of_breath'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'patient_uuid': patientUuid,
      'checked_at': checkedAt.toIso8601String(),
      'headache': headache ? 1 : 0,
      'blurred_vision': blurredVision ? 1 : 0,
      'epigastric_pain': epigastricPain ? 1 : 0,
      'shortness_of_breath': shortnessOfBreath ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  /// Payload untuk `POST /api/v1/sync/symptom`.
  Map<String, dynamic> toSyncPayload() {
    return {
      'patient_uuid': patientUuid,
      'uuid': uuid,
      'checked_at': checkedAt.toIso8601String(),
      'headache': headache,
      'blurred_vision': blurredVision,
      'epigastric_pain': epigastricPain,
      'shortness_of_breath': shortnessOfBreath,
    };
  }
}

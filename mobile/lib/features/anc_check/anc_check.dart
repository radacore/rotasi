import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Standar pemeriksaan Antenatal Care 10T (FR-08).
enum AncItem {
  t1('t1', 'Ukur Berat Badan', 'Pantau kenaikan berat badan ibu', Icons.monitor_weight_outlined),
  t2('t2', 'Ukur Tekanan Darah', '10T No.2 Buku KIA 2025 — wajib tiap ANC K1-K6, deteksi hipertensi ≥140/90', Icons.favorite_outline),
  t3('t3', 'Ukur Tinggi Fundus', 'Periksa pertumbuhan janin', Icons.straighten),
  t4('t4', 'Periksa Letak Janin', 'Pemeriksaan Leopold', Icons.accessibility_new),
  t5('t5', 'Hitung DJJ', 'Denyut jantung janin', Icons.monitor_heart_outlined),
  t6('t6', 'Imunisasi TT', 'Skrining status imunisasi tetanus', Icons.vaccines_outlined),
  t7('t7', 'Tablet Tambah Darah', 'Minimal 90 tablet selama hamil', Icons.medication_outlined),
  t8('t8', 'Pemeriksaan Lab', 'Hb, golongan darah, protein urin', Icons.science_outlined),
  t9('t9', 'Tatalaksana Kasus', 'Terapi atau rujukan sesuai kondisi', Icons.medical_services_outlined),
  t10('t10', 'Konseling', 'Tanya jawab & edukasi kesehatan', Icons.chat_outlined);

  const AncItem(this.code, this.title, this.subtitle, this.icon);

  final String code;
  final String title;
  final String subtitle;
  final IconData icon;

  static AncItem fromCode(String code) => AncItem.values.firstWhere(
        (e) => e.code == code,
        orElse: () => AncItem.t1,
      );
}

/// Satu kunjungan ANC dengan ceklis 10T (FR-08).
///
/// Sinkron ke `POST /api/v1/sync/anc` (idempoten berbasis UUID).
class AncCheck {
  const AncCheck({
    required this.uuid,
    required this.patientUuid,
    required this.visitedAt,
    this.items = const [],
    this.synced = false,
  });

  final String uuid;
  final String patientUuid;
  final DateTime visitedAt;
  final List<String> items;
  final bool synced;

  /// Kunjungan baru tanpa ceklis.
  factory AncCheck.forDate({
    required String patientUuid,
    required DateTime visitedAt,
  }) {
    return AncCheck(
      uuid: const Uuid().v4(),
      patientUuid: patientUuid,
      visitedAt: visitedAt,
    );
  }

  bool isChecked(AncItem item) => items.contains(item.code);

  int get checkedCount => items.length;

  int get totalItems => AncItem.values.length;

  factory AncCheck.fromMap(Map<String, dynamic> map) {
    return AncCheck(
      uuid: map['uuid'] as String,
      patientUuid: map['patient_uuid'] as String,
      visitedAt: DateTime.parse(map['visited_at'] as String),
      items: (jsonDecode(map['t_items'] as String? ?? '[]') as List)
          .cast<String>(),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'patient_uuid': patientUuid,
      'visited_at': visitedAt.toIso8601String(),
      't_items': jsonEncode(items),
      'synced': synced ? 1 : 0,
    };
  }

  /// Payload untuk `POST /api/v1/sync/anc`.
  Map<String, dynamic> toSyncPayload() {
    return {
      'patient_uuid': patientUuid,
      'uuid': uuid,
      'visited_at': visitedAt.toIso8601String(),
      't_items': items,
    };
  }
}

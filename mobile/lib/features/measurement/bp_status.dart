import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Status warna tekanan darah ROTASI — 6 tier (revisi Beranda).
///
/// Hipotensi <90/60 #EE65C1, Normal <120/<80 #79B038, Waspada 120-129/<80 #FFD66E,
/// Berisiko 130-139/80-89 #F08E2B, Bahaya ≥140/≥90 #C85858, Darurat ≥160/110 #E23F25
/// Selalu ditampilkan dengan label + ikon + warna (bukan warna saja)
/// agar aman bagi pengguna buta warna.
enum BpStatus {
  hypotension('pink', 'Hipotensi', AppColors.hypotension, Icons.water_drop_outlined),
  normal('green', 'Normal', AppColors.normal, Icons.check_circle),
  elevated('yellow', 'Waspada', AppColors.elevated, Icons.info_outline),
  stage1('orange', 'Berisiko', AppColors.stage1, Icons.warning_amber_rounded),
  crisis('red', 'Bahaya', AppColors.crisis, Icons.error),
  emergency('darkred', 'Darurat', AppColors.emergency, Icons.emergency_outlined);

  const BpStatus(this.code, this.label, this.color, this.icon);

  final String code;
  final String label;
  final Color color;
  final IconData icon;

  /// Klasifikasi 6 tier:
  /// Darurat ≥160/110 diperiksa dulu (subset Bahaya), lalu Bahaya ≥140/≥90,
  /// Berisiko ≥130/80, Waspada 120-129/<80, terakhir Hipotensi <90 ATAU <60,
  /// sisanya Normal. Hipotensi di akhir agar hipertensi prioritas (mis. 85/85
  /// tetap Berisiko, bukan Hipotensi).
  static BpStatus classify(int systolic, int diastolic) {
    if (systolic >= 160 || diastolic >= 110) return BpStatus.emergency;
    if (systolic >= 140 || diastolic >= 90) return BpStatus.crisis;
    if (systolic >= 130 || diastolic >= 80) return BpStatus.stage1;
    if (systolic >= 120) return BpStatus.elevated;
    if (systolic < 90 || diastolic < 60) return BpStatus.hypotension;
    return BpStatus.normal;
  }

  static BpStatus fromCode(String? code) => BpStatus.values.firstWhere(
        (s) => s.code == code,
        orElse: () => BpStatus.normal,
      );
}

/// Sesi pengukuran pagi/sore (FR-03).
///
/// Sesuai Buku KIA 2025: tensi wajib pada tiap kunjungan ANC K1-K6 (6x, 10T No.2).
enum SessionCode {
  pagi('pagi', 'Pagi'),
  sore('sore', 'Sore');

  const SessionCode(this.value, this.label);

  final String value;
  final String label;

  /// Default sesi dari jam sekarang (<12 = pagi).
  static SessionCode fromHour(DateTime time) =>
      time.hour < 12 ? SessionCode.pagi : SessionCode.sore;

  static SessionCode fromValue(String? value) => SessionCode.values.firstWhere(
        (s) => s.value == value,
        orElse: () => SessionCode.pagi,
      );
}

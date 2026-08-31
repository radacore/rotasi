import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Status warna tekanan darah ROTASI — 6 tier (revisi Beranda).
///
/// Hipotensi <90/<60 #EE65C1, Normal <120/<80 #79B038, Waspada 120-129/<80 #FFD66E,
/// Berisiko 130-139/80-89 #F08E2B, Bahaya 140-159/90-120 #C85858, Darurat ≥160/>120 #E23F25
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

  /// Klasifikasi sesuai spesifikasi client (prioritas Darurat dulu):
  /// 1. Darurat ≥160 ATAU >120, 2. Bahaya 140-159 ATAU 90-120,
  /// 3. Berisiko 130-139 ATAU 80-89, 4. Hipotensi <90 ATAU <60,
  /// 5. Waspada 120-129 DAN <80, 6. Normal <120 DAN <80.
  static BpStatus classify(int systolic, int diastolic) {
    if (systolic >= 160 || diastolic > 120) return BpStatus.emergency;
    if ((systolic >= 140 && systolic <= 159) || (diastolic >= 90 && diastolic <= 120)) {
      return BpStatus.crisis;
    }
    if ((systolic >= 130 && systolic <= 139) || (diastolic >= 80 && diastolic <= 89)) {
      return BpStatus.stage1;
    }
    if (systolic < 90 || diastolic < 60) return BpStatus.hypotension;
    if (systolic >= 120 && systolic <= 129 && diastolic < 80) return BpStatus.elevated;
    if (systolic < 120 && diastolic < 80) return BpStatus.normal;
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

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Status warna tekanan darah ROTASI (AHA 2025, FR-04).
///
/// Selalu ditampilkan dengan label + ikon + warna (bukan warna saja)
/// agar aman bagi pengguna buta warna.
enum BpStatus {
  normal('green', 'Normal', AppColors.normal, Icons.check_circle),
  elevated('yellow', 'Waspada', AppColors.elevated, Icons.info_outline),
  stage1('orange', 'Berisiko', AppColors.stage1, Icons.warning_amber_rounded),
  crisis('red', 'Bahaya', AppColors.crisis, Icons.error);

  const BpStatus(this.code, this.label, this.color, this.icon);

  final String code;
  final String label;
  final Color color;
  final IconData icon;

  /// Klasifikasi sesuai AHA 2025 dengan aturan *ambil kategori terburuk*
  /// antara sistolik dan diastolik:
  /// - Hijau: SYS <120 & DIA <80
  /// - Kuning: SYS 120–129 & DIA <80
  /// - Oranye: SYS 130–139 ATAU DIA 80–89
  /// - Merah: SYS >=140 ATAU DIA >=90
  static BpStatus classify(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) return BpStatus.crisis;
    if (systolic >= 130 || diastolic >= 80) return BpStatus.stage1;
    if (systolic >= 120) return BpStatus.elevated;
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

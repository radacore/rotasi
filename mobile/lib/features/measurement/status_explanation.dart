import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'bp_status.dart';

/// Keterangan warna gauge ROTASI (FR-04).
///
/// Hanya menampilkan satu kotak sesuai status aktif [active].
class StatusExplanation extends StatelessWidget {
  const StatusExplanation({super.key, required this.active});

  final BpStatus active;

  @override
  Widget build(BuildContext context) {
    final entry = _entries.firstWhere((e) => e.status == active);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: entry.status.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: entry.status.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: entry.status.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(entry.status.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.code,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: entry.status.color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Explanation {
  const _Explanation(this.status, this.code, this.text);

  final BpStatus status;
  final String code;
  final String text;
}

const _entries = <_Explanation>[
  _Explanation(
    BpStatus.normal,
    'HIJAU - AMAN',
    'Tekanan darah normal. Teruskan pola hidup sehat, makan bergizi, dan kontrol rutin ke bidan sesuai jadwal.',
  ),
  _Explanation(
    BpStatus.elevated,
    'KUNING - WASPADA',
    'Tekanan darah mulai naik. Kurangi makanan asin, istirahat cukup, dan sampaikan hasil ini ke bidan saat pemeriksaan ANC berikutnya.',
  ),
  _Explanation(
    BpStatus.stage1,
    'ORANYE - BERISIKO',
    'Tekanan darah sudah masuk Hipertensi Derajat 1. Ibu perlu segera berkonsultasi ke Puskesmas.',
  ),
  _Explanation(
    BpStatus.crisis,
    'MERAH - BAHAYA',
    'Tekanan darah sangat tinggi (Hipertensi Derajat 2). Ibu harus segera ke Puskesmas atau RS, terutama jika disertai gejala berat.',
  ),
];


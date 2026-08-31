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
                  entry.status.label.toUpperCase(),
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
  const _Explanation(this.status, this.text);

  final BpStatus status;
  final String text;
}

const _entries = <_Explanation>[
  _Explanation(
    BpStatus.hypotension,
    'Tekanan darah Anda terlalu rendah. Disarankan untuk minum air putih yang cukup, konsumsi makanan asin dalam batas wajar, dan hindari berdiri terlalu cepat secara mendadak.',
  ),
  _Explanation(
    BpStatus.normal,
    'Luar biasa! Tekanan darah Anda berada dalam kondisi prima. Pertahankan gaya hidup sehat, pola makan gizi seimbang, dan olahraga teratur.',
  ),
  _Explanation(
    BpStatus.elevated,
    'Tekanan darah Anda sedikit di atas normal. Mulai batasi konsumsi garam (natrium) berlebih dan kelola stres dengan baik untuk mencegah kenaikan lebih lanjut.',
  ),
  _Explanation(
    BpStatus.stage1,
    'Anda memasuki kategori Hipertensi Tingkat 1. Sangat disarankan untuk memantau tekanan darah secara berkala dalam 1 minggu ke depan dan berkonsultasi dengan dokter.',
  ),
  _Explanation(
    BpStatus.crisis,
    'Tekanan darah Anda tinggi (Hipertensi Tingkat 2). Anda membutuhkan evaluasi medis dari dokter dan kemungkinan terapi obat penurun tensi untuk mencegah komplikasi.',
  ),
  _Explanation(
    BpStatus.emergency,
    'PERINGATAN: Tekanan darah Anda berada di tingkat krisis! Jika Anda merasakan nyeri dada, sesak napas, sakit kepala hebat, atau gangguan penglihatan, segera hubungi ambulans atau pergi ke IGD terdekat.',
  ),
];


import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'bp_status.dart';

/// Keterangan warna gauge ROTASI (FR-04).
///
/// Empat kotak (HIJAU/KUNING/ORANYE/MERAH) dengan penjelasan dalam bahasa
/// Indonesia. Kotak status aktif disorot penuh, kotak lain disamarkan.
class StatusExplanation extends StatelessWidget {
  const StatusExplanation({super.key, required this.active});

  final BpStatus active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in _entries) ...[
          _ExplanationRow(entry: entry, isActive: entry.status == active),
          if (entry != _entries.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Explanation {
  const _Explanation(this.status, this.code, this.text);

  final BpStatus status;
  final String code;
  final String text;
}

const _mutedText = Color(0xFF94A3B8);

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

class _ExplanationRow extends StatelessWidget {
  const _ExplanationRow({required this.entry, required this.isActive});

  final _Explanation entry;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final muted = !isActive;
    final accent = muted ? _mutedText : entry.status.color;
    final bg = muted ? const Color(0xFFEEEEEE) : entry.status.color;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
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
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted
                      ? _mutedText
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

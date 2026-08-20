import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'bp_status.dart';

/// Roda warna ROTASI (FR-04) — visual menyerupai roda fisik.
///
/// Empat kuadran (Hijau→Kuning→Oranye→Merah, searah jarum jam dari atas).
/// Status aktif ditandai cincin luar lebih tebal + penunjuk. Bagian tengah
/// menampilkan ikon dan label agar aman bagi buta warna.
class RotasiWheel extends StatelessWidget {
  const RotasiWheel({super.key, required this.status, this.size = 220});

  final BpStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WheelPainter(status),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, size: size * 0.18, color: status.color),
              const SizedBox(height: 4),
              Text(
                status.label,
                style: TextStyle(
                  fontSize: size * 0.1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.status);

  final BpStatus status;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = radius * 0.55;
    final activeStroke = stroke * 1.18;

    final rect = Rect.fromCircle(center: center, radius: radius * 0.9);

    const segments = [0.25, 0.25, 0.25, 0.25];
    final colors = [
      AppColors.normal,
      AppColors.elevated,
      AppColors.stage1,
      AppColors.crisis,
    ];
    // Mulai dari atas, searah jarum jam.
    var start = -math.pi / 2;

    for (var i = 0; i < segments.length; i++) {
      final sweep = segments[i] * 2 * math.pi;
      final isActive = BpStatus.values[i] == status;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = colors[i]
        ..strokeWidth = isActive ? activeStroke : stroke;

      canvas.drawArc(rect, start + 0.02, sweep - 0.04, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) =>
      oldDelegate.status != status;
}

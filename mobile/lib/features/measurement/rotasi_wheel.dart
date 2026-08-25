import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'bp_status.dart';

/// Gauge ROTASI (FR-04) — lingkaran 4 sektor warna seperti alat ukur fisik.
///
/// Empat sektor (Hijau→Kuning→Oranye→Merah) mengelilingi lingkaran penuh:
/// Normal di kiri, Waspada di atas, Berisiko di kanan, Bahaya di bawah.
/// Setiap sektor memuat ambang tekanan darah, label, dan ikon. Jarum
/// abu-abu menunjuk ke tengah sektor status aktif dengan poros kuning emas.
class RotasiWheel extends StatelessWidget {
  const RotasiWheel({
    super.key,
    required this.status,
    this.size = 220,
  });

  final BpStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GaugePainter(status)),
    );
  }
}

class _Sector {
  const _Sector(this.status, this.label, this.threshold, this.icon);

  final BpStatus status;
  final String label;
  final String threshold;
  final IconData icon;
}

const _sectors = <_Sector>[
  _Sector(BpStatus.hypotension, 'HIPOTENSI', '<90/60', Icons.water_drop_outlined),
  _Sector(BpStatus.normal, 'NORMAL', '<120/<80', Icons.person),
  _Sector(BpStatus.elevated, 'WASPADA', '120-129/<80', Icons.warning_amber_rounded),
  _Sector(BpStatus.stage1, 'BERISIKO', '130-139/80-89', Icons.favorite),
  _Sector(BpStatus.crisis, 'BAHAYA', '≥140/≥90', Icons.local_hospital),
  _Sector(BpStatus.emergency, 'DARURAT', '≥160/110', Icons.emergency_outlined),
];

const _startAngles = <double>[
  -math.pi,          // Hipotensi  : kiri-bawah (pusat 210°)
  -2 * math.pi / 3,  // Normal     : atas (pusat 270°)
  -math.pi / 3,      // Waspada    : kanan-atas (pusat 330°)
  0,                 // Berisiko   : kanan (pusat 30°)
  math.pi / 3,       // Bahaya     : bawah (pusat 90°)
  2 * math.pi / 3,   // Darurat    : kiri-atas (pusat 150°)
];

const _sweep = 2 * math.pi / 6;

const _needleColor = Color(0xFF37474F);
const _hubColor = Color(0xFFE9A800);

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.status);

  final BpStatus status;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius * 0.92);

    // Sektor warna.
    for (var i = 0; i < _sectors.length; i++) {
      final sector = _sectors[i];
      final start = _startAngles[i];
      final isActive = sector.status == status;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rect, start, _sweep, false)
        ..close();
      canvas.drawPath(path, Paint()..color = sector.status.color);

      if (isActive) {
        canvas.drawArc(
          rect,
          start,
          _sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * 0.03
            ..color = AppColors.white,
        );
      }

      final mid = start + _sweep / 2;
      final dir = Offset(math.cos(mid), math.sin(mid));
      final isDark = sector.status == BpStatus.elevated || sector.status == BpStatus.hypotension;
      final textColor =
          isDark ? AppColors.textPrimary : Colors.white;
      final shadow = [
        const Shadow(color: Colors.black38, blurRadius: 2),
      ];

      _paintText(
        canvas,
        sector.threshold,
        center + dir * (radius * 0.38),
        size.width * 0.048,
        textColor,
        FontWeight.w800,
        shadow,
      );
      _paintText(
        canvas,
        sector.label,
        center + dir * (radius * 0.58),
        size.width * 0.055,
        textColor,
        FontWeight.w800,
        shadow,
      );
      _paintIcon(
        canvas,
        sector.icon,
        center + dir * (radius * 0.8),
        size.width * 0.11,
        textColor,
        shadow,
      );
    }

    // Bingkai luar.
    canvas.drawCircle(
      center,
      radius * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.03
        ..color = AppColors.white,
    );

    // Jarum penunjuk menuju tengah sektor aktif (setengah jari-jari).
    final activeMid = _startAngles[status.index] + _sweep / 2;
    final dir = Offset(math.cos(activeMid), math.sin(activeMid));
    final perp = Offset(-dir.dy, dir.dx);
    final base = center + dir * (radius * 0.16);
    final tip = center + dir * (radius * 0.5);
    final baseHalf = perp * (radius * 0.07);

    final needle = Path()
      ..moveTo((base - baseHalf).dx, (base - baseHalf).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo((base + baseHalf).dx, (base + baseHalf).dy)
      ..close();
    canvas.drawPath(needle, Paint()..color = _needleColor);

    // Poros kuning emas.
    canvas.drawCircle(center, radius * 0.1, Paint()..color = _hubColor);
    canvas.drawCircle(center, radius * 0.045, Paint()..color = AppColors.white);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset at,
    double fontSize,
    Color color,
    FontWeight weight,
    List<Shadow> shadows,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset at,
    double fontSize,
    Color color,
    List<Shadow> shadows,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) => oldDelegate.status != status;
}

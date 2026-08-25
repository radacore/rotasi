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
  const _Sector(this.status, this.label, this.icon);

  final BpStatus status;
  final String label;
  final IconData icon;
}

/// Opsi 1 minimal clean: roda hanya warna + icon + label caps.
/// Ambang angka dipindah ke StatusExplanation/TrendPage agar roda tidak padat.
const _sectors = <_Sector>[
  _Sector(BpStatus.hypotension, 'HIPOTENSI', Icons.water_drop_outlined),
  _Sector(BpStatus.normal, 'NORMAL', Icons.favorite),
  _Sector(BpStatus.elevated, 'WASPADA', Icons.info_outline),
  _Sector(BpStatus.stage1, 'BERISIKO', Icons.warning_amber_rounded),
  _Sector(BpStatus.crisis, 'BAHAYA', Icons.error),
  _Sector(BpStatus.emergency, 'DARURAT', Icons.emergency_outlined),
];

const _startAngles = <double>[
  -math.pi,          // Hipotensi  : kiri-bawah (pusat 210°)
  -2 * math.pi / 3,  // Normal     : atas (pusat 270°)
  -math.pi / 3,      // Waspada    : kanan-atas (pusat 330°)
  0,                 // Berisiko   : kanan (pusat 30°)
  math.pi / 3,       // Bahaya     : bawah (pusat 90°)
  2 * math.pi / 3,   // Darurat    : kiri-atas (pusat 150°)
];

/// Gap 2° antar sektor + sweep 58° (60°-gap) agar ada celah putih halus.
const _gap = 2 * math.pi / 180;
const _sweep = 2 * math.pi / 6 - _gap;

/// Donut tebal 35% radius: luar 0.92r, dalam 0.57r
const _outerFactor = 0.92;
const _innerFactor = 0.57;

const _needleColor = Color(0xFF37474F);
const _hubColor = Color(0xFFE9A800);

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.status);

  final BpStatus status;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final outerR = radius * _outerFactor;
    final innerR = radius * _innerFactor;
    final repoOuter = Rect.fromCircle(center: center, radius: outerR);
    final gapHalf = _gap / 2;

    // Donut gap-putih: 6 sektor cincin dengan celah 2°.
    for (var i = 0; i < _sectors.length; i++) {
      final sector = _sectors[i];
      final start = _startAngles[i] + gapHalf;
      final sweep = _sweep;
      final isActive = sector.status == status;

      final path = Path()
        ..arcTo(repoOuter, start, sweep, false)
        ..arcTo(Rect.fromCircle(center: center, radius: innerR), start + sweep, -sweep, false)
        ..close();
      canvas.drawPath(path, Paint()..color = sector.status.color);

      if (isActive) {
        final hi = Path()
          ..arcTo(repoOuter, start, sweep, false)
          ..arcTo(Rect.fromCircle(center: center, radius: innerR), start + sweep, -sweep, false)
          ..close();
        canvas.drawPath(
          hi,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * 0.018
            ..color = Colors.white.withValues(alpha: 0.9),
        );
      }

      // Satu kolom di 0.74r: icon atas + label caps bawah (tanpa threshold).
      final mid = start + sweep / 2;
      final dir = Offset(math.cos(mid), math.sin(mid));
      final midR = (outerR + innerR) / 2;
      final anchor = center + dir * midR;
      final isDark = sector.status == BpStatus.elevated;
      // Hipotensi pink gelap cukup untuk putih (kontras ok), Waspada kuning terang perlu gelap.
      final fg = isDark ? AppColors.textPrimary : Colors.white;
      final shadow = isDark
          ? const <Shadow>[]
          : [const Shadow(color: Colors.black38, blurRadius: 2)];

      final labelSize = size.width * 0.036;
      final iconSize = size.width * 0.075;
      const iconLabelGap = 3.0;

      // Ukur label agar kolom terpusat vertikal.
      final tpLabel = TextPainter(
        text: TextSpan(
          text: sector.label,
          style: TextStyle(color: fg, fontSize: labelSize, fontWeight: FontWeight.w800, letterSpacing: 0.6, shadows: shadow),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final colH = iconSize + iconLabelGap + tpLabel.height;
      final iconAt = anchor - const Offset(0, 0) + Offset(0, -colH / 2 + iconSize / 2);
      final labelAt = anchor + Offset(0, colH / 2 - tpLabel.height / 2);

      _paintIcon(canvas, sector.icon, iconAt, iconSize, fg, shadow);
      _paintTextAt(canvas, sector.label, labelAt, labelSize, fg, shadow);
    }

    // Bingkai luar tipis.
    canvas.drawCircle(center, outerR, Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.015 ..color = Colors.white);
    canvas.drawCircle(center, innerR, Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.012 ..color = Colors.white.withValues(alpha: 0.7));
    // Isi pusat putih bersih.
    canvas.drawCircle(center, innerR - radius * 0.012, Paint()..color = Colors.white);

    // Jarum menunjuk tengah sektor aktif (ujung 0.54r, pangkal 0.18r).
    final activeMid = _startAngles[status.index] + gapHalf + _sweep / 2;
    final dir = Offset(math.cos(activeMid), math.sin(activeMid));
    final perp = Offset(-dir.dy, dir.dx);
    final base = center + dir * (radius * 0.18);
    final tip = center + dir * (radius * 0.54);
    final baseHalf = perp * (radius * 0.06);

    final needle = Path()
      ..moveTo((base - baseHalf).dx, (base - baseHalf).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo((base + baseHalf).dx, (base + baseHalf).dy)
      ..close();
    canvas.drawPath(needle, Paint()..color = _needleColor);
    canvas.drawPath(needle, Paint()..style = PaintingStyle.stroke ..strokeWidth = 1 ..color = Colors.white.withValues(alpha: 0.9));

    // Poros kuning emas.
    canvas.drawCircle(center, radius * 0.09, Paint()..color = _hubColor);
    canvas.drawCircle(center, radius * 0.06, Paint()..color = _hubColor.withValues(alpha: 0.9));
    canvas.drawCircle(center, radius * 0.035, Paint()..color = Colors.white);
  }

  void _paintTextAt(
    Canvas canvas,
    String text,
    Offset at,
    double fontSize,
    Color color,
    List<Shadow> shadows,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: 0.6, shadows: shadows),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
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

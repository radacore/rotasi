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

/// Gap 1.5° antar sektor + sweep agar celah putih halus namun donat tampak tebal.
const _gap = 1.5 * math.pi / 180;
const _sweep = 2 * math.pi / 6 - _gap;

/// Donat tebal 55%: luar 0.95r, dalam 0.40r (tebal 55% radius, was 47%)
const _outerFactor = 0.95;
const _innerFactor = 0.40;
/// Sektor aktif menonjol keluar & ke dalam agar ekstra tebal dan pop.
const _activeOuterBump = 0.04;
const _activeInnerBump = 0.04;

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

    // Donut tebal 47%: 6 sektor cincin gap 1.8°. Aktif menonjol keluar+ke dalam + bayangan.
    for (var i = 0; i < _sectors.length; i++) {
      final sector = _sectors[i];
      final start = _startAngles[i] + gapHalf;
      final sweep = _sweep;
      final isActive = sector.status == status;
      final activeOuter = isActive ? outerR + radius * _activeOuterBump : outerR;
      final activeInner = isActive ? (innerR - radius * _activeInnerBump).clamp(radius * 0.38, innerR) : innerR;

      final outerRect = Rect.fromCircle(center: center, radius: activeOuter);
      final innerRect = Rect.fromCircle(center: center, radius: activeInner);
      final path = Path()
        ..arcTo(outerRect, start, sweep, false)
        ..arcTo(innerRect, start + sweep, -sweep, false)
        ..close();
      if (isActive) {
        canvas.drawShadow(path, Colors.black.withValues(alpha: 0.32), 10, true);
      }
      canvas.drawPath(path, Paint()..color = sector.status.color);

      // Aktif: cincin melengkung mengikuti donut (garis putih lengkung di tepi luar & dalam)
      if (isActive) {
        final outerArcR = activeOuter - radius * 0.014;
        final innerArcR = activeInner + radius * 0.014;
        // Busur luar & dalam mengikuti kelengkungan donat
        canvas.drawArc(Rect.fromCircle(center: center, radius: outerArcR), start, sweep, false,
            Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.016 ..color = Colors.white.withValues(alpha: 0.98) ..strokeCap = StrokeCap.round);
        canvas.drawArc(Rect.fromCircle(center: center, radius: innerArcR), start, sweep, false,
            Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.014 ..color = Colors.white.withValues(alpha: 0.92) ..strokeCap = StrokeCap.round);
        // Outline penuh sektor aktif
        final hi = Path()
          ..arcTo(outerRect, start, sweep, false)
          ..arcTo(innerRect, start + sweep, -sweep, false)
          ..close();
        canvas.drawPath(hi, Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.020 ..color = Colors.white.withValues(alpha: 0.95));
        canvas.drawPath(hi, Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.036 ..color = Colors.white.withValues(alpha: 0.18));
      } else {
        canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.07));
      }

      // Satu kolom di midR: icon atas + label caps bawah. Aktif lebih tebal jadi wedge jauh lebih lebar.
      final mid = start + sweep / 2;
      final dir = Offset(math.cos(mid), math.sin(mid));
      final midR = (activeOuter + activeInner) / 2;
      final anchor = center + dir * midR;
      final isDark = sector.status == BpStatus.elevated;
      final fg = isDark ? AppColors.textPrimary : Colors.white;
      final shadow = isDark
          ? const <Shadow>[]
          : [const Shadow(color: Colors.black45, blurRadius: 3)];

      final wedgeAngle = sweep;
      final wedgeWidth = 2 * midR * math.sin(wedgeAngle / 2) - radius * 0.03;
      final baseLabelSize = size.width * 0.040;
      final baseIconSize = size.width * 0.078;
      var labelSize = baseLabelSize * (isActive ? 1.28 : 1.0);
      var iconSize = baseIconSize * (isActive ? 1.20 : 1.0);
      final iconLabelGap = isActive ? 4.0 : 3.0;
      final labelWeight = isActive ? FontWeight.w900 : FontWeight.w800;
      final labelSpacing = isActive ? 0.9 : 0.55;

      TextPainter tpLabel = TextPainter(
        text: TextSpan(text: sector.label, style: TextStyle(color: fg, fontSize: labelSize, fontWeight: labelWeight, letterSpacing: labelSpacing, shadows: shadow)),
        textDirection: TextDirection.ltr,
      )..layout();
      // Pad 0.04 saja (donat tebal) + aktif midR luar jadi hampir tak perlu shrink; tetap clamp minimal 0.026
      while (tpLabel.width > wedgeWidth && labelSize > size.width * 0.026) {
        labelSize -= 0.4;
        tpLabel = TextPainter(
          text: TextSpan(text: sector.label, style: TextStyle(color: fg, fontSize: labelSize, fontWeight: labelWeight, letterSpacing: labelSpacing, shadows: shadow)),
          textDirection: TextDirection.ltr,
        )..layout();
      }
      if (isActive) {
        iconSize = (baseIconSize * 1.30).clamp(size.width * 0.076, size.width * 0.105);
      }
      final colH = iconSize + iconLabelGap + tpLabel.height;
      final iconAt = anchor + Offset(0, -colH / 2 + iconSize / 2);
      final labelAt = anchor + Offset(0, colH / 2 - tpLabel.height / 2);

      // Aktif: icon dengan halo putih tipis agar pop di atas warna
      if (isActive && !isDark) {
        _paintIcon(canvas, sector.icon, iconAt, iconSize + 2, Colors.white.withValues(alpha: 0.85), const []);
      }
      _paintIcon(canvas, sector.icon, iconAt, iconSize, fg, shadow);
      _paintTextAt(canvas, sector.label, labelAt, labelSize, fg, shadow, weight: labelWeight, spacing: labelSpacing);
    }

    // Bingkai luar tipis.
    canvas.drawCircle(center, outerR, Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.015 ..color = Colors.white);
    canvas.drawCircle(center, innerR, Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.012 ..color = Colors.white.withValues(alpha: 0.7));
    // Isi pusat putih bersih.
    canvas.drawCircle(center, innerR - radius * 0.012, Paint()..color = Colors.white);

    // Jarum menunjuk tengah sektor aktif (ujung ikut bump aktif).
    final activeMid = _startAngles[status.index] + gapHalf + _sweep / 2;
    final dir = Offset(math.cos(activeMid), math.sin(activeMid));
    final perp = Offset(-dir.dy, dir.dx);
    final base = center + dir * (radius * 0.18);
    final tip = center + dir * (radius * 0.54 + radius * _activeOuterBump * 0.5);
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
    List<Shadow> shadows, {
    FontWeight weight = FontWeight.w800,
    double spacing = 0.6,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight, letterSpacing: spacing, shadows: shadows),
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

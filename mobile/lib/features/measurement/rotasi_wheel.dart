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

/// Donat tebal 55%: luar 0.95r, dalam 0.40r (tebal 55% radius)
const _outerFactor = 0.95;
const _innerFactor = 0.40;

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

    // Donut 55% — 6 sektor sama, tanpa bump aktif/cincin lengkung (sesuai request: samakan).
    for (var i = 0; i < _sectors.length; i++) {
      final sector = _sectors[i];
      final start = _startAngles[i] + gapHalf;
      final sweep = _sweep;
      final isActive = sector.status == status;

      final outerRect = Rect.fromCircle(center: center, radius: outerR);
      final innerRect = Rect.fromCircle(center: center, radius: innerR);
      final path = Path()
        ..arcTo(outerRect, start, sweep, false)
        ..arcTo(innerRect, start + sweep, -sweep, false)
        ..close();
      canvas.drawPath(path, Paint()..color = sector.status.color);

      // Penanda status terpilih: dot + label bold, bukan bump/garis melengkung (donat tetap rata).
      final mid = start + sweep / 2;
      final dir = Offset(math.cos(mid), math.sin(mid));
      final midR = (outerR + innerR) / 2;
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
      var labelSize = baseLabelSize * (isActive ? 1.12 : 1.0);
      var iconSize = baseIconSize * (isActive ? 1.10 : 1.0);
      final iconLabelGap = isActive ? 4.0 : 3.0;
      final labelWeight = isActive ? FontWeight.w900 : FontWeight.w800;
      final labelSpacing = isActive ? 0.85 : 0.55;

      TextPainter tpLabel = TextPainter(
        text: TextSpan(text: sector.label, style: TextStyle(color: fg, fontSize: labelSize, fontWeight: labelWeight, letterSpacing: labelSpacing, shadows: shadow)),
        textDirection: TextDirection.ltr,
      )..layout();
      while (tpLabel.width > wedgeWidth && labelSize > size.width * 0.026) {
        labelSize -= 0.4;
        tpLabel = TextPainter(
          text: TextSpan(text: sector.label, style: TextStyle(color: fg, fontSize: labelSize, fontWeight: labelWeight, letterSpacing: labelSpacing, shadows: shadow)),
          textDirection: TextDirection.ltr,
        )..layout();
      }
      if (isActive) {
        iconSize = (baseIconSize * 1.18).clamp(size.width * 0.076, size.width * 0.098);
      }
      final colH = iconSize + iconLabelGap + tpLabel.height + (isActive ? 6 : 0);
      final iconAt = anchor + Offset(0, -colH / 2 + iconSize / 2);
      final labelAt = anchor + Offset(0, colH / 2 - tpLabel.height / 2 - (isActive ? 3 : 0));

      if (isActive && !isDark) {
        _paintIcon(canvas, sector.icon, iconAt, iconSize + 1.2, Colors.white.withValues(alpha: 0.85), const []);
      }
      _paintIcon(canvas, sector.icon, iconAt, iconSize, fg, shadow);
      _paintTextAt(canvas, sector.label, labelAt, labelSize, fg, shadow, weight: labelWeight, spacing: labelSpacing);
      if (isActive) {
        // Dot kecil di bawah label sebagai penanda halus (tanpa bump/cincin)
        final dotAt = labelAt + Offset(0, tpLabel.height / 2 + 5);
        canvas.drawCircle(dotAt, radius * 0.018, Paint()..color = Colors.white.withValues(alpha: 0.95));
        canvas.drawCircle(dotAt, radius * 0.018, Paint()..style = PaintingStyle.stroke ..strokeWidth = 1 ..color = sector.status.color.withValues(alpha: 0.9));
      }
    }

    // Bingkai luar tipis.
    canvas.drawCircle(center, outerR, Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.015 ..color = Colors.white);
    canvas.drawCircle(center, innerR, Paint()..style = PaintingStyle.stroke ..strokeWidth = radius * 0.012 ..color = Colors.white.withValues(alpha: 0.7));
    // Isi pusat putih bersih.
    canvas.drawCircle(center, innerR - radius * 0.012, Paint()..color = Colors.white);

    // Jarum menunjuk tengah sektor aktif.
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

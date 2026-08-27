import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Satu seri garis pada grafik tren (mis. sistolik pagi).
class TrendSeries {
  const TrendSeries({required this.name, required this.color, required this.values});

  final String name;
  final Color color;

  /// Nilai per hari; null berarti tidak ada pengukuran pada hari tsb.
  final List<double?> values;
}

/// Pita warna referensi (mis. batas kategori AHA di sumbu Y).
class ChartBand {
  const ChartBand({required this.min, required this.max, required this.color});

  final double min;
  final double max;
  final Color color;
}

/// Grafik garis tren tekanan darah (FR-05).
///
/// CustomPaint tanpa dependency eksternal: pita warna latar menunjukkan
/// ambang kategori, garis putus saat data hilang pada hari tertentu.
class BpTrendChart extends StatelessWidget {
  const BpTrendChart({
    super.key,
    required this.title,
    required this.bands,
    required this.series,
    required this.xLabels,
  });

  final String title;
  final List<ChartBand> bands;
  final List<TrendSeries> series;
  final List<String> xLabels;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: series
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 4,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  bands: bands,
                  series: series,
                  xLabels: xLabels,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.bands,
    required this.series,
    required this.xLabels,
  });

  final List<ChartBand> bands;
  final List<TrendSeries> series;
  final List<String> xLabels;

  static const _left = 38.0;
  static const _right = 10.0;
  static const _top = 12.0;
  static const _bottom = 8.0;

  late final double _minV;
  late final double _maxV;

  void _computeRange() {
    final all = <double>[];
    for (final s in series) {
      all.addAll(s.values.whereType<double>());
    }
    final bandVals = <double>[];
    for (final b in bands) {
      bandVals.add(b.min);
      bandVals.add(b.max);
    }
    final lo = all.isEmpty ? bandVals.reduce((a, b) => a < b ? a : b) : all.reduce((a, b) => a < b ? a : b);
    final hi = all.isEmpty ? bandVals.reduce((a, b) => a > b ? a : b) : all.reduce((a, b) => a > b ? a : b);
    // Bulatkan kelipatan 10 dengan ruang 10.
    _minV = (lo / 10).floorToDouble() * 10 - 10;
    _maxV = (hi / 10).ceilToDouble() * 10 + 10;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _computeRange();
    final plotW = size.width - _left - _right;
    final plotH = size.height - _top - _bottom;
    if (plotW <= 0 || plotH <= 0) return;

    final plotRect = Rect.fromLTWH(_left, _top, plotW, plotH);
    // Clip hanya untuk pita & garis agar tidak keluar plot; label angka di luar clip agar tidak terpotong.
    canvas.save();
    canvas.clipRect(plotRect);

    // Pita warna latar.
    for (final band in bands) {
      final topY = _y(band.max, plotH);
      final bottomY = _y(band.min, plotH);
      final visible = Rect.fromLTRB(
        _left,
        topY.clamp(_top, _top + plotH),
        _left + plotW,
        bottomY.clamp(_top, _top + plotH),
      );
      if (visible.bottom > visible.top) {
        canvas.drawRect(
          visible,
          Paint()..color = band.color.withValues(alpha: 0.08),
        );
      }
    }

    // Garis & label ambang batas.
    final boundaries = <double>{};
    for (final b in bands) {
      boundaries.add(b.min);
      boundaries.add(b.max);
    }
    for (final v in boundaries) {
      final y = _y(v, plotH);
      if (y < _top || y > _top + plotH) continue;
      canvas.drawLine(
        Offset(_left, y),
        Offset(_left + plotW, y),
        Paint()
          ..color = AppColors.border.withValues(alpha: 0.6)
          ..strokeWidth = 1,
      );
      // Label Y tetap di dalam clip (kiri plot), aman — gambar setelah restore juga bisa, tetap di sini agar konsisten
    }

    // Seri garis + dot.
    final n = xLabels.length;
    for (final s in series) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = s.color;

      Offset? prev;
      for (var i = 0; i < n; i++) {
        final v = s.values[i];
        if (v == null) {
          prev = null;
          continue;
        }
        final p = Offset(_x(i, plotW), _y(v, plotH));
        if (prev != null) {
          canvas.drawLine(prev, p, paint);
        }
        canvas.drawCircle(
          p,
          3.5,
          Paint()..color = s.color,
        );
        prev = p;
      }
    }

    canvas.restore();

    // Label Y (di luar clip agar tidak terpotong di tepi)
    for (final v in boundaries) {
      final y = _y(v, plotH);
      if (y < _top || y > _top + plotH) continue;
      _drawLabel(canvas, v.toInt().toString(), Offset(_left - 6, y),
          alignRight: true);
    }

    // Angka kecil di atas tiap titik — warna ikut seri (biru) + halo putih agar kontras di pita.
    for (final s in series) {
      for (var i = 0; i < n; i++) {
        final v = s.values[i];
        if (v == null) continue;
        final p = Offset(_x(i, plotW), _y(v, plotH));
        // Di atas dot 13px; jika mepet atas, pindah ke bawah dot agar tidak keluar canvas
        final above = p - const Offset(0, 13);
        final below = p + const Offset(0, 7);
        final useBelow = above.dy < _top + 2;
        _drawValueLabel(canvas, v.toInt().toString(), useBelow ? below : above, s.color, below: useBelow);
      }
    }

    // Label sumbu X dihapus — tanggal/waktu cek di tab Riwayat agar tidak tumpang tindih.
  }

  double _x(int i, double plotW) {
    final n = xLabels.length;
    if (n <= 1) return _left + plotW / 2;
    return _left + (i + 0.5) / n * plotW;
  }

  double _y(double v, double plotH) {
    return _top + (1 - (v - _minV) / (_maxV - _minV)) * plotH;
  }

  void _drawLabel(Canvas canvas, String text, Offset pos,
      {required bool alignRight}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = alignRight
        ? pos - Offset(tp.width, tp.height / 2)
        : pos - Offset(tp.width / 2, tp.height / 2);
    tp.paint(canvas, offset);
  }

  void _drawValueLabel(Canvas canvas, String text, Offset pos, Color color, {required bool below}) {
    // Halo putih + teks 9px w700 — kecil namun terbaca di pita warna, tidak mengganggu dot/garis.
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 2),
            Shadow(color: Colors.white, blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = below
        ? pos - Offset(tp.width / 2, 0)
        : pos - Offset(tp.width / 2, tp.height);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) => true;
}

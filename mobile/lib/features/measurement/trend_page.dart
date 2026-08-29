import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import 'bp_measurement.dart';
import 'bp_repository.dart';
import 'bp_status.dart';
import 'bp_trend_chart.dart';
import 'measurement_page.dart';

/// Grafik tren tekanan darah (FR-05) + pintu masuk ukur tensi (FR-03).
///
/// Tab "Tekanan Darah" menggabungkan alur pengukuran (tombol Ukur Sekarang)
/// dengan ringkasan nilai terakhir, grafik sistolik & diastolik, distribusi
/// status, dan interpretasi otomatis.
class TrendPage extends StatefulWidget {
  const TrendPage({super.key, this.repository});

  final BpRepository? repository;

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _DayRow {
  const _DayRow({
    required this.key,
    required this.label,
    this.sys,
    this.dia,
  });

  final String key;
  final String label;
  final double? sys;
  final double? dia;

  bool get hasMeasurement => sys != null || dia != null;

  double? get avgSys => sys;

  double? get avgDia => dia;

  BpStatus? get status {
    final s = sys;
    final d = dia;
    if (s == null || d == null) return null;
    return BpStatus.classify(s.round(), d.round());
  }
}

class _TrendPageState extends State<TrendPage> {
  late final BpRepository _repository;
  List<BpMeasurement> _data = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BpRepository();
    _repository.addListener(_onBpChanged);
    _load();
  }

  @override
  void dispose() {
    _repository.removeListener(_onBpChanged);
    super.dispose();
  }

  /// Muat ulang saat data pengukuran baru tersimpan (auto-update).
  void _onBpChanged() {
    _load();
  }

  /// Buka alur ukur tensi (2x pengukuran). Memakai repository yang sama agar
  /// grafik langsung ter-refresh setelah hasil disimpan.
  void _openMeasurement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeasurementPage(repository: _repository),
      ),
    );
  }

  Future<void> _load() async {
    final history = await _repository.history(limit: 90);
    if (!mounted) return;
    setState(() {
      _data = history;
      _loaded = true;
    });
  }

  List<_DayRow> _buildDays() {
    // Per-pengukuran (bukan per-hari) agar tes berkali-kali di hari sama tidak hilang.
    // Sebelumnya map byDay menimpa key 'yyyy-m-d' sehingga 5 tes hari ini -> 1 titik di tengah.
    final sorted = _data.toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return sorted
        .map((m) => _DayRow(
              key: m.uuid,
              label: DateFormat('dd/MM HH:mm').format(m.measuredAt.toLocal()),
              sys: m.avgSystolic.toDouble(),
              dia: m.avgDiastolic.toDouble(),
            ))
        .toList();
  }

  String _interpretation(List<_DayRow> days) {
    final last = days.last.status;
    final emergencyDays = days.where((d) => d.status == BpStatus.emergency).length;
    final crisisDays = days.where((d) => d.status == BpStatus.crisis).length;
    final hypoDays = days.where((d) => d.status == BpStatus.hypotension).length;

    String trendText = 'stabil';
    if (days.length >= 2) {
      final firstSys = days.first.avgSys ?? 0;
      final lastSys = days.last.avgSys ?? 0;
      final diff = lastSys - firstSys;
      trendText = diff >= 5 ? 'cenderung naik' : (diff <= -5 ? 'cenderung turun' : 'stabil');
    }

    if (emergencyDays > 0) {
      return 'Ada $emergencyDays hari kategori Darurat (≥160/110). Segera ke IGD/RS & hubungi 119.';
    }
    if (crisisDays > 0) {
      return 'Ada $crisisDays hari masuk kategori Bahaya. '
          'Segera hubungi Puskesmas/RS untuk pemeriksaan lebih lanjut.';
    }
    if (hypoDays > 0 && last == BpStatus.hypotension) {
      return 'Ada $hypoDays hari Hipotensi (<90/60). Cukupkan cairan & konsultasi bidan bila sering pingsan.';
    }
    if (trendText != 'stabil') {
      return 'Tekanan darah $trendText dalam ${days.length} hari terakhir. '
          'Sampaikan hasil ini ke bidan pada kontrol berikutnya.';
    }
    if (last != null && last != BpStatus.normal) {
      return 'Tekanan darah cenderung stabil namun masih di kategori '
          '${last.label.toLowerCase()}. Terus pantau dan kurangi garam.';
    }
    return 'Tekanan darah cenderung stabil dan normal. Teruskan pola hidup '
        'sehat dan pantau rutin.';
  }

  String _kForDesc(int descIndex, int total) => 'K${total - descIndex}';

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tekanan Darah')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_data.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tekanan Darah')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MeasureCtaCard(onPressed: _openMeasurement),
            const SizedBox(height: 16),
            const _EmptyState(),
          ],
        ),
      );
    }
    final days = _buildDays();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tekanan Darah'),
          bottom: const TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle:
                TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: 'Grafik'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: _buildGrafikBody(context, days),
              ),
            ),
            RefreshIndicator(
              onRefresh: _load,
              child: _buildRiwayatBody(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGrafikBody(BuildContext context, List<_DayRow> days) {
    final counts = {
      for (final s in BpStatus.values) s: days.where((d) => d.status == s).length,
    };

    return [
      _MeasureCtaCard(onPressed: _openMeasurement),
      const SizedBox(height: 12),
      Card(
        margin: EdgeInsets.zero,
        color: AppColors.skyLight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.menu_book_outlined,
                  color: AppColors.primaryLight, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buku KIA 2025: tensi wajib tiap ANC K1-K6 (6x). '
                  'Catatan tensi untuk ditunjukkan ke bidan (≥140/90 rujuk).',
                  style: TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _SummaryCard(days: days),
      const SizedBox(height: 12),
      _DistributionCard(counts: counts, total: days.length),
      const SizedBox(height: 16),
      Text(
        'Grafik dapat ditunjukkan ke bidan saat kontrol.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 8),
      ..._buildCharts(days),
      const SizedBox(height: 12),
      _InterpretationCard(message: _interpretation(days)),
    ];
  }

  Widget _buildRiwayatBody(BuildContext context) {
    // Riwayat per tes, desc terbaru di atas, 2 baris/card + label K1-K6 ordinal
    final sorted = _data.toList()
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final total = sorted.length;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: total,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final m = sorted[i];
        final k = _kForDesc(i, total);
        return _HistoryTile(measurement: m, kLabel: k);
      },
    );
  }

  List<Widget> _buildCharts(List<_DayRow> days) {
    final xLabels = days.map((d) => d.label).toList();
    final n = days.length;
    final sys = List<double?>.filled(n, null);
    final dia = List<double?>.filled(n, null);
    for (var i = 0; i < n; i++) {
      sys[i] = days[i].sys;
      dia[i] = days[i].dia;
    }

    return [
      BpTrendChart(
        title: 'Sistolik (atas)',
        bands: const [
          ChartBand(min: 0, max: 90, color: AppColors.hypotension),
          ChartBand(min: 90, max: 120, color: AppColors.normal),
          ChartBand(min: 120, max: 130, color: AppColors.elevated),
          ChartBand(min: 130, max: 140, color: AppColors.stage1),
          ChartBand(min: 140, max: 160, color: AppColors.crisis),
          ChartBand(min: 160, max: 999, color: AppColors.emergency),
        ],
        series: [
          TrendSeries(name: 'Catatan', color: AppColors.primaryLight, values: sys),
        ],
        xLabels: xLabels,
      ),
      const SizedBox(height: 12),
      BpTrendChart(
        title: 'Diastolik (bawah)',
        bands: const [
          ChartBand(min: 0, max: 60, color: AppColors.hypotension),
          ChartBand(min: 60, max: 80, color: AppColors.normal),
          ChartBand(min: 80, max: 90, color: AppColors.stage1),
          ChartBand(min: 90, max: 110, color: AppColors.crisis),
          ChartBand(min: 110, max: 999, color: AppColors.emergency),
        ],
        series: [
          TrendSeries(name: 'Catatan', color: AppColors.primaryLight, values: dia),
        ],
        xLabels: xLabels,
      ),
    ];
  }
}

class _MeasureCtaCard extends StatelessWidget {
  const _MeasureCtaCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.skyLight.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.favorite, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ukur Tensi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Catat tekanan darah pagi/sore — 2x pengukuran dengan jeda 1 menit '
              '(protokol AHA 2025).',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              child: const Text('Ukur Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.days});

  final List<_DayRow> days;

  @override
  Widget build(BuildContext context) {
    final last = days.last;
    final sys = last.avgSys?.round() ?? 0;
    final dia = last.avgDia?.round() ?? 0;
    final status = last.status ?? BpStatus.normal;

    final prevSys = days.length >= 2 ? (days[days.length - 2].avgSys?.round() ?? sys) : sys;
    final delta = sys - prevSys;

    final String deltaText;
    final IconData deltaIcon;
    final Color deltaColor;
    if (days.length < 2 || delta == 0) {
      deltaText = 'Sama dengan hari sebelumnya';
      deltaIcon = Icons.trending_flat;
      deltaColor = AppColors.textSecondary;
    } else if (delta > 0) {
      deltaText = 'Naik +$delta dibanding kemarin';
      deltaIcon = Icons.trending_up;
      deltaColor = AppColors.crisis;
    } else {
      deltaText = 'Turun ${delta.abs()} dibanding kemarin';
      deltaIcon = Icons.trending_down;
      deltaColor = AppColors.normal;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terakhir',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sys/$dia',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: status.color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(deltaIcon, size: 16, color: deltaColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          deltaText,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: deltaColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(status.icon, size: 18, color: status.color),
                  const SizedBox(width: 6),
                  Text(
                    status.label,
                    style: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.counts, required this.total});

  final Map<BpStatus, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Distribusi Status',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total pengukuran',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bar proporsi 6 warna
            if (total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    for (final s in BpStatus.values)
                      if ((counts[s] ?? 0) > 0)
                        Expanded(
                          flex: counts[s]!,
                          child: Container(height: 8, color: s.color),
                        ),
                  ],
                ),
              ),
            if (total > 0) const SizedBox(height: 12),
            // Grid 3×2 — lega di HP kecil, tidak sesak 6 kolom
            LayoutBuilder(
              builder: (context, c) {
                const gap = 8.0;
                final colW = (c.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final s in BpStatus.values)
                      SizedBox(
                        width: colW,
                        child: _DistTile(status: s, count: counts[s] ?? 0, total: total),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DistTile extends StatelessWidget {
  const _DistTile({required this.status, required this.count, required this.total});

  final BpStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count * 100 / total).round();
    final has = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: has ? status.color.withValues(alpha: 0.10) : AppColors.neutralLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: has ? status.color.withValues(alpha: 0.22) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: has ? status.color : AppColors.textSecondary.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: has ? status.color : AppColors.textSecondary,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($pct%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
                Text(
                  status.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.4,
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

class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.skyLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline,
                color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.measurement, required this.kLabel});

  final BpMeasurement measurement;
  final String kLabel;

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    final status = m.status;
    final date = DateFormat('dd MMM yyyy • HH:mm').format(m.measuredAt.toLocal());
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: tanggal + K + status
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          kLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 12, color: status.color),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: status.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Baris 2: nilai
            Row(
              children: [
                Text(
                  '${m.avgSystolic}/${m.avgDiastolic}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(width: 6),
                Text(
                  'mmHg',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '(${m.systolic1}/${m.diastolic1} • ${m.systolic2}/${m.diastolic2})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.show_chart,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Belum ada data pengukuran.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Lakukan pengukuran tensi untuk melihat tren.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

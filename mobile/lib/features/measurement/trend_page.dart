import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'bp_measurement.dart';
import 'bp_repository.dart';
import 'bp_status.dart';
import 'bp_trend_chart.dart';

/// Grafik tren tekanan darah (FR-05).
///
/// Menampilkan ringkasan nilai terakhir, filter rentang, grafik sistolik &
/// diastolik, distribusi status, dan interpretasi otomatis.
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
  static const int _kMaxDays = 28;

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

  Future<void> _load() async {
    final history = await _repository.history(limit: 90);
    if (!mounted) return;
    setState(() {
      _data = history;
      _loaded = true;
    });
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<_DayRow> _buildDays() {
    final byDay = <String, _DayRow>{};
    for (final m in _data) {
      final key = _dayKey(m.measuredAt);
      byDay[key] = _DayRow(
        key: key,
        label: '${key.split('-')[2]}/${key.split('-')[1]}',
        sys: m.avgSystolic.toDouble(),
        dia: m.avgDiastolic.toDouble(),
      );
    }
    final days = byDay.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (days.length > _kMaxDays) {
      return days.sublist(days.length - _kMaxDays);
    }
    return days;
  }

  String _interpretation(List<_DayRow> days) {
    final last = days.last.status;
    final crisisDays = days.where((d) => d.status == BpStatus.crisis).length;

    String trendText = 'stabil';
    if (days.length >= 2) {
      final firstSys = days.first.avgSys ?? 0;
      final lastSys = days.last.avgSys ?? 0;
      final diff = lastSys - firstSys;
      trendText = diff >= 5 ? 'cenderung naik' : (diff <= -5 ? 'cenderung turun' : 'stabil');
    }

    if (crisisDays > 0) {
      return 'Ada $crisisDays hari masuk kategori Bahaya. '
          'Segera hubungi Puskesmas/RS untuk pemeriksaan lebih lanjut.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tren Tekanan Darah')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: _buildBody(context),
                  ),
                ),
    );
  }

  List<Widget> _buildBody(BuildContext context) {
    final days = _buildDays();
    final counts = {
      for (final s in BpStatus.values) s: days.where((d) => d.status == s).length,
    };

    return [
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
          ChartBand(min: 0, max: 120, color: AppColors.normal),
          ChartBand(min: 120, max: 130, color: AppColors.elevated),
          ChartBand(min: 130, max: 140, color: AppColors.stage1),
          ChartBand(min: 140, max: 999, color: AppColors.crisis),
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
          ChartBand(min: 0, max: 80, color: AppColors.normal),
          ChartBand(min: 80, max: 90, color: AppColors.stage1),
          ChartBand(min: 90, max: 999, color: AppColors.crisis),
        ],
        series: [
          TrendSeries(name: 'Catatan', color: AppColors.primaryLight, values: dia),
        ],
        xLabels: xLabels,
      ),
    ];
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribusi Status',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final s in BpStatus.values) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${counts[s] ?? 0}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: s.color,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (s != BpStatus.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
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

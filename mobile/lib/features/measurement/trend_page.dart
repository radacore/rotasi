import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'bp_measurement.dart';
import 'bp_repository.dart';
import 'bp_status.dart';
import 'bp_trend_chart.dart';

/// Grafik tren tekanan darah harian pagi & sore (FR-05).
class TrendPage extends StatefulWidget {
  const TrendPage({super.key, this.repository});

  final BpRepository? repository;

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  late final BpRepository _repository;
  List<BpMeasurement> _data = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BpRepository();
    _load();
  }

  Future<void> _load() async {
    final history = await _repository.history(limit: 28);
    if (!mounted) return;
    setState(() {
      _data = history;
      _loaded = true;
    });
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tren Tekanan Darah')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? _EmptyState(onRefresh: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Grafik dapat ditunjukkan ke bidan saat kontrol.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ..._buildCharts(),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildCharts() {
    // Grup data per hari (urut kronologis) dan index hari.
    final days = <String, int>{};
    final dayList = <String>[];
    for (final m in _data) {
      final key = _dayKey(m.measuredAt);
      if (!days.containsKey(key)) {
        days[key] = dayList.length;
        dayList.add(key);
      }
    }
    final xLabels = dayList
        .map((k) => '${k.split('-')[2]}/${k.split('-')[1]}')
        .toList();

    final n = dayList.length;
    final sysPagi = List<double?>.filled(n, null);
    final diaPagi = List<double?>.filled(n, null);
    final sysSore = List<double?>.filled(n, null);
    final diaSore = List<double?>.filled(n, null);
    for (final m in _data) {
      final i = days[_dayKey(m.measuredAt)]!;
      if (m.sessionCode == SessionCode.pagi) {
        sysPagi[i] = m.avgSystolic.toDouble();
        diaPagi[i] = m.avgDiastolic.toDouble();
      } else {
        sysSore[i] = m.avgSystolic.toDouble();
        diaSore[i] = m.avgDiastolic.toDouble();
      }
    }

    const pagiColor = AppColors.primaryLight;
    const soreColor = AppColors.sun;

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
          TrendSeries(name: 'Pagi', color: pagiColor, values: sysPagi),
          TrendSeries(name: 'Sore', color: soreColor, values: sysSore),
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
          TrendSeries(name: 'Pagi', color: pagiColor, values: diaPagi),
          TrendSeries(name: 'Sore', color: soreColor, values: diaSore),
        ],
        xLabels: xLabels,
      ),
    ];
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

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
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRefresh, child: const Text('Muat Ulang')),
        ],
      ),
    );
  }
}

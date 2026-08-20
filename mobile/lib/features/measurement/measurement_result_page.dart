import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'bp_measurement.dart';
import 'bp_repository.dart';
import 'bp_status.dart';
import 'rotasi_wheel.dart';
import 'status_explanation.dart';

/// Ringkasan hasil sesi pengukuran (FR-04): roda warna, rata-rata, dan simpan.
class MeasurementResultPage extends StatefulWidget {
  const MeasurementResultPage({
    super.key,
    required this.repository,
    required this.measurement,
  });

  final BpRepository repository;
  final BpMeasurement measurement;

  @override
  State<MeasurementResultPage> createState() => _MeasurementResultPageState();
}

class _MeasurementResultPageState extends State<MeasurementResultPage> {
  bool _saving = false;

  String get _guidance {
    switch (widget.measurement.status) {
      case BpStatus.crisis:
        return 'Segera hubungi faskes terdekat atau layanan darurat.';
      case BpStatus.stage1:
        return 'Periksa ulang secara rutin dan sampaikan hasil ke bidan.';
      case BpStatus.elevated:
        return 'Terus pantau. Hindari garam berlebih dan kelola stres.';
      case BpStatus.normal:
        return 'Tekanan darah normal. Pertahankan pola hidup sehat.';
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.repository.saveLocal(widget.measurement);
    final synced = await widget.repository.sync(widget.measurement);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'Hasil tersimpan dan tersinkron.'
              : 'Hasil tersimpan di perangkat (offline).',
        ),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.measurement;
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Pengukuran')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: RotasiWheel(
              status: m.status,
              size: 240,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Rata-rata ${m.avgSystolic}/${m.avgDiastolic}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: m.status.color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sesi ${m.sessionCode.label} · ${m.status.label}',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          StatusExplanation(active: m.status),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            color: m.status.color.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(m.status.icon, color: m.status.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _guidance,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.looks_one),
                  title: const Text('Pengukuran 1'),
                  trailing: Text('${m.systolic1}/${m.diastolic1}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.looks_two),
                  title: const Text('Pengukuran 2'),
                  trailing: Text('${m.systolic2}/${m.diastolic2}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Simpan Hasil'),
          ),
        ],
      ),
    );
  }
}

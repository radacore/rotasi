import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../referral/referral_settings.dart';
import '../referral/setting_repository.dart';
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
    this.referralRepository,
  });

  final BpRepository repository;
  final BpMeasurement measurement;
  final SettingRepository? referralRepository;

  @override
  State<MeasurementResultPage> createState() => _MeasurementResultPageState();
}

class _MeasurementResultPageState extends State<MeasurementResultPage> {
  bool _saving = false;
  ReferralSettings? _referral;
  // Darurat = tetap 4 warna, tapi ≥160 atau ≥110 perlu aksi gawat darurat (booklet p.19)
  bool get _isEmergency =>
      widget.measurement.avgSystolic >= 160 ||
      widget.measurement.avgDiastolic >= 110;
  // Hipotensi: booklet p.9 ~ ≤90/60
  bool get _isHypotension =>
      widget.measurement.avgSystolic <= 90 ||
      widget.measurement.avgDiastolic <= 60;

  @override
  void initState() {
    super.initState();
    _loadReferral();
  }

  // Fallback statis bila kontak belum termuat (tanpa async timer agar test tidak pending)
  static const _defaultReferral = ReferralSettings(
    emergencyPhone: '119',
    puskesmasName: 'Puskesmas Barombong',
    puskesmasAddress:
        'Jl. Perjanjian Bongaya, Barombong, Kec. Tamalate, Kota Makassar',
  );

  Future<void> _loadReferral() async {
    final repo = widget.referralRepository;
    if (repo == null) {
      _referral = _defaultReferral;
      return;
    }
    try {
      final s = await repo.getLocal();
      if (!mounted) return;
      if (s != null) setState(() => _referral = s);
    } catch (_) {}
  }

  ReferralSettings get _effectiveReferral => _referral ?? _defaultReferral;

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  String get _guidance {
    if (_isHypotension) {
      return 'Hipotensi (≤90/60 mmHg). Minum cukup (±2,5–3 L/hari), jangan bangun mendadak, tidur miring kiri. Jika sering pingsan/pusing hebat, segera hubungi bidan.';
    }
    if (_isEmergency) {
      return 'DARURAT ≥160/110 mmHg — risiko kejang/stroke. Segera ke IGD/RS, hubungi darurat & keluarga siaga.';
    }
    switch (widget.measurement.status) {
      case BpStatus.crisis:
        return '≥140/90 mmHg (Buku KIA 2025). Segera ke faskes/layanan darurat.';
      case BpStatus.stage1:
        return 'Periksa ulang rutin dan sampaikan hasil ke bidan pada ANC berikutnya.';
      case BpStatus.elevated:
        return 'Kurangi garam, kelola stres, dan pantau rutin.';
      case BpStatus.normal:
        return 'Tekanan darah normal. Pertahankan pola hidup sehat & ANC 6x.';
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
              size: 260,
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
            m.status.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: m.status.color,
                ),
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
          if (_isEmergency || _isHypotension) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              color: (_isEmergency ? AppColors.crisis : AppColors.primary).withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isEmergency ? Icons.emergency_outlined : Icons.water_drop_outlined,
                          color: _isEmergency ? AppColors.crisis : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isEmergency ? 'Kontak Darurat — Segera Hubungi' : 'Hipotensi — Anjuran',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEmergency) ...[
                      Text(
                        '1. Hubungi suami & keluarga siaga\n2. Siapkan perlengkapan\n3. Segera berangkat ke IGD terdekat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _call(_effectiveReferral.emergencyPhone),
                            icon: const Icon(Icons.call, size: 16),
                            label: Text(_effectiveReferral.emergencyPhone),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.crisis,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          if (_effectiveReferral.puskesmasName.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.local_hospital_outlined, size: 16),
                              label: Text(_effectiveReferral.puskesmasName, style: const TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      if (_effectiveReferral.puskesmasAddress.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _effectiveReferral.puskesmasAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Cukupkan cairan (±2,5–3 L/hari), jangan bangun mendadak, nutrisi seimbang (B12, folat), tidur miring kiri optimalkan aliran ke plasenta. Jika sering pingsan/pusing hebat → konsultasi bidan.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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

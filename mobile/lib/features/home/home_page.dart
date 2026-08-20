import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/sync/sync_service.dart';
import '../measurement/bp_measurement.dart';
import '../measurement/bp_repository.dart';
import '../measurement/measurement_page.dart';
import '../measurement/rotasi_wheel.dart';
import '../measurement/trend_page.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';
import '../symptom_check/symptom_check_page.dart';
import '../kick_count/kick_count_page.dart';
import '../anc_check/anc_check_page.dart';
import '../education/education_page.dart';
import '../referral/referral_page.dart';
import '../midwife/midwife_page.dart';
import '../breathing/breathing_page.dart';
import '../reminder/reminder_page.dart';

/// Beranda / Status Hari Ini.
///
/// Menampilkan roda status pengukuran terakhir dan tombol "Ukur Tensi"
/// sebagai aksi dominan (DESIGN_SYSTEM.md).
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.repository,
    this.bpRepository,
    this.syncService,
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;
  final SyncService? syncService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Patient? _patient;
  BpMeasurement? _lastMeasurement;
  bool _syncing = false;
  late final PatientRepository _repository;
  late final BpRepository _bpRepository;
  late final SyncService _syncService;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PatientRepository();
    _bpRepository = widget.bpRepository ?? BpRepository();
    _syncService = widget.syncService ?? SyncService();
    _load();
  }

  Future<void> _load() async {
    final patient = await _repository.getLocal();
    final last = await _bpRepository.last();
    if (!mounted) return;
    setState(() {
      _patient = patient;
      _lastMeasurement = last;
    });
  }

  void _openMeasurement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeasurementPage(repository: _bpRepository),
      ),
    );
  }

  void _openTrend() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrendPage(repository: _bpRepository),
      ),
    );
  }

  void _openSymptoms() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SymptomCheckPage()),
    );
  }

  void _openKickCount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KickCountPage()),
    );
  }

  void _openAncCheck() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AncCheckPage()),
    );
  }

  void _openEducation() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EducationPage()),
    );
  }

  void _openReferral() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReferralPage()),
    );
  }

  void _openMidwife() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MidwifePage()),
    );
  }

  void _openBreathing() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BreathingPage()),
    );
  }

  void _openReminder() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReminderPage()),
    );
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final summary = await _syncService.syncAll();
    if (!mounted) return;
    setState(() => _syncing = false);

    final message = summary.sent == 0 && summary.failed == 0
        ? 'Semua data sudah tersinkron.'
        : summary.failed == 0
            ? 'Sinkron selesai: ${summary.sent} data terkirim.'
            : 'Sinkron selesai: ${summary.sent} terkirim, '
                '${summary.failed} gagal (dicoba lagi nanti).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROTASI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_patient != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Halo, ${_patient!.name}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          if (_patient != null)
            _RiskCard(patient: _patient!),
          _StatusCard(measurement: _lastMeasurement),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _openMeasurement,
            child: const Text('Ukur Tensi'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openBreathing,
            icon: const Icon(Icons.air),
            label: const Text('Latihan Napas'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openReminder,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Pengingat Pengukuran'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openMidwife,
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('Hubungi Bidan'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openReferral,
            icon: const Icon(Icons.emergency_outlined),
            label: const Text('Panduan Rujukan & Darurat'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openEducation,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Pustaka Edukasi'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openAncCheck,
            icon: const Icon(Icons.checklist_outlined),
            label: const Text('Ceklis 10T ANC'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openKickCount,
            icon: const Icon(Icons.child_care),
            label: const Text('Hitung Gerakan Janin'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openSymptoms,
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Cek Gejala Harian'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openTrend,
            icon: const Icon(Icons.show_chart),
            label: const Text('Lihat Tren Tekanan Darah'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Data Ibu'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _syncing ? null : _sync,
                  icon: _syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(_syncing ? 'Menyinkron…' : 'Sinkron'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.patient});

  final Patient patient;

  (Color, IconData) _visual(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return (AppColors.crisis, Icons.error);
      case RiskLevel.medium:
        return (AppColors.stage1, Icons.warning_amber_rounded);
      case RiskLevel.low:
        return (AppColors.normal, Icons.check_circle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _visual(patient.riskLevel);
    final factors = patient.riskFactors();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 6),
                      Text(
                        'Risiko ${patient.riskLevel.label}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.medical_services_outlined,
                    color: AppColors.primaryLight),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Skrining Risiko Otomatis',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              patient.recommendation,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (factors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: factors
                    .map(
                      (f) => Chip(
                        label: Text(f, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.measurement});

  final BpMeasurement? measurement;

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (m == null) ...[
              const Icon(Icons.favorite, color: AppColors.crisis, size: 48),
              const SizedBox(height: 8),
              Text(
                'Belum ada pengukuran',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lakukan pengukuran pertama untuk melihat status hari ini.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ] else ...[
              RotasiWheel(status: m.status, size: 180),
              const SizedBox(height: 12),
              Text(
                'Terakhir: ${m.avgSystolic}/${m.avgDiastolic} · ${m.sessionCode.label}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

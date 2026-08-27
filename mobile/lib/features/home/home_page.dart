import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../biodata/biodata_page.dart';
import '../measurement/bp_measurement.dart';
import '../measurement/bp_repository.dart';
import '../measurement/measurement_page.dart';
import '../measurement/rotasi_wheel.dart';
import '../measurement/status_explanation.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';
import 'more_page.dart';

/// Beranda / Status Hari Ini.
///
/// Menampilkan roda status pengukuran terakhir dan tombol "Ukur Tensi"
/// sebagai aksi dominan (DESIGN_SYSTEM.md).
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.repository,
    this.bpRepository,
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Patient? _patient;
  BpMeasurement? _lastMeasurement;
  late final PatientRepository _repository;
  late final BpRepository _bpRepository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PatientRepository();
    _bpRepository = widget.bpRepository ?? BpRepository();
    _bpRepository.addListener(_onBpChanged);
    _load();
  }

  @override
  void dispose() {
    _bpRepository.removeListener(_onBpChanged);
    super.dispose();
  }

  /// Muat ulang saat data pengukuran baru tersimpan (auto-update).
  void _onBpChanged() {
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

  Future<void> _openMore() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MorePage(
          repository: _repository,
          bpRepository: _bpRepository,
        ),
      ),
    );
    // Muat ulang profil setelah kembali, agar sapaan ikut terbarui bila diedit.
    if (!mounted) return;
    _load();
  }

  Future<void> _openBiodata() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BiodataPage(repository: _repository)),
    );
    if (!mounted) return;
    _load();
  }

  bool get _needsBiodata {
    final p = _patient;
    if (p == null) return false;
    // Minimal KIA dianggap belum lengkap bila NIK / darah / gravida / BMI pra-hamil kosong
    return (p.nik == null || p.nik!.isEmpty) ||
        p.bloodType == null ||
        p.gravida == null ||
        p.prePregnancyWeight == null ||
        p.faskesTk1 == null ||
        p.address == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Lainnya',
            onPressed: _openMore,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_patient != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${_patient!.name},',
                    style: const TextStyle(
                      fontFamily: 'DancingScript',
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                      height: 1.1,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'semoga sehat selalu',
                    style: const TextStyle(
                      fontFamily: 'DancingScript',
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      height: 1.1,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          if (_patient != null && _needsBiodata) _IncompleteBiodataCard(onTap: _openBiodata),
          if (_patient != null && _needsBiodata) const SizedBox(height: 12),
          _StatusCard(measurement: _lastMeasurement),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _openMeasurement,
            child: const Text('Ukur Tensi'),
          ),
        ],
      ),
    );
  }
}

class _IncompleteBiodataCard extends StatelessWidget {
  const _IncompleteBiodataCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.skyLight.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Lengkapi Biodata KIA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('NIK, Faskes, golongan darah & BMI pra-hamil diperlukan untuk skrining risiko.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.3)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Lengkapi Sekarang', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
              ]),
            ),
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: m == null
            ? Column(
                children: [
                  const Icon(Icons.favorite, color: AppColors.primaryLight, size: 48),
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
                ],
              )
            : Column(
                children: [
                  RotasiWheel(status: m.status, size: 250),
                  const SizedBox(height: 12),
                  Text(
                    'Terakhir: ${m.avgSystolic}/${m.avgDiastolic}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  StatusExplanation(active: m.status),
                ],
              ),
      ),
    );
  }
}

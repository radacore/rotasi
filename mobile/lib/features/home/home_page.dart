import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.measurement});

  final BpMeasurement? measurement;

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    return Card(
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

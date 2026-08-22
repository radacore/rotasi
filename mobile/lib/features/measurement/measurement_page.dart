import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'bp_measurement.dart';
import 'bp_repository.dart';
import 'bp_status.dart';
import 'measurement_result_page.dart';

/// Sesi pengukuran tekanan darah (FR-03).
///
/// Protokol AHA 2025: satu sesi pagi/sore berisi 2x pengukuran dengan
/// istirahat 1 menit di antaranya, dirata-ratakan otomatis.
class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key, this.repository, this.patientUuid});

  final BpRepository? repository;
  final String? patientUuid;

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  static const _restSeconds = 60;

  late final BpRepository _repository;
  final _s1Controller = TextEditingController();
  final _d1Controller = TextEditingController();
  final _s2Controller = TextEditingController();
  final _d2Controller = TextEditingController();

  final _session = SessionCode.pagi;
  bool _r1Saved = false;
  bool _countdownActive = false;
  bool _r2Unlocked = false;
  int _remaining = _restSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BpRepository();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _s1Controller.dispose();
    _d1Controller.dispose();
    _s2Controller.dispose();
    _d2Controller.dispose();
    super.dispose();
  }

  void _saveReading1() {
    if (!_validate(_s1Controller, _d1Controller)) return;
    setState(() {
      _r1Saved = true;
      _countdownActive = true;
      _remaining = _restSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _countdownActive = false;
          _r2Unlocked = true;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _saveReading2() async {
    if (!_validate(_s2Controller, _d2Controller)) return;
    final patient = await _repository.localPatient();
    final measurement = BpMeasurement.record(
      patientUuid: widget.patientUuid ?? patient?.uuid ?? '',
      measuredAt: DateTime.now(),
      sessionCode: _session,
      systolic1: int.parse(_s1Controller.text),
      diastolic1: int.parse(_d1Controller.text),
      systolic2: int.parse(_s2Controller.text),
      diastolic2: int.parse(_d2Controller.text),
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeasurementResultPage(
          repository: _repository,
          measurement: measurement,
        ),
      ),
    );
  }

  bool _validate(TextEditingController sys, TextEditingController dia) {
    final s = int.tryParse(sys.text);
    final d = int.tryParse(dia.text);
    final valid = s != null &&
        d != null &&
        s >= 50 &&
        s <= 180 &&
        d >= 30 &&
        d <= 120;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Periksa nilai tekanan darah (SYS 50–180, DIA 30–120).'),
        ),
      );
    }
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ukur Tensi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.skyLight,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.menu_book_outlined,
                      color: AppColors.primaryLight, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '10T No.2 Buku KIA 2025 — Wajib tiap ANC (6x)',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tensi diukur wajib pada tiap kunjungan ANC K1-K6 (6x). '
                          'Hasil ≥140/90 mmHg segera rujuk ke faskes (Buku KIA 2025).',
                          style: TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ReadingCard(
            title: 'Pengukuran 1',
            subtitle: 'Duduk rileks 5 menit sebelum mengukur.',
            sysController: _s1Controller,
            diaController: _d1Controller,
            enabled: !_r1Saved,
            buttonLabel: 'Simpan Pengukuran 1',
            onPressed: _saveReading1,
          ),
          if (_countdownActive) ...[
            const SizedBox(height: 12),
            _RestCard(remaining: _remaining),
          ],
          if (_r2Unlocked) ...[
            const SizedBox(height: 12),
            _ReadingCard(
              title: 'Pengukuran 2',
              subtitle: 'Tunggu 1 menit sejak pengukuran 1.',
              sysController: _s2Controller,
              diaController: _d2Controller,
              enabled: true,
              buttonLabel: 'Simpan Pengukuran 2',
              onPressed: _saveReading2,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.title,
    required this.subtitle,
    required this.sysController,
    required this.diaController,
    required this.enabled,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final TextEditingController sysController;
  final TextEditingController diaController;
  final bool enabled;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sysController,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sistolik (atas)',
                      prefixIcon: Icon(Icons.favorite_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: diaController,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diastolik (bawah)',
                      prefixIcon: Icon(Icons.favorite_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: enabled ? onPressed : null,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.skyLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.timer, color: AppColors.primaryLight, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Istirahat sebentar. Ukur pengukuran kedua dalam $remaining detik.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

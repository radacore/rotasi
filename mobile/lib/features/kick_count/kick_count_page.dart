import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'kick_count.dart';
import 'kick_repository.dart';

enum _Phase { idle, counting, finished }

/// Hitung gerakan janin (FR-07).
///
/// Pengamatan 30 menit; ketukan dihitung via tombol besar. Status aktif
/// bila minimal 3 gerakan. Timer berjalan penuh secara lokal.
class KickCountPage extends StatefulWidget {
  const KickCountPage({super.key, this.repository, this.patientUuid});

  final KickRepository? repository;
  final String? patientUuid;

  @override
  State<KickCountPage> createState() => _KickCountPageState();
}

class _KickCountPageState extends State<KickCountPage> {
  static const _totalSeconds = KickCount.observationMinutes * 60;

  late final KickRepository _repository;
  _Phase _phase = _Phase.idle;
  int _remaining = _totalSeconds;
  int _kicks = 0;
  KickCount? _result;
  Timer? _timer;
  String? _patientUuid;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? KickRepository();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    final patient = await _repository.localPatient();
    if (!mounted) return;
    setState(() => _patientUuid = patient?.uuid);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _start() {
    setState(() {
      _phase = _Phase.counting;
      _remaining = _totalSeconds;
      _kicks = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        _finish();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _tapKick() {
    setState(() => _kicks++);
  }

  void _finish() {
    _timer?.cancel();
    final result = KickCount.start(
      patientUuid: _patientUuid ?? '',
      startedAt: DateTime.now().subtract(
        Duration(seconds: _totalSeconds - _remaining),
      ),
    );
    // Rekonstruksi dengan jumlah ketukan agar konsisten.
    final completed = KickCount.fromMap({
      ...result.toMap(),
      'kick_count': _kicks,
      'ended_at': DateTime.now().toIso8601String(),
    }).complete();
    setState(() {
      _phase = _Phase.finished;
      _result = completed;
    });
  }

  Future<void> _save() async {
    final result = _result!;
    await _repository.saveLocal(result);
    final synced = await _repository.sync(result);
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
    setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hitung Gerakan Janin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(),
          const SizedBox(height: 12),
          switch (_phase) {
            _Phase.idle => _IdleView(onStart: _start),
            _Phase.counting => _CountingView(
                countdown: _countdown,
                kicks: _kicks,
                onKick: _tapKick,
                onFinish: _finish,
              ),
            _Phase.finished => _ResultView(
                result: _result!,
                onSave: _save,
                onRestart: () => setState(() => _phase = _Phase.idle),
              ),
          },
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.skyLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.info_outline, color: AppColors.primaryLight),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cara: hitung gerakan bayi selama 30 menit. '
                'Minimal 3 gerakan berarti bayi aktif.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onStart,
          child: const Text('Mulai Hitung'),
        ),
      ],
    );
  }
}

class _CountingView extends StatelessWidget {
  const _CountingView({
    required this.countdown,
    required this.kicks,
    required this.onKick,
    required this.onFinish,
  });

  final String countdown;
  final int kicks;
  final VoidCallback onKick;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Sisa waktu',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  countdown,
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                Text(
                  'Gerakan: $kicks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: FilledButton(
            onPressed: onKick,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Ketuk saat bayi bergerak'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onFinish,
          child: const Text('Selesai Pengamatan'),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.onSave,
    required this.onRestart,
  });

  final KickCount result;
  final VoidCallback onSave;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final color = result.isActive ? AppColors.normal : AppColors.stage1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  result.isActive ? Icons.check_circle : Icons.info,
                  size: 56,
                  color: color,
                ),
                const SizedBox(height: 8),
                Text(
                  result.isActive ? 'Bayi Aktif' : 'Bayi Kurang Aktif',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.kickCount} gerakan dalam 30 menit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!result.isActive) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Coba lagi nanti. Bila tetap kurang aktif, '
                    'hubungi bidan atau faskes.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onSave, child: const Text('Simpan Hasil')),
        const SizedBox(height: 8),
        TextButton(onPressed: onRestart, child: const Text('Hitung Ulang')),
      ],
    );
  }
}

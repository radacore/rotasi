import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'breathing_phase.dart';

/// Latihan Napas Lambat 4-2-6 (FR-12), berjalan penuh offline.
///
/// Panduan: tarik 4 detik, tahan 2 detik, buang 6 detik. Durasi latihan
/// bisa dipilih (default 15 menit) dengan hitungan mundur dan lingkaran
/// visual yang mengembang/mengempis.
class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key, this.duration = const Duration(minutes: 15)});

  /// Durasi latihan (default 15 menit).
  final Duration duration;

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

enum _BreathingState { setup, running, done }

class _BreathingPageState extends State<BreathingPage> {
  static const _presets = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
  ];

  _BreathingState _state = _BreathingState.setup;
  Duration _total = const Duration(minutes: 15);
  late Duration _remaining;
  Timer? _timer;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _total = widget.duration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectDuration(Duration d) {
    setState(() => _total = d);
  }

  void _start() {
    setState(() {
      _state = _BreathingState.running;
      _remaining = _total;
      _elapsed = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() => _state = _BreathingState.done);
      } else {
        setState(() {
          _remaining -= const Duration(seconds: 1);
          _elapsed++;
        });
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _state = _BreathingState.setup);
  }

  void _restart() {
    setState(() => _state = _BreathingState.setup);
  }

  String get _remainingText {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Latihan Napas')),
      body: switch (_state) {
        _BreathingState.setup => _SetupView(
            selected: _total,
            onSelect: _selectDuration,
            onStart: _start,
          ),
        _BreathingState.running => _RunningView(
            remainingText: _remainingText,
            phase: BreathingPhase.phaseAt(_elapsed),
            phaseFraction: _phaseFraction(),
            phaseRemaining: _phaseRemaining(),
            onStop: _stop,
          ),
        _BreathingState.done => _DoneView(onRestart: _restart),
      },
    );
  }

  double _phaseFraction() {
    final phase = BreathingPhase.phaseAt(_elapsed);
    return BreathingPhase.inPhase(_elapsed) / phase.seconds;
  }

  int _phaseRemaining() {
    final phase = BreathingPhase.phaseAt(_elapsed);
    return phase.seconds - BreathingPhase.inPhase(_elapsed);
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.selected,
    required this.onSelect,
    required this.onStart,
  });

  final Duration selected;
  final ValueChanged<Duration> onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: AppColors.skyLight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.air, color: AppColors.primaryLight),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ikuti irama: tarik napas 4 detik, tahan 2 detik, '
                    'buang napas 6 detik. Ulangi selama durasi latihan.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Durasi latihan',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        RadioGroup<Duration>(
          groupValue: selected,
          onChanged: (v) {
            if (v != null) onSelect(v);
          },
          child: Column(
            children: [
              for (final d in _BreathingPageState._presets)
                RadioListTile<Duration>(
                  value: d,
                  title: Text('${d.inMinutes} menit'),
                  dense: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: Text('Mulai Latihan (${selected.inMinutes} menit)'),
        ),
      ],
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({
    required this.remainingText,
    required this.phase,
    required this.phaseFraction,
    required this.phaseRemaining,
    required this.onStop,
  });

  final String remainingText;
  final BreathingPhase phase;
  final double phaseFraction;
  final int phaseRemaining;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final color = switch (phase) {
      BreathingPhase.inhale => AppColors.primaryLight,
      BreathingPhase.hold => AppColors.sun,
      BreathingPhase.exhale => AppColors.accent,
    };
    // Lingkaran membesar saat tarik, penuh saat tahan, mengempis saat buang.
    final growth = switch (phase) {
      BreathingPhase.inhale => phaseFraction,
      BreathingPhase.hold => 1.0,
      BreathingPhase.exhale => 1 - phaseFraction,
    };
    const base = 140.0;
    const maxGrowth = 90.0;

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          remainingText,
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  width: base + growth * maxGrowth,
                  height: base + growth * maxGrowth,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      phase.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$phaseRemaining',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  phase.tip,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Selesai'),
          ),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 72, color: AppColors.normal),
            const SizedBox(height: 12),
            Text(
              'Latihan selesai',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Semoga Anda lebih rileks. Ulangi bila perlu.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay),
              label: const Text('Latihan Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

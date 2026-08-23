import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import 'kick_count.dart';
import 'kick_repository.dart';

enum _Phase { idle, counting, finished }

/// Hitung gerakan janin (FR-07) + tab Riwayat offline-first.
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
  List<KickCount> _history = const [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? KickRepository();
    _loadPatient();
    _loadHistory();
  }

  Future<void> _loadPatient() async {
    final patient = await _repository.localPatient();
    if (!mounted) return;
    setState(() => _patientUuid = patient?.uuid);
  }

  Future<void> _loadHistory() async {
    final h = await _repository.history(limit: 90);
    if (!mounted) return;
    setState(() {
      _history = h;
      _loadingHistory = false;
    });
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
    await _loadHistory();
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hitung Gerakan Janin'),
          bottom: const TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle:
                TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: 'Hitung'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
            ),
            RefreshIndicator(
              onRefresh: _loadHistory,
              child: _buildHistory(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 48, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text('Belum ada riwayat gerakan'),
              SizedBox(height: 4),
              Text(
                'Hasil hitung 30 menit akan tampil di sini (offline).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final k = _history[i];
        return _KickHistoryTile(kick: k);
      },
    );
  }
}

class _KickHistoryTile extends StatelessWidget {
  const _KickHistoryTile({required this.kick});

  final KickCount kick;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy • HH:mm').format(kick.startedAt.toLocal());
    final color = kick.isActive ? AppColors.normal : AppColors.stage1;
    final label = kick.isActive ? 'Aktif' : 'Kurang aktif';
    final icon = kick.isActive ? Icons.check_circle : Icons.info;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${kick.kickCount} gerakan • 30 menit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (kick.synced)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Tersinkron',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                ),
              ),
          ],
        ),
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

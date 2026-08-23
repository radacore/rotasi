import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import 'symptom_check.dart';
import 'symptom_repository.dart';

/// Ceklis gejala bahaya harian (FR-06) + tab Riwayat offline-first.
class SymptomCheckPage extends StatefulWidget {
  const SymptomCheckPage({super.key, this.repository});

  final SymptomRepository? repository;

  @override
  State<SymptomCheckPage> createState() => _SymptomCheckPageState();
}

class _SymptomCheckPageState extends State<SymptomCheckPage>
    with SingleTickerProviderStateMixin {
  late final SymptomRepository _repository;
  late final TabController _tabController;
  final Map<DangerSymptom, bool> _values = {
    for (final s in DangerSymptom.values) s: false,
  };
  String? _patientUuid;
  bool _loading = true;
  bool _saving = false;
  List<SymptomCheck> _history = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SymptomRepository();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final patient = await _repository.localPatient();
    final today = await _repository.getByDate(DateTime.now());
    final history = await _repository.history(limit: 90);
    if (!mounted) return;
    setState(() {
      _patientUuid = patient?.uuid;
      if (today != null) {
        for (final s in DangerSymptom.values) {
          _values[s] = today.valueOf(s);
        }
      }
      _history = history;
      _loading = false;
    });
  }

  void _reset() {
    setState(() {
      for (final s in DangerSymptom.values) {
        _values[s] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ceklis direset.')),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final check = SymptomCheck.daily(
      patientUuid: _patientUuid ?? '',
      checkedAt: DateTime.now(),
      headache: _values[DangerSymptom.headache]!,
      blurredVision: _values[DangerSymptom.blurredVision]!,
      epigastricPain: _values[DangerSymptom.epigastricPain]!,
      shortnessOfBreath: _values[DangerSymptom.shortnessOfBreath]!,
    );
    await _repository.saveForDate(check);
    final synced = await _repository.sync(check);
    final history = await _repository.history(limit: 90);
    if (!mounted) return;

    setState(() {
      _history = history;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'Ceklis tersimpan dan tersinkron.'
              : 'Ceklis tersimpan di perangkat (offline).',
        ),
      ),
    );
    // Tetap di page, pindah ke Riwayat agar langsung terlihat (tidak reset isian)
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cek Gejala Harian')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Gejala Harian'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Ceklis'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: _buildForm(context),
            ),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: _buildHistory(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildForm(BuildContext context) {
    return [
      Text(
        'Centang bila Anda merasakan gejala berikut hari ini.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
      ...DangerSymptom.values.map(_buildTile),
      if (_values.values.contains(true)) ...[
        const SizedBox(height: 12),
        _WarningCard(),
      ],
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? 'Menyimpan…' : 'Simpan Ceklis'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _reset,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildHistory(BuildContext context) {
    if (_history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 48, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text('Belum ada riwayat gejala'),
              SizedBox(height: 4),
              Text(
                'Ceklis harian akan tampil di sini (offline).',
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
        final c = _history[i];
        return _SymptomHistoryTile(check: c);
      },
    );
  }

  Widget _buildTile(DangerSymptom symptom) {
    final checked = _values[symptom]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => setState(() => _values[symptom] = !checked),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: checked
                ? symptomCheckedColor(symptom)
                : AppColors.neutralLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            symptom.icon,
            color: checked ? AppColors.white : AppColors.textSecondary,
          ),
        ),
        title: Text(
          symptom.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Icon(
          checked ? Icons.check_circle : Icons.cancel_outlined,
          color: checked ? symptomCheckedColor(symptom) : AppColors.border,
          size: 28,
        ),
      ),
    );
  }

  Color symptomCheckedColor(DangerSymptom symptom) {
    if (symptom == DangerSymptom.headache ||
        symptom == DangerSymptom.blurredVision) {
      return AppColors.stage1;
    }
    return AppColors.crisis;
  }
}

class _SymptomHistoryTile extends StatelessWidget {
  const _SymptomHistoryTile({required this.check});

  final SymptomCheck check;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy • HH:mm').format(check.checkedAt.toLocal());
    final any = check.hasAny;
    final ctxColor = any ? AppColors.crisis : AppColors.normal;
    final ctxLabel = any ? 'Ada gejala' : 'Tidak ada gejala';
    final ctxIcon = any ? Icons.warning_amber_rounded : Icons.check_circle_outline;
    final symptoms = DangerSymptom.values.where(check.valueOf).map((e) => e.label).join(', ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: tanggal + status
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
                    color: ctxColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(ctxIcon, size: 12, color: ctxColor),
                      const SizedBox(width: 4),
                      Text(
                        ctxLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ctxColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Baris 2: gejala
            Text(
              any ? symptoms : 'Tidak ada gejala bahaya',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                    color: any ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
            ),
            if (check.synced)
              Padding(
                padding: const EdgeInsets.only(top: 4),
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

class _WarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.crisis.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.crisis),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ada gejala yang Anda rasakan. Segera hubungi bidan atau '
                'faskes terdekat dan jangan menunggu.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

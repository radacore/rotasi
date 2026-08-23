import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import 'anc_check.dart';
import 'anc_repository.dart';

/// Ceklis 10T ANC (FR-08) + tab Riwayat offline-first (view-only).
class AncCheckPage extends StatefulWidget {
  const AncCheckPage({super.key, this.repository, this.patientUuid});

  final AncRepository? repository;
  final String? patientUuid;

  @override
  State<AncCheckPage> createState() => _AncCheckPageState();
}

class _AncCheckPageState extends State<AncCheckPage>
    with SingleTickerProviderStateMixin {
  late final AncRepository _repository;
  late final TabController _tabController;
  final Set<AncItem> _selected = {};
  DateTime _visitedAt = DateTime.now();
  String? _patientUuid;
  bool _loaded = false;
  List<AncCheck> _history = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AncRepository();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final patient = await _repository.localPatient();
    final existing = await _repository.getByVisitedAt(_visitedAt);
    if (!mounted) return;
    setState(() {
      _patientUuid = widget.patientUuid ?? patient?.uuid;
      if (existing != null) {
        _selected
          ..clear()
          ..addAll(
            existing.items.map(AncItem.fromCode),
          );
      }
      _loaded = true;
    });
  }

  Future<void> _loadHistory() async {
    final h = await _repository.history(limit: 90);
    if (!mounted) return;
    setState(() => _history = h);
  }

  void _toggle(AncItem item) {
    setState(() {
      if (!_selected.remove(item)) _selected.add(item);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _visitedAt = picked;
      _selected.clear();
    });
    // reload existing for new date
    final existing = await _repository.getByVisitedAt(picked);
    if (!mounted) return;
    setState(() {
      _selected.clear();
      if (existing != null) {
        _selected.addAll(existing.items.map(AncItem.fromCode));
      }
    });
  }

  void _reset() {
    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ceklis direset.')),
    );
  }

  Future<void> _save() async {
    if (_patientUuid == null) return;
    final check = AncCheck.forDate(
      patientUuid: _patientUuid!,
      visitedAt: _visitedAt,
    );
    final saved = AncCheck(
      uuid: check.uuid,
      patientUuid: check.patientUuid,
      visitedAt: check.visitedAt,
      items: _selected.map((e) => e.code).toList(),
    );
    await _repository.saveLocal(saved);
    final synced = await _repository.sync(saved);
    await _loadHistory();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'Ceklis tersimpan dan tersinkron.'
              : 'Ceklis tersimpan di perangkat (offline).',
        ),
      ),
    );
    // Tetap di page, tidak reset isian, pindah ke Riwayat
    _tabController.animateTo(1);
  }

  String _kForHistory(int index, int total) => 'K${total - index}';

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ceklis 10T ANC')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceklis 10T ANC'),
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
              onRefresh: () async {
                await _load();
                await _loadHistory();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: _buildForm(context),
              ),
            ),
            RefreshIndicator(
              onRefresh: _loadHistory,
              child: _buildHistory(context),
            ),
          ],
        ),
    );
  }

  List<Widget> _buildForm(BuildContext context) {
    final progress = _selected.length;
    return [
      _DateRow(visitedAt: _visitedAt, onPick: _pickDate),
      const SizedBox(height: 12),
      LinearProgressIndicator(
        value: progress / AncItem.values.length,
        backgroundColor: AppColors.skyLight,
        color: AppColors.primary,
      ),
      const SizedBox(height: 8),
      Text(
        '$progress dari ${AncItem.values.length} pemeriksaan ditandai',
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 8),
      Card(
        margin: EdgeInsets.zero,
        color: AppColors.skyLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.menu_book_outlined, color: AppColors.primaryLight),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buku KIA 2025 — Wajib 6x ANC (hal 96)',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'K1: <12 minggu, K2: 20, K3: 26, K4: 30, K5: 34, K6: 36 minggu–lahir. '
                      'Setiap kunjungan wajib 10T termasuk T2 Ukur Tekanan Darah. '
                      'Centang sesuai yang sudah dilakukan di faskes.',
                      style: TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      for (final item in AncItem.values) ...[
        _AncTile(
          item: item,
          checked: _selected.contains(item),
          onTap: () => _toggle(item),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _patientUuid == null ? null : _save,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Simpan Ceklis'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _reset,
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
              Text('Belum ada riwayat ANC'),
              SizedBox(height: 4),
              Text(
                'Ceklis 10T yang tersimpan akan tampil di sini (offline).',
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
        final k = _kForHistory(i, _history.length);
        return _AncHistoryTile(check: c, kLabel: k);
      },
    );
  }
}

class _AncHistoryTile extends StatelessWidget {
  const _AncHistoryTile({required this.check, required this.kLabel});

  final AncCheck check;
  final String kLabel;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(check.visitedAt.toLocal());
    final progress = check.checkedCount;
    final total = check.totalItems;
    final color = progress == total ? AppColors.normal : AppColors.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: K + tanggal + status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    kLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                  child: Text(
                    '$progress/$total',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Baris 2: ringkasan item
            LinearProgressIndicator(
              value: total == 0 ? 0 : progress / total,
              backgroundColor: AppColors.skyLight,
              color: color,
              minHeight: 4,
            ),
            const SizedBox(height: 6),
            Text(
              check.items.isEmpty
                  ? 'Belum ada pemeriksaan ditandai'
                  : check.items.map((e) => e.toUpperCase()).join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.visitedAt, required this.onPick});

  final DateTime visitedAt;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.event_outlined, color: AppColors.primary),
        title: const Text('Tanggal kunjungan'),
        subtitle: Text(
          '${visitedAt.day.toString().padLeft(2, '0')}-'
          '${visitedAt.month.toString().padLeft(2, '0')}-'
          '${visitedAt.year}',
        ),
        trailing: TextButton(onPressed: onPick, child: const Text('Ubah')),
        onTap: onPick,
      ),
    );
  }
}

class _AncTile extends StatelessWidget {
  const _AncTile({
    required this.item,
    required this.checked,
    required this.onTap,
  });

  final AncItem item;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: checked ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: checked ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.code.toUpperCase()} · ${item.title}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      item.subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                checked ? Icons.check_circle : Icons.radio_button_unchecked,
                color: checked ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

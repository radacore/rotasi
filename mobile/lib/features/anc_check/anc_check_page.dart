import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'anc_check.dart';
import 'anc_repository.dart';

/// Ceklis 10T ANC (FR-08) — satu halaman per tanggal kunjungan.
class AncCheckPage extends StatefulWidget {
  const AncCheckPage({super.key, this.repository, this.patientUuid});

  final AncRepository? repository;
  final String? patientUuid;

  @override
  State<AncCheckPage> createState() => _AncCheckPageState();
}

class _AncCheckPageState extends State<AncCheckPage> {
  late final AncRepository _repository;
  final Set<AncItem> _selected = {};
  DateTime _visitedAt = DateTime.now();
  String? _patientUuid;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AncRepository();
    _load();
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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _selected.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Ceklis 10T ANC')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                        Icon(Icons.info_outline,
                            color: AppColors.primaryLight),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tandai pemeriksaan yang sudah dilakukan '
                            'saat kontrol ke faskes. Bisa untuk riwayat '
                            'kunjungan sebelumnya.',
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
                ElevatedButton.icon(
                  onPressed: _patientUuid == null ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Ceklis'),
                ),
              ],
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

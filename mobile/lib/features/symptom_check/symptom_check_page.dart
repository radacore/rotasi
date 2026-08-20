import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'symptom_check.dart';
import 'symptom_repository.dart';

/// Ceklis gejala bahaya harian (FR-06).
///
/// Empat gejala dengan tombol ya/tidak besar agar mudah dipakai
/// pengguna dengan literasi rendah. Ada gejala -> imbauan faskes.
class SymptomCheckPage extends StatefulWidget {
  const SymptomCheckPage({super.key, this.repository});

  final SymptomRepository? repository;

  @override
  State<SymptomCheckPage> createState() => _SymptomCheckPageState();
}

class _SymptomCheckPageState extends State<SymptomCheckPage> {
  late final SymptomRepository _repository;
  final Map<DangerSymptom, bool> _values = {
    for (final s in DangerSymptom.values) s: false,
  };
  String? _patientUuid;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SymptomRepository();
    _load();
  }

  Future<void> _load() async {
    final patient = await _repository.localPatient();
    final today = await _repository.getByDate(DateTime.now());
    if (!mounted) return;
    setState(() {
      _patientUuid = patient?.uuid;
      if (today != null) {
        for (final s in DangerSymptom.values) {
          _values[s] = today.valueOf(s);
        }
      }
      _loading = false;
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Gejala Harian')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Simpan Ceklis'),
                ),
              ],
            ),
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

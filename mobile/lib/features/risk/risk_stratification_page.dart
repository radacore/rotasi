import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';

/// Stratifikasi Risiko Preeklamsia — Phase 1 (offline, tanpa VPS).
///
/// Skrining anamnesis 4 faktor: prior preeklamsia, hipertensi kronis,
/// riwayat keluarga, primigravida. Hitung `Patient.riskFromAnamnesis`
/// + tampilkan kategori + dampak + tabel tindakan medis.
class RiskStratificationPage extends StatefulWidget {
  const RiskStratificationPage({super.key, this.repository});

  final PatientRepository? repository;

  @override
  State<RiskStratificationPage> createState() => _RiskStratificationPageState();
}

class _RiskStratificationPageState extends State<RiskStratificationPage> {
  late final PatientRepository _repo;
  Patient? _patient;
  bool _loading = true;

  // Checklist lokal — untuk preview tanpa simpan (Phase 1: belum sync detail)
  bool _hasPrior = false;
  bool _hasChronic = false;
  bool _hasFamily = false;
  // primigravida diambil dari biodata bila ada, else toggle manual

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? PatientRepository();
    _load();
  }

  Future<void> _load() async {
    final p = await _repo.getLocal();
    if (!mounted) return;
    setState(() {
      _patient = p;
      _loading = false;
      if (p != null) {
        // Phase 2: baca 4 bool + fallback historyType untuk data lama
        _hasPrior = p.hasPriorPreeclampsia || p.historyType == HistoryType.priorPreeclampsia;
        _hasChronic = p.hasChronicHypertension || p.historyType == HistoryType.hypertension;
        _hasFamily = p.hasFamilyHistory || p.historyType == HistoryType.family;
      }
    });
  }

  bool get _isPrimigravida {
    if (_patient == null) return false;
    if (_patient!.gravida != null) return _patient!.isPrimigravida;
    // fallback bila biodata belum diisi — asumsi dari checklist tidak ada, tampil info
    return false;
  }

  RiskLevel get _computed {
    if (_patient == null) return RiskLevel.unknown;
    // Phase 2: multi-faktor (prior/chronic/family bisa bersamaan) + primigravida
    final high = _hasPrior || _hasChronic || _patient!.age >= 40 || (_patient!.bmi != null && _patient!.bmi! >= 35);
    final medium = _hasFamily || _isPrimigravida || _patient!.age > 35 || (_patient!.bmi != null && _patient!.bmi! > 30);
    if (high) return RiskLevel.high;
    if (medium) return RiskLevel.medium;
    return RiskLevel.low;
  }

  HistoryType get _derivedHistoryType {
    if (_hasPrior) return HistoryType.priorPreeclampsia;
    if (_hasChronic) return HistoryType.hypertension;
    if (_hasFamily) return HistoryType.family;
    return HistoryType.none;
  }

  Future<void> _save() async {
    final p = _patient;
    if (p == null) return;
    final ht = _derivedHistoryType;
    final level = _computed;
    final updated = p.copyWith(
      historyType: ht,
      riskLevel: level,
      synced: false,
      hasPriorPreeclampsia: _hasPrior,
      hasChronicHypertension: _hasChronic,
      hasFamilyHistory: _hasFamily,
      riskDetail: {
        'factors': [
          if (_hasPrior) 'prior_preeclampsia',
          if (_hasChronic) 'chronic_hypertension',
          if (_hasFamily) 'family',
          if (_isPrimigravida) 'primigravida',
        ],
        'source': 'mobile_phase2',
        'computed_at': DateTime.now().toIso8601String(),
      },
    );
    await _repo.saveLocal(updated);
    await _repo.sync(updated);
    if (!mounted) return;
    setState(() => _patient = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Skrining tersimpan & tersinkron ke VPS.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stratifikasi Risiko')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stratifikasi Risiko')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Belum ada profil. Isi registrasi awal dulu.'),
          ),
        ),
      );
    }

    final level = _computed;
    final color = _colorFor(level);

    return Scaffold(
      appBar: AppBar(title: const Text('Stratifikasi Risiko')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.skyLight,
            margin: EdgeInsets.zero,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Skrining berbasis faktor risiko — tentukan apakah kehamilan masuk Risiko Tinggi atau Sedang sesuai Buku KIA 2025.',
                      style: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ResultCard(level: level, color: color),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faktor risiko', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const Divider(height: 16),
                  _FactorTile(
                    title: 'Pernah preeklamsia sebelumnya',
                    subtitle: 'Risiko Tinggi — prediktor terkuat, risiko berulang 7–10×. Jika pernah <34 minggu (onset dini) risiko melonjak.',
                    value: _hasPrior,
                    onChanged: (v) => setState(() => _hasPrior = v),
                    riskLabel: 'Tinggi',
                    riskColor: AppColors.crisis,
                  ),
                  _FactorTile(
                    title: 'Hipertensi kronis (sebelum hamil / <20 minggu)',
                    subtitle: 'Risiko Tinggi — berisiko Superimposed Preeclampsia (preeklamsia menumpuk di atas hipertensi).',
                    value: _hasChronic,
                    onChanged: (v) => setState(() => _hasChronic = v),
                    riskLabel: 'Tinggi',
                    riskColor: AppColors.crisis,
                  ),
                  _FactorTile(
                    title: 'Riwayat orang tua / saudara perempuan',
                    subtitle: 'Risiko Sedang — komponen genetik, risiko 2–3× bila ibu/saudara kandung pernah preeklamsia/hipertensi.',
                    value: _hasFamily,
                    onChanged: (v) => setState(() => _hasFamily = v),
                    riskLabel: 'Sedang',
                    riskColor: AppColors.stage1,
                  ),
                  _InfoTile(
                    title: 'Hamil pertama (primigravida)',
                    subtitle: _patient!.gravida == null
                        ? 'Risiko Sedang — bila ini kehamilan pertama tanpa riwayat, tetap masuk Sedang. Lengkapi Biodata KIA (gravida/para) untuk deteksi otomatis.'
                        : _isPrimigravida
                            ? 'Risiko Sedang — terdeteksi dari Biodata KIA G${_patient!.gravida}P${_patient!.para} (primigravida).'
                            : 'Tidak — terdeteksi G${_patient!.gravida}P${_patient!.para}, bukan primigravida.',
                    isActive: _isPrimigravida,
                  ),
                  if (_patient!.gravida == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Tip: isi Biodata KIA agar primigravida terdeteksi otomatis.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ActionTable(level: level),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Simpan Skrining'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phase 2: 4 faktor + is_primigravida + risk_detail tersinkron ke VPS. Device lama tanpa has_* tetap kompatibel.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _colorFor(RiskLevel l) {
    switch (l) {
      case RiskLevel.high:
        return AppColors.crisis;
      case RiskLevel.medium:
        return AppColors.stage1;
      case RiskLevel.low:
        return AppColors.normal;
      case RiskLevel.unknown:
        return AppColors.textSecondary;
    }
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.level, required this.color});
  final RiskLevel level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kategori risiko', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                Text(level.label.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text(Patient.actionFor(level), style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3)),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({required this.title, required this.subtitle, required this.value, required this.onChanged, required this.riskLabel, required this.riskColor});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String riskLabel;
  final Color riskColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(riskLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: riskColor)),
                    ),
                  ],
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.3, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.subtitle, required this.isActive});
  final String title;
  final String subtitle;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isActive ? Icons.check_circle : Icons.info_outline, size: 20, color: isActive ? AppColors.stage1 : AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.3, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTable extends StatelessWidget {
  const _ActionTable({required this.level});
  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Pernah preeklamsia', 'Tinggi', 'Aspirin dosis rendah + pemantauan ketat'],
      ['Hipertensi kronis', 'Tinggi', 'Aspirin dosis rendah + kontrol TD'],
      ['Riwayat keluarga', 'Sedang', 'Pertimbangkan aspirin bila ada ≥2 faktor sedang'],
      ['Hamil pertama', 'Sedang', 'Pantau rutin tensi & protein urine tiap ANC'],
      ['Tidak ada riwayat', 'Rendah', 'Pola hidup sehat + ANC rutin'],
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tindakan medis standar', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(2.5)},
              border: TableBorder.all(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppColors.neutralLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                  children: const [
                    Padding(padding: EdgeInsets.all(8), child: Text('Riwayat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Kategori', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Tindakan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                  ],
                ),
                for (final r in rows)
                  TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(8), child: Text(r[0], style: const TextStyle(fontSize: 11))),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(r[1],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: r[1] == 'Tinggi'
                                    ? AppColors.crisis
                                    : r[1] == 'Sedang'
                                        ? AppColors.stage1
                                        : AppColors.normal)),
                      ),
                      Padding(padding: const EdgeInsets.all(8), child: Text(r[2], style: const TextStyle(fontSize: 11, height: 1.3))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Sumber: NICE & Buku KIA 2025. Konsultasikan ke bidan/dokter untuk keputusan aspirin.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

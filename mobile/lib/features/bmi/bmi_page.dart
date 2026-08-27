import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';

/// Menu BMI Ibu Hamil — input tinggi & berat pra-hamil.
///
/// Jelaskan pencegahan preeklampsia: jaga BMI pra-hamil ideal 18,5–24,9
/// + kontrol kenaikan sesuai kategori. Simpan ke `PUT /patient`
/// lalu `GET /patient/bmi` (VPS) dengan fallback hitung lokal offline.
class BmiPage extends StatefulWidget {
  const BmiPage({super.key, this.repository});

  final PatientRepository? repository;

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  late final PatientRepository _repo;
  bool _loading = true;
  bool _saving = false;
  Patient? _patient;
  BmiResult? _remoteBmi;

  final _heightC = TextEditingController();
  final _weightC = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? PatientRepository();
    _load();
  }

  @override
  void dispose() {
    _heightC.dispose();
    _weightC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await _repo.getLocal();
    BmiResult? remote;
    try {
      remote = await _repo.fetchBmi();
    } catch (_) {}
    if (!mounted) return;
    _patient = p;
    _remoteBmi = remote;
    if (p != null) {
      _heightC.text = _numText(p.prePregnancyHeight ?? p.heightCm);
      _weightC.text = _numText(p.prePregnancyWeight ?? p.weightKg);
    }
    setState(() => _loading = false);
  }

  String _numText(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double? get _localBmi {
    final h = double.tryParse(_heightC.text);
    final w = double.tryParse(_weightC.text);
    if (h == null || h <= 0 || w == null) return null;
    return w / ((h / 100) * (h / 100));
  }

  String _categoryOf(double? b) {
    if (b == null) return '-';
    if (b < 18.5) return 'kurus';
    if (b < 25) return 'normal';
    if (b < 30) return 'gemuk';
    return 'obesitas';
  }

  String _rangeOf(String cat) {
    switch (cat) {
      case 'kurus':
        return '12,5–18 kg';
      case 'normal':
        return '11,5–16 kg';
      case 'gemuk':
        return '7–11,5 kg';
      case 'obesitas':
        return '5–9 kg';
      default:
        return '-';
    }
  }

  /// Gaya input konsisten dengan form Biodata KIA.
  InputDecoration _dec(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: AppColors.primary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.crisis),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.crisis, width: 1.5),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final p = _patient;
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi registrasi awal dulu.')));
      return;
    }
    final h = double.parse(_heightC.text);
    final w = double.parse(_weightC.text);
    final updated = p.copyWith(prePregnancyHeight: h, prePregnancyWeight: w, synced: false);
    setState(() => _saving = true);
    await _repo.saveLocal(updated);
    final ok = await _repo.sync(updated);
    BmiResult? remote;
    try {
      remote = await _repo.fetchBmi();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _patient = updated;
      _remoteBmi = remote;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'BMI tersimpan & tersinkron.' : 'BMI tersimpan di perangkat (offline).')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('BMI Ibu Hamil')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('BMI Ibu Hamil')),
        body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada profil. Isi registrasi awal dulu.'))),
      );
    }
    final localBmi = _localBmi;
    final localCat = _categoryOf(localBmi);
    final displayBmi = _remoteBmi?.bmi ?? localBmi;
    final displayCat = _remoteBmi?.category ?? localCat;
    final displayRange = _remoteBmi?.weightGainRange ?? _rangeOf(localCat);
    final displayAdvice = _remoteBmi?.advice ?? _patient!.bmiAdvice;

    return Scaffold(
      appBar: AppBar(title: const Text('BMI Ibu Hamil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              color: AppColors.skyLight,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.info_outline, color: AppColors.primaryLight, size: 18), SizedBox(width: 8), Expanded(child: Text('Pencegahan preeklampsia: jaga BMI pra-kehamilan ideal 18,5–24,9 kg/m² dan kontrol kenaikan berat selama hamil.', style: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600)))]),
                  SizedBox(height: 8),
                  Text('Batas kenaikan (berdasarkan BMI sebelum hamil):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('• Kurus <18,5 → 12,5–18 kg\n• Normal 18,5–24,9 → 11,5–16 kg\n• Gemuk 25–29,9 → 7–11,5 kg\n• Obesitas ≥30 → 5–9 kg', style: TextStyle(fontSize: 11, height: 1.35)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Input pra-kehamilan', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const Divider(height: 16),
                  TextFormField(
                    controller: _heightC,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Tinggi pra-hamil (cm)', Icons.height, hint: '155'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 100 || n > 250) return '100–250 cm';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _weightC,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Berat pra-hamil (kg)', Icons.monitor_weight_outlined, hint: '52'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 30 || n > 200) return '30–200 kg';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _BmiResultCard(bmi: displayBmi, category: displayCat, range: displayRange, advice: displayAdvice, localBmi: localBmi),
                  const SizedBox(height: 12),
                  SizedBox(height: 44, child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan BMI'))),
                  if (_remoteBmi == null && localBmi != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Hasil dihitung lokal (offline). Akan sinkron saat online.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiResultCard extends StatelessWidget {
  const _BmiResultCard({required this.bmi, required this.category, required this.range, required this.advice, required this.localBmi});
  final double? bmi;
  final String category;
  final String range;
  final String advice;
  final double? localBmi;

  Color _catColor(String c) {
    switch (c) {
      case 'kurus':
        return const Color(0xFF0284C7);
      case 'normal':
        return AppColors.normal;
      case 'gemuk':
        return AppColors.stage1;
      case 'obesitas':
        return AppColors.emergency;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _catColor(category);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calculate_outlined, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BMI pra-hamil', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              Text(bmi == null ? '—' : bmi!.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: c)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
            child: Text(category.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.trending_up, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('Batas kenaikan: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(range, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: c)),
        ]),
        const SizedBox(height: 8),
        Text(advice, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35)),
      ]),
    );
  }
}

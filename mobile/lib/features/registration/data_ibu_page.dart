import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../measurement/bp_repository.dart';
import 'patient.dart';
import 'patient_repository.dart';
import 'registration_page.dart';

/// Screen "Data Ibu": menampilkan profil ibu yang tersimpan (auto-fill) dan
/// bisa diedit. Menyimpan ke rekam yang sama (UUID tetap) lalu sinkron
/// best-effort. Bila belum ada profil, diarahkan ke registrasi.
class DataIbuPage extends StatefulWidget {
  const DataIbuPage({super.key, this.repository, this.bpRepository});

  final PatientRepository? repository;
  final BpRepository? bpRepository;

  @override
  State<DataIbuPage> createState() => _DataIbuPageState();
}

class _DataIbuPageState extends State<DataIbuPage> {
  late final PatientRepository _repository;
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _notFound = false;
  bool _saving = false;
  Patient? _existing;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weeksController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  HistoryType _historyType = HistoryType.none;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PatientRepository();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weeksController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final existing = await _repository.getLocal();
    if (!mounted) return;
    if (existing == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }
    _nameController.text = existing.name;
    _ageController.text = existing.age.toString();
    _weeksController.text = existing.gestationalWeeks?.toString() ?? '';
    _heightController.text = _numText(existing.heightCm);
    _weightController.text = _numText(existing.weightKg);
    _historyType = existing.historyType;
    setState(() {
      _existing = existing;
      _loading = false;
    });
  }

  /// Format angka desimal tanpa desimal yang tidak perlu (160.0 -> 160).
  static String _numText(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// BMI dihitung live dari tinggi & berat yang sedang diinput.
  double? get _bmi {
    final h = double.tryParse(_heightController.text);
    final w = double.tryParse(_weightController.text);
    if (h == null || h <= 0 || w == null) return null;
    final m = h / 100;
    return w / (m * m);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = _existing!;
    final age = int.parse(_ageController.text);
    final height = double.parse(_heightController.text);
    final weight = double.parse(_weightController.text);
    final weeks = _weeksController.text.isEmpty
        ? null
        : int.parse(_weeksController.text);
    final bmi = _bmi;

    // Simpan ke rekam yang sama; tandai belum tersinkron agar diunggah ulang.
    final updated = Patient(
      uuid: existing.uuid,
      name: _nameController.text.trim(),
      age: age,
      heightCm: height,
      weightKg: weight,
      gestationalWeeks: weeks,
      dueDate: weeks == null
          ? null
          : DateTime.now().add(Duration(days: (40 - weeks) * 7)),
      lastSystolic: existing.lastSystolic,
      lastDiastolic: existing.lastDiastolic,
      historyType: _historyType,
      riskLevel: Patient.computeRiskLevel(
        age: age,
        historyType: _historyType,
        bmi: bmi,
        hasMeasurement: existing.lastSystolic != null && existing.lastDiastolic != null,
      ),
      phone: existing.phone,
      synced: false,
    );

    setState(() => _saving = true);
    await _repository.saveLocal(updated);
    final synced = await _repository.sync(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'Profil tersimpan dan tersinkron.'
              : 'Profil tersimpan di perangkat (offline).',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Ibu')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notFound
              ? _EmptyState(
                  repository: widget.repository,
                  bpRepository: widget.bpRepository,
                )
              : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.skyLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryLight),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data di bawah sudah terisi otomatis dari profil Anda. '
                      'Ubah bila perlu lalu simpan.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama ibu',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Usia (tahun)',
                      prefixIcon: Icon(Icons.cake),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 12 || n > 55) {
                        return 'Usia 12–55 tahun';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weeksController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Usia kehamilan (minggu)',
                      prefixIcon: Icon(Icons.pregnant_woman),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 0 || n > 45) return '0–45 minggu';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tinggi badan (cm)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 100 || n > 250) return '100–250 cm';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Berat badan (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 30 || n > 200) return '30–200 kg';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.skyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate_outlined,
                            size: 20, color: AppColors.primaryLight),
                        const SizedBox(width: 8),
                        Text(
                          'BMI',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          _bmi == null
                              ? '—'
                              : _bmi!.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Riwayat hipertensi',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: HistoryType.values.map((type) {
                      final selected = type == _historyType;
                      return ChoiceChip(
                        label: Text(type.label),
                        selected: selected,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) =>
                            setState(() => _historyType = type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
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
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

/// Ditampilkan bila belum ada profil tersimpan di perangkat.
class _EmptyState extends StatelessWidget {
  const _EmptyState({this.repository, this.bpRepository});

  final PatientRepository? repository;
  final BpRepository? bpRepository;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search_outlined,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Belum ada profil ibu',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Lengkapi biodata dulu untuk mulai memantau tekanan darah.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RegistrationPage(
                    repository: repository,
                    bpRepository: bpRepository,
                  ),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Isi Biodata'),
            ),
          ],
        ),
      ),
    );
  }
}

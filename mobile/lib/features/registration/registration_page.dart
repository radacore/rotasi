import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_shell.dart';
import '../measurement/bp_repository.dart';
import 'patient.dart';
import 'patient_repository.dart';

/// Alur registrasi biodata ibu (FR-01).
///
/// Data tersimpan lokal dulu (offline-first); sinkronisasi dilakukan
/// best-effort saat online. Setelah selesai masuk ke Beranda.
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, this.repository, this.bpRepository});

  final PatientRepository? repository;
  final BpRepository? bpRepository;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  late final PatientRepository _repository;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _gestationalWeeksController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _phoneController = TextEditingController();

  HistoryType _historyType = HistoryType.none;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PatientRepository();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _gestationalWeeksController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final int? gestationalWeeks = _gestationalWeeksController.text.isEmpty
        ? null
        : int.parse(_gestationalWeeksController.text);

    final patient = Patient.newLocal(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      heightCm: double.parse(_heightController.text),
      weightKg: double.parse(_weightController.text),
      gestationalWeeks: gestationalWeeks,
      lastSystolic: _systolicController.text.isEmpty
          ? null
          : int.parse(_systolicController.text),
      lastDiastolic: _diastolicController.text.isEmpty
          ? null
          : int.parse(_diastolicController.text),
      historyType: _historyType,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    setState(() => _submitting = true);
    await _repository.saveLocal(patient);
    final synced = await _repository.sync(patient);
    if (!mounted) return;

    if (synced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil tersimpan dan tersinkron.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil tersimpan di perangkat (offline).')),
      );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeShell(
          repository: widget.repository,
          bpRepository: widget.bpRepository,
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            children: [
              Text(
                'Selamat Datang',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lengkapi biodata ibu untuk mulai menggunakan\nAplikasi Rotasi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 14),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border, width: 0.9),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Nama ibu', Icons.person_outline),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Usia (tahun)', Icons.cake_outlined),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 12 || n > 55) return 'Usia 12–55 tahun';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _gestationalWeeksController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Usia kehamilan (minggu)', Icons.pregnant_woman_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 0 || n > 45) return '0–45 minggu';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Tinggi badan (cm)', Icons.height_outlined),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 100 || n > 250) return '100–250 cm';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Berat badan (kg)', Icons.monitor_weight_outlined),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 30 || n > 200) return '30–200 kg';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tekanan darah terakhir (opsional)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _systolicController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Sistolik (atas)', Icons.favorite_border),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 50 || n > 180) return '50–180';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _diastolicController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Diastolik (bawah)', Icons.favorite_border),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 30 || n > 120) return '30–120';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Riwayat hipertensi',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: HistoryType.values.map((type) {
                          final selected = type == _historyType;
                          return ChoiceChip(
                            label: Text(type.label, style: const TextStyle(fontSize: 12)),
                            selected: selected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: selected ? AppColors.primary : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            labelStyle: TextStyle(
                              color: selected ? AppColors.white : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            onSelected: (_) => setState(() => _historyType = type),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Nomor WhatsApp (opsional)', Icons.phone_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Simpan dan Mulai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

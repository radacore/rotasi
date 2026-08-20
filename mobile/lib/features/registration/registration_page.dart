import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_page.dart';
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
  late final BpRepository? _bpRepository;

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
    _bpRepository = widget.bpRepository;
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
        builder: (_) => HomePage(
          repository: _repository,
          bpRepository: _bpRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.favorite, color: AppColors.primary, size: 56),
              const SizedBox(height: 12),
              Text(
                'Selamat Datang',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lengkapi biodata ibu untuk mulai memantau tekanan darah.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),
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
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _gestationalWeeksController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Usia kehamilan (minggu)',
                                prefixIcon: Icon(Icons.pregnant_woman),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final n = int.tryParse(v);
                                if (n == null || n < 0 || n > 45) {
                                  return '0–45 minggu';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tinggi badan (cm)',
                                prefixIcon: Icon(Icons.height),
                              ),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n < 100 || n > 250) {
                                  return '100–250 cm';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Berat badan (kg)',
                                prefixIcon: Icon(Icons.monitor_weight),
                              ),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n < 30 || n > 200) {
                                  return '30–200 kg';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tekanan darah terakhir (opsional)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _systolicController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Sistolik (atas)',
                                prefixIcon: Icon(Icons.favorite_outline),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final n = int.tryParse(v);
                                if (n == null || n < 50 || n > 180) {
                                  return '50–180';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _diastolicController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Diastolik (bawah)',
                                prefixIcon: Icon(Icons.favorite_outline),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final n = int.tryParse(v);
                                if (n == null || n < 30 || n > 120) {
                                  return '30–120';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
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
                              color: selected ? AppColors.white : AppColors.textPrimary,
                            ),
                            onSelected: (_) =>
                                setState(() => _historyType = type),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor WhatsApp (opsional)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Simpan dan Mulai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

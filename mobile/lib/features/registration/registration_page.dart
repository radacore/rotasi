import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_shell.dart';
import '../measurement/bp_repository.dart';
import 'patient.dart';
import 'patient_repository.dart';

/// Welcome minimal (opsi 1) — hanya Nama + WA.
///
/// Data lengkap KIA (NIK, Faskes, darah, gravida, BMI pra-hamil) diisi
/// nanti via tombol di Beranda → Biodata KIA. Default age/height/weight
/// aman agar Patient tetap valid & sinkron langsung.
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
  final _phoneController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PatientRepository();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final patient = Patient.newLocal(
      name: _nameController.text.trim(),
      age: 25,
      heightCm: 155,
      weightKg: 52,
      historyType: HistoryType.none,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
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
      backgroundColor: AppColors.white,
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
                'Masukkan nama untuk memulai.\nLengkapi Biodata KIA & BMI di Beranda setelahnya.',
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
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 14),
                        decoration: _dec('Nomor WhatsApp (opsional)', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.skyLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppColors.primaryLight),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'NIK, Faskes, golongan darah, kehamilan ke-/BMI pra-hamil bisa dilengkapi nanti lewat tombol di Beranda.',
                                style: TextStyle(fontSize: 11, height: 1.35, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
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
                      : const Text('Mulai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

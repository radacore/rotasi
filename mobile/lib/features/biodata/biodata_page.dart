import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';

/// Menu terpisah Biodata Ibu Hamil sesuai Buku KIA 2025.
///
/// Dipecah jadi 4 step (Identitas → Faskes → Sosial & Darah → Obstetri)
/// agar selaras dengan Selamat Datang (satu Card per layar, tanpa scroll
/// panjang). Tiap step divalidasi sebelum pindah; `Simpan Biodata` hanya
/// di step terakhir. Simpan ke `patients` lokal + `PUT /api/v1/patient`.
class BiodataPage extends StatefulWidget {
  const BiodataPage({super.key, this.repository});

  final PatientRepository? repository;

  @override
  State<BiodataPage> createState() => _BiodataPageState();
}

class _BiodataPageState extends State<BiodataPage> {
  late final PatientRepository _repo;
  final _stepKeys = List.generate(4, (_) => GlobalKey<FormState>());
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _saving = false;
  int _currentStep = 0;
  Patient? _existing;

  static const _stepTitles = ['Identitas', 'Faskes', 'Sosial & Darah', 'Obstetri'];
  static const _stepDescs = [
    'Data pribadi ibu sesuai identitas resmi.',
    'Tempat ibu melakukan ANC rutin & rujukan.',
    'Latar belakang pendidikan, pekerjaan, dan golongan darah.',
    'Riwayat kehamilan dan kesehatan ibu.',
  ];

  // Identitas
  final _nikC = TextEditingController();
  final _jknC = TextEditingController();
  final _nameC = TextEditingController();
  final _birthPlaceC = TextEditingController();
  final _birthDateC = TextEditingController();
  final _ageC = TextEditingController();
  final _addressC = TextEditingController();
  final _phoneC = TextEditingController();
  DateTime? _birthDate;

  // Faskes
  final _faskesTk1C = TextEditingController();
  final _faskesRujukanC = TextEditingController();

  // Sosial
  final _educationC = TextEditingController();
  final _occupationC = TextEditingController();

  // Obstetri
  final _gravidaC = TextEditingController();
  final _paraC = TextEditingController();
  final _livingC = TextEditingController();
  final _miscarriageC = TextEditingController();
  final _diseaseC = TextEditingController();
  BloodType? _bloodType;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? PatientRepository();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in [
      _nikC,
      _jknC,
      _nameC,
      _birthPlaceC,
      _birthDateC,
      _ageC,
      _addressC,
      _phoneC,
      _faskesTk1C,
      _faskesRujukanC,
      _educationC,
      _occupationC,
      _gravidaC,
      _paraC,
      _livingC,
      _miscarriageC,
      _diseaseC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final p = await _repo.getLocal();
    // Coba hydrate dari VPS bila ada (best-effort)
    Patient? remote;
    try {
      remote = await _repo.fetchRemote();
    } catch (_) {}
    final e = remote ?? p;
    if (!mounted) return;
    if (e == null) {
      setState(() => _loading = false);
      return;
    }
    _existing = e;
    _nikC.text = e.nik ?? '';
    _jknC.text = e.jknNo ?? '';
    _nameC.text = e.name;
    _birthPlaceC.text = e.birthPlace ?? '';
    _birthDate = e.birthDate;
    _birthDateC.text = e.birthDate == null ? '' : _fmtDate(e.birthDate!);
    // Usia jangan diisi dari default welcome (25). Hanya hitung dari tanggal
    // lahir bila tersedia; selain itu biarkan kosong agar ibu mengisi sendiri.
    if (e.birthDate != null) {
      final now = DateTime.now();
      final age = now.year -
          e.birthDate!.year -
          (now.month < e.birthDate!.month ||
                  (now.month == e.birthDate!.month &&
                      now.day < e.birthDate!.day)
              ? 1
              : 0);
      _ageC.text = age.clamp(12, 55).toString();
    }
    _addressC.text = e.address ?? '';
    _phoneC.text = e.phone ?? '';
    _faskesTk1C.text = e.faskesTk1 ?? '';
    _faskesRujukanC.text = e.faskesRujukan ?? '';
    _educationC.text = e.education ?? '';
    _occupationC.text = e.occupation ?? '';
    _gravidaC.text = e.gravida?.toString() ?? '';
    _paraC.text = e.para?.toString() ?? '';
    _livingC.text = e.livingChildren?.toString() ?? '';
    _miscarriageC.text = e.miscarriageCount?.toString() ?? '';
    _diseaseC.text = e.diseaseHistory ?? '';
    _bloodType = e.bloodType;
    setState(() => _loading = false);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _birthDateC.text = _fmtDate(picked);
      // usia otomatis
      final age = now.year - picked.year - (now.month < picked.month || (now.month == picked.month && now.day < picked.day) ? 1 : 0);
      _ageC.text = age.clamp(12, 55).toString();
    });
  }

  void _goTo(int step) {
    _scrollController.jumpTo(0);
    setState(() => _currentStep = step);
  }

  void _next() {
    if (!_stepKeys[_currentStep].currentState!.validate()) return;
    if (_currentStep < 3) {
      _goTo(_currentStep + 1);
    } else {
      _save();
    }
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  String? _requiredNum(String? v, String label, {int min = 0}) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    final n = int.tryParse(v.trim());
    if (n == null || n < min) return min > 0 ? 'Minimal $min' : 'Angka valid';
    return null;
  }

  Future<void> _save() async {
    final existing = _existing;
    if (existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi registrasi awal dulu.')));
      return;
    }
    final age = int.tryParse(_ageC.text) ?? existing.age;
    final repo = _repo;
    final updated = Patient(
      uuid: existing.uuid,
      name: _nameC.text.trim().isEmpty ? existing.name : _nameC.text.trim(),
      age: age,
      heightCm: existing.heightCm,
      weightKg: existing.weightKg,
      gestationalWeeks: existing.gestationalWeeks,
      dueDate: existing.dueDate,
      lastSystolic: existing.lastSystolic,
      lastDiastolic: existing.lastDiastolic,
      historyType: existing.historyType,
      riskLevel: existing.riskLevel,
      phone: _phoneC.text.trim().isEmpty ? null : _phoneC.text.trim(),
      synced: false,
      nik: _nikC.text.trim().isEmpty ? null : _nikC.text.trim(),
      jknNo: _jknC.text.trim().isEmpty ? null : _jknC.text.trim(),
      faskesTk1: _faskesTk1C.text.trim().isEmpty ? null : _faskesTk1C.text.trim(),
      faskesRujukan: _faskesRujukanC.text.trim().isEmpty ? null : _faskesRujukanC.text.trim(),
      birthPlace: _birthPlaceC.text.trim().isEmpty ? null : _birthPlaceC.text.trim(),
      birthDate: _birthDate,
      education: _educationC.text.trim().isEmpty ? null : _educationC.text.trim(),
      occupation: _occupationC.text.trim().isEmpty ? null : _occupationC.text.trim(),
      address: _addressC.text.trim().isEmpty ? null : _addressC.text.trim(),
      bloodType: _bloodType,
      gravida: _gravidaC.text.isEmpty ? null : int.tryParse(_gravidaC.text),
      para: _paraC.text.isEmpty ? null : int.tryParse(_paraC.text),
      livingChildren: _livingC.text.isEmpty ? null : int.tryParse(_livingC.text),
      miscarriageCount: _miscarriageC.text.isEmpty ? null : int.tryParse(_miscarriageC.text),
      diseaseHistory: _diseaseC.text.trim().isEmpty ? null : _diseaseC.text.trim(),
      prePregnancyWeight: existing.prePregnancyWeight,
      prePregnancyHeight: existing.prePregnancyHeight,
    );

    setState(() => _saving = true);
    await repo.saveLocal(updated);
    final ok = await repo.sync(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Biodata tersimpan & tersinkron.' : 'Biodata tersimpan di perangkat (offline).')));
    Navigator.of(context).pop();
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) => InputDecoration(
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

  Widget _stepCard(List<Widget> children) => Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 0.9),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );

  Widget _stepBody(Widget fields) => Form(
        key: _stepKeys[_currentStep],
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Text(
              _stepTitles[_currentStep],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              _stepDescs[_currentStep],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            fields,
          ],
        ),
      );

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _stepBody(_stepCard([
          TextFormField(
            controller: _nikC,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
            decoration: _dec('NIK (16 digit)', Icons.badge_outlined, hint: '1234567890123456'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'NIK wajib diisi';
              if (!RegExp(r'^[0-9]{16}$').hasMatch(v)) return 'NIK 16 digit angka';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _jknC,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
            decoration: _dec('No. JKN', Icons.health_and_safety_outlined, hint: '0001234567890'),
            validator: (v) => _required(v, 'No. JKN'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameC,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Nama ibu', Icons.person_outline),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _birthPlaceC, decoration: _dec('Tempat lahir', Icons.location_on_outlined), validator: (v) => _required(v, 'Tempat lahir'))),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _birthDateC,
                readOnly: true,
                decoration: _dec('Tanggal lahir', Icons.cake_outlined),
                onTap: _pickBirthDate,
                validator: (v) => _required(v, 'Tanggal lahir'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _ageC,
            keyboardType: TextInputType.number,
            decoration: _dec('Usia ibu (tahun)', Icons.cake_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Usia wajib diisi';
              final n = int.tryParse(v);
              if (n == null || n < 12 || n > 55) return '12–55';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(controller: _addressC, maxLines: 2, decoration: _dec('Alamat rumah', Icons.home_outlined), validator: (v) => _required(v, 'Alamat')),
          const SizedBox(height: 10),
          TextFormField(controller: _phoneC, keyboardType: TextInputType.phone, decoration: _dec('No. telp/WA', Icons.phone_outlined), validator: (v) => _required(v, 'No. telp/WA')),
        ]));
      case 1:
        return _stepBody(_stepCard([
          TextFormField(controller: _faskesTk1C, decoration: _dec('Faskes TK1', Icons.local_hospital_outlined), validator: (v) => _required(v, 'Faskes TK1')),
          const SizedBox(height: 10),
          TextFormField(controller: _faskesRujukanC, decoration: _dec('Faskes rujukan', Icons.medical_services_outlined), validator: (v) => _required(v, 'Faskes rujukan')),
        ]));
      case 2:
        return _stepBody(_stepCard([
          TextFormField(controller: _educationC, decoration: _dec('Pendidikan', Icons.school_outlined, hint: 'SMA / S1 ...'), validator: (v) => _required(v, 'Pendidikan')),
          const SizedBox(height: 10),
          TextFormField(controller: _occupationC, decoration: _dec('Pekerjaan', Icons.work_outline, hint: 'IRT / PNS ...'), validator: (v) => _required(v, 'Pekerjaan')),
          const SizedBox(height: 10),
          DropdownButtonFormField<BloodType>(
            initialValue: _bloodType,
            decoration: _dec('Golongan darah', Icons.water_drop_outlined),
            items: BloodType.values.map((b) => DropdownMenuItem(value: b, child: Text(b.label))).toList(),
            onChanged: (v) => setState(() => _bloodType = v),
            validator: (v) => v == null ? 'Pilih golongan darah' : null,
          ),
        ]));
      case 3:
      default:
        return _stepBody(_stepCard([
          Row(children: [
            Expanded(child: TextFormField(controller: _gravidaC, keyboardType: TextInputType.number, decoration: _dec('Kehamilan ke- (G)', Icons.numbers), validator: (v) => _requiredNum(v, 'Kehamilan ke-', min: 1))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _paraC, keyboardType: TextInputType.number, decoration: _dec('Anak ke- (P)', Icons.numbers), validator: (v) => _requiredNum(v, 'Anak ke-'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _livingC, keyboardType: TextInputType.number, decoration: _dec('Anak hidup', Icons.child_care), validator: (v) => _requiredNum(v, 'Anak hidup'))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _miscarriageC, keyboardType: TextInputType.number, decoration: _dec('Keguguran', Icons.warning_amber_rounded), validator: (v) => _requiredNum(v, 'Keguguran'))),
          ]),
          const SizedBox(height: 10),
          TextFormField(controller: _diseaseC, maxLines: 3, decoration: _dec('Riwayat penyakit ibu', Icons.medical_information_outlined, hint: 'Tulis "tidak ada" bila tidak ada'), validator: (v) => _required(v, 'Riwayat penyakit')),
        ]));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('Biodata KIA')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Biodata KIA')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_search_outlined, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Belum ada profil', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Isi registrasi awal dulu.', textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
    }
    final isLast = _currentStep == 3;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Biodata KIA')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lengkapi Biodata', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Step ${_currentStep + 1}/4', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildStep(_currentStep),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _saving ? null : () => _goTo(_currentStep - 1),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(108, 48)),
                      child: const Text('Kembali'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _next,
                      child: _saving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isLast ? 'Simpan Biodata' : 'Selanjutnya'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

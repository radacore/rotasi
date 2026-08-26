import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../registration/patient.dart';
import '../registration/patient_repository.dart';

/// Menu terpisah Biodata Ibu Hamil sesuai Buku KIA 2025.
///
/// 4 section: Identitas, Faskes, Sosial, Obstetri.
/// Simpan ke `patients` lokal + `PUT /api/v1/patient` (VPS sudah migrasi).
class BiodataPage extends StatefulWidget {
  const BiodataPage({super.key, this.repository});

  final PatientRepository? repository;

  @override
  State<BiodataPage> createState() => _BiodataPageState();
}

class _BiodataPageState extends State<BiodataPage> {
  late final PatientRepository _repo;
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  Patient? _existing;

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
    _ageC.text = e.age.toString();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = _existing;
    if (existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi registrasi awal dulu di Data Ibu.')));
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
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

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
              const Text('Isi Data Ibu dulu.', textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Biodata KIA')),
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
                child: Row(children: [
                  Icon(Icons.menu_book_outlined, color: AppColors.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Sesuai Buku KIA — NIK 16 digit, Faskes TK1/rujukan, TTL, darah, gravida dll.', style: TextStyle(fontSize: 12, height: 1.35))),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            _Section(title: 'Identitas', children: [
              TextFormField(
                controller: _nikC,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                decoration: _dec('NIK (16 digit)', Icons.badge_outlined, hint: '1234567890123456'),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^[0-9]{16}$').hasMatch(v)) return 'NIK 16 digit angka';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(controller: _jknC, decoration: _dec('No. JKN', Icons.health_and_safety_outlined, hint: '0001234567890')),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameC,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Nama ibu', Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib' : null,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(controller: _birthPlaceC, decoration: _dec('Tempat lahir', Icons.location_on_outlined))),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _birthDateC,
                    readOnly: true,
                    decoration: _dec('Tanggal lahir', Icons.cake_outlined),
                    onTap: _pickBirthDate,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ageC,
                keyboardType: TextInputType.number,
                decoration: _dec('Usia ibu (tahun)', Icons.cake_outlined),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 12 || n > 55) return '12–55';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(controller: _addressC, maxLines: 2, decoration: _dec('Alamat rumah', Icons.home_outlined)),
              const SizedBox(height: 10),
              TextFormField(controller: _phoneC, keyboardType: TextInputType.phone, decoration: _dec('No. telp/WA', Icons.phone_outlined)),
            ]),
            const SizedBox(height: 12),
            _Section(title: 'Faskes', children: [
              TextFormField(controller: _faskesTk1C, decoration: _dec('Faskes TK1', Icons.local_hospital_outlined)),
              const SizedBox(height: 10),
              TextFormField(controller: _faskesRujukanC, decoration: _dec('Faskes rujukan', Icons.medical_services_outlined)),
            ]),
            const SizedBox(height: 12),
            _Section(title: 'Sosial & Darah', children: [
              TextFormField(controller: _educationC, decoration: _dec('Pendidikan', Icons.school_outlined, hint: 'SMA / S1 ...')),
              const SizedBox(height: 10),
              TextFormField(controller: _occupationC, decoration: _dec('Pekerjaan', Icons.work_outline, hint: 'IRT / PNS ...')),
              const SizedBox(height: 10),
              DropdownButtonFormField<BloodType>(
                initialValue: _bloodType,
                decoration: _dec('Golongan darah', Icons.water_drop_outlined),
                items: BloodType.values.map((b) => DropdownMenuItem(value: b, child: Text(b.label))).toList(),
                onChanged: (v) => setState(() => _bloodType = v),
              ),
            ]),
            const SizedBox(height: 12),
            _Section(title: 'Obstetri', children: [
              Row(children: [
                Expanded(child: TextFormField(controller: _gravidaC, keyboardType: TextInputType.number, decoration: _dec('Kehamilan ke- (G)', Icons.numbers))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _paraC, keyboardType: TextInputType.number, decoration: _dec('Anak ke- (P)', Icons.numbers))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(controller: _livingC, keyboardType: TextInputType.number, decoration: _dec('Anak hidup', Icons.child_care))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _miscarriageC, keyboardType: TextInputType.number, decoration: _dec('Keguguran', Icons.warning_amber_rounded))),
              ]),
              const SizedBox(height: 10),
              TextFormField(controller: _diseaseC, maxLines: 3, decoration: _dec('Riwayat penyakit ibu', Icons.medical_information_outlined, hint: 'Hipertensi, DM, dll — kosongkan bila tidak ada')),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Biodata')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
          const Divider(height: 16),
          ...children,
        ]),
      ),
    );
  }
}

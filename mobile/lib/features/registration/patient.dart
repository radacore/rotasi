import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Riwayat hipertensi ibu (FR-01, FR-02).
enum HistoryType {
  none('none', 'Tidak ada'),
  hypertension('hypertension', 'Hipertensi'),
  priorPreeclampsia('prior_preeclampsia', 'Pernah preeklamsia'),
  family('family', 'Riwayat turunan');

  const HistoryType(this.value, this.label);

  final String value;
  final String label;

  static HistoryType fromValue(String? value) => HistoryType.values.firstWhere(
        (e) => e.value == value,
        orElse: () => HistoryType.none,
      );
}

/// Kategori risiko (FR-02). Dikirim bersama profil saat sinkronisasi.
///
/// `unknown` = belum ada pengukuran tensi — tampil sebagai "Belum dinilai"
/// agar tidak memberi kesan aman palsu sebelum ada data TD.
enum RiskLevel {
  unknown('unknown', 'Belum dinilai'),
  low('low', 'Rendah'),
  medium('medium', 'Sedang'),
  high('high', 'Tinggi');

  const RiskLevel(this.value, this.label);

  final String value;
  final String label;

  static RiskLevel fromValue(String? value) => RiskLevel.values.firstWhere(
        (e) => e.value == value,
        orElse: () => RiskLevel.unknown,
      );
}

enum BloodType {
  a('A', 'A'),
  b('B', 'B'),
  ab('AB', 'AB'),
  o('O', 'O');

  const BloodType(this.value, this.label);
  final String value;
  final String label;

  static BloodType? fromValue(String? v) {
    if (v == null) return null;
    for (final e in BloodType.values) {
      if (e.value == v) return e;
    }
    return null;
  }
}

/// Profil ibu hamil (FR-01). Sinkron ke `PUT /api/v1/patient`.
///
/// Biodata KIA (FR-01b) + BMI pra-hamil ditambah nullable agar kompatibel
/// dengan data lama. Backend VPS sudah migrasi 2026_08_25_add_biodata_to_patients.
class Patient {
  const Patient({
    required this.uuid,
    required this.name,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.gestationalWeeks,
    this.dueDate,
    this.lastSystolic,
    this.lastDiastolic,
    this.historyType = HistoryType.none,
    this.riskLevel = RiskLevel.unknown,
    this.phone,
    this.synced = false,
    // Biodata KIA
    this.nik,
    this.jknNo,
    this.faskesTk1,
    this.faskesRujukan,
    this.birthPlace,
    this.birthDate,
    this.education,
    this.occupation,
    this.address,
    this.bloodType,
    this.gravida,
    this.para,
    this.livingChildren,
    this.miscarriageCount,
    this.diseaseHistory,
    this.prePregnancyWeight,
    this.prePregnancyHeight,
    this.hasPriorPreeclampsia = false,
    this.hasChronicHypertension = false,
    this.hasFamilyHistory = false,
    this.riskDetail,
  });

  final String uuid;
  final String name;
  final int age;
  final double heightCm;
  final double weightKg;
  final int? gestationalWeeks;
  final DateTime? dueDate;
  final int? lastSystolic;
  final int? lastDiastolic;
  final HistoryType historyType;
  final RiskLevel riskLevel;
  final String? phone;
  final bool synced;
  // Biodata KIA (nullable untuk backward compat)
  final String? nik;
  final String? jknNo;
  final String? faskesTk1;
  final String? faskesRujukan;
  final String? birthPlace;
  final DateTime? birthDate;
  final String? education;
  final String? occupation;
  final String? address;
  final BloodType? bloodType;
  final int? gravida;
  final int? para;
  final int? livingChildren;
  final int? miscarriageCount;
  final String? diseaseHistory;
  final double? prePregnancyWeight;
  final double? prePregnancyHeight;
  // Stratifikasi Phase 2 — 4 faktor + detail json (VPS 2026_08_26/27)
  final bool hasPriorPreeclampsia;
  final bool hasChronicHypertension;
  final bool hasFamilyHistory;
  final Map<String, dynamic>? riskDetail;

  /// Biodata KIA belum lengkap bila ada field wajib form yang masih kosong.
  ///
  /// Dipakai untuk menyembunyikan kartu "Lengkapi Biodata KIA" di Beranda dan
  /// men-disable aksi "Ukur Tensi" sampai semua field terisi (FR-01b).
  bool get biodataIncomplete {
    return (nik == null || nik!.isEmpty) ||
        (jknNo == null || jknNo!.isEmpty) ||
        (birthPlace == null || birthPlace!.isEmpty) ||
        birthDate == null ||
        (address == null || address!.isEmpty) ||
        (phone == null || phone!.isEmpty) ||
        (faskesTk1 == null || faskesTk1!.isEmpty) ||
        (faskesRujukan == null || faskesRujukan!.isEmpty) ||
        (education == null || education!.isEmpty) ||
        (occupation == null || occupation!.isEmpty) ||
        bloodType == null ||
        gravida == null ||
        para == null ||
        livingChildren == null ||
        miscarriageCount == null ||
        (diseaseHistory == null || diseaseHistory!.isEmpty);
  }

  factory Patient.newLocal({
    required String name,
    required int age,
    required double heightCm,
    required double weightKg,
    int? gestationalWeeks,
    DateTime? dueDate,
    int? lastSystolic,
    int? lastDiastolic,
    HistoryType historyType = HistoryType.none,
    String? phone,
  }) {
    final hasMeasurement = lastSystolic != null && lastDiastolic != null;
    return Patient(
      uuid: const Uuid().v4(),
      name: name,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      gestationalWeeks: gestationalWeeks,
      dueDate: dueDate ?? _dueDateFromWeeks(gestationalWeeks),
      lastSystolic: lastSystolic,
      lastDiastolic: lastDiastolic,
      historyType: historyType,
      riskLevel: computeRiskLevel(
        age: age,
        historyType: historyType,
        bmi: _bmiOf(weightKg: weightKg, heightCm: heightCm),
        hasMeasurement: hasMeasurement,
      ),
      phone: phone,
    );
  }

  static double? _bmiOf({required double weightKg, required double heightCm}) {
    if (heightCm <= 0) return null;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  /// Perkiraan HPL dari usia kehamilan (40 minggu standar ANC).
  static DateTime? _dueDateFromWeeks(int? weeks) {
    if (weeks == null) return null;
    return DateTime.now().add(Duration(days: (40 - weeks) * 7));
  }

  Patient copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    int? gestationalWeeks,
    DateTime? dueDate,
    int? lastSystolic,
    int? lastDiastolic,
    HistoryType? historyType,
    RiskLevel? riskLevel,
    String? phone,
    bool? synced,
    String? nik,
    String? jknNo,
    String? faskesTk1,
    String? faskesRujukan,
    String? birthPlace,
    DateTime? birthDate,
    String? education,
    String? occupation,
    String? address,
    BloodType? bloodType,
    int? gravida,
    int? para,
    int? livingChildren,
    int? miscarriageCount,
    String? diseaseHistory,
    double? prePregnancyWeight,
    double? prePregnancyHeight,
    bool? hasPriorPreeclampsia,
    bool? hasChronicHypertension,
    bool? hasFamilyHistory,
    Map<String, dynamic>? riskDetail,
  }) {
    return Patient(
      uuid: uuid,
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gestationalWeeks: gestationalWeeks ?? this.gestationalWeeks,
      dueDate: dueDate ?? this.dueDate,
      lastSystolic: lastSystolic ?? this.lastSystolic,
      lastDiastolic: lastDiastolic ?? this.lastDiastolic,
      historyType: historyType ?? this.historyType,
      riskLevel: riskLevel ?? this.riskLevel,
      phone: phone ?? this.phone,
      synced: synced ?? this.synced,
      nik: nik ?? this.nik,
      jknNo: jknNo ?? this.jknNo,
      faskesTk1: faskesTk1 ?? this.faskesTk1,
      faskesRujukan: faskesRujukan ?? this.faskesRujukan,
      birthPlace: birthPlace ?? this.birthPlace,
      birthDate: birthDate ?? this.birthDate,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      gravida: gravida ?? this.gravida,
      para: para ?? this.para,
      livingChildren: livingChildren ?? this.livingChildren,
      miscarriageCount: miscarriageCount ?? this.miscarriageCount,
      diseaseHistory: diseaseHistory ?? this.diseaseHistory,
      prePregnancyWeight: prePregnancyWeight ?? this.prePregnancyWeight,
      prePregnancyHeight: prePregnancyHeight ?? this.prePregnancyHeight,
      hasPriorPreeclampsia: hasPriorPreeclampsia ?? this.hasPriorPreeclampsia,
      hasChronicHypertension: hasChronicHypertension ?? this.hasChronicHypertension,
      hasFamilyHistory: hasFamilyHistory ?? this.hasFamilyHistory,
      riskDetail: riskDetail ?? this.riskDetail,
    );
  }

  /// Skrining risiko otomatis (FR-02) — Phase 1 stratifikasi preeklamsia.
  ///
  /// Kriteria NICE/KIA 2024 disesuaikan spek Rotasi:
  /// - tinggi: pernah preeklamsia, hipertensi kronis (= hypertension), usia >= 40, IMT >= 35
  /// - sedang: riwayat keluarga, primigravida (G1P0), usia > 35, IMT > 30
  ///
  /// Bila belum ada pengukuran tensi (`hasMeasurement == false`), kembalikan
  /// [RiskLevel.unknown] agar Beranda tidak menampilkan "Rendah" menyesatkan.
  /// Untuk halaman Stratifikasi Risiko pakai `hasMeasurement: true` + `isPrimigravida`
  /// agar anamnesis tetap dinilai tanpa tensi.
  static RiskLevel computeRiskLevel({
    required int age,
    required HistoryType historyType,
    double? bmi,
    bool hasMeasurement = false,
    bool isPrimigravida = false,
  }) {
    if (!hasMeasurement) return RiskLevel.unknown;
    final highRisk = historyType == HistoryType.priorPreeclampsia ||
        historyType == HistoryType.hypertension ||
        age >= 40 ||
        (bmi != null && bmi >= 35);
    final mediumRisk = historyType == HistoryType.family ||
        isPrimigravida ||
        age > 35 ||
        (bmi != null && bmi > 30);
    if (highRisk) return RiskLevel.high;
    if (mediumRisk) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Penilaian anamnesis tanpa tensi — untuk halaman Stratifikasi Risiko.
  static RiskLevel riskFromAnamnesis({
    required int age,
    required HistoryType historyType,
    double? bmi,
    bool isPrimigravida = false,
  }) =>
      computeRiskLevel(
        age: age,
        historyType: historyType,
        bmi: bmi,
        hasMeasurement: true,
        isPrimigravida: isPrimigravida,
      );

  /// Indeks Massa Tubuh (IMT) saat ini.
  double? get bmi {
    if (heightCm <= 0) return null;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  /// BMI pra-kehamilan (pakai prePregnancyWeight/Height bila ada, fallback ke saat ini).
  double? get bmiPrePregnancy {
    final h = (prePregnancyHeight ?? heightCm);
    final w = (prePregnancyWeight ?? weightKg);
    if (h <= 0) return null;
    final m = h / 100;
    return w / (m * m);
  }

  /// Kategori BMI pra-hamil: kurus <18.5, normal 18.5-24.9, gemuk 25-29.9, obesitas >=30
  String get bmiCategory {
    final b = bmiPrePregnancy;
    if (b == null) return '-';
    if (b < 18.5) return 'kurus';
    if (b < 25) return 'normal';
    if (b < 30) return 'gemuk';
    return 'obesitas';
  }

  String get bmiCategoryLabel {
    switch (bmiCategory) {
      case 'kurus':
        return 'Kurus';
      case 'normal':
        return 'Normal';
      case 'gemuk':
        return 'Gemuk (Overweight)';
      case 'obesitas':
        return 'Obesitas';
      default:
        return '-';
    }
  }

  /// Batas kenaikan berat selama hamil berdasarkan BMI pra-hamil.
  String get weightGainRange {
    switch (bmiCategory) {
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

  String get bmiAdvice {
    switch (bmiCategory) {
      case 'kurus':
        return 'BMI kurus. Kejar gizi seimbang, target +12,5–18 kg selama hamil. Konsultasi bidan untuk suplementasi.';
      case 'normal':
        return 'BMI ideal 18,5–24,9. Pertahankan kenaikan 11,5–16 kg, makan bergizi & aktivitas ringan teratur.';
      case 'gemuk':
        return 'BMI gemuk. Batasi kenaikan 7–11,5 kg, kurangi makanan tinggi gula/garam, kontrol rutin.';
      case 'obesitas':
        return 'BMI obesitas. Kenaikan ketat 5–9 kg, butuh pemantauan ketat bidan/dokter untuk cegah preeklampsia.';
      default:
        return 'Lengkapi berat & tinggi pra-hamil untuk melihat saran.';
    }
  }

  /// Faktor risiko yang terpenuhi, untuk ditampilkan ke pengguna.
  List<String> riskFactors() {
    final factors = <String>[];
    if (hasPriorPreeclampsia || historyType == HistoryType.priorPreeclampsia) factors.add('Pernah preeklamsia');
    if (hasChronicHypertension || historyType == HistoryType.hypertension) factors.add('Hipertensi kronis');
    if (hasFamilyHistory || historyType == HistoryType.family) factors.add('Riwayat keluarga');
    if (isPrimigravida) factors.add('Hamil pertama (primigravida)');
    if (age > 35) factors.add('Usia > 35 tahun');
    final b = bmi;
    if (b != null && b > 30) factors.add('IMT ${b.toStringAsFixed(1)}');
    return factors;
  }

  bool get isPrimigravida => gravida == 1 && para == 0;

  /// Risk anamnesis (tanpa butuh tensi) — dipakai card Beranda & halaman Stratifikasi.
  /// Phase 2: pakai 4 bool (has_*) + isPrimigravida agar multi-faktor tidak lossy.
  RiskLevel get anamnesisRisk {
    // Jika 4 bool sudah terisi, pakai itu; fallback ke historyType single untuk data lama.
    final hasPrior = hasPriorPreeclampsia || historyType == HistoryType.priorPreeclampsia;
    final hasChronic = hasChronicHypertension || historyType == HistoryType.hypertension;
    final hasFamily = hasFamilyHistory || historyType == HistoryType.family;
    if (hasPrior || hasChronic || hasFamily || hasPriorPreeclampsia || hasChronicHypertension || hasFamilyHistory) {
      // Ada explicit bool → hitung via 4 faktor
      final high = hasPrior || hasChronic || age >= 40 || (bmi != null && bmi! >= 35);
      final medium = hasFamily || isPrimigravida || age > 35 || (bmi != null && bmi! > 30);
      if (high) return RiskLevel.high;
      if (medium) return RiskLevel.medium;
      return RiskLevel.low;
    }
    return Patient.riskFromAnamnesis(
      age: age,
      historyType: historyType,
      bmi: bmi,
      isPrimigravida: isPrimigravida,
    );
  }

  /// Rekomendasi konsultasi sesuai kategori risiko (FR-02) — selaras tabel stratifikasi.
  String get recommendation {
    switch (riskLevel) {
      case RiskLevel.unknown:
        return 'Belum ada pengukuran tensi. Lakukan pengukuran pertama untuk menilai risiko.';
      case RiskLevel.low:
        return 'Risiko rendah. Lanjutkan pola hidup sehat dan kontrol ANC rutin.';
      case RiskLevel.medium:
        return 'Risiko sedang. Konsultasikan dengan bidan untuk pemantauan lebih ketat.';
      case RiskLevel.high:
        return 'Risiko tinggi. Segera konsultasikan ke tenaga kesehatan untuk penanganan khusus.';
    }
  }

  /// Tindakan medis standar per kategori risiko (untuk tabel stratifikasi).
  static String actionFor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return 'Aspirin dosis rendah + pemantauan ketat + kontrol tekanan darah';
      case RiskLevel.medium:
        return 'Pertimbangkan aspirin bila ada ≥2 faktor sedang + pantau rutin tensi & protein urine';
      case RiskLevel.low:
        return 'Pemantauan rutin tensi & protein urine tiap ANC';
      case RiskLevel.unknown:
        return 'Lengkapi skrining untuk menilai';
    }
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? decodeDetail(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is String) {
        try {
          final d = jsonDecode(v);
          if (d is Map<String, dynamic>) return d;
        } catch (_) {}
      }
      return null;
    }

    return Patient(
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      age: (map['age'] as num).toInt(),
      heightCm: (map['height_cm'] as num).toDouble(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      gestationalWeeks: (map['gestational_weeks'] as num?)?.toInt(),
      dueDate: map['due_date'] == null
          ? null
          : DateTime.tryParse(map['due_date'] as String),
      lastSystolic: (map['last_systolic'] as num?)?.toInt(),
      lastDiastolic: (map['last_diastolic'] as num?)?.toInt(),
      historyType: HistoryType.fromValue(map['history_type'] as String?),
      riskLevel: RiskLevel.fromValue(map['risk_level'] as String?),
      phone: map['phone'] as String?,
      synced: (map['synced'] as int? ?? 0) == 1,
      nik: map['nik'] as String?,
      jknNo: map['jkn_no'] as String?,
      faskesTk1: map['faskes_tk1'] as String?,
      faskesRujukan: map['faskes_rujukan'] as String?,
      birthPlace: map['birth_place'] as String?,
      birthDate: map['birth_date'] == null ? null : DateTime.tryParse(map['birth_date'] as String),
      education: map['education'] as String?,
      occupation: map['occupation'] as String?,
      address: map['address'] as String?,
      bloodType: BloodType.fromValue(map['blood_type'] as String?),
      gravida: (map['gravida'] as num?)?.toInt(),
      para: (map['para'] as num?)?.toInt(),
      livingChildren: (map['living_children'] as num?)?.toInt(),
      miscarriageCount: (map['miscarriage_count'] as num?)?.toInt(),
      diseaseHistory: map['disease_history'] as String?,
      prePregnancyWeight: (map['pre_pregnancy_weight'] as num?)?.toDouble(),
      prePregnancyHeight: (map['pre_pregnancy_height'] as num?)?.toDouble(),
      hasPriorPreeclampsia: (map['has_prior_preeclampsia'] as int? ?? 0) == 1,
      hasChronicHypertension: (map['has_chronic_hypertension'] as int? ?? 0) == 1,
      hasFamilyHistory: (map['has_family_history'] as int? ?? 0) == 1,
      riskDetail: decodeDetail(map['risk_detail']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'gestational_weeks': gestationalWeeks,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'last_systolic': lastSystolic,
      'last_diastolic': lastDiastolic,
      'history_type': historyType.value,
      'risk_level': riskLevel.value,
      'phone': phone,
      'synced': synced ? 1 : 0,
      'nik': nik,
      'jkn_no': jknNo,
      'faskes_tk1': faskesTk1,
      'faskes_rujukan': faskesRujukan,
      'birth_place': birthPlace,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'education': education,
      'occupation': occupation,
      'address': address,
      'blood_type': bloodType?.value,
      'gravida': gravida,
      'para': para,
      'living_children': livingChildren,
      'miscarriage_count': miscarriageCount,
      'disease_history': diseaseHistory,
      'pre_pregnancy_weight': prePregnancyWeight,
      'pre_pregnancy_height': prePregnancyHeight,
      'has_prior_preeclampsia': hasPriorPreeclampsia ? 1 : 0,
      'has_chronic_hypertension': hasChronicHypertension ? 1 : 0,
      'has_family_history': hasFamilyHistory ? 1 : 0,
      'is_primigravida': isPrimigravida ? 1 : 0,
      'risk_detail': riskDetail == null ? null : jsonEncode(riskDetail),
    };
  }

  /// Payload untuk `PUT /api/v1/patient` (VPS sudah validasi nik 16 digit, blood_type, dll).
  /// Phase 2: kirim 4 faktor + is_primigravida + risk_detail (nullable, backward-compat).
  Map<String, dynamic> toSyncPayload() {
    return {
      'patient_uuid': uuid,
      'name': name,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'gestational_weeks': gestationalWeeks,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'last_systolic': lastSystolic,
      'last_diastolic': lastDiastolic,
      'history_type': historyType.value,
      'risk_level': riskLevel.value,
      'phone': phone,
      'nik': nik,
      'jkn_no': jknNo,
      'faskes_tk1': faskesTk1,
      'faskes_rujukan': faskesRujukan,
      'birth_place': birthPlace,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'education': education,
      'occupation': occupation,
      'address': address,
      'blood_type': bloodType?.value,
      'gravida': gravida,
      'para': para,
      'living_children': livingChildren,
      'miscarriage_count': miscarriageCount,
      'disease_history': diseaseHistory,
      'pre_pregnancy_weight': prePregnancyWeight,
      'pre_pregnancy_height': prePregnancyHeight,
      'has_prior_preeclampsia': hasPriorPreeclampsia,
      'has_chronic_hypertension': hasChronicHypertension,
      'has_family_history': hasFamilyHistory,
      'is_primigravida': isPrimigravida,
      'risk_detail': riskDetail,
    };
  }

  /// Parse dari `GET /api/v1/patient` VPS (snake_case, beberapa field mungkin null).
  factory Patient.fromApi(Map<String, dynamic> m, {required String fallbackUuid}) {
    Map<String, dynamic>? parseDetail(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is String) {
        try {
          final d = jsonDecode(v);
          if (d is Map<String, dynamic>) return d;
        } catch (_) {}
      }
      return null;
    }

    return Patient(
      uuid: (m['patient_uuid'] ?? m['uuid'] ?? fallbackUuid) as String,
      name: (m['name'] ?? '') as String,
      age: (m['age'] as num?)?.toInt() ?? 25,
      heightCm: (m['height_cm'] as num?)?.toDouble() ?? 160,
      weightKg: (m['weight_kg'] as num?)?.toDouble() ?? 55,
      gestationalWeeks: (m['gestational_weeks'] as num?)?.toInt(),
      dueDate: m['due_date'] == null ? null : DateTime.tryParse(m['due_date'] as String),
      lastSystolic: (m['last_systolic'] as num?)?.toInt(),
      lastDiastolic: (m['last_diastolic'] as num?)?.toInt(),
      historyType: HistoryType.fromValue(m['history_type'] as String?),
      riskLevel: RiskLevel.fromValue(m['risk_level'] as String?),
      phone: m['phone'] as String?,
      synced: true,
      nik: m['nik'] as String?,
      jknNo: m['jkn_no'] as String?,
      faskesTk1: m['faskes_tk1'] as String?,
      faskesRujukan: m['faskes_rujukan'] as String?,
      birthPlace: m['birth_place'] as String?,
      birthDate: m['birth_date'] == null ? null : DateTime.tryParse(m['birth_date'] as String),
      education: m['education'] as String?,
      occupation: m['occupation'] as String?,
      address: m['address'] as String?,
      bloodType: BloodType.fromValue(m['blood_type'] as String?),
      gravida: (m['gravida'] as num?)?.toInt(),
      para: (m['para'] as num?)?.toInt(),
      livingChildren: (m['living_children'] as num?)?.toInt(),
      miscarriageCount: (m['miscarriage_count'] as num?)?.toInt(),
      diseaseHistory: m['disease_history'] as String?,
      prePregnancyWeight: (m['pre_pregnancy_weight'] as num?)?.toDouble(),
      prePregnancyHeight: (m['pre_pregnancy_height'] as num?)?.toDouble(),
      hasPriorPreeclampsia: _boolFrom(m['has_prior_preeclampsia']),
      hasChronicHypertension: _boolFrom(m['has_chronic_hypertension']),
      hasFamilyHistory: _boolFrom(m['has_family_history']),
      riskDetail: parseDetail(m['risk_detail']),
    );
  }

  static bool _boolFrom(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}

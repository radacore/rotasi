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
enum RiskLevel {
  low('low', 'Rendah'),
  medium('medium', 'Sedang'),
  high('high', 'Tinggi');

  const RiskLevel(this.value, this.label);

  final String value;
  final String label;

  static RiskLevel fromValue(String? value) => RiskLevel.values.firstWhere(
        (e) => e.value == value,
        orElse: () => RiskLevel.low,
      );
}

/// Profil ibu hamil (FR-01). Sinkron ke `PUT /api/v1/patient`.
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
    this.riskLevel = RiskLevel.low,
    this.phone,
    this.synced = false,
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
    );
  }

  /// Skrining risiko otomatis (FR-02) dari biodata, berdasar
  /// kriteria NICE & KIA 2024:
  /// - tinggi: pernah preeklamsia, usia >= 40, IMT >= 35
  /// - sedang: hipertensi, riwayat turunan, usia > 35, IMT > 30
  static RiskLevel computeRiskLevel({
    required int age,
    required HistoryType historyType,
    double? bmi,
  }) {
    final highRisk = historyType == HistoryType.priorPreeclampsia ||
        age >= 40 ||
        (bmi != null && bmi >= 35);
    final mediumRisk = historyType == HistoryType.hypertension ||
        historyType == HistoryType.family ||
        age > 35 ||
        (bmi != null && bmi > 30);
    if (highRisk) return RiskLevel.high;
    if (mediumRisk) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Indeks Massa Tubuh (IMT) dihitung otomatis dari tinggi & berat.
  double? get bmi {
    if (heightCm <= 0) return null;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  /// Faktor risiko yang terpenuhi, untuk ditampilkan ke pengguna.
  List<String> riskFactors() {
    final factors = <String>[];
    if (historyType != HistoryType.none) factors.add(historyType.label);
    if (age > 35) factors.add('Usia > 35 tahun');
    final b = bmi;
    if (b != null && b > 30) factors.add('IMT ${b.toStringAsFixed(1)}');
    return factors;
  }

  /// Rekomendasi konsultasi sesuai kategori risiko (FR-02).
  String get recommendation {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Risiko rendah. Lanjutkan pola hidup sehat dan kontrol ANC rutin.';
      case RiskLevel.medium:
        return 'Risiko sedang. Konsultasikan dengan bidan untuk pemantauan lebih ketat.';
      case RiskLevel.high:
        return 'Risiko tinggi. Segera konsultasikan ke tenaga kesehatan untuk penanganan khusus.';
    }
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
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
    };
  }

  /// Payload untuk `PUT /api/v1/patient`.
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
    };
  }
}

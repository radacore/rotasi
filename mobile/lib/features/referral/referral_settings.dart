/// Pengaturan global untuk panduan rujukan (FR-10), sumber dari web admin.
class ReferralSettings {
  const ReferralSettings({
    this.appName = '',
    this.emergencyPhone = '',
    this.puskesmasName = '',
    this.puskesmasAddress = '',
    this.defaultWaMessage = '',
    this.rules = const ReferralRules(),
    this.updatedAt,
  });

  final String appName;
  final String emergencyPhone;
  final String puskesmasName;
  final String puskesmasAddress;
  final String defaultWaMessage;
  final ReferralRules rules;
  final DateTime? updatedAt;

  factory ReferralSettings.fromJson(Map<String, dynamic> json) {
    final rulesJson = json['referral_rules'] as Map<String, dynamic>?;
    DateTime? updated;
    final rawUpdated = json['updated_at'];
    if (rawUpdated is String && rawUpdated.isNotEmpty) {
      updated = DateTime.tryParse(rawUpdated);
    }
    return ReferralSettings(
      appName: json['app_name'] as String? ?? '',
      emergencyPhone: json['emergency_phone'] as String? ?? '',
      puskesmasName: json['puskesmas_name'] as String? ?? '',
      puskesmasAddress: json['puskesmas_address'] as String? ?? '',
      defaultWaMessage: json['default_wa_message'] as String? ?? '',
      rules: rulesJson == null
          ? const ReferralRules()
          : ReferralRules.fromJson(rulesJson),
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() => {
        'app_name': appName,
        'emergency_phone': emergencyPhone,
        'puskesmas_name': puskesmasName,
        'puskesmas_address': puskesmasAddress,
        'default_wa_message': defaultWaMessage,
        'referral_rules': rules.toJson(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// Aturan kapan harus segera ke faskes.
class ReferralRules {
  const ReferralRules({
    this.persistentColors = const ['orange', 'red'],
    this.symptomCheckTrigger = true,
    this.kickThreshold = 3,
  });

  final List<String> persistentColors;
  final bool symptomCheckTrigger;
  final int kickThreshold;

  factory ReferralRules.fromJson(Map<String, dynamic> json) {
    return ReferralRules(
      persistentColors: (json['persistent_colors'] as List? ?? const [])
          .cast<String>(),
      symptomCheckTrigger: json['symptom_check_trigger'] as bool? ?? true,
      kickThreshold: json['kick_threshold'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'persistent_colors': persistentColors,
        'symptom_check_trigger': symptomCheckTrigger,
        'kick_threshold': kickThreshold,
      };
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/referral/referral_settings.dart';

void main() {
  group('ReferralSettings', () {
    test('fromJson memetakan pengaturan global', () {
      final s = ReferralSettings.fromJson({
        'app_name': 'ROTASI',
        'emergency_phone': '119',
        'puskesmas_name': 'Puskesmas Sehat',
        'puskesmas_address': 'Jl. Merdeka 1',
        'default_wa_message': 'Halo',
        'referral_rules': {
          'persistent_colors': ['orange', 'red'],
          'symptom_check_trigger': true,
          'kick_threshold': 3,
        },
      });
      expect(s.emergencyPhone, '119');
      expect(s.puskesmasName, 'Puskesmas Sehat');
      expect(s.rules.persistentColors, ['orange', 'red']);
      expect(s.rules.symptomCheckTrigger, true);
      expect(s.rules.kickThreshold, 3);
    });

    test('fromJson dengan nilai kosong -> default', () {
      final s = ReferralSettings.fromJson({});
      expect(s.emergencyPhone, '');
      expect(s.rules.persistentColors, ['orange', 'red']);
      expect(s.rules.symptomCheckTrigger, true);
      expect(s.rules.kickThreshold, 3);
    });

    test('toJson/fromJson roundtrip', () {
      final s = ReferralSettings(
        emergencyPhone: '118',
        puskesmasName: 'Puskesmas A',
        rules: const ReferralRules(
          persistentColors: ['red'],
          symptomCheckTrigger: false,
          kickThreshold: 4,
        ),
      );
      final restored = ReferralSettings.fromJson(s.toJson());
      expect(restored.emergencyPhone, '118');
      expect(restored.rules.persistentColors, ['red']);
      expect(restored.rules.symptomCheckTrigger, false);
      expect(restored.rules.kickThreshold, 4);
    });
  });
}

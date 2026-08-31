import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/referral/referral_settings.dart';

void main() {
  group('ReferralSettings', () {
    test('fromJson memetakan pengaturan global + 4 nomor kontak', () {
      final s = ReferralSettings.fromJson({
        'app_name': 'ROTASI',
        'emergency_phone': '119',
        'ambulance_phone': '119',
        'homecare_phone': '112',
        'puskesmas_phone': '081343677797',
        'puskesmas_phone_alt': '0812417777718',
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
      expect(s.ambulancePhone, '119');
      expect(s.homecarePhone, '112');
      expect(s.puskesmasPhone, '081343677797');
      expect(s.puskesmasPhoneAlt, '0812417777718');
      expect(s.puskesmasName, 'Puskesmas Sehat');
      expect(s.rules.persistentColors, ['orange', 'red']);
      expect(s.rules.symptomCheckTrigger, true);
      expect(s.rules.kickThreshold, 3);
    });

    test('fromJson fallback ambulancePhone ke emergencyPhone', () {
      final s = ReferralSettings.fromJson({
        'emergency_phone': '119',
        'puskesmas_name': 'Puskesmas A',
      });
      expect(s.ambulancePhone, '119');
    });

    test('fromJson dengan nilai kosong -> default', () {
      final s = ReferralSettings.fromJson({});
      expect(s.emergencyPhone, '');
      expect(s.ambulancePhone, '');
      expect(s.homecarePhone, '');
      expect(s.rules.persistentColors, ['orange', 'red']);
      expect(s.rules.symptomCheckTrigger, true);
      expect(s.rules.kickThreshold, 3);
    });

    test('toJson/fromJson roundtrip 4 nomor kontak', () {
      final s = ReferralSettings(
        emergencyPhone: '119',
        ambulancePhone: '119',
        homecarePhone: '112',
        puskesmasPhone: '081343677797',
        puskesmasPhoneAlt: '0812417777718',
        puskesmasName: 'Puskesmas A',
        puskesmasAddress: 'Jl. Bongaya',
        rules: const ReferralRules(
          persistentColors: ['red'],
          symptomCheckTrigger: false,
          kickThreshold: 4,
        ),
      );
      final restored = ReferralSettings.fromJson(s.toJson());
      expect(restored.ambulancePhone, '119');
      expect(restored.homecarePhone, '112');
      expect(restored.puskesmasPhone, '081343677797');
      expect(restored.puskesmasPhoneAlt, '0812417777718');
      expect(restored.puskesmasAddress, 'Jl. Bongaya');
      expect(restored.rules.persistentColors, ['red']);
      expect(restored.rules.symptomCheckTrigger, false);
      expect(restored.rules.kickThreshold, 4);
    });
  });
}

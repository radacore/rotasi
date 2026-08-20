import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/measurement/bp_status.dart';

void main() {
  group('BpStatus.classify (AHA 2025, ambil kategori terburuk)', () {
    test('SYS <120 & DIA <80 -> Normal (hijau)', () {
      expect(BpStatus.classify(119, 79), BpStatus.normal);
      expect(BpStatus.classify(100, 60), BpStatus.normal);
    });

    test('SYS 120-129 & DIA <80 -> Waspada (kuning)', () {
      expect(BpStatus.classify(120, 79), BpStatus.elevated);
      expect(BpStatus.classify(129, 79), BpStatus.elevated);
    });

    test('SYS 130-139 ATAU DIA 80-89 -> Berisiko (oranye)', () {
      expect(BpStatus.classify(130, 79), BpStatus.stage1);
      expect(BpStatus.classify(129, 80), BpStatus.stage1);
      expect(BpStatus.classify(139, 89), BpStatus.stage1);
    });

    test('SYS >=140 ATAU DIA >=90 -> Bahaya (merah)', () {
      expect(BpStatus.classify(140, 89), BpStatus.crisis);
      expect(BpStatus.classify(139, 90), BpStatus.crisis);
      expect(BpStatus.classify(160, 100), BpStatus.crisis);
    });
  });

  group('BpStatus.fromCode', () {
    test('kode dikenal -> enum sesuai', () {
      expect(BpStatus.fromCode('green'), BpStatus.normal);
      expect(BpStatus.fromCode('yellow'), BpStatus.elevated);
      expect(BpStatus.fromCode('orange'), BpStatus.stage1);
      expect(BpStatus.fromCode('red'), BpStatus.crisis);
    });

    test('kode tidak dikenal/null -> normal', () {
      expect(BpStatus.fromCode(null), BpStatus.normal);
      expect(BpStatus.fromCode('biru'), BpStatus.normal);
    });
  });

  group('SessionCode', () {
    test('before jam 12 -> pagi', () {
      expect(SessionCode.fromHour(DateTime(2026, 8, 20, 8)), SessionCode.pagi);
    });

    test('jam 12 ke atas -> sore', () {
      expect(
        SessionCode.fromHour(DateTime(2026, 8, 20, 12)),
        SessionCode.sore,
      );
      expect(SessionCode.fromHour(DateTime(2026, 8, 20, 18)), SessionCode.sore);
    });

    test('fromValue roundtrip & fallback pagi', () {
      expect(SessionCode.fromValue('sore'), SessionCode.sore);
      expect(SessionCode.fromValue('lorem'), SessionCode.pagi);
      expect(SessionCode.fromValue(null), SessionCode.pagi);
    });
  });
}

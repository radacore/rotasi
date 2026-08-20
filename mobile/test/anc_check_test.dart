import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/anc_check/anc_check.dart';

void main() {
  const patientUuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  group('AncCheck', () {
    test('forDate membuat uuid baru tanpa ceklis', () {
      final c = AncCheck.forDate(
        patientUuid: patientUuid,
        visitedAt: DateTime(2026, 8, 20),
      );
      expect(c.uuid, isNotEmpty);
      expect(c.items, isEmpty);
      expect(c.checkedCount, 0);
      expect(c.totalItems, 10);
      expect(c.isChecked(AncItem.t1), false);
    });

    test('isChecked & checkedCount', () {
      final c = AncCheck(
        uuid: 'u1',
        patientUuid: patientUuid,
        visitedAt: DateTime(2026, 8, 20),
        items: const ['t1', 't2', 't3'],
      );
      expect(c.isChecked(AncItem.t1), true);
      expect(c.isChecked(AncItem.t10), false);
      expect(c.checkedCount, 3);
    });

    test('AncItem.fromCode', () {
      expect(AncItem.fromCode('t10'), AncItem.t10);
      expect(AncItem.fromCode('t5'), AncItem.t5);
      expect(AncItem.fromCode('tidak-ada'), AncItem.t1);
    });

    test('toMap/fromMap roundtrip', () {
      final c = AncCheck(
        uuid: 'u1',
        patientUuid: patientUuid,
        visitedAt: DateTime(2026, 8, 20),
        items: const ['t1', 't4', 't7'],
      );
      final restored = AncCheck.fromMap(c.toMap());
      expect(restored.uuid, 'u1');
      expect(restored.patientUuid, patientUuid);
      expect(restored.visitedAt, c.visitedAt);
      expect(restored.items, ['t1', 't4', 't7']);
      expect(restored.synced, false);
    });

    test('toSyncPayload sesuai kontrak /sync/anc', () {
      final c = AncCheck(
        uuid: 'u1',
        patientUuid: patientUuid,
        visitedAt: DateTime(2026, 8, 20),
        items: const ['t2', 't3', 't5'],
      );
      final payload = c.toSyncPayload();
      expect(payload['patient_uuid'], patientUuid);
      expect(payload['uuid'], 'u1');
      expect(payload['visited_at'], c.visitedAt.toIso8601String());
      expect(payload['t_items'], ['t2', 't3', 't5']);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/core/db/app_database.dart';
import 'package:rotasi_mobile/features/anc_check/anc_check.dart';
import 'package:rotasi_mobile/features/anc_check/anc_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.testDatabasePath = inMemoryDatabasePath;
  });

  const patientUuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  AncCheck build({String uuid = 'u1', DateTime? visitedAt, List<String> items = const ['t1', 't2']}) {
    return AncCheck(
      uuid: uuid,
      patientUuid: patientUuid,
      visitedAt: visitedAt ?? DateTime(2026, 8, 20, 9, 30),
      items: items,
    );
  }

  setUp(() async {
    await AppDatabase.reset();
  });

  tearDown(() async {
    await AppDatabase.close();
  });

  test('saveLocal + getByVisitedAt roundtrip', () async {
    final repo = AncRepository();
    final c = build();
    await repo.saveLocal(c);

    final stored = await repo.getByVisitedAt(DateTime(2026, 8, 20));
    expect(stored, isNotNull);
    expect(stored!.uuid, 'u1');
    expect(stored.items, ['t1', 't2']);
    expect(stored.synced, false);
  });

  test('getByVisitedAt memakai tanggal, bukan jam', () async {
    final repo = AncRepository();
    final c = build(visitedAt: DateTime(2026, 8, 20, 9, 30));
    await repo.saveLocal(c);

    final stored = await repo.getByVisitedAt(DateTime(2026, 8, 20, 23, 59));
    expect(stored, isNotNull);
    expect(stored!.uuid, 'u1');
  });

  test('getByVisitedAt tanggal berbeda -> null', () async {
    final repo = AncRepository();
    await repo.saveLocal(build());
    expect(await repo.getByVisitedAt(DateTime(2026, 8, 21)), isNull);
  });

  test('markSynced menandai synced = 1', () async {
    final repo = AncRepository();
    await repo.saveLocal(build());
    await repo.markSynced('u1');

    final stored = await repo.getByVisitedAt(DateTime(2026, 8, 20));
    expect(stored!.synced, true);
  });
}

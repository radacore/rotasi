import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/core/db/app_database.dart';
import 'package:rotasi_mobile/features/kick_count/kick_count.dart';
import 'package:rotasi_mobile/features/kick_count/kick_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.testDatabasePath = inMemoryDatabasePath;
  });

  const patientUuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  KickCount build({String? uuid}) {
    final k = KickCount.start(
      patientUuid: patientUuid,
      startedAt: DateTime(2026, 8, 20, 10),
    );
    final completed = KickCount.fromMap({
      ...k.toMap(),
      'kick_count': 4,
      'ended_at': DateTime(2026, 8, 20, 10, 30).toIso8601String(),
    }).complete();
    return uuid == null
        ? completed
        : KickCount.fromMap({...completed.toMap(), 'uuid': uuid});
  }

  setUp(() async {
    await AppDatabase.reset();
  });

  tearDown(() async {
    await AppDatabase.close();
  });

  test('saveLocal + getByUuid roundtrip', () async {
    final repo = KickRepository();
    final k = build();
    await repo.saveLocal(k);

    final stored = await repo.getByUuid(k.uuid);
    expect(stored, isNotNull);
    expect(stored!.patientUuid, patientUuid);
    expect(stored.kickCount, 4);
    expect(stored.isActive, true);
    expect(stored.synced, false);
  });

  test('getByUuid yang tidak ada -> null', () async {
    final repo = KickRepository();
    expect(
      await repo.getByUuid('ffffffff-0000-1111-2222-333333333333'),
      isNull,
    );
  });

  test('markSynced menandai synced = 1', () async {
    final repo = KickRepository();
    final k = build();
    await repo.saveLocal(k);

    await repo.markSynced(k.uuid);

    final stored = await repo.getByUuid(k.uuid);
    expect(stored!.synced, true);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/core/db/app_database.dart';
import 'package:rotasi_mobile/features/symptom_check/symptom_check.dart';
import 'package:rotasi_mobile/features/symptom_check/symptom_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.testDatabasePath = inMemoryDatabasePath;
  });

  const patientUuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  SymptomCheck build({
    String? uuid,
    DateTime? at,
    bool headache = true,
  }) {
    final s = SymptomCheck.daily(
      patientUuid: patientUuid,
      checkedAt: at ?? DateTime(2026, 8, 20, 9),
      headache: headache,
      blurredVision: false,
      epigastricPain: false,
      shortnessOfBreath: false,
    );
    return uuid == null
        ? s
        : SymptomCheck.fromMap({...s.toMap(), 'uuid': uuid});
  }

  setUp(() async {
    await AppDatabase.reset();
  });

  tearDown(() async {
    await AppDatabase.close();
  });

  test('saveForDate menulis record baru + getByDate mengembalikannya',
      () async {
    final repo = SymptomRepository();
    final s = build();
    await repo.saveForDate(s);

    final stored = await repo.getByDate(DateTime(2026, 8, 20));
    expect(stored, isNotNull);
    expect(stored!.uuid, s.uuid);
    expect(stored.patientUuid, patientUuid);
    expect(stored.headache, true);
    expect(stored.synced, false);
  });

  test('saveForDate hari yang sama membuat record baru (tidak upsert)', () async {
    final repo = SymptomRepository();
    final s1 = build(uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
    await repo.saveForDate(s1);

    final s2 = build(
      uuid: 'ffffffff-0000-1111-2222-333333333333',
      headache: false,
    );
    await repo.saveForDate(s2);

    final history = await repo.history();
    expect(history.length, 2, reason: 'satu hari bisa 5x per jam seperti web');
    expect(history.first.uuid, s2.uuid, reason: 'terbaru di atas DESC');
    final latest = await repo.getByDate(DateTime(2026, 8, 20));
    expect(latest!.uuid, s2.uuid);
    expect(latest.headache, false);
  });

  test('getByDate tanggal berbeda -> null', () async {
    final repo = SymptomRepository();
    await repo.saveForDate(build());
    expect(await repo.getByDate(DateTime(2026, 8, 21)), isNull);
  });

  test('markSynced menandai synced = 1', () async {
    final repo = SymptomRepository();
    final s = build();
    await repo.saveForDate(s);

    await repo.markSynced(s.uuid);

    final stored = await repo.getByDate(DateTime(2026, 8, 20));
    expect(stored!.synced, true);
  });
}

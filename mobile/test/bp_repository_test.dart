import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/core/db/app_database.dart';
import 'package:rotasi_mobile/features/measurement/bp_measurement.dart';
import 'package:rotasi_mobile/features/measurement/bp_repository.dart';
import 'package:rotasi_mobile/features/measurement/bp_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.testDatabasePath = inMemoryDatabasePath;
  });

  const patientUuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  BpMeasurement build({
    String? uuid,
    DateTime? at,
    SessionCode session = SessionCode.pagi,
    int s1 = 120,
    int d1 = 80,
    int s2 = 124,
    int d2 = 78,
  }) {
    final m = BpMeasurement.record(
      patientUuid: patientUuid,
      measuredAt: at ?? DateTime.utc(2026, 8, 20, 8, 30),
      sessionCode: session,
      systolic1: s1,
      diastolic1: d1,
      systolic2: s2,
      diastolic2: d2,
    );
    return uuid == null ? m : BpMeasurement.fromMap({...m.toMap(), 'uuid': uuid});
  }

  setUp(() async {
    await AppDatabase.reset();
  });

  tearDown(() async {
    await AppDatabase.close();
  });

  test('saveLocal lalu last() mengembalikan data sama', () async {
    final repo = BpRepository();
    final m = build(at: DateTime.utc(2026, 8, 20, 8, 30));
    await repo.saveLocal(m);

    final last = await repo.last();
    expect(last, isNotNull);
    expect(last!.uuid, m.uuid);
    expect(last.patientUuid, patientUuid);
    expect(last.sessionCode, SessionCode.pagi);
    expect(last.systolic1, 120);
    expect(last.diastolic2, 78);
    expect(last.avgSystolic, 122);
    expect(last.avgDiastolic, 79);
    expect(last.status, BpStatus.elevated);
    expect(last.synced, false);
  });

  test('last() mengembalikan yang terbaru berdasarkan measured_at', () async {
    final repo = BpRepository();
    final older = build(
      uuid: '11111111-2222-3333-4444-555555555555',
      at: DateTime.utc(2026, 8, 20, 8, 30),
    );
    final newer = build(
      uuid: '66666666-7777-8888-9999-000000000000',
      at: DateTime.utc(2026, 8, 20, 18, 30),
      session: SessionCode.sore,
      s1: 150,
      d1: 95,
      s2: 152,
      d2: 96,
    );
    await repo.saveLocal(older);
    await repo.saveLocal(newer);

    final last = await repo.last();
    expect(last!.uuid, newer.uuid);
    expect(last.sessionCode, SessionCode.sore);
    expect(last.status, BpStatus.crisis);
  });

  test('saveLocal memberi tahu listener (auto-update Beranda/Tren)', () async {
    final repo = BpRepository();
    var notified = 0;
    repo.addListener(() => notified++);

    await repo.saveLocal(build());

    expect(notified, 1);
  });

  test('markSynced menandai synced = 1', () async {
    final repo = BpRepository();
    final m = build();
    await repo.saveLocal(m);

    await repo.markSynced(m.uuid);

    final last = await repo.last();
    expect(last!.synced, true);
  });

  test('last() tanpa data -> null', () async {
    final repo = BpRepository();
    expect(await repo.last(), isNull);
  });

  test('history() urut kronologis dan dibatasi limit (FR-05)', () async {
    final repo = BpRepository();
    final d1 = build(
      uuid: '11111111-2222-3333-4444-555555555555',
      at: DateTime.utc(2026, 8, 20, 8, 30),
    );
    final d2 = build(
      uuid: '66666666-7777-8888-9999-000000000000',
      at: DateTime.utc(2026, 8, 21, 8, 30),
    );
    final d3 = build(
      uuid: 'aaaaaaaa-bbbb-0000-1111-222222222222',
      at: DateTime.utc(2026, 8, 22, 18, 30),
      session: SessionCode.sore,
    );
    await repo.saveLocal(d2);
    await repo.saveLocal(d1);
    await repo.saveLocal(d3);

    final all = await repo.history();
    expect(all.map((m) => m.uuid), [d1.uuid, d2.uuid, d3.uuid]);

    final limited = await repo.history(limit: 2);
    expect(limited.length, 2);
    expect(limited.first.uuid, d1.uuid);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/core/db/app_database.dart';
import 'package:rotasi_mobile/features/registration/patient.dart';
import 'package:rotasi_mobile/features/registration/patient_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.testDatabasePath = inMemoryDatabasePath;
  });

  test('saveLocal + getLocal roundtrip ke SQLite', () async {
    final repository = PatientRepository();
    final patient = Patient.newLocal(
      name: 'Sitti',
      age: 28,
      heightCm: 155,
      weightKg: 52.5,
      gestationalWeeks: 24,
      historyType: HistoryType.none,
      phone: '62812',
    );

    await repository.saveLocal(patient);
    final stored = await repository.getLocal();

    expect(stored, isNotNull);
    expect(stored!.uuid, patient.uuid);
    expect(stored.name, 'Sitti');
    expect(stored.age, 28);
    expect(stored.heightCm, 155);
    expect(stored.weightKg, 52.5);
    expect(stored.gestationalWeeks, 24);
    expect(stored.riskLevel, RiskLevel.low);
    expect(stored.synced, isFalse);
  });
}

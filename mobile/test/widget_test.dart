import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rotasi_mobile/core/sync/sync_service.dart';
import 'package:rotasi_mobile/app.dart';
import 'package:rotasi_mobile/features/measurement/bp_measurement.dart';
import 'package:rotasi_mobile/features/measurement/bp_repository.dart';
import 'package:rotasi_mobile/features/measurement/measurement_page.dart';
import 'package:rotasi_mobile/features/measurement/rotasi_wheel.dart';
import 'package:rotasi_mobile/features/measurement/bp_status.dart';
import 'package:rotasi_mobile/features/measurement/trend_page.dart';
import 'package:rotasi_mobile/features/symptom_check/symptom_check.dart';
import 'package:rotasi_mobile/features/symptom_check/symptom_check_page.dart';
import 'package:rotasi_mobile/features/symptom_check/symptom_repository.dart';
import 'package:rotasi_mobile/features/kick_count/kick_count.dart';
import 'package:rotasi_mobile/features/kick_count/kick_count_page.dart';
import 'package:rotasi_mobile/features/kick_count/kick_repository.dart';
import 'package:rotasi_mobile/features/anc_check/anc_check.dart';
import 'package:rotasi_mobile/features/anc_check/anc_check_page.dart';
import 'package:rotasi_mobile/features/anc_check/anc_guide_page.dart';
import 'package:rotasi_mobile/features/anc_check/anc_repository.dart';
import 'package:rotasi_mobile/features/education/booklet.dart';
import 'package:rotasi_mobile/features/education/booklet_repository.dart';
import 'package:rotasi_mobile/features/education/education_page.dart';
import 'package:rotasi_mobile/features/referral/referral_page.dart';
import 'package:rotasi_mobile/features/referral/referral_settings.dart';
import 'package:rotasi_mobile/features/referral/setting_repository.dart';
import 'package:rotasi_mobile/features/midwife/midwife.dart';
import 'package:rotasi_mobile/features/midwife/midwife_page.dart';
import 'package:rotasi_mobile/features/midwife/midwife_repository.dart';
import 'package:rotasi_mobile/features/breathing/breathing_page.dart';
import 'package:rotasi_mobile/features/reminder/reminder_page.dart';
import 'package:rotasi_mobile/features/reminder/reminder_repository.dart';
import 'package:rotasi_mobile/features/reminder/reminder_settings.dart';
import 'package:rotasi_mobile/core/notifications/notification_scheduler.dart';
import 'package:rotasi_mobile/features/registration/patient.dart';
import 'package:rotasi_mobile/features/registration/patient_repository.dart';
import 'package:rotasi_mobile/features/registration/registration_page.dart';
import 'package:rotasi_mobile/features/home/home_shell.dart';
import 'package:rotasi_mobile/features/home/home_page.dart';

class FakePatientRepository extends PatientRepository {
  FakePatientRepository({this.initial, this.syncResult = true});

  Patient? stored;
  final Patient? initial;
  final bool syncResult;
  int saveCount = 0;
  int syncCount = 0;

  @override
  Future<Patient?> getLocal() async => stored ?? initial;

  @override
  Future<void> saveLocal(Patient patient) async {
    stored = patient;
    saveCount++;
  }

  @override
  Future<bool> sync(Patient patient) async {
    syncCount++;
    return syncResult;
  }

  @override
  Future<void> markSynced(String uuid) async {}
}

class FakeBpRepository extends BpRepository {
  BpMeasurement? stored;
  List<BpMeasurement> storedHistory = [];
  int saveCount = 0;
  int syncCount = 0;

  @override
  Future<BpMeasurement?> last() async => stored;

  @override
  Future<List<BpMeasurement>> history({int? limit}) async => storedHistory;

  @override
  Future<void> saveLocal(BpMeasurement measurement) async {
    stored = measurement;
    storedHistory = [...storedHistory, measurement];
    saveCount++;
    notifyListeners();
  }

  @override
  Future<bool> sync(BpMeasurement measurement) async {
    syncCount++;
    return true;
  }

  @override
  Future<void> markSynced(String uuid) async {}

  @override
  Future<Patient?> localPatient() async => null;
}

Future<void> _pumpApp(
  WidgetTester tester,
  PatientRepository repo, {
  BpRepository? bpRepo,
  SyncService? syncService,
}) async {
  await tester.pumpWidget(RotasiApp(
    repository: repo,
    bpRepository: bpRepo,
    syncService: syncService,
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StartupGate', () {
    testWidgets('first launch -> halaman registrasi biodata', (tester) async {
      await _pumpApp(tester, FakePatientRepository());

      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.text('Nama ibu'), findsOneWidget);
    });

    testWidgets('profil sudah ada -> langsung beranda', (tester) async {
      final existing = Patient.newLocal(
        name: 'Sitti',
        age: 28,
        heightCm: 155,
        weightKg: 52,
      );
      await _pumpApp(
        tester,
        FakePatientRepository(initial: existing),
        bpRepo: FakeBpRepository(),
      );

      expect(find.text('Halo, Sitti,', findRichText: true), findsOneWidget);
      expect(find.text('semoga sehat selalu'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Ukur Tensi'),
        findsOneWidget,
      );
    });

    testWidgets('beranda tidak menampilkan card skrining risiko (FR-02)',
        (tester) async {
      final existing = Patient.newLocal(
        name: 'Nur',
        age: 38,
        heightCm: 155,
        weightKg: 80,
      );
      await _pumpApp(
        tester,
        FakePatientRepository(initial: existing),
        bpRepo: FakeBpRepository(),
      );

      expect(find.text('Skrining Risiko Otomatis'), findsNothing);
    });

    testWidgets('beranda menampilkan tombol mengambang Hubungi Bidan',
        (tester) async {
      final existing = Patient.newLocal(
        name: 'Sitti',
        age: 28,
        heightCm: 155,
        weightKg: 52,
      );
      await _pumpApp(
        tester,
        FakePatientRepository(initial: existing),
        bpRepo: FakeBpRepository(),
      );

      expect(find.bySemanticsLabel('Hubungi Bidan'), findsOneWidget);
    });

    testWidgets('first launch (Selamat Datang) menyembunyikan Hubungi Bidan',
        (tester) async {
      await _pumpApp(tester, FakePatientRepository());

      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.bySemanticsLabel('Hubungi Bidan'), findsNothing);
    });
  });

  group('RegistrationPage', () {
    Future<void> pumpRegistration(
      WidgetTester tester,
      PatientRepository repo, {
      BpRepository? bpRepo,
    }) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: RegistrationPage(repository: repo, bpRepository: bpRepo)),
      );
    }

    testWidgets('submit kosong menampilkan error dan tidak pindah halaman',
        (tester) async {
      final repo = FakePatientRepository();
      await pumpRegistration(tester, repo);

      await tester.tap(find.text('Simpan dan Mulai'));
      await tester.pumpAndSettle();

      expect(find.text('Nama wajib diisi'), findsOneWidget);
      expect(repo.saveCount, 0);
    });

    testWidgets('submit valid menyimpan lokal lalu masuk beranda',
        (tester) async {
      final repo = FakePatientRepository();
      final bpRepo = FakeBpRepository();
      await pumpRegistration(tester, repo, bpRepo: bpRepo);

      await tester.enterText(find.byType(TextFormField).at(0), 'Sitti');
      await tester.enterText(find.byType(TextFormField).at(1), '28');
      await tester.enterText(find.byType(TextFormField).at(3), '155');
      await tester.enterText(find.byType(TextFormField).at(4), '52');
      await tester.tap(find.text('Simpan dan Mulai'));
      await tester.pumpAndSettle();

      expect(repo.saveCount, 1);
      expect(repo.syncCount, 1);
      expect(find.text('Halo, Sitti,', findRichText: true), findsOneWidget);
      expect(find.text('semoga sehat selalu'), findsOneWidget);
    });

    testWidgets('riwayat hipertensi tersimpan ke model', (tester) async {
      final repo = FakePatientRepository();
      final bpRepo = FakeBpRepository();
      await pumpRegistration(tester, repo, bpRepo: bpRepo);

      await tester.enterText(find.byType(TextFormField).at(0), 'Rahma');
      await tester.enterText(find.byType(TextFormField).at(1), '24');
      await tester.enterText(find.byType(TextFormField).at(3), '160');
      await tester.enterText(find.byType(TextFormField).at(4), '55');
      await tester.tap(find.text('Hipertensi'));
      await tester.tap(find.text('Simpan dan Mulai'));
      await tester.pumpAndSettle();

      expect(repo.stored!.historyType, HistoryType.hypertension);
      expect(repo.stored!.riskLevel, RiskLevel.medium);
    });
  });

  group('MeasurementPage (FR-03 + FR-04)', () {
    Future<void> pumpMeasurement(WidgetTester tester, BpRepository bpRepo) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MeasurementPage(
            repository: bpRepo,
            patientUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          ),
        ),
      );
    }

    testWidgets('input tidak valid -> snackbar tanpa menyimpan',
        (tester) async {
      final bpRepo = FakeBpRepository();
      await pumpMeasurement(tester, bpRepo);

      await tester.enterText(find.byType(TextField).at(0), '999');
      await tester.enterText(find.byType(TextField).at(1), '80');
      await tester.tap(find.text('Simpan Pengukuran 1'));
      await tester.pump();

      expect(find.textContaining('Periksa nilai tekanan darah'), findsOneWidget);
      expect(bpRepo.saveCount, 0);
    });

    testWidgets('alur lengkap: 2x ukur, countdown, hasil, simpan',
        (tester) async {
      final bpRepo = FakeBpRepository();
      await pumpMeasurement(tester, bpRepo);

      // Pengukuran 1.
      await tester.enterText(find.byType(TextField).at(0), '120');
      await tester.enterText(find.byType(TextField).at(1), '80');
      await tester.tap(find.text('Simpan Pengukuran 1'));
      await tester.pump();

      // Countdown 1 menit berjalan, pengukuran 2 belum muncul.
      expect(find.textContaining('Istirahat sebentar'), findsOneWidget);
      expect(find.text('Simpan Pengukuran 2'), findsNothing);

      // Lewatkan 61 detik.
      await tester.pump(const Duration(seconds: 61));
      await tester.pump();

      expect(find.textContaining('Istirahat sebentar'), findsNothing);
      expect(find.text('Simpan Pengukuran 2'), findsOneWidget);

      // Pengukuran 2 -> rata-rata 122/79 = Waspada (kuning).
      await tester.enterText(find.byType(TextField).at(2), '124');
      await tester.enterText(find.byType(TextField).at(3), '78');
      await tester.tap(find.text('Simpan Pengukuran 2'));
      await tester.pumpAndSettle();

      expect(find.byType(RotasiWheel), findsOneWidget);
      expect(find.text('Rata-rata 122/79'), findsOneWidget);
      expect(find.text('Waspada'), findsOneWidget);

      await tester.tap(find.text('Simpan Hasil'));
      await tester.pumpAndSettle();

      expect(bpRepo.saveCount, 1);
      expect(bpRepo.syncCount, 1);
      expect(bpRepo.stored, isNotNull);
      expect(bpRepo.stored!.sessionCode.value, 'pagi');
      expect(bpRepo.stored!.status.label, 'Waspada');
    });
  });

  group('TrendPage (FR-05)', () {
    Future<void> pumpTrend(WidgetTester tester, BpRepository bpRepo) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: TrendPage(repository: bpRepo)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tanpa data -> pesan kosong', (tester) async {
      await pumpTrend(tester, FakeBpRepository());
      expect(find.text('Belum ada data pengukuran.'), findsOneWidget);
    });

    testWidgets('dengan data -> grafik sistolik & diastolik + legenda',
        (tester) async {
      final bpRepo = FakeBpRepository()
        ..storedHistory = [
          BpMeasurement.record(
            patientUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
            measuredAt: DateTime(2026, 8, 20, 8, 0),
            sessionCode: SessionCode.pagi,
            systolic1: 120,
            diastolic1: 80,
            systolic2: 122,
            diastolic2: 78,
          ),
          BpMeasurement.record(
            patientUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
            measuredAt: DateTime(2026, 8, 20, 18, 0),
            sessionCode: SessionCode.sore,
            systolic1: 140,
            diastolic1: 90,
            systolic2: 142,
            diastolic2: 92,
          ),
        ];
      await pumpTrend(tester, bpRepo);

      expect(find.text('Sistolik (atas)'), findsOneWidget);
      expect(find.text('Diastolik (bawah)'), findsOneWidget);
      expect(find.text('Catatan'), findsNWidgets(2));
    });
  });

  group('SymptomCheckPage (FR-06)', () {
    Future<void> pumpSymptom(
      WidgetTester tester,
      SymptomRepository repo,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: SymptomCheckPage(repository: repo)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tandai gejala -> imbauan faskes muncul, simpan & keluar',
        (tester) async {
      final repo = FakeSymptomRepository();
      await pumpSymptom(tester, repo);

      // Awalnya belum ada gejala, tanpa imbauan.
      expect(find.textContaining('Ada gejala'), findsNothing);

      // Tandai 2 gejala.
      await tester.tap(find.text('Sakit kepala hebat'));
      await tester.tap(find.text('Sesak napas'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ada gejala'), findsOneWidget);

      await tester.tap(find.text('Simpan Ceklis'));
      await tester.pumpAndSettle();

      expect(repo.saveCount, 1);
      expect(repo.syncCount, 1);
      expect(repo.stored, isNotNull);
      expect(repo.stored!.headache, true);
      expect(repo.stored!.shortnessOfBreath, true);
      expect(repo.stored!.blurredVision, false);
      expect(find.text('Cek Gejala Harian'), findsNothing);
    });
  });

  group('KickCountPage (FR-07)', () {
    Future<void> pumpKick(WidgetTester tester, KickRepository repo) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KickCountPage(
            repository: repo,
            patientUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('ketukan cukup -> Bayi Aktif, simpan tersimpan',
        (tester) async {
      final repo = FakeKickRepository();
      await pumpKick(tester, repo);

      await tester.tap(find.text('Mulai Hitung'));
      await tester.pump();

      // 3 ketukan -> aktif.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Ketuk saat bayi bergerak'));
        await tester.pump();
      }
      expect(find.text('Gerakan: 3'), findsOneWidget);

      await tester.tap(find.text('Selesai Pengamatan'));
      await tester.pumpAndSettle();

      expect(find.text('Bayi Aktif'), findsOneWidget);
      expect(find.text('3 gerakan dalam 30 menit'), findsOneWidget);

      await tester.tap(find.text('Simpan Hasil'));
      await tester.pumpAndSettle();

      expect(repo.saveCount, 1);
      expect(repo.syncCount, 1);
      expect(repo.stored, isNotNull);
      expect(repo.stored!.kickCount, 3);
      expect(repo.stored!.isActive, true);
    });

    testWidgets('ketukan kurang -> Bayi Kurang Aktif', (tester) async {
      final repo = FakeKickRepository();
      await pumpKick(tester, repo);

      await tester.tap(find.text('Mulai Hitung'));
      await tester.pump();

      await tester.tap(find.text('Ketuk saat bayi bergerak'));
      await tester.pump();

      await tester.tap(find.text('Selesai Pengamatan'));
      await tester.pumpAndSettle();

      expect(find.text('Bayi Kurang Aktif'), findsOneWidget);
      expect(find.textContaining('hubungi bidan'), findsOneWidget);
    });

    testWidgets('timer 30 menit selesai otomatis', (tester) async {
      final repo = FakeKickRepository();
      await pumpKick(tester, repo);

      await tester.tap(find.text('Mulai Hitung'));
      await tester.pump();

      await tester.pump(const Duration(minutes: 30));
      await tester.pump();

      expect(find.text('Bayi Kurang Aktif'), findsOneWidget);
    });
  });

  group('AncCheckPage (FR-08)', () {
    Future<void> pumpAnc(WidgetTester tester, AncRepository repo) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: AncCheckPage(
            repository: repo,
            patientUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tandai beberapa pemeriksaan, simpan & keluar', (tester) async {
      final repo = FakeAncRepository();
      await pumpAnc(tester, repo);

      expect(find.text('0 dari 10 pemeriksaan ditandai'), findsOneWidget);

      await tester.tap(find.text('T1 · Ukur Berat Badan'));
      await tester.pump();
      await tester.tap(find.text('T3 · Ukur Tinggi Fundus'));
      await tester.pump();
      await tester.ensureVisible(find.text('T5 · Hitung DJJ'));
      await tester.tap(find.text('T5 · Hitung DJJ'));
      await tester.pump();

      expect(find.text('3 dari 10 pemeriksaan ditandai'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Simpan Ceklis'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('Simpan Ceklis'));
      await tester.pumpAndSettle();

      expect(repo.saveCount, 1);
      expect(repo.syncCount, 1);
      expect(repo.stored, isNotNull);
      expect(repo.stored!.items, ['t1', 't3', 't5']);
      expect(find.text('Ceklis 10T ANC'), findsNothing);
    });

    testWidgets('kunjungan yang sudah ada dimuat ulang', (tester) async {
      final repo = FakeAncRepository();
      repo.existing = AncCheck(
        uuid: 'existing',
        patientUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        visitedAt: DateTime(2026, 8, 20),
        items: const ['t2', 't7'],
      );
      await pumpAnc(tester, repo);

      expect(find.text('2 dari 10 pemeriksaan ditandai'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Simpan Ceklis'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('Simpan Ceklis'));
      await tester.pumpAndSettle();
      expect(repo.saveCount, 1);
      expect(repo.stored!.items, ['t2', 't7']);
    });
  });

  group('AncGuidePage (panduan pemeriksaan kehamilan)', () {
    testWidgets('menampilkan intro, standar 10T, lab, dan USG', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: AncGuidePage()),
      );

      expect(find.text('Panduan Pemeriksaan'), findsOneWidget);
      expect(find.text('6x'), findsOneWidget);
      expect(find.text('10T'), findsOneWidget);
      expect(
        find.text('Pemeriksaan Fisik Klinis & Medis (Standar 10 T)'),
        findsOneWidget,
      );
      expect(find.text('T10'), findsOneWidget);
      expect(
        find.text('Skrining Penyakit Menular (Triple Elimination)'),
        findsOneWidget,
      );
      expect(find.text('USG Trimester 3 (sekitar 32–36 minggu)'),
          findsOneWidget);
    });
  });

  group('EducationPage (FR-09)', () {
    Future<void> pumpEdu(WidgetTester tester, BookletRepository repo) async {
      await tester.pumpWidget(
        MaterialApp(home: EducationPage(repository: repo)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('booklet terunduh -> status tersedia offline + Buka Booklet',
        (tester) async {
      final repo = FakeBookletRepository(booklets: [
        Booklet(
          id: 1,
          title: 'Panduan Ibu Hamil',
          version: '1.0',
          fileUrl: 'http://x/b.pdf',
          localPath: '/tmp/b.pdf',
          downloadedAt: DateTime(2026, 8, 1),
        ),
      ]);
      await pumpEdu(tester, repo);

      expect(find.text('Panduan Ibu Hamil'), findsOneWidget);
      expect(find.text('Tersedia offline'), findsOneWidget);
      expect(find.text('Buka Booklet'), findsOneWidget);
    });

    testWidgets('versi baru -> tombol Unduh Booklet, setelah unduh jadi Buka Booklet',
        (tester) async {
      final repo = FakeBookletRepository(booklets: [
        Booklet(
          id: 2,
          title: 'Panduan Ibu Hamil',
          version: '2.0',
          fileUrl: 'http://x/b.pdf',
        ),
      ], needsDownload: {2});
      await pumpEdu(tester, repo);

      expect(find.text('Perlu diunduh'), findsOneWidget);
      expect(find.text('Unduh Booklet'), findsOneWidget);

      repo.downloadResult = Booklet(
        id: 2,
        title: 'Panduan Ibu Hamil',
        version: '2.0',
        fileUrl: 'http://x/b.pdf',
        localPath: '/tmp/b.pdf',
        downloadedAt: DateTime(2026, 8, 2),
      );

      await tester.tap(find.text('Unduh Booklet'));
      await tester.pumpAndSettle();

      expect(repo.downloadCount, 1);
      expect(find.text('Tersedia offline'), findsOneWidget);
      expect(find.text('Buka Booklet'), findsOneWidget);
    });

    testWidgets('menampilkan semua booklet aktif', (tester) async {
      final repo = FakeBookletRepository(booklets: [
        Booklet(
          id: 1,
          title: 'Booklet Nutrisi',
          version: '1.0',
          fileUrl: 'http://x/nutrisi.pdf',
          localPath: '/tmp/nutrisi.pdf',
          downloadedAt: DateTime(2026, 8, 1),
        ),
        Booklet(
          id: 2,
          title: 'Booklet Stres',
          version: '1.0',
          fileUrl: 'http://x/stres.pdf',
        ),
      ], needsDownload: {2});
      await pumpEdu(tester, repo);

      expect(find.text('Booklet Nutrisi'), findsOneWidget);
      expect(find.text('Booklet Stres'), findsOneWidget);
      expect(find.text('Buka Booklet'), findsOneWidget);
      expect(find.text('Unduh Booklet'), findsOneWidget);
    });

    testWidgets('tanpa booklet -> ajakan periksa pembaruan', (tester) async {
      final repo = FakeBookletRepository(booklets: []);
      await pumpEdu(tester, repo);

      expect(find.text('Belum ada booklet aktif'), findsOneWidget);
      expect(find.text('Periksa Pembaruan'), findsOneWidget);
    });
  });

  group('ReferralPage (FR-10)', () {
    Future<void> pumpReferral(
      WidgetTester tester,
      SettingRepository repo,
      Future<void> Function(String) onLaunch,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ReferralPage(repository: repo, onLaunch: onLaunch)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan disclaimer, kriteria rujukan, dan kontak darurat',
        (tester) async {
      final calls = <String>[];
      final repo = FakeSettingRepository(
        settings: ReferralSettings(
          emergencyPhone: '119',
          puskesmasName: 'Puskesmas Sehat',
          puskesmasAddress: 'Jl. Merdeka 1',
          rules: const ReferralRules(
            persistentColors: ['orange', 'red'],
            symptomCheckTrigger: true,
            kickThreshold: 3,
          ),
        ),
      );
      await pumpReferral(tester, repo, (url) async => calls.add(url));

      expect(
        find.textContaining('bukan pengganti pemeriksaan ANC'),
        findsOneWidget,
      );
      expect(find.text('Kapan harus segera ke faskes'), findsOneWidget);
      expect(
        find.textContaining('Tekanan darah oranye/merah berulang'),
        findsOneWidget,
      );
      expect(
        find.textContaining('minimal satu tanda bahaya'),
        findsOneWidget,
      );
      expect(find.textContaining('Gerakan janin kurang aktif'), findsOneWidget);
      expect(find.text('119'), findsOneWidget);
      expect(find.text('Puskesmas Sehat'), findsOneWidget);

      await tester.tap(find.text('Panggil'));
      await tester.pumpAndSettle();
      expect(calls, ['tel:119']);
    });

    testWidgets('tanpa pengaturan -> fallback offline tetap tampil',
        (tester) async {
      final repo = FakeSettingRepository(settings: null);
      await pumpReferral(tester, repo, (url) async {});

      // Fallback offline-first: tetap tampil data default, bukan empty.
      expect(find.text('Belum ada panduan rujukan'), findsNothing);
      expect(find.text('119'), findsOneWidget);
      expect(find.text('Puskesmas Barombong'), findsOneWidget);
    });
  });

  group('MidwifePage (FR-11)', () {
    Future<void> pumpMidwife(
      WidgetTester tester,
      MidwifeRepository repo, {
      Future<void> Function(String)? onLaunch,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MidwifePage(
            repository: repo,
            messageBuilder: () async => 'Saya Siti. Tekanan darah oranye.',
            onLaunch: onLaunch,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('daftar bidan tampil dan Chat membuka wa.me',
        (tester) async {
      final calls = <String>[];
      final repo = FakeMidwifeRepository(midwives: const [
        Midwife(id: 1, name: 'Bidan Rini', role: 'Bidan Desa', phone: '08123'),
        Midwife(id: 2, name: 'Bidan Sari', role: 'Bidan', phone: '+62 811'),
      ]);
      await pumpMidwife(tester, repo, onLaunch: (url) async => calls.add(url));

      expect(find.text('Bidan Rini'), findsOneWidget);
      expect(find.text('Bidan Desa'), findsOneWidget);
      expect(find.text('Bidan Sari'), findsOneWidget);

      await tester.tap(find.text('Chat').first);
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      final uri = Uri.parse(calls.first);
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.pathSegments, ['08123']);
      expect(uri.queryParameters['text'],
          contains('Halo Bidan Bidan Rini'));
      expect(uri.queryParameters['text'], contains('Siti'));
    });

    testWidgets('tanpa daftar -> fallback bidan default tetap tampil',
        (tester) async {
      final repo = FakeMidwifeRepository(midwives: const []);
      await pumpMidwife(tester, repo);

      // Fallback offline-first: MidwifePage pakai default Lusi bila kosong.
      expect(find.text('Belum ada daftar bidan'), findsNothing);
      expect(find.text('Lusi'), findsOneWidget);
    });
  });

  group('BreathingPage (FR-12)', () {
    Future<void> pumpBreath(
      WidgetTester tester, {
      Duration duration = const Duration(minutes: 15),
    }) async {
      await tester.pumpWidget(
        MaterialApp(home: BreathingPage(duration: duration)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('setup: pilih durasi lalu mulai', (tester) async {
      await pumpBreath(tester);

      expect(find.text('5 menit'), findsOneWidget);
      expect(find.text('10 menit'), findsOneWidget);
      expect(find.text('15 menit'), findsOneWidget);

      await tester.tap(find.text('5 menit'));
      await tester.pump();
      expect(find.text('Mulai Latihan (5 menit)'), findsOneWidget);

      await tester.tap(find.text('Mulai Latihan (5 menit)'));
      await tester.pump();
      expect(find.text('Tarik Napas'), findsOneWidget);
    });

    testWidgets('irama 4-2-6: tarik -> tahan -> buang', (tester) async {
      await pumpBreath(tester, duration: const Duration(seconds: 24));

      await tester.tap(find.textContaining('Mulai Latihan'));
      await tester.pump();
      expect(find.text('Tarik Napas'), findsOneWidget);

      // 4 detik tarik (t=1..4).
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Tarik Napas'), findsOneWidget);

      // Masuk tahan (t=4..6).
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Tahan'), findsOneWidget);

      // Masuk buang (t=6..12).
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Buang Napas'), findsOneWidget);

      // Siklus berikutnya kembali tarik.
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Tarik Napas'), findsOneWidget);
    });

    testWidgets('hitungan mundur selesai otomatis', (tester) async {
      await pumpBreath(tester, duration: const Duration(seconds: 12));

      await tester.tap(find.textContaining('Mulai Latihan'));
      await tester.pump();

      // Majukan sampai selesai (12 detik + tick terakhir).
      await tester.pump(const Duration(seconds: 12));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Latihan selesai'), findsOneWidget);
      expect(find.text('Latihan Lagi'), findsOneWidget);
    });

    testWidgets('Selesai menghentikan latihan kembali ke setup',
        (tester) async {
      await pumpBreath(tester, duration: const Duration(seconds: 60));

      await tester.tap(find.textContaining('Mulai Latihan'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Durasi latihan'), findsOneWidget);
      expect(find.textContaining('Mulai Latihan'), findsOneWidget);
    });
  });

  group('HomePage Sinkron (FR-13)', () {
    Future<void> pumpHome(
      WidgetTester tester, {
      required FakeSyncService sync,
    }) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final existing = Patient.newLocal(
        name: 'Sitti',
        age: 28,
        heightCm: 155,
        weightKg: 52,
      );
      await _pumpApp(
        tester,
        FakePatientRepository(initial: existing),
        bpRepo: FakeBpRepository(),
        syncService: sync,
      );
    }

    testWidgets('semua tersinkron menampilkan konfirmasi', (tester) async {
      final sync = FakeSyncService(
        summary: const SyncSummary(sent: 3, failed: 0),
      );
      await pumpHome(tester, sync: sync);

      await tester.tap(find.text('Sinkron'));
      await tester.pumpAndSettle();

      expect(sync.callCount, 1);
      expect(find.text('Sinkron selesai: 3 data terkirim.'), findsOneWidget);
    });

    testWidgets('sebagian gagal menampilkan peringatan', (tester) async {
      final sync = FakeSyncService(
        summary: const SyncSummary(sent: 1, failed: 2),
      );
      await pumpHome(tester, sync: sync);

      await tester.tap(find.text('Sinkron'));
      await tester.pumpAndSettle();

      expect(sync.callCount, 1);
      expect(
        find.text('Sinkron selesai: 1 terkirim, 2 gagal (dicoba lagi nanti).'),
        findsOneWidget,
      );
    });

    testWidgets('tidak ada data baru menampilkan status terbaru',
        (tester) async {
      final sync = FakeSyncService();
      await pumpHome(tester, sync: sync);

      await tester.tap(find.text('Sinkron'));
      await tester.pumpAndSettle();

      expect(sync.callCount, 1);
      expect(find.text('Semua data sudah tersinkron.'), findsOneWidget);
    });
  });

  group('Beranda auto-refresh (opsi 1)', () {
    testWidgets('menyimpan pengukuran langsung memperbarui status card',
        (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final bpRepo = FakeBpRepository();
      final existing = Patient.newLocal(
        name: 'Sitti',
        age: 28,
        heightCm: 155,
        weightKg: 52,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            repository: FakePatientRepository(initial: existing),
            bpRepository: bpRepo,
            syncService: FakeSyncService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada pengukuran'), findsOneWidget);

      await bpRepo.saveLocal(
        BpMeasurement.record(
          patientUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          measuredAt: DateTime(2026, 8, 20, 8, 0),
          sessionCode: SessionCode.pagi,
          systolic1: 120,
          diastolic1: 80,
          systolic2: 124,
          diastolic2: 78,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada pengukuran'), findsNothing);
      expect(find.text('Terakhir: 122/79'), findsOneWidget);
    });
  });

  group('Tren auto-refresh (opsi 1)', () {
    testWidgets('menyimpan pengukuran langsung memperbarui grafik tren',
        (tester) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final bpRepo = FakeBpRepository();
      await tester.pumpWidget(MaterialApp(home: TrendPage(repository: bpRepo)));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada data pengukuran.'), findsOneWidget);

      await bpRepo.saveLocal(
        BpMeasurement.record(
          patientUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          measuredAt: DateTime(2026, 8, 20, 8, 0),
          sessionCode: SessionCode.pagi,
          systolic1: 120,
          diastolic1: 80,
          systolic2: 124,
          diastolic2: 78,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada data pengukuran.'), findsNothing);
      expect(find.text('Sistolik (atas)'), findsOneWidget);
    });
  });

  group('ReminderPage (FR-14)', () {
    Future<void> pumpReminder(
      WidgetTester tester, {
      FakeReminderRepository? repo,
      FakeNotificationScheduler? scheduler,
    }) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderPage(repository: repo, scheduler: scheduler),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('aktifkan lalu simpan menjadwalkan pagi & sore',
        (tester) async {
      final scheduler = FakeNotificationScheduler();
      final repo = FakeReminderRepository();
      await pumpReminder(tester, repo: repo, scheduler: scheduler);

      await tester.tap(find.text('Aktifkan pengingat'));
      await tester.pump();
      await tester.tap(find.text('Simpan Pengaturan'));
      await tester.pumpAndSettle();

      expect(scheduler.scheduled, hasLength(2));
      expect(scheduler.scheduled.first.id, 1);
      expect(scheduler.scheduled.first.hour, 7);
      expect(scheduler.scheduled.first.minute, 0);
      expect(scheduler.scheduled.last.id, 2);
      expect(scheduler.scheduled.last.hour, 18);
      expect(scheduler.scheduled.last.minute, 0);
      expect(repo.saved!.enabled, isTrue);
      expect(
        find.text('Pengingat diaktifkan untuk pagi & sore.'),
        findsOneWidget,
      );
    });

    testWidgets('menggunakan waktu yang sudah disimpan sebelumnya',
        (tester) async {
      final scheduler = FakeNotificationScheduler();
      final repo = FakeReminderRepository(
        initial: const ReminderSettings(
          enabled: true,
          morning: TimeOfDay(hour: 6, minute: 30),
          evening: TimeOfDay(hour: 19, minute: 15),
        ),
      );
      await pumpReminder(tester, repo: repo, scheduler: scheduler);

      await tester.tap(find.text('Simpan Pengaturan'));
      await tester.pumpAndSettle();

      expect(scheduler.scheduled, hasLength(2));
      expect(scheduler.scheduled.first.hour, 6);
      expect(scheduler.scheduled.first.minute, 30);
      expect(scheduler.scheduled.last.hour, 19);
      expect(scheduler.scheduled.last.minute, 15);
    });

    testWidgets('nonaktif lalu simpan membatalkan jadwal', (tester) async {
      final scheduler = FakeNotificationScheduler();
      final repo = FakeReminderRepository(
        initial: const ReminderSettings(enabled: true),
      );
      await pumpReminder(tester, repo: repo, scheduler: scheduler);

      await tester.tap(find.text('Aktifkan pengingat'));
      await tester.pump();
      await tester.tap(find.text('Simpan Pengaturan'));
      await tester.pumpAndSettle();

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelled, containsAll([1, 2]));
      expect(repo.saved!.enabled, isFalse);
      expect(find.text('Pengingat dimatikan.'), findsOneWidget);
    });
  });

  group('HomeShell navigasi (bottom bar)', () {
    Future<void> pumpShell(WidgetTester tester) async {
      final patient = Patient.newLocal(
        name: 'Sitti',
        age: 28,
        heightCm: 155,
        weightKg: 52,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeShell(
            repository: FakePatientRepository(initial: patient),
            bpRepository: FakeBpRepository(),
            syncService: FakeSyncService(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan 5 menu bottom navigation', (tester) async {
      await pumpShell(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      for (final label in [
        'Beranda',
        'Ukur Tensi',
        'Tren',
        'Pantau',
        'Edukasi',
      ]) {
        expect(find.text(label), findsWidgets);
      }
    });

    testWidgets('berpindah antar tab membuka halaman terkait', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Tren'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tren Tekanan Darah'), findsOneWidget);

      await tester.tap(find.text('Pantau'));
      await tester.pumpAndSettle();
      expect(find.text('Cek Gejala Harian'), findsOneWidget);

      await tester.tap(find.text('Edukasi'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Pustaka Edukasi'), findsOneWidget);
    });

    testWidgets('ikon Lainnya di AppBar membuka menu terkategori', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.byTooltip('Lainnya'));
      await tester.pumpAndSettle();

      expect(find.text('Data & Profil'), findsOneWidget);
      expect(find.text('Kesehatan & Kebiasaan'), findsOneWidget);
      expect(find.text('Bantuan & Kontak'), findsOneWidget);
      expect(find.text('Data Ibu'), findsOneWidget);
      expect(find.text('Latihan Napas'), findsOneWidget);
      expect(find.text('Rujukan & Darurat'), findsOneWidget);
    });
  });
}

class FakeMidwifeRepository extends MidwifeRepository {
  FakeMidwifeRepository({required this.midwives});

  List<Midwife> midwives;

  @override
  Future<List<Midwife>> getLocal() async => midwives;

  @override
  Future<List<Midwife>> fetchRemote() async => midwives;

  @override
  Future<List<Midwife>?> ensureSeeded() async => null;
}

class FakeSettingRepository extends SettingRepository {
  FakeSettingRepository({this.settings});

  ReferralSettings? settings;

  @override
  Future<ReferralSettings?> getLocal() async => settings;

  @override
  Future<ReferralSettings?> fetchRemote() async => settings;

  @override
  Future<ReferralSettings?> ensureSeeded() async => null;
}

class FakeBookletRepository extends BookletRepository {
  FakeBookletRepository({
    this.booklets = const [],
    this.needsDownload = const <int>{},
  });

  List<Booklet> booklets;
  Set<int> needsDownload;
  Booklet? downloadResult;
  int downloadCount = 0;

  @override
  Future<List<Booklet>> getAllLocal() async => booklets;

  @override
  Future<({List<Booklet> booklets, Set<int> needsDownload})> fetchAll() async =>
      (booklets: booklets, needsDownload: needsDownload);

  @override
  Future<Booklet?> download(Booklet meta) async {
    downloadCount++;
    final result = downloadResult ?? meta.copyWith(localPath: '/tmp/downloaded.pdf');
    booklets = [
      for (final b in booklets) if (b.id == result.id) result else b,
    ];
    return result;
  }

  @override
  Future<Booklet?> ensureSeeded() async => null;
}

class FakeAncRepository extends AncRepository {
  AncCheck? stored;
  AncCheck? existing;
  int saveCount = 0;
  int syncCount = 0;

  @override
  Future<Patient?> localPatient() async => null;

  @override
  Future<AncCheck?> getByVisitedAt(DateTime visitedAt) async => existing;

  @override
  Future<void> saveLocal(AncCheck check) async {
    stored = check;
    saveCount++;
  }

  @override
  Future<bool> sync(AncCheck check) async {
    syncCount++;
    return true;
  }

  @override
  Future<void> markSynced(String uuid) async {}
}

class FakeKickRepository extends KickRepository {
  KickCount? stored;
  int saveCount = 0;
  int syncCount = 0;

  @override
  Future<Patient?> localPatient() async => null;

  @override
  Future<void> saveLocal(KickCount kick) async {
    stored = kick;
    saveCount++;
  }

  @override
  Future<KickCount?> getByUuid(String uuid) async => stored;

  @override
  Future<bool> sync(KickCount kick) async {
    syncCount++;
    return true;
  }

  @override
  Future<void> markSynced(String uuid) async {}
}

class FakeSyncService extends SyncService {
  FakeSyncService({this.summary = const SyncSummary(sent: 0, failed: 0)});

  SyncSummary summary;
  int callCount = 0;

  @override
  Future<SyncSummary> syncAll() async {
    callCount++;
    return summary;
  }
}

class FakeSymptomRepository extends SymptomRepository {
  SymptomCheck? stored;
  int saveCount = 0;
  int syncCount = 0;

  @override
  Future<Patient?> localPatient() async => null;

  @override
  Future<SymptomCheck?> getByDate(DateTime date) async => stored;

  @override
  Future<void> saveForDate(SymptomCheck check) async {
    stored = check;
    saveCount++;
  }

  @override
  Future<bool> sync(SymptomCheck check) async {
    syncCount++;
    return true;
  }

  @override
  Future<void> markSynced(String uuid) async {}
}

class FakeReminderRepository extends ReminderRepository {
  FakeReminderRepository({this.initial});

  ReminderSettings? initial;
  ReminderSettings? saved;

  @override
  Future<ReminderSettings?> getLocal() async => initial;

  @override
  Future<void> save(ReminderSettings settings) async {
    saved = settings;
  }
}

class FakeNotificationScheduler extends NotificationScheduler {
  final List<({int id, int hour, int minute, String title})> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    scheduled.add((id: id, hour: hour, minute: minute, title: title));
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> cancelAll() async {}
}

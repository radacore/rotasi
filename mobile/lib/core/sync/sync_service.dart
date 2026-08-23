import '../../features/anc_check/anc_check.dart';
import '../../features/anc_check/anc_repository.dart';
import '../../features/kick_count/kick_count.dart';
import '../../features/kick_count/kick_repository.dart';
import '../../features/measurement/bp_measurement.dart';
import '../../features/measurement/bp_repository.dart';
import '../../features/education/booklet_repository.dart';
import '../../features/midwife/midwife_repository.dart';
import '../../features/referral/setting_repository.dart';
import '../../features/registration/patient.dart';
import '../../features/registration/patient_repository.dart';
import '../../features/symptom_check/symptom_check.dart';
import '../../features/symptom_check/symptom_repository.dart';

/// Ringkasan hasil sinkronisasi (FR-13).
class SyncSummary {
  const SyncSummary({required this.sent, required this.failed});

  final int sent;
  final int failed;

  bool get hasError => failed > 0;
}

/// Sinkronisasi data lokal ke server saat online (FR-13).
///
/// Urutan: profil pasien → tekanan darah → ceklis gejala → hitungan gerakan
/// janin → ceklis 10T. Setiap record memakai UUID client-side sebagai kunci
/// idempoten, sehingga sinkronisasi ulang tidak menduplikasi data. Gagal
/// (offline/error) tidak menghapus data; record tetap tersimpan dan dicoba
/// lagi pada sinkronisasi berikutnya.
class SyncService {
  SyncService({
    PatientRepository? patients,
    BpRepository? bp,
    SymptomRepository? symptoms,
    KickRepository? kicks,
    AncRepository? anc,
    SettingRepository? settings,
    MidwifeRepository? midwives,
    BookletRepository? booklets,
  })  : _patients = patients ?? PatientRepository(),
        _bp = bp ?? BpRepository(),
        _symptoms = symptoms ?? SymptomRepository(),
        _kicks = kicks ?? KickRepository(),
        _anc = anc ?? AncRepository(),
        _settings = settings ?? SettingRepository(),
        _midwives = midwives ?? MidwifeRepository(),
        _booklets = booklets ?? BookletRepository();

  final PatientRepository _patients;
  final BpRepository _bp;
  final SymptomRepository _symptoms;
  final KickRepository _kicks;
  final AncRepository _anc;
  final SettingRepository _settings;
  final MidwifeRepository _midwives;
  final BookletRepository _booklets;

  Future<SyncSummary> syncAll() async {
    var sent = 0;
    var failed = 0;

    for (final p in await _patients.unsynced()) {
      if (await _patients.sync(p)) {
        sent++;
      } else {
        failed++;
      }
    }
    for (final m in await _bp.unsynced()) {
      if (await _bp.sync(m)) {
        sent++;
      } else {
        failed++;
      }
    }
    for (final s in await _symptoms.unsynced()) {
      if (await _symptoms.sync(s)) {
        sent++;
      } else {
        failed++;
      }
    }
    for (final k in await _kicks.unsynced()) {
      if (await _kicks.sync(k)) {
        sent++;
      } else {
        failed++;
      }
    }
    for (final a in await _anc.unsynced()) {
      if (await _anc.sync(a)) {
        sent++;
      } else {
        failed++;
      }
    }

    return SyncSummary(sent: sent, failed: failed);
  }

  /// Tarik konfigurasi terbaru dari web (down-sync, offline-first).
  ///
  /// Dipanggil setelah `syncAll` saat online dan saat app resume — data tetap
  /// tampil offline, perubahan di web akan otomatis ter-cache dan terlihat di
  /// Panduan Rujukan / Bidan / Pustaka Edukasi tanpa buka halaman tersebut.
  /// Pustaka diunduh senyap (auto-download) bila versi/file berubah.
  Future<void> pullRemoteConfig() async {
    await Future.wait([
      _settings.refreshInBackground(),
      _midwives.refreshInBackground(),
      _booklets.refreshInBackground(),
    ]);
  }
}

/// Kelompok tipe data untuk repo *fake* pada tes (FR-13).
typedef UnsyncedData = ({
  List<Patient> patients,
  List<BpMeasurement> bp,
  List<SymptomCheck> symptoms,
  List<KickCount> kicks,
  List<AncCheck> anc,
});

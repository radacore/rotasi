import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'sync_service.dart';

/// Sinkronisasi otomatis saat online (FR-13).
///
/// Memanggil [SyncService.syncAll] saat app dibuka dan setiap kali koneksi
/// internet kembali tersedia. Senyap tanpa notifikasi UI — tombol "Sinkron"
/// manual di Beranda tetap menampilkan ringkasan.
class AutoSync {
  AutoSync({SyncService? syncService, Connectivity? connectivity})
      : _sync = syncService ?? SyncService(),
        _connectivity = connectivity ?? Connectivity();

  final SyncService _sync;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;
  bool _wasOnline = false;

  /// Memulai sinkronisasi awal dan memantau perubahan koneksi.
  Future<void> start() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _wasOnline = _online(results);
      if (_wasOnline) await _syncSilently();
    } catch (_) {
      // Plugin tidak tersedia (mis. di lingkungan uji); tidak apa-apa.
    }
    try {
      _sub = _connectivity.onConnectivityChanged.listen(
        _onChanged,
        onError: (_) {},
      );
    } catch (_) {
      // Abaikan bila pemantauan tidak tersedia.
    }
  }

  void _onChanged(List<ConnectivityResult> results) {
    final online = _online(results);
    if (online && !_wasOnline) {
      _syncSilently();
    }
    _wasOnline = online;
  }

  static bool _online(List<ConnectivityResult> results) => results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );

  /// Dipanggil saat app kembali foreground — segarkan konfigurasi rujukan.
  Future<void> onResume() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (_online(results)) await _syncSilently();
    } catch (_) {}
  }

  Future<void> _syncSilently() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _sync.syncAll();
      await _sync.pullRemoteConfig();
    } catch (_) {
      // Offline/error: data tetap tersimpan, dicoba lagi berikutnya.
    } finally {
      _syncing = false;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}

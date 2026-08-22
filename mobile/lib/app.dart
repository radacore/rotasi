import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/sync/sync_service.dart';
import 'features/home/home_shell.dart';
import 'features/measurement/bp_repository.dart';
import 'features/midwife/contact_fab.dart';
import 'features/registration/patient.dart';
import 'features/registration/patient_repository.dart';
import 'features/registration/registration_page.dart';
import 'features/splash/splash_page.dart';

class RotasiApp extends StatefulWidget {
  const RotasiApp({
    super.key,
    this.repository,
    this.bpRepository,
    this.syncService,
    this.splashMinDuration = const Duration(milliseconds: 3400),
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;
  final SyncService? syncService;
  /// Durasi minimal splash terlihat (animasi 3000ms + hold 400ms). 0 untuk test.
  final Duration splashMinDuration;

  @override
  State<RotasiApp> createState() => _RotasiAppState();
}

class _RotasiAppState extends State<RotasiApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _fabVisibility = ContactFabVisibility();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROTASI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: _navigatorKey,
      navigatorObservers: [_fabVisibility],
      builder: (context, child) => Stack(
        children: [
          ?child,
          ContactFabOverlay(
            visibility: _fabVisibility,
            navigatorKey: _navigatorKey,
          ),
        ],
      ),
      home: StartupGate(
        repository: widget.repository,
        bpRepository: widget.bpRepository,
        syncService: widget.syncService,
        fabVisibility: _fabVisibility,
        splashMinDuration: widget.splashMinDuration,
      ),
    );
  }
}

/// Menentukan halaman awal: splash -> registrasi biodata (first-launch) atau Beranda.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    this.repository,
    this.bpRepository,
    this.syncService,
    this.fabVisibility,
    this.splashMinDuration = const Duration(milliseconds: 3400),
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;
  final SyncService? syncService;
  final ContactFabVisibility? fabVisibility;
  final Duration splashMinDuration;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final PatientRepository _repository;
  late final BpRepository _bpRepository;
  late final Future<Patient?> _initFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PatientRepository();
    _bpRepository = widget.bpRepository ?? BpRepository();
    // Tahan splash minimal splashMinDuration agar animasi logo tengah->kiri
    // + teks Rotasi selesai, sekaligus load profil (offline-first).
    _initFuture = Future.wait([
      _repository.getLocal(),
      Future.delayed(widget.splashMinDuration),
    ]).then((list) => list[0] as Patient?);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Patient?>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashPage();
        }
        final hasProfile = snapshot.data != null;
        // Jadwalkan setelah build agar tidak trigger ValueListenableBuilder
        // di dalam FutureBuilder build (setState-during-build).
        final hidden = !hasProfile;
        if (widget.fabVisibility?.registrationHidden != hidden) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.fabVisibility?.setRegistrationHidden(hidden);
          });
        }
        return hasProfile
            ? HomeShell(
                repository: _repository,
                bpRepository: _bpRepository,
                syncService: widget.syncService,
              )
            : RegistrationPage(
                repository: _repository,
                bpRepository: _bpRepository,
              );
      },
    );
  }

  @override
  void dispose() {
    widget.fabVisibility?.setRegistrationHidden(false);
    super.dispose();
  }
}

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/sync/sync_service.dart';
import 'features/home/home_shell.dart';
import 'features/measurement/bp_repository.dart';
import 'features/midwife/contact_fab.dart';
import 'features/registration/patient.dart';
import 'features/registration/patient_repository.dart';
import 'features/registration/registration_page.dart';

class RotasiApp extends StatelessWidget {
  const RotasiApp({
    super.key,
    this.repository,
    this.bpRepository,
    this.syncService,
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;
  final SyncService? syncService;

  @override
  Widget build(BuildContext context) {
    final navigatorKey = GlobalKey<NavigatorState>();
    final fabVisibility = ContactFabVisibility();
    return MaterialApp(
      title: 'ROTASI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      navigatorObservers: [fabVisibility],
      builder: (context, child) => Stack(
        children: [
          ?child,
          ContactFabOverlay(
            visibility: fabVisibility,
            navigatorKey: navigatorKey,
          ),
        ],
      ),
      home: StartupGate(
        repository: repository,
        bpRepository: bpRepository,
        syncService: syncService,
      ),
    );
  }
}

/// Menentukan halaman awal: registrasi biodata (first-launch) atau Beranda.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    this.repository,
    this.bpRepository,
    this.syncService,
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;
  final SyncService? syncService;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final PatientRepository _repository;
  late final BpRepository _bpRepository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PatientRepository();
    _bpRepository = widget.bpRepository ?? BpRepository();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Patient?>(
      future: _repository.getLocal(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final hasProfile = snapshot.data != null;
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
}

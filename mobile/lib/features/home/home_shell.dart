import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sync/auto_sync.dart';
import '../../core/sync/sync_service.dart';
import '../education/education_page.dart';
import '../measurement/bp_repository.dart';
import '../measurement/trend_page.dart';
import '../registration/patient_repository.dart';
import 'home_page.dart';
import 'monitor_page.dart';

/// Cangkang aplikasi dengan bottom navigation (4 menu utama).
///
/// Tiap tab membawa navigator sendiri agar navigasi internal (mis. hasil
/// pengukuran) tetap terisolasi dan state tiap tab tidak hilang saat berpindah.
/// Tab "Tekanan Darah" menggabungkan alur ukur tensi + tren (gabungan FR-03/FR-05).
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.repository,
    this.bpRepository,
    this.syncService,
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;
  final SyncService? syncService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  final Set<int> _visited = {0};
  final _navKeys = List<GlobalKey<NavigatorState>>.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final AutoSync _autoSync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoSync = AutoSync(syncService: widget.syncService);
    _autoSync.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoSync.onResume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSync.dispose();
    super.dispose();
  }

  late final List<Widget> _pages = [
    HomePage(
      repository: widget.repository,
      bpRepository: widget.bpRepository,
    ),
    TrendPage(repository: widget.bpRepository),
    const MonitorPage(),
    const EducationPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _pages.length; i++)
              if (_visited.contains(i))
                Navigator(
                  key: _navKeys[i],
                  onGenerateRoute: (_) =>
                      MaterialPageRoute(builder: (_) => _pages[i]),
                )
              else
                const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            if (i == _index) {
              _navKeys[i].currentState?.popUntil((r) => r.isFirst);
              return;
            }
            setState(() {
              _index = i;
              _visited.add(i);
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Tekanan Darah',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart),
              label: 'Pantau',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Edukasi',
            ),
          ],
        ),
      ),
    );
  }
}

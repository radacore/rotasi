import 'package:flutter/material.dart';

import '../education/booklet_viewer_page.dart';
import 'midwife_page.dart';

/// Nama route halaman Hubungi Bidan, dipakai untuk menyembunyikan tombol
/// mengambang di atas screen itu sendiri.
const midwifeRouteName = '/hubungi-bidan';

/// Route registrasi awal (Selamat Datang) — FAB disembunyikan di sini.
const registrationRouteName = '/registration';

/// Hijau resmi WhatsApp.
const whatsappGreen = Color(0xFF25D366);

/// Melacak route aktif untuk menyembunyikan tombol mengambang saat berada
/// di halaman Hubungi Bidan atau saat ada dialog/bottom sheet di atas.
class ContactFabVisibility extends NavigatorObserver {
  /// Awalnya sembunyikan agar tidak kedip di loading first-launch.
  final ValueNotifier<bool> visible = ValueNotifier(false);
  final List<Route<dynamic>> _stack = [];
  bool registrationHidden = true;

  /// Dipanggil StartupGate saat di layar Selamat Datang (first-launch).
  void setRegistrationHidden(bool hidden) {
    registrationHidden = hidden;
    _sync();
  }

  void _sync() {
    if (registrationHidden) {
      visible.value = false;
      return;
    }
    if (_stack.isEmpty) {
      visible.value = true;
      return;
    }
    final top = _stack.last;
    final hide = (top is ModalRoute && !top.opaque) ||
        top.settings.name == midwifeRouteName ||
        top.settings.name == bookletViewerRouteName ||
        top.settings.name == registrationRouteName;
    visible.value = !hide;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _stack.remove(oldRoute);
    if (newRoute != null) _stack.add(newRoute);
    _sync();
  }
}

/// Tombol mengambang "Hubungi Bidan" berlogo WhatsApp yang muncul di
/// setiap screen, disembunyikan otomatis di halaman Hubungi Bidan itu sendiri
/// serta saat dialog/bottom sheet terbuka.
class ContactFabOverlay extends StatelessWidget {
  const ContactFabOverlay({
    super.key,
    required this.visibility,
    required this.navigatorKey,
  });

  final ContactFabVisibility visibility;
  final GlobalKey<NavigatorState> navigatorKey;

  void _open(BuildContext context) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: midwifeRouteName),
        builder: (_) => const MidwifePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visibility.visible,
      builder: (context, show, _) {
        if (!show) return const SizedBox.shrink();
        // Di atas bottom navigation (tinggi 80) + safe area bawah.
        final bottomOffset =
            MediaQuery.paddingOf(context).bottom + 80 + 12;
        return Positioned(
          right: 16,
          bottom: bottomOffset,
          child: _FabButton(onTap: () => _open(context)),
        );
      },
    );
  }
}

class _FabButton extends StatelessWidget {
  const _FabButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hubungi Bidan',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: whatsappGreen,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/whatsapp.png',
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Intro ucapan selamat datang yang tampil setelah animasi logo splash.
///
/// Menjelaskan arti ROTASI (ROda panTAu tenSI) dan manfaatnya memantau
/// tekanan darah ibu hamil untuk mencegah preeklamsia. Muncul di setiap
/// pembukaan aplikasi, lalu otomatis lanjut ke Registrasi/Beranda setelah
/// [duration].
class WelcomeIntroPage extends StatefulWidget {
  const WelcomeIntroPage({
    super.key,
    required this.onContinue,
    this.duration = const Duration(seconds: 3),
  });

  final VoidCallback onContinue;
  final Duration duration;

  @override
  State<WelcomeIntroPage> createState() => _WelcomeIntroPageState();
}

class _WelcomeIntroPageState extends State<WelcomeIntroPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onContinue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 92,
                    height: 92,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.monitor_heart_outlined,
                          color: AppColors.sun, size: 46),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Selamat Datang di ROTASI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      height: 1.2,
                      color: Colors.white,
                    ),
                    children: const [
                      TextSpan(
                        text: 'RO',
                        style: TextStyle(color: AppColors.sun, fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: 'da '),
                      TextSpan(
                        text: 'pan',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'TA',
                        style: TextStyle(color: AppColors.sun, fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: 'u '),
                      TextSpan(
                        text: 'ten',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'SI',
                        style: TextStyle(color: AppColors.sun, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'ROTASI akan memudahkan ibu hamil memantau status tekanan darahnya untuk mencegah terjadinya preeklamsia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

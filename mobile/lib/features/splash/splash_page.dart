import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Splash animasi: logo tengah -> geser kiri + teks Rotasi.
/// Dipakai sebagai handoff dari native splash (#0C4A6E) agar tidak kedip.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _entranceScale;
  late final Animation<double> _logoSize;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleScale;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    // Logo napas dulu di tengah (pop-in elastis), lalu pelan mengecil geser kiri.
    _entranceScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.18, curve: Curves.elasticOut),
      ),
    );
    _logoSize = Tween<double>(begin: 96, end: 52).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.22, 0.58, curve: Curves.easeInOutCubicEmphasized),
      ),
    );
    // Rotasi muncul dengan overshoot ringan setelah logo mulai gerak
    _titleOpacity = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.30, 0.58, curve: Curves.easeOut),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0.22, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.30, 0.62, curve: Curves.easeOutBack),
      ),
    );
    _titleScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.30, 0.62, curve: Curves.easeOutBack),
      ),
    );
    // Subtitle nyusul biar stagger hidup
    _subtitleOpacity = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.46, 0.74, curve: Curves.easeOut),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0.16, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.46, 0.76, curve: Curves.easeOutCubic),
      ),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // #0C4A6E sama dengan native
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _entranceScale,
                  child: Image.asset(
                    'assets/logo.png',
                    width: _logoSize.value,
                    height: _logoSize.value,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => SizedBox(
                      width: _logoSize.value,
                      height: _logoSize.value,
                    ),
                  ),
                ),
                SizedBox(width: _titleOpacity.value * 14),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: ScaleTransition(
                          scale: _titleScale,
                          child: const Text(
                            'Rotasi',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FadeTransition(
                      opacity: _subtitleOpacity,
                      child: SlideTransition(
                        position: _subtitleSlide,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.35,
                              height: 1.1,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                            children: const [
                              TextSpan(
                                text: 'RO',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: 'da '),
                              TextSpan(
                                text: 'pan',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'TA',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: 'u '),
                              TextSpan(text: 'ten'),
                              TextSpan(
                                text: 'SI',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

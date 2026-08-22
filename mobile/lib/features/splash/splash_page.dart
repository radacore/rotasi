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
  late final Animation<double> _logoSize;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // 0-25% hold, 25-75% gerak, 75-100% hold
    _logoSize = Tween<double>(begin: 96, end: 52).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.22, 0.72, curve: Curves.easeInOutCubic),
      ),
    );
    _textOpacity = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.28, 0.75, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0.18, 0), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.28, 0.78, curve: Curves.easeOutCubic),
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
                Image.asset(
                  'assets/logo.png',
                  width: _logoSize.value,
                  height: _logoSize.value,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => SizedBox(
                    width: _logoSize.value,
                    height: _logoSize.value,
                  ),
                ),
                      // RS: Rotasi warna beda di-richtext
                SizedBox(width: _textOpacity.value * 14),
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
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
                        const SizedBox(height: 2),
                        RichText(
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
                                  color: Color(0xFFF59E0B), // sun - highlight
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

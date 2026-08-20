/// Fase latihan napas lambat 4-2-6 (FR-12).
///
/// Satu siklus = 4 detik tarik + 2 detik tahan + 6 detik buang = 12 detik.
enum BreathingPhase {
  inhale(4, 'Tarik Napas', 'Hirup perlahan lewat hidung'),
  hold(2, 'Tahan', 'Tahan napas sejenak'),
  exhale(6, 'Buang Napas', 'Hembuskan perlahan lewat mulut');

  const BreathingPhase(this.seconds, this.label, this.tip);

  final int seconds;
  final String label;
  final String tip;

  /// Total detik satu siklus penuh (4+2+6 = 12).
  static int get cycleSeconds =>
      inhale.seconds + hold.seconds + exhale.seconds;

  /// Fase pada detik ke-`elapsed` sejak latihan dimulai.
  static BreathingPhase phaseAt(int elapsed) {
    final t = elapsed % cycleSeconds;
    if (t < inhale.seconds) return inhale;
    if (t < inhale.seconds + hold.seconds) return hold;
    return exhale;
  }

  /// Detik yang sudah berjalan di dalam fase ini (0..seconds).
  static int inPhase(int elapsed) {
    final t = elapsed % cycleSeconds;
    if (t < inhale.seconds) return t;
    if (t < inhale.seconds + hold.seconds) return t - inhale.seconds;
    return t - inhale.seconds - hold.seconds;
  }
}

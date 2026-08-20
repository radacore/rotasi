import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/breathing/breathing_phase.dart';

void main() {
  group('BreathingPhase 4-2-6', () {
    test('siklus 12 detik', () {
      expect(BreathingPhase.cycleSeconds, 12);
      expect(BreathingPhase.inhale.seconds, 4);
      expect(BreathingPhase.hold.seconds, 2);
      expect(BreathingPhase.exhale.seconds, 6);
    });

    test('phaseAt mengikuti urutan tarik->tahan->buang', () {
      expect(BreathingPhase.phaseAt(0), BreathingPhase.inhale);
      expect(BreathingPhase.phaseAt(3), BreathingPhase.inhale);
      expect(BreathingPhase.phaseAt(4), BreathingPhase.hold);
      expect(BreathingPhase.phaseAt(5), BreathingPhase.hold);
      expect(BreathingPhase.phaseAt(6), BreathingPhase.exhale);
      expect(BreathingPhase.phaseAt(11), BreathingPhase.exhale);
    });

    test('phaseAt berulang tiap siklus', () {
      expect(BreathingPhase.phaseAt(12), BreathingPhase.inhale);
      expect(BreathingPhase.phaseAt(16), BreathingPhase.hold);
      expect(BreathingPhase.phaseAt(18), BreathingPhase.exhale);
      expect(BreathingPhase.phaseAt(23), BreathingPhase.exhale);
    });

    test('inPhase menghitung detik dalam fase', () {
      expect(BreathingPhase.inPhase(0), 0);
      expect(BreathingPhase.inPhase(3), 3);
      expect(BreathingPhase.inPhase(4), 0); // mulai tahan
      expect(BreathingPhase.inPhase(5), 1);
      expect(BreathingPhase.inPhase(6), 0); // mulai buang
      expect(BreathingPhase.inPhase(11), 5);
    });
  });
}

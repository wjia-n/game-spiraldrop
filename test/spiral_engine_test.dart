import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiraldrop/engine/spiral_engine.dart';

void main() {
  group('SpiralEngine state machine', () {
    test('start() runs countdown then auto-transitions to playing',
        () async {
      final engine = SpiralEngine(rand: Random(42));
      engine.attach();
      final phases = <SpiralPhase>[];
      engine.onPhase = phases.add;
      engine.start(
          mode: SpiralMode.classic,
          difficulty: SpiralDifficulty.chill,
          best: 0);
      expect(engine.phase, SpiralPhase.countdown);
      // countdown: 3 ticks × 650ms
      await Future.delayed(const Duration(milliseconds: 2300));
      expect(engine.phase, SpiralPhase.playing);
      expect(phases, contains(SpiralPhase.playing));
      engine.dispose();
    });

    test('tick applies gravity and moves ball down', () async {
      final engine = SpiralEngine(rand: Random(42));
      engine.attach();
      engine.start(
          mode: SpiralMode.classic,
          difficulty: SpiralDifficulty.chill,
          best: 0);
      await Future.delayed(const Duration(milliseconds: 2300));
      final y0 = engine.ballY;
      engine.tick(0.016);
      engine.tick(0.016);
      expect(engine.ballY, greaterThan(y0));
      engine.dispose();
    });

    test('drag only affects rotation while playing', () async {
      final engine = SpiralEngine(rand: Random(42));
      engine.attach();
      engine.start(
          mode: SpiralMode.classic,
          difficulty: SpiralDifficulty.chill,
          best: 0);
      engine.applyDrag(50); // countdown: ignored
      engine.tick(0.016);
      expect(engine.rot, 0);
      await Future.delayed(const Duration(milliseconds: 2300));
      engine.applyDrag(50);
      engine.tick(0.016);
      expect(engine.rot, isNot(0));
      engine.dispose();
    });

    test('pause/resume/restart transitions are clean', () async {
      final engine = SpiralEngine(rand: Random(42));
      engine.attach();
      engine.start(
          mode: SpiralMode.classic,
          difficulty: SpiralDifficulty.classic,
          best: 0);
      await Future.delayed(const Duration(milliseconds: 2300));
      engine.pause();
      expect(engine.phase, SpiralPhase.paused);
      engine.resume();
      expect(engine.phase, SpiralPhase.playing);
      engine.score = 123;
      engine.restart();
      expect(engine.phase, SpiralPhase.countdown);
      expect(engine.score, 0);
      engine.dispose();
    });

    test('watchdog re-arms a stalled countdown', () async {
      final engine = SpiralEngine(rand: Random(42));
      engine.attach();
      engine.start(
          mode: SpiralMode.classic,
          difficulty: SpiralDifficulty.chill,
          best: 0);
      expect(engine.phase, SpiralPhase.countdown);
      // Simulate a dead phase timer (should never happen, but guard anyway).
      engine.debugKillPhaseTimer();
      await Future.delayed(const Duration(milliseconds: 3400));
      // Watchdog should have re-armed countdown → playing eventually.
      expect(engine.phase, SpiralPhase.playing);
      engine.dispose();
    });

    test('red-zone hit ends the run when not fireball', () async {
      final engine = SpiralEngine(rand: Random(42));
      engine.attach();
      engine.start(
          mode: SpiralMode.classic,
          difficulty: SpiralDifficulty.chill,
          best: 0);
      await Future.delayed(const Duration(milliseconds: 2300));
      // Platform directly under the ball: no gap, red zone at ball angle.
      engine.platforms = [
        SpiralPlatform(3.0, 0.01, [engine.rot], 1.0),
      ];
      engine.ballY = SpiralEngine.y0 - SpiralEngine.ballR - 1;
      engine.vy = 500;
      engine.tick(0.016);
      engine.tick(0.016);
      expect(engine.phase, SpiralPhase.gameOver);
      engine.dispose();
    });

    test('three consecutive gap falls ignite fireball', () async {
      final engine = SpiralEngine(rand: Random(42));
      engine.attach();
      engine.start(
          mode: SpiralMode.classic,
          difficulty: SpiralDifficulty.chill,
          best: 0);
      await Future.delayed(const Duration(milliseconds: 2300));
      for (int k = 0; k < 3; k++) {
        engine.platforms = [
          SpiralPlatform(engine.rot, 2.0, [], 0.5),
        ];
        engine.ballY = SpiralEngine.y0 - SpiralEngine.ballR - 1;
        engine.vy = 500;
        engine.tick(0.016);
        engine.tick(0.016);
      }
      expect(engine.fireball, isTrue);
      expect(engine.fallCount, greaterThanOrEqualTo(3));
      engine.dispose();
    });

    test('fireball smashes through a red zone instead of dying',
        () async {
      final engine = SpiralEngine(rand: Random(42));
      engine.attach();
      engine.start(
          mode: SpiralMode.classic,
          difficulty: SpiralDifficulty.chill,
          best: 0);
      await Future.delayed(const Duration(milliseconds: 2300));
      // Ignite fireball with 3 gap falls.
      for (int k = 0; k < 3; k++) {
        engine.platforms = [
          SpiralPlatform(engine.rot, 2.0, [], 0.5),
        ];
        engine.ballY = SpiralEngine.y0 - SpiralEngine.ballR - 1;
        engine.vy = 500;
        engine.tick(0.016);
        engine.tick(0.016);
      }
      expect(engine.fireball, isTrue);
      // Now a red-zone platform under the ball: fireball smashes it.
      engine.platforms = [
        SpiralPlatform(3.0, 0.01, [engine.rot], 1.0),
      ];
      engine.ballY = SpiralEngine.y0 - SpiralEngine.ballR - 1;
      engine.vy = 500;
      engine.tick(0.016);
      engine.tick(0.016);
      expect(engine.phase, SpiralPhase.playing);
      expect(engine.platforms.first.smashed, isTrue);
      engine.dispose();
    });
  });
}

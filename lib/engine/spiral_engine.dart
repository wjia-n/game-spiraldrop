import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Spiral Drop engine — owns ALL game state, phases and timers.
///
/// The UI is a dumb renderer: it calls [tick] every frame and renders what
/// the engine reports. No game logic lives in widgets, so no UI state can
/// ever desync the game.
///
/// A watchdog ([_watchdog]) re-arms any engine timer that should be alive and
/// force-pauses play when frames stop arriving, so stuck states are
/// impossible by construction.
enum SpiralPhase { idle, countdown, playing, paused, levelComplete, gameOver }

enum SpiralMode { classic, endless }

/// Difficulty tiers. Chill = gentle, Classic = standard, Turbo = fast,
/// Inferno = brutal (Pro).
class SpiralDifficulty {
  static const int chill = 0;
  static const int classic = 1;
  static const int turbo = 2;
  static const int inferno = 3;

  static const names = ['Chill', 'Classic', 'Turbo', 'Inferno'];
  static const descriptions = [
    'Gentle spin, wide gaps. Learn the drop.',
    'The real spiral. Steady speed, honest reds.',
    'Faster fall, tighter gaps. Hands sweaty.',
    'Pro only. Maximum speed, razor gaps.',
  ];
}

/// Difficulty tuning knobs.
class _Tuning {
  final double gravity;
  final double bounceV;
  final double maxFall; // terminal velocity: keeps falls fast but controllable
  final double gapBase;
  final double gapShrink;
  final double redChance;
  final double drag;
  const _Tuning({
    required this.gravity,
    required this.bounceV,
    required this.maxFall,
    required this.gapBase,
    required this.gapShrink,
    required this.redChance,
    required this.drag,
  });
}

const _tunings = [
  _Tuning(gravity: 2200, bounceV: 950, maxFall: 2600, gapBase: 1.55, gapShrink: 0.008, redChance: 0.25, drag: 0.012),
  _Tuning(gravity: 2600, bounceV: 1080, maxFall: 3000, gapBase: 1.35, gapShrink: 0.012, redChance: 0.45, drag: 0.012),
  _Tuning(gravity: 3100, bounceV: 1220, maxFall: 3400, gapBase: 1.15, gapShrink: 0.016, redChance: 0.65, drag: 0.011),
  _Tuning(gravity: 3700, bounceV: 1380, maxFall: 3800, gapBase: 1.0, gapShrink: 0.02, redChance: 0.85, drag: 0.010),
];

/// A single tower platform.
class SpiralPlatform {
  double gapCenter; // absolute angle, radians
  double gapWidth;
  List<double> redCenters;
  double redWidth;
  bool smashed = false;
  SpiralPlatform(this.gapCenter, this.gapWidth, this.redCenters, this.redWidth);
}

/// Juicy, visible events the engine emits for the UI to celebrate.
enum SpiralEventKind {
  scorePopup, // text + points
  bounce,
  smash,
  fireballStart,
  fireballEnd,
  levelClear,
  newBest,
  gameOver,
  countdownTick,
  go,
  invalid,
}

/// Engine → UI callback contract.
typedef PhaseCallback = void Function(SpiralPhase phase);
typedef EventCallback = void Function(SpiralEventKind kind, String text, int points);
typedef UpdateCallback = void Function();

class SpiralEngine {
  final Random _rand;

  SpiralEngine({Random? rand}) : _rand = rand ?? Random();

  // ---------------- public state ----------------
  SpiralPhase phase = SpiralPhase.idle;
  SpiralMode mode = SpiralMode.classic;
  int difficulty = SpiralDifficulty.classic;
  int level = 1;
  int score = 0;
  int depth = 0; // platforms cleared (endless)
  int best = 0;
  int newBestScore = 0;

  List<SpiralPlatform> platforms = [];
  double rot = 0;
  double rotVel = 0;
  double ballY = 0;
  double vy = 0;
  int fallCount = 0; // consecutive gap falls; >=3 => fireball
  int smashedStreak = 0;
  double shake = 0; // screen shake amount, decays in tick
  double fireballFlash = 0;

  int countdownValue = 0; // 3..1 during countdown

  static const double y0 = 170;
  static const double spacing = 96;
  static const double ballR = 15;

  bool get fireball => fallCount >= 3 && phase == SpiralPhase.playing;

  PhaseCallback? onPhase;
  EventCallback? onEvent;
  UpdateCallback? onUpdate;

  // ---------------- internal timers ----------------
  Timer? _watchdog;
  Timer? _phaseTimer;
  DateTime _lastTick = DateTime.now();
  bool _disposed = false;

  /// Total platforms ever generated (drives the endless difficulty ramp).
  int _generated = 0;

  void attach() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) => _guard());
  }

  void _setPhase(SpiralPhase p) {
    phase = p;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    onPhase?.call(p);
  }

  /// Watchdog: re-arm phase timers that should be alive, and never let the
  /// game sit in `playing` without frames arriving.
  void _guard() {
    if (_disposed) return;
    switch (phase) {
      case SpiralPhase.countdown:
        if (_phaseTimer == null || !_phaseTimer!.isActive) _runCountdown();
        break;
      case SpiralPhase.levelComplete:
        if (_phaseTimer == null || !_phaseTimer!.isActive) _advanceLevel();
        break;
      case SpiralPhase.playing:
        if (DateTime.now().difference(_lastTick).inMilliseconds > 1500) {
          pause(auto: true); // frames stopped arriving — auto-pause, never stuck
        }
        break;
      case SpiralPhase.idle:
      case SpiralPhase.paused:
      case SpiralPhase.gameOver:
        break;
    }
  }

  // ---------------- lifecycle ----------------
  void start({
    required SpiralMode mode,
    required int difficulty,
    required int best,
  }) {
    this.mode = mode;
    this.difficulty = difficulty.clamp(0, 3);
    this.best = best;
    newBestScore = 0;
    score = 0;
    level = 1;
    depth = 0;
    _runCountdown();
  }

  void _runCountdown() {
    countdownValue = 3;
    _setPhase(SpiralPhase.countdown);
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 650), (t) {
      if (_disposed) return;
      if (phase != SpiralPhase.countdown) {
        t.cancel();
        return;
      }
      onEvent?.call(SpiralEventKind.countdownTick, '$countdownValue', 0);
      countdownValue--;
      if (countdownValue <= 0) {
        t.cancel();
        _beginPlay();
      }
    });
  }

  void _beginPlay() {
    if (phase != SpiralPhase.countdown) return;
    _setupLevel();
    _setPhase(SpiralPhase.playing);
    _lastTick = DateTime.now();
    onEvent?.call(SpiralEventKind.go, 'DROP!', 0);
  }

  void pause({bool auto = false}) {
    if (phase != SpiralPhase.playing) return;
    _setPhase(SpiralPhase.paused);
    if (auto) onEvent?.call(SpiralEventKind.invalid, 'Auto-paused', 0);
  }

  void resume() {
    if (phase != SpiralPhase.paused) return;
    _setPhase(SpiralPhase.playing);
    _lastTick = DateTime.now();
    onEvent?.call(SpiralEventKind.go, 'GO!', 0);
  }

  void restart() {
    start(mode: mode, difficulty: difficulty, best: best);
  }

  void quitToMenu() {
    _setPhase(SpiralPhase.idle);
  }

  // ---------------- level setup ----------------
  void _setupLevel() {
    final t = _tunings[difficulty];
    final n = mode == SpiralMode.endless ? 40 : min(10 + level * 2, 34);
    platforms = [
      for (int i = 0; i < n; i++) _makePlatform(i, n, t),
    ];
    _generated = n;
    ballY = y0 - 120;
    vy = 0;
    fallCount = 0;
    rot = 0;
    rotVel = 0;
    shake = 0;
  }

  SpiralPlatform _makePlatform(int i, int n, _Tuning t) {
    final gapC = _rand.nextDouble() * pi * 2;
    final gapW = max(0.6, t.gapBase - level * t.gapShrink - i * 0.004);
    final reds = <double>[];
    if (i >= 2) {
      final redCount = min(3, (level ~/ 3) + (i > n * 0.6 ? 1 : 0));
      for (int r = 0; r < redCount; r++) {
        if (_rand.nextDouble() < t.redChance) {
          reds.add(gapC + pi + (_rand.nextDouble() - 0.5) * 2.4);
        }
      }
    }
    return SpiralPlatform(gapC, gapW, reds, 0.55);
  }

  /// Endless mode: keep generating platforms below the ball forever, so the
  /// tower never runs out no matter how deep the run goes.
  void _extendEndless() {
    if (mode != SpiralMode.endless) return;
    final t = _tunings[difficulty];
    var lastY = y0 + (platforms.length - 1) * spacing;
    while (lastY - ballY < 30 * spacing) {
      platforms.add(_makePlatform(_generated, _generated + 1, t));
      _generated++;
      lastY += spacing;
    }
  }

  // ---------------- input ----------------
  void applyDrag(double dx) {
    if (phase != SpiralPhase.playing) return;
    rotVel += dx * _tunings[difficulty].drag;
    rotVel = rotVel.clamp(-0.35, 0.35);
  }

  // ---------------- simulation ----------------
  double relAngle(double absAngle) {
    var r = (absAngle - rot + pi) % (pi * 2);
    if (r < 0) r += pi * 2;
    return r - pi;
  }

  void tick(double dt) {
    if (_disposed || phase != SpiralPhase.playing) return;
    _lastTick = DateTime.now();
    dt = dt.clamp(0.0, 0.05);
    final t = _tunings[difficulty];

    rot += rotVel * dt;
    rotVel *= (1 - 2.2 * dt); // friction
    if (shake > 0) shake = max(0, shake - dt * 3.2);
    if (fireballFlash > 0) fireballFlash = max(0, fireballFlash - dt * 2.5);

    vy = min(vy + t.gravity * dt, t.maxFall); // terminal velocity
    final prevBottom = ballY + ballR;
    ballY += vy * dt;
    final newBottom = ballY + ballR;

    for (int i = 0; i < platforms.length; i++) {
      final p = platforms[i];
      if (p.smashed) continue;
      final py = y0 + i * spacing;
      if (prevBottom < py && newBottom >= py && vy > 0) {
        _hitPlatform(p, i);
        if (phase != SpiralPhase.playing) return;
        break;
      }
    }

    if (mode == SpiralMode.endless) {
      _extendEndless();
    } else {
      final lastY = y0 + (platforms.length - 1) * spacing;
      if (ballY > lastY + 160) _levelCleared();
    }
    onUpdate?.call();
  }

  void _hitPlatform(SpiralPlatform p, int index) {
    final t = _tunings[difficulty];
    final gapRel = relAngle(p.gapCenter);
    final inGap = gapRel.abs() < p.gapWidth / 2 - ballR * 0.001 / 100;

    if (inGap) {
      final wasFireball = fireball;
      fallCount++;
      depth++;
      final pts = fireball ? 40 : 10;
      score += pts;
      onEvent?.call(
        SpiralEventKind.scorePopup,
        fireball ? '+$pts FIREBALL' : '+$pts',
        pts,
      );
      if (!wasFireball && fireball) {
        fireballFlash = 1.0;
        onEvent?.call(SpiralEventKind.fireballStart, 'FIREBALL! 🔥', 0);
      }
      return;
    }

    bool inRed = false;
    for (final rc in p.redCenters) {
      if (relAngle(rc).abs() < p.redWidth / 2) {
        inRed = true;
        break;
      }
    }

    if (inRed && !fireball) {
      _gameOver('Smashed on red!');
      return;
    }

    if (fireball) {
      p.smashed = true;
      fallCount++;
      depth++;
      smashedStreak++;
      score += 50;
      shake = 1.0;
      onEvent?.call(SpiralEventKind.smash, 'SMASH x$smashedStreak! +50', 50);
      return;
    }

    // Bounce: gap missed on a safe zone.
    vy = -t.bounceV;
    if (fallCount >= 3) {
      onEvent?.call(SpiralEventKind.fireballEnd, 'Fireball out', 0);
    }
    fallCount = 0;
    smashedStreak = 0;
    onEvent?.call(SpiralEventKind.bounce, '', 0);
  }

  void _levelCleared() {
    final bonus = 100 + level * 10;
    score += bonus;
    _setPhase(SpiralPhase.levelComplete);
    onEvent?.call(
      SpiralEventKind.levelClear,
      'Level $level clear! +$bonus',
      bonus,
    );
    // Engine-owned auto-advance — the UI never has to remember to continue.
    _phaseTimer = Timer(const Duration(milliseconds: 2200), () {
      if (_disposed || phase != SpiralPhase.levelComplete) return;
      _advanceLevel();
    });
  }

  void _advanceLevel() {
    if (phase != SpiralPhase.levelComplete) return;
    level++;
    _setupLevel();
    _setPhase(SpiralPhase.playing);
    _lastTick = DateTime.now();
    onEvent?.call(SpiralEventKind.go, 'Level $level — DROP!', 0);
  }

  void _gameOver(String reason) {
    if (phase == SpiralPhase.gameOver) return;
    final isBest = score > best;
    if (isBest) {
      newBestScore = score;
      best = score;
      onEvent?.call(SpiralEventKind.newBest, 'NEW BEST!', 0);
    }
    _setPhase(SpiralPhase.gameOver);
    onEvent?.call(SpiralEventKind.gameOver, reason, score);
  }

  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    _phaseTimer?.cancel();
  }

  /// Testing hook: simulate a dead phase timer so tests can prove the
  /// watchdog re-arms it.
  @visibleForTesting
  void debugKillPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
  }
}

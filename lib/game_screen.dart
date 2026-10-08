import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Spiral Drop — rotate the tower, drop the ball, smash combos. 🌀
class SpiralDropScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const SpiralDropScreen({super.key, required this.players, required this.callbacks});

  @override
  State<SpiralDropScreen> createState() => _SpiralDropScreenState();
}

class _Platform {
  double gapCenter; // absolute angle, radians
  double gapWidth;
  List<double> redCenters;
  double redWidth;
  bool smashed = false;
  _Platform(this.gapCenter, this.gapWidth, this.redCenters, this.redWidth);
}

class _SpiralDropScreenState extends State<SpiralDropScreen> {
  static const _bestKey = 'spiraldrop_best';
  static const _bestLevelKey = 'spiraldrop_best_level';

  final _rand = Random();
  Ticker? _ticker;
  double _lastSec = 0;
  bool over = false;
  bool started = false;

  int level = 1;
  List<_Platform> platforms = [];
  double rot = 0;
  double ballY = 0; // world y
  double vy = 0;
  int fallCount = 0;
  int smashedStreak = 0;
  double smashTextT = 0;
  int best = 0;
  int bestLevel = 0;
  Size _size = Size.zero;

  static const double _y0 = 170;
  static const double _spacing = 96;
  static const double _ballR = 15;

  int get score => widget.players[0].score;
  bool get fireball => fallCount >= 3 && !over;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      best = prefs.getInt(_bestKey) ?? 0;
      bestLevel = prefs.getInt(_bestLevelKey) ?? 0;
    });
  }

  void _begin() {
    setState(() {
      started = true;
      over = false;
      level = 1;
      widget.players[0].score = 0;
    });
    widget.callbacks.refreshHud();
    _setupLevel();
    _lastSec = 0;
    _ticker?.dispose();
    _ticker = Ticker(_tick)..start();
    Sfx.click();
  }

  void _setupLevel() {
    final n = min(10 + level * 2, 34);
    platforms = [];
    for (int i = 0; i < n; i++) {
      final gapC = _rand.nextDouble() * pi * 2;
      final gapW = max(0.75, 1.3 - level * 0.012 - i * 0.004);
      final reds = <double>[];
      final redCount = i < 2 ? 0 : min(2, (level ~/ 4) + (i > n * 0.6 ? 1 : 0));
      for (int r = 0; r < redCount; r++) {
        double c = gapC + pi + (_rand.nextDouble() - 0.5) * 2.2;
        reds.add(c);
      }
      platforms.add(_Platform(gapC, gapW, reds, 0.55));
    }
    ballY = _y0 - 120;
    vy = 0;
    fallCount = 0;
    rot = 0;
    setState(() {});
  }

  double _rel(double absAngle) {
    var r = (absAngle - rot + pi) % (pi * 2);
    if (r < 0) r += pi * 2;
    return r - pi;
  }

  void _tick(Duration d) {
    final sec = d.inMicroseconds / 1e6;
    final dt = min(0.05, _lastSec == 0 ? 0.016 : sec - _lastSec);
    _lastSec = sec;
    if (over || !mounted || !started) return;
    setState(() {
      if (smashTextT > 0) smashTextT -= dt;
      vy += 2600 * dt;
      final prevBottom = ballY + _ballR;
      ballY += vy * dt;
      final newBottom = ballY + _ballR;
      for (int i = 0; i < platforms.length; i++) {
        final py = _y0 + i * _spacing;
        final p = platforms[i];
        if (p.smashed) continue;
        if (prevBottom < py && newBottom >= py && vy > 0) {
          _hitPlatform(p, i);
          if (over) return;
          break;
        }
      }
      // level complete?
      final lastY = _y0 + (platforms.length - 1) * _spacing;
      if (ballY > lastY + 160) {
        level++;
        widget.players[0].score += 100;
        Sfx.win();
        widget.callbacks.refreshHud();
        _setupLevel();
      }
    });
  }

  void _hitPlatform(_Platform p, int i) {
    final w = _size.width;
    final gapX = w * (_rel(p.gapCenter) + pi) / (pi * 2);
    final gapW = w * p.gapWidth / (pi * 2);
    final bx = w / 2;
    final inGap = bx + _ballR > gapX - gapW / 2 && bx - _ballR < gapX + gapW / 2;
    if (inGap) {
      fallCount++;
      widget.players[0].score += fireball ? 40 : 10;
      Sfx.move();
      widget.callbacks.refreshHud();
      return;
    }
    bool inRed = false;
    for (final rc in p.redCenters) {
      final rx = w * (_rel(rc) + pi) / (pi * 2);
      final rw = w * p.redWidth / (pi * 2);
      if (bx + _ballR * 0.6 > rx - rw / 2 && bx - _ballR * 0.6 < rx + rw / 2) {
        inRed = true;
        break;
      }
    }
    if (inRed && !fireball) {
      _gameOver('Smashed on red! 🔴');
      return;
    }
    if (fireball) {
      // SMASH through!
      p.smashed = true;
      fallCount++;
      smashedStreak++;
      smashTextT = 0.9;
      widget.players[0].score += 50;
      Sfx.win();
      widget.callbacks.refreshHud();
      return;
    }
    // bounce
    vy = -1080;
    fallCount = 0;
    smashedStreak = 0;
    Sfx.tap();
  }

  Future<void> _gameOver(String reason) async {
    if (over) return;
    over = true;
    _ticker?.stop();
    Sfx.lose();
    final s = score;
    final isBest = s > best;
    if (isBest) {
      best = s;
      bestLevel = max(bestLevel, level);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, best);
      await prefs.setInt(_bestLevelKey, bestLevel);
    }
    if (!mounted) return;
    widget.callbacks.finish(
      headline: '$reason Level $level — score $s! 🌀',
      subline: isBest ? 'NEW BEST! Spiral royalty 🏆' : 'Best: $best (lvl $bestLevel) — drop again?',
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    _size = MediaQuery.of(context).size;
    if (!started) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌀', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('Drag to spin. Drop through gaps.',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.text),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Red zones smash you — unless you\'re a FIREBALL! Fall through 3+ platforms without bouncing to go nuclear and smash everything. 🔥',
                  style: TextStyle(color: theme.muted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              WajihaButton(label: 'Start dropping', emoji: '⬇️', onTap: _begin, primary: true),
              const SizedBox(height: 12),
              Text('Best: $best (lvl $bestLevel)', style: TextStyle(color: theme.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => setState(() => rot += d.delta.dx * 0.012),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _SpiralPainter(
              platforms: platforms,
              rot: rot,
              ballY: ballY,
              fireball: fireball,
              smashTextT: smashTextT,
              smashedStreak: smashedStreak,
              theme: theme,
            ),
          ),
          Positioned(
            top: 8, left: 12, right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🌀 $score', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.text)),
                Text(fireball ? '🔥 FIREBALL' : 'Level $level',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: fireball ? Colors.orange : theme.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpiralPainter extends CustomPainter {
  final List<_Platform> platforms;
  final double rot;
  final double ballY;
  final bool fireball;
  final double smashTextT;
  final int smashedStreak;
  final GameTheme theme;

  _SpiralPainter({
    required this.platforms,
    required this.rot,
    required this.ballY,
    required this.fireball,
    required this.smashTextT,
    required this.smashedStreak,
    required this.theme,
  });

  static const double _y0 = 170;
  static const double _spacing = 96;

  double _rel(double absAngle) {
    var r = (absAngle - rot + pi) % (pi * 2);
    if (r < 0) r += pi * 2;
    return r - pi;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // camera: keep ball around 38% height
    final camY = ballY - size.height * 0.38;

    // central column
    final colPaint = Paint()..color = theme.muted.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTWH(w / 2 - 14, -camY, 28, size.height + 400), colPaint);

    for (int i = 0; i < platforms.length; i++) {
      final p = platforms[i];
      if (p.smashed) continue;
      final py = _y0 + i * _spacing - camY;
      if (py < -60 || py > size.height + 60) continue;
      // full bar
      final barPaint = Paint()..color = theme.primary;
      final barRect = RRect.fromRectAndRadius(Rect.fromLTWH(16, py - 13, w - 32, 26), const Radius.circular(13));
      canvas.drawRRect(barRect, barPaint);
      // red zones
      for (final rc in p.redCenters) {
        final rx = w * (_rel(rc) + pi) / (pi * 2);
        final rw = w * p.redWidth / (pi * 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(rx - rw / 2, py - 13, rw, 26), const Radius.circular(13)),
          Paint()..color = Colors.red,
        );
      }
      // gap (erase)
      final gapX = w * (_rel(p.gapCenter) + pi) / (pi * 2);
      final gapW = w * p.gapWidth / (pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(gapX - gapW / 2, py - 15, gapW, 30), const Radius.circular(13)),
        Paint()..color = theme.background,
      );
    }

    // ball
    final bx = w / 2;
    final by = ballY - camY;
    if (fireball) {
      canvas.drawCircle(Offset(bx, by), 26, Paint()..color = Colors.orange.withValues(alpha: 0.35));
      canvas.drawCircle(Offset(bx, by), 20, Paint()..color = Colors.deepOrange.withValues(alpha: 0.5));
    }
    final ballPaint = Paint()..color = fireball ? Colors.deepOrange : theme.accent;
    canvas.drawCircle(Offset(bx, by), 15, ballPaint);
    canvas.drawCircle(Offset(bx - 5, by - 5), 5, Paint()..color = Colors.white.withValues(alpha: 0.6));

    if (smashTextT > 0 && smashedStreak > 0) {
      final tp = TextPainter(
        text: TextSpan(
            text: 'SMASH x$smashedStreak! 🔥',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.orange)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, size.height * 0.2));
    }
  }

  @override
  bool shouldRepaint(covariant _SpiralPainter old) => true;
}

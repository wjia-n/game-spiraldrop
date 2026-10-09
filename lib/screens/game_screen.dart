import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/spiral_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../theme/spiral_themes.dart';
import '../widgets/spiral_widgets.dart';

/// Game screen: a dumb renderer over [SpiralEngine]. The engine owns phases,
/// timers and physics; this widget draws, plays sounds and celebrates.
class GameScreen extends StatefulWidget {
  final SpiralAudio audio;
  final SpiralSettings settings;
  final StoreService store;
  final ReviewService review;
  final VoidCallback onExit;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.review,
    required this.onExit,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _Popup {
  final String text;
  final int points;
  double t = 1.2; // seconds remaining
  final double xJitter;
  _Popup(this.text, this.points, this.xJitter);
}

class _GameScreenState extends State<GameScreen> {
  late final SpiralEngine _engine;
  Ticker? _ticker;
  double _lastSec = 0;
  final List<_Popup> _popups = [];
  final _rand = Random();
  String _banner = '';
  double _bannerT = 0;
  bool _recorded = false;

  SpiralThemeDef get _theme => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    _engine = SpiralEngine();
    _engine.onPhase = _onPhase;
    _engine.onEvent = _onEvent;
    _engine.onUpdate = () {
      if (mounted) setState(() {});
    };
    _engine.attach();
    _engine.start(
      mode: widget.settings.mode,
      difficulty: widget.settings.difficulty,
      best: widget.settings.bestForMode,
    );
    _lastSec = 0;
    _ticker = Ticker(_tick)..start();
    widget.audio.startGameMusic();
  }

  void _tick(Duration d) {
    final sec = d.inMicroseconds / 1e6;
    final dt = _lastSec == 0 ? 0.016 : min(0.05, sec - _lastSec);
    _lastSec = sec;
    if (!mounted) return;
    _engine.tick(dt);
    // popups + banners decay here (purely visual)
    var dirty = false;
    for (final p in _popups) {
      p.t -= dt;
      dirty = true;
    }
    _popups.removeWhere((p) => p.t <= 0);
    if (_bannerT > 0) {
      _bannerT -= dt;
      dirty = true;
    }
    if (dirty && mounted) setState(() {});
  }

  void _onPhase(SpiralPhase phase) {
    if (!mounted) return;
    setState(() {});
    if (phase == SpiralPhase.gameOver) _finishRun();
  }

  void _onEvent(SpiralEventKind kind, String text, int points) {
    if (!mounted) return;
    switch (kind) {
      case SpiralEventKind.scorePopup:
        _popups.add(_Popup(text, points, (_rand.nextDouble() - 0.5) * 80));
        widget.audio.whoosh();
        break;
      case SpiralEventKind.bounce:
        widget.audio.bounce();
        break;
      case SpiralEventKind.smash:
        _popups.add(_Popup(text, points, (_rand.nextDouble() - 0.5) * 60));
        widget.audio.smash();
        break;
      case SpiralEventKind.fireballStart:
        _banner = 'FIREBALL! 🔥';
        _bannerT = 1.4;
        widget.audio.ignite();
        break;
      case SpiralEventKind.fireballEnd:
        _banner = 'Fireball out';
        _bannerT = 0.9;
        break;
      case SpiralEventKind.levelClear:
        _banner = text;
        _bannerT = 2.0;
        widget.audio.levelClear();
        break;
      case SpiralEventKind.newBest:
        widget.audio.newBest();
        break;
      case SpiralEventKind.gameOver:
        widget.audio.gameOver();
        break;
      case SpiralEventKind.countdownTick:
        widget.audio.countBeep();
        break;
      case SpiralEventKind.go:
        _banner = text;
        _bannerT = 1.0;
        widget.audio.go();
        break;
      case SpiralEventKind.invalid:
        break;
    }
    setState(() {});
  }

  Future<void> _finishRun() async {
    if (_recorded) return;
    _recorded = true;
    final s = widget.settings;
    final newBest = await s.recordRun(
      runMode: _engine.mode,
      score: _engine.score,
      level: _engine.level,
    );
    if (newBest && mounted) {
      // Celebrate a new best at most 3 times per install, gracefully.
      await widget.review.maybeAsk(
        maxTimes: 3,
        alreadyAsked: s.newBestCelebrated,
      );
      await s.markBestCelebrated();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _share() {
    widget.audio.click();
    SharePlus.instance.share(
      ShareParams(
        text: 'I scored ${_engine.score} in Spiral Drop! 🌀 Can you beat me?\n'
            'https://play.google.com/store/apps/details?id=com.gameswajiha.spiraldrop',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return SpiralThemeHolder(
      theme: t,
      child: Scaffold(
        body: WoodBackdrop(
          theme: t,
          child: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) =>
                  _engine.applyDrag(d.delta.dx),
              child: Stack(
                children: [
                  _buildTower(),
                  _buildHud(),
                  if (_engine.phase == SpiralPhase.countdown)
                    _buildCountdown(),
                  if (_bannerT > 0) _buildBanner(),
                  ..._buildPopups(),
                  if (_engine.phase == SpiralPhase.paused)
                    _buildPauseOverlay(),
                  if (_engine.phase == SpiralPhase.levelComplete)
                    _buildLevelClearOverlay(),
                  if (_engine.phase == SpiralPhase.gameOver)
                    _buildGameOverOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTower() {
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TowerPainter(
            engine: _engine,
            theme: _theme,
            ballStyle: widget.settings.ballStyle,
            randSeed: 7,
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    final t = _theme;
    final fireball = _engine.fireball;
    return Positioned(
      top: 6,
      left: 12,
      right: 12,
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: t.accent.withValues(alpha: 0.5)),
            ),
            child: Text(
              '🌀 ${_engine.score}',
              style: SpiralLook.title(20, t),
            ),
          ),
          const Spacer(),
          if (fireball)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD0542A)
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '🔥 FIREBALL',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _engine.mode == SpiralMode.classic
                    ? 'Level ${_engine.level}'
                    : 'Depth ${_engine.depth}',
                style: SpiralLook.body(15, t),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              widget.audio.click();
              _engine.pause();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: t.accent.withValues(alpha: 0.5)),
              ),
              child: Text('⏸', style: TextStyle(fontSize: 18, color: t.textOn)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final t = _theme;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${_engine.countdownValue}',
              key: ValueKey(_engine.countdownValue),
              style: SpiralLook.display(110, t).copyWith(
                color: t.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final t = _theme;
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.22,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: t.accent.withValues(alpha: 0.7), width: 2),
          ),
          child: Text(_banner, style: SpiralLook.title(26, t)),
        ),
      ),
    );
  }

  List<Widget> _buildPopups() {
    final t = _theme;
    final size = MediaQuery.of(context).size;
    return [
      for (final p in _popups)
        Positioned(
          top: size.height * 0.38 - (1.2 - p.t) * 90,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: (p.t / 1.2).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(p.xJitter, 0),
                  child: Text(
                    p.text,
                    style: SpiralLook.title(
                        p.points >= 40 ? 30 : 24, t)
                        .copyWith(
                      color: p.points >= 40
                          ? const Color(0xFFFF8A3A)
                          : t.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildPauseOverlay() {
    final t = _theme;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: SpiralLook.panel(t),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⏸ Paused', style: SpiralLook.title(30, t)),
                const SizedBox(height: 6),
                Text('Take a breath, spinner.',
                    style: SpiralLook.body(15, t)),
                const SizedBox(height: 20),
                SpiralButton(
                    label: 'Resume', emoji: '▶️', primary: true,
                    onTap: () {
                      widget.audio.click();
                      _engine.resume();
                    }),
                const SizedBox(height: 12),
                SpiralButton(
                    label: 'Restart', emoji: '🔄',
                    onTap: () {
                      widget.audio.click();
                      _recorded = false;
                      _engine.restart();
                    }),
                const SizedBox(height: 12),
                SpiralButton(
                    label: 'Quit', emoji: '🏠',
                    onTap: () {
                      widget.audio.click();
                      widget.audio.startMenuMusic();
                      widget.onExit();
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelClearOverlay() {
    final t = _theme;
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 72)),
              Text('LEVEL ${_engine.level} CLEAR!',
                  style: SpiralLook.display(38, t)),
              Text('Next tower rising…',
                  style: SpiralLook.body(17, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final t = _theme;
    final isBest = _engine.newBestScore > 0;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(26),
              decoration: SpiralLook.panel(t),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💥', style: TextStyle(fontSize: 56)),
                  Text('Game Over', style: SpiralLook.title(34, t)),
                  if (isBest)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.accent),
                      ),
                      child: Text('🏆 NEW BEST: ${_engine.score}!',
                          style: SpiralLook.title(20, t)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Score: ${_engine.score}',
                          style: SpiralLook.title(24, t)),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Best: ${widget.settings.bestForMode} • '
                    '${_engine.mode == SpiralMode.classic ? 'Level ${_engine.level}' : 'Depth ${_engine.depth}'}',
                    style: SpiralLook.body(15, t),
                  ),
                  const SizedBox(height: 20),
                  SpiralButton(
                      label: 'Drop again', emoji: '🌀', primary: true,
                      onTap: () {
                        widget.audio.click();
                        _recorded = false;
                        _popups.clear();
                        _engine.restart();
                      }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _miniBtn('📤 Share', _share),
                      const SizedBox(width: 10),
                      _miniBtn('🏠 Menu', () {
                        widget.audio.click();
                        widget.audio.startMenuMusic();
                        widget.onExit();
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(String label, VoidCallback onTap) {
    final t = _theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: t.woodMid.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: t.accent.withValues(alpha: 0.5), width: 2),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: t.textOn)),
      ),
    );
  }
}

/// The tower painter: wooden column, platforms with bevel + grain, red
/// danger zones, gaps, and the ball with trail, highlight and fireball aura.
class _TowerPainter extends CustomPainter {
  final SpiralEngine engine;
  final SpiralThemeDef theme;
  final BallStyleDef ballStyle;
  final int randSeed;

  _TowerPainter({
    required this.engine,
    required this.theme,
    required this.ballStyle,
    required this.randSeed,
  });

  static const double _y0 = SpiralEngine.y0;
  static const double _spacing = SpiralEngine.spacing;
  static const double _ballR = SpiralEngine.ballR;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final camY = engine.ballY - size.height * 0.38;
    // screen shake
    final shake = engine.shake;
    final sx = shake > 0 ? (randSeed % 7 - 3) * shake * 6 : 0.0;
    final sy = shake > 0 ? ((randSeed * 3) % 7 - 3) * shake * 6 : 0.0;
    canvas.translate(sx, sy);

    // central wooden column with grain
    final colW = 30.0;
    final colRect =
        Rect.fromLTWH(w / 2 - colW / 2, -camY - 200, colW, size.height + 800);
    canvas.drawRect(
        colRect,
        Paint()
          ..shader = LinearGradient(
            colors: [theme.woodLight, theme.woodMid, theme.woodDark],
          ).createShader(colRect));
    // column shadow edges
    canvas.drawRect(
        Rect.fromLTWH(w / 2 - colW / 2, -camY - 200, 5, size.height + 800),
        Paint()..color = Colors.black.withValues(alpha: 0.25));
    canvas.drawRect(
        Rect.fromLTWH(w / 2 + colW / 2 - 5, -camY - 200, 5, size.height + 800),
        Paint()..color = Colors.black.withValues(alpha: 0.25));

    final grainRand = Random(randSeed);
    for (int i = 0; i < engine.platforms.length; i++) {
      final p = engine.platforms[i];
      if (p.smashed) continue;
      final py = _y0 + i * _spacing - camY;
      if (py < -80 || py > size.height + 80) continue;
      _drawPlatform(canvas, w, p, py, grainRand);
    }

    // fireball aura
    final bx = w / 2;
    final by = engine.ballY - camY;
    if (engine.fireball) {
      final flash = 0.5 + engine.fireballFlash * 0.5;
      for (final r in [44.0, 34.0, 26.0]) {
        canvas.drawCircle(
            Offset(bx, by),
            r * flash,
            Paint()
              ..color = const Color(0xFFFF7A2A)
                  .withValues(alpha: 0.18 * flash));
      }
    }

    // ball trail
    final trailPaint = Paint()..color = ballStyle.trail.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(bx, by + 18), _ballR * 0.7, trailPaint);
    canvas.drawCircle(Offset(bx, by + 34), _ballR * 0.45,
        Paint()..color = ballStyle.trail.withValues(alpha: 0.2));

    // ball body with bevel
    final ballRect =
        Rect.fromCircle(center: Offset(bx, by), radius: _ballR);
    canvas.drawCircle(
        Offset(bx, by),
        _ballR,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: [
              engine.fireball
                  ? const Color(0xFFFFD06E)
                  : ballStyle.ballLight,
              engine.fireball ? const Color(0xFFFF7A2A) : ballStyle.ball,
              engine.fireball
                  ? const Color(0xFFB03A10)
                  : ballStyle.ball.withValues(alpha: 0.75),
            ],
          ).createShader(ballRect));
    // marble veins
    if (ballStyle.marbled && !engine.fireball) {
      final vein = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawArc(ballRect.deflate(3), 0.4, 1.1, false, vein);
      canvas.drawArc(ballRect.deflate(6), 2.8, 0.9, false, vein);
    }
    // glossy highlight
    canvas.drawCircle(
        Offset(bx - 5, by - 5),
        4.5,
        Paint()..color = Colors.white.withValues(alpha: 0.65));
    // contact shadow under ball
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bx, by + _ballR + 6), width: 30, height: 8),
        Paint()..color = Colors.black.withValues(alpha: 0.3));
  }

  void _drawPlatform(
      Canvas canvas, double w, SpiralPlatform p, double py, Random r) {
    // platform body: rounded wooden bar with bevel gradient
    final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(14, py - 14, w - 28, 28),
        const Radius.circular(14));
    canvas.drawRRect(
        barRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.woodLight, theme.woodMid, theme.woodDark],
          ).createShader(barRect.outerRect));
    // top highlight strip (bevel)
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(20, py - 14, w - 40, 7),
            const Radius.circular(3.5)),
        Paint()..color = Colors.white.withValues(alpha: 0.18));
    // wood grain lines
    final grain = Paint()
      ..color = theme.woodDark.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    for (int g = 0; g < 3; g++) {
      final gy = py - 6 + g * 6 + r.nextDouble() * 2;
      canvas.drawLine(Offset(24, gy), Offset(w - 24, gy), grain);
    }
    // drop shadow under platform
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(18, py + 12, w - 36, 8),
            const Radius.circular(4)),
        Paint()..color = Colors.black.withValues(alpha: 0.28));

    // red danger zones with brushed texture
    for (final rc in p.redCenters) {
      final rx = w * (engine.relAngle(rc) + pi) / (pi * 2);
      final rw = w * p.redWidth / (pi * 2);
      final redRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(rx - rw / 2, py - 14, rw, 28),
          const Radius.circular(12));
      canvas.drawRRect(
          redRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.redZone.withValues(alpha: 0.95),
                theme.redZone.withValues(alpha: 0.7),
              ],
            ).createShader(redRect.outerRect));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(rx - rw / 2 + 4, py - 12, rw - 8, 5),
              const Radius.circular(2.5)),
          Paint()..color = Colors.white.withValues(alpha: 0.22));
    }

    // gap: carve out with room background + accent trim
    final gapX = w * (engine.relAngle(p.gapCenter) + pi) / (pi * 2);
    final gapW = w * p.gapWidth / (pi * 2);
    final gapRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(gapX - gapW / 2, py - 16, gapW, 32),
        const Radius.circular(14));
    canvas.drawRRect(
        gapRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.bgTop, theme.bgBottom],
          ).createShader(gapRect.outerRect));
    // accent trim on gap edges
    final trim = Paint()
      ..color = theme.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(gapX - gapW / 2, py - 16),
        Offset(gapX - gapW / 2, py + 16), trim);
    canvas.drawLine(Offset(gapX + gapW / 2, py - 16),
        Offset(gapX + gapW / 2, py + 16), trim);
  }

  @override
  bool shouldRepaint(covariant _TowerPainter old) => true;
}

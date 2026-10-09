import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/spiral_themes.dart';
import '../widgets/spiral_widgets.dart';
import 'custom_theme_screen.dart';
import 'pro_screen.dart';

/// Theme + ball-style picker. 12 physical-material themes, 8 ball styles,
/// plus the custom workshop (Pro).
class ThemeScreen extends StatefulWidget {
  final SpiralAudio audio;
  final SpiralSettings settings;
  final StoreService store;
  const ThemeScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _goPro() {
    widget.audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ProScreen(
              audio: widget.audio,
              settings: widget.settings,
              store: widget.store),
        ))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = s.theme;
    return SpiralThemeHolder(
      theme: t,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Text('←', style: TextStyle(fontSize: 26, color: t.textOn)),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Look & Feel', style: SpiralLook.title(22, t)),
          bottom: TabBar(
            controller: _tabs,
            labelColor: t.accent,
            unselectedLabelColor: t.muted,
            indicatorColor: t.accent,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 15),
            tabs: const [
              Tab(text: '🎨 Tower'),
              Tab(text: '⚽ Ball'),
            ],
          ),
        ),
        body: WoodBackdrop(
          theme: t,
          child: TabBarView(
            controller: _tabs,
            children: [
              _themeGrid(),
              _ballGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeGrid() {
    final s = widget.settings;
    final items = [
      ...SpiralThemes.all,
      if (s.isPro) s.customTheme,
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final th = items[i];
        final locked =
            !s.isPro && SpiralThemes.isProTheme(th.id);
        final selected = s.themeId == th.id;
        return GestureDetector(
          onTap: () {
            if (locked) {
              _goPro();
              return;
            }
            widget.audio.click();
            s.setTheme(th.id);
            setState(() {});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [th.bgTop, th.bgBottom],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? th.accent : Colors.white24,
                width: selected ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 6),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Stack(
              children: [
                // mini tower preview: wooden bars + red zone + ball
                Positioned.fill(
                  child: CustomPaint(
                      painter: _MiniTowerPainter(theme: th)),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      if (locked)
                        const Text('🔒 PRO',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      Text(th.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: th.textOn,
                            shadows: const [
                              Shadow(
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                  blurRadius: 4)
                            ],
                          )),
                    ],
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Text('✅',
                        style: TextStyle(fontSize: 20)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ballGrid() {
    final s = widget.settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemCount: BallStyles.all.length,
          itemBuilder: (_, i) {
            final b = BallStyles.all[i];
            final locked = !s.isPro && b.isPro;
            final selected = s.ballStyleId == b.id;
            return GestureDetector(
              onTap: () {
                if (locked) {
                  _goPro();
                  return;
                }
                widget.audio.click();
                s.setBallStyle(b.id);
                setState(() {});
              },
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center:
                              const Alignment(-0.35, -0.35),
                          colors: [
                            b.ballLight,
                            b.ball,
                            b.ball.withValues(alpha: 0.7)
                          ],
                        ),
                        border: Border.all(
                          color: selected
                              ? s.theme.accent
                              : Colors.white24,
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: b.trail
                                .withValues(alpha: 0.5),
                            blurRadius: selected ? 16 : 6,
                          ),
                        ],
                      ),
                      child: locked
                          ? const Center(
                              child: Text('🔒',
                                  style: TextStyle(
                                      fontSize: 18)))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(b.name,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: s.theme.textOn
                              .withValues(alpha: 0.85))),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        _workshopCard(),
      ],
    );
  }

  Widget _workshopCard() {
    final s = widget.settings;
    final t = s.theme;
    final locked = !s.isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          _goPro();
          return;
        }
        widget.audio.click();
        Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (_) => CustomThemeScreen(
                  audio: widget.audio, settings: s),
            ))
            .then((_) => setState(() {}));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: SpiralLook.panel(t),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.35),
                  colors: [
                    s.customBall.ballLight,
                    s.customBall.ball,
                  ],
                ),
                border:
                    Border.all(color: t.accent, width: 2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🛠 My Workshop',
                          style:
                              SpiralLook.title(18, t)),
                      if (locked)
                        const Text(' 🔒',
                            style: TextStyle(
                                fontSize: 16)),
                    ],
                  ),
                  Text(
                    locked
                        ? 'Pro unlocks the custom tower + ball designer.'
                        : 'Design your own tower theme and ball.',
                    style: SpiralLook.body(13, t),
                  ),
                ],
              ),
            ),
            Text('→',
                style: TextStyle(
                    fontSize: 24, color: t.accent)),
          ],
        ),
      ),
    );
  }
}

/// Tiny tower preview painted inside theme cards.
class _MiniTowerPainter extends CustomPainter {
  final SpiralThemeDef theme;
  _MiniTowerPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final barH = 10.0;
    for (int i = 0; i < 4; i++) {
      final y = 14.0 + i * 26.0;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              10, y, size.width - 20, barH),
          const Radius.circular(5));
      canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(colors: [
              theme.woodLight,
              theme.woodMid,
              theme.woodDark
            ]).createShader(rect.outerRect));
      if (i == 1) {
        // red zone sample
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(size.width * 0.55, y,
                    size.width * 0.22, barH),
                const Radius.circular(5)),
            Paint()..color = theme.redZone);
      }
      if (i == 2) {
        // gap sample
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(size.width * 0.3, y - 1,
                    size.width * 0.3, barH + 2),
                const Radius.circular(6)),
            Paint()..color = theme.bgBottom);
      }
    }
    // sample ball
    canvas.drawCircle(
        Offset(size.width * 0.72, 96),
        9,
        Paint()
          ..shader = RadialGradient(colors: [
            theme.accent.withValues(alpha: 0.9),
            theme.woodDark
          ]).createShader(
              Rect.fromCircle(
                  center: Offset(size.width * 0.72, 96),
                  radius: 9)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

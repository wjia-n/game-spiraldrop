import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/spiral_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../theme/spiral_themes.dart';
import '../widgets/spiral_widgets.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';

class MenuScreen extends StatefulWidget {
  final SpiralAudio audio;
  final SpiralSettings settings;
  const MenuScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  StoreService? _store;
  final _review = ReviewService();
  bool _inGame = false;

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
  }

  StoreService _storeService() =>
      _store ??= (StoreService()..init());

  void _play(SpiralMode mode) {
    widget.audio.click();
    setState(() => _inGame = true);
  }

  void _onExitGame() {
    setState(() => _inGame = false);
    widget.audio.startMenuMusic();
  }

  void _share() {
    widget.audio.click();
    SharePlus.instance.share(
      ShareParams(
        text: 'Spiral Drop is dangerously fun 🌀 Spin the tower, thread the gaps, go FIREBALL!\n'
            'https://play.google.com/store/apps/details?id=com.gameswajiha.spiraldrop',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = s.theme;
    if (_inGame) {
      return GameScreen(
        key: ValueKey(
            '${s.mode.name}_${s.difficulty}_${DateTime.now().millisecondsSinceEpoch}'),
        audio: widget.audio,
        settings: s,
        store: _storeService(),
        review: _review,
        onExit: _onExitGame,
      );
    }
    return SpiralThemeHolder(
      theme: t,
      child: Scaffold(
        body: WoodBackdrop(
          theme: t,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: t.accent, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.5),
                            offset: const Offset(0, 8),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                          'assets/spiraldrop_logo.png',
                          fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    Text('Spiral Drop',
                        style: SpiralLook.display(40, t)),
                    Text(
                        s.isPro
                            ? '★ PRO EDITION ★'
                            : 'SPIN • DROP • SMASH',
                        style: SpiralLook.label(12, t)),
                    const SizedBox(height: 14),
                    _bestCard(t),
                    const SizedBox(height: 16),
                    _modeRow(t),
                    const SizedBox(height: 12),
                    _difficultyRow(t),
                    const SizedBox(height: 18),
                    SpiralButton(
                      label: 'Start dropping',
                      emoji: '⬇️',
                      primary: true,
                      onTap: () => _play(s.mode),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _miniBtn(t, '🎨 Themes', () {
                          widget.audio.click();
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (_) => ThemeScreen(
                                audio: widget.audio,
                                settings: s,
                                store: _storeService()),
                          ))
                              .then((_) => setState(() {}));
                        }),
                        _miniBtn(t, '⚙️ Settings', () {
                          widget.audio.click();
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                                audio: widget.audio,
                                settings: s,
                                store: _storeService()),
                          ))
                              .then((_) => setState(() {}));
                        }),
                        _miniBtn(
                            t,
                            s.isPro ? '⭐ PRO' : '⭐ Go Pro',
                            () {
                          widget.audio.click();
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (_) => ProScreen(
                                audio: widget.audio,
                                settings: s,
                                store: _storeService()),
                          ))
                              .then((_) => setState(() {}));
                        }),
                        _miniBtn(t, '📤 Share', _share),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _howTo(t),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bestCard(SpiralThemeDef t) {
    final s = widget.settings;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👤', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(s.playerName, style: SpiralLook.title(17, t)),
          const SizedBox(width: 16),
          Text('🏆 ${s.bestClassic}',
              style: SpiralLook.body(15, t)),
          const SizedBox(width: 12),
          Text('🌀 ${s.bestEndless}',
              style: SpiralLook.body(15, t)),
        ],
      ),
    );
  }

  Widget _modeRow(SpiralThemeDef t) {
    final s = widget.settings;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(
          t,
          '🏁 Classic',
          s.mode == SpiralMode.classic,
          () {
            widget.audio.click();
            s.setMode(SpiralMode.classic);
          },
        ),
        const SizedBox(width: 10),
        _chip(
          t,
          '∞ Endless',
          s.mode == SpiralMode.endless,
          () {
            widget.audio.click();
            s.setMode(SpiralMode.endless);
          },
        ),
      ],
    );
  }

  Widget _difficultyRow(SpiralThemeDef t) {
    final s = widget.settings;
    return Column(
      children: [
        Text('DIFFICULTY', style: SpiralLook.label(11, t)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (int d = 0;
                d < SpiralDifficulty.names.length;
                d++)
              _chip(
                t,
                (d == SpiralDifficulty.inferno ? '🔥 ' : '') +
                    SpiralDifficulty.names[d],
                s.difficulty == d,
                (d == SpiralDifficulty.inferno && !s.isPro)
                    ? null
                    : () {
                        widget.audio.click();
                        s.setDifficulty(d);
                      },
                locked:
                    d == SpiralDifficulty.inferno && !s.isPro,
              ),
          ],
        ),
        if (s.mode == SpiralMode.classic)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              SpiralDifficulty.descriptions[s.difficulty],
              style: SpiralLook.body(12, t),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _chip(SpiralThemeDef t, String label, bool selected,
      VoidCallback? onTap,
      {bool locked = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [
                  t.woodLight,
                  t.woodMid
                ])
              : null,
          color: selected ? null : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? t.accent
                : t.accent.withValues(alpha: 0.4),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          locked ? '$label 🔒' : label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: selected
                ? t.textOn
                : t.textOn.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(
      SpiralThemeDef t, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: t.woodMid.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: t.accent.withValues(alpha: 0.5), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 4),
                blurRadius: 8),
          ],
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: t.textOn)),
      ),
    );
  }

  Widget _howTo(SpiralThemeDef t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SpiralLook.panel(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW TO PLAY', style: SpiralLook.label(12, t)),
          const SizedBox(height: 8),
          _tip(t, '👉 Drag left / right to spin the tower.'),
          _tip(t, '🕳️ Drop the ball through the gaps.'),
          _tip(t, '🔴 Red zones smash you — steer clear!'),
          _tip(t,
              '🔥 Fall through 3+ platforms without bouncing to become a FIREBALL and smash everything.'),
          _tip(t,
              '🏁 Classic: clear every platform to climb levels. ∞ Endless: how deep can you go?'),
        ],
      ),
    );
  }

  Widget _tip(SpiralThemeDef t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(text, style: SpiralLook.body(13.5, t)),
      );
}

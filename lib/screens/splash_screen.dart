import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/spiral_themes.dart';
import '../widgets/spiral_widgets.dart';
import 'menu_screen.dart';

/// Launch splash: WAJIHA company moment, then the game splash with logo,
/// animated loading line and credits.
class SplashScreen extends StatefulWidget {
  final SpiralAudio audio;
  final SpiralSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyDone = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Company splash moment (official WAJIHA logo, untouched).
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _companyDone = true);
    // Pre-warm audio while the game splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF120B06),
      body: _companyDone
          ? _GameSplash(theme: theme, loader: _loader)
          : _CompanySplash(theme: theme),
    );
  }
}

class _CompanySplash extends StatelessWidget {
  final SpiralThemeDef theme;
  const _CompanySplash({required this.theme});

  @override
  Widget build(BuildContext context) {
    return WoodBackdrop(
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  Image.asset('assets/wajiha_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            Text('WAJIHA', style: SpiralLook.label(22, theme)),
          ],
        ),
      ),
    );
  }
}

class _GameSplash extends StatelessWidget {
  final SpiralThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return WoodBackdrop(
      theme: theme,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/spiraldrop_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text('Spiral Drop',
                  style: SpiralLook.display(46, theme)),
              const SizedBox(height: 6),
              Text('SPIN THE TOWER • THREAD THE GAPS',
                  style: SpiralLook.label(12, theme)),
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: theme.accent
                                  .withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor:
                              loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  theme.woodLight,
                                  theme.accent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loader.value < 1
                            ? 'Carving the tower…'
                            : 'Ready!',
                        style: SpiralLook.body(13, theme),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/wajiha_logo.png',
                      width: 30, height: 30, fit: BoxFit.contain),
                  const SizedBox(width: 10),
                  Text('Credits: WAJIHA',
                      style: SpiralLook.label(14, theme)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

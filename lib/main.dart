import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'widgets/spiral_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = SpiralSettings();
  await settings.load();
  final audio = SpiralAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(SpiralDropApp(settings: settings, audio: audio));
}

class SpiralDropApp extends StatefulWidget {
  final SpiralSettings settings;
  final SpiralAudio audio;
  const SpiralDropApp(
      {super.key, required this.settings, required this.audio});

  @override
  State<SpiralDropApp> createState() => _SpiralDropAppState();
}

class _SpiralDropAppState extends State<SpiralDropApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the engine's watchdog additionally auto-pauses play when
    // frames stop arriving.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final theme = widget.settings.theme;
        return SpiralThemeHolder(
          theme: theme,
          child: MaterialApp(
            title: 'Spiral Drop',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: theme.bgBottom,
              colorScheme: ColorScheme.dark(
                primary: theme.accent,
                surface: theme.bgBottom,
              ),
              fontFamily: 'Roboto',
            ),
            home: SplashScreen(
                audio: widget.audio, settings: widget.settings),
          ),
        );
      },
    );
  }
}

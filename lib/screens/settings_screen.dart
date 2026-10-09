import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/spiral_themes.dart';
import '../widgets/spiral_widgets.dart';

/// Settings: renameable profile, audio toggles + volume, Pro status.
class SettingsScreen extends StatefulWidget {
  final SpiralAudio audio;
  final SpiralSettings settings;
  final StoreService store;
  const SettingsScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.settings.playerName);
    // Commit the name when the field loses focus (final keystroke commit).
    _nameFocus = FocusNode()
      ..addListener(() {
        if (!_nameFocus.hasFocus) _commitName();
      });
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _applyAudio() {
    final s = widget.settings;
    widget.audio.configure(
        musicOn: s.musicOn, sfxOn: s.sfxOn, volume: s.volume);
    if (s.musicOn) {
      widget.audio.startMenuMusic();
    }
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
          title: Text('Settings', style: SpiralLook.title(22, t)),
        ),
        body: WoodBackdrop(
          theme: t,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section(t, 'PROFILE', [
                Text('Your spinner name',
                    style: SpiralLook.body(15, t)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14),
                        decoration: BoxDecoration(
                          color:
                              Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: t.accent
                                  .withValues(alpha: 0.5)),
                        ),
                        child: TextField(
                          controller: _name,
                          focusNode: _nameFocus,
                          maxLength: 16,
                          style: SpiralLook.body(17, t),
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            hintText: 'e.g. Tower Queen',
                            hintStyle: TextStyle(
                                color: t.muted,
                                fontWeight: FontWeight.w600),
                          ),
                          // Save on EVERY keystroke (never keyboard-done
                          // only), commit again on focus loss.
                          onChanged: (_) => _saveName(silent: true),
                          onSubmitted: (_) => _saveName(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _smallBtn(t, 'Save', _saveName),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Games played: ${s.gamesPlayed} • Best classic: ${s.bestClassic} • Best endless: ${s.bestEndless}',
                  style: SpiralLook.body(13, t),
                ),
              ]),
              const SizedBox(height: 16),
              _section(t, 'AUDIO', [
                _toggleRow(
                  t,
                  '🎵 Music',
                  s.musicOn,
                  (v) {
                    s.setMusic(v);
                    _applyAudio();
                  },
                ),
                _toggleRow(
                  t,
                  '🔊 Sound effects',
                  s.sfxOn,
                  (v) {
                    s.setSfx(v);
                    _applyAudio();
                  },
                ),
                const SizedBox(height: 10),
                Text('🔈 Volume', style: SpiralLook.body(15, t)),
                Slider(
                  value: s.volume,
                  min: 0,
                  max: 1,
                  activeColor: t.accent,
                  inactiveColor:
                      t.accent.withValues(alpha: 0.25),
                  onChanged: (v) {
                    s.setVolume(v);
                    _applyAudio();
                  },
                ),
              ]),
              const SizedBox(height: 16),
              _section(t, 'PRO', [
                Row(
                  children: [
                    Text(
                      s.isPro
                          ? '⭐ You are PRO — thank you!'
                          : '🆓 Free version',
                      style: SpiralLook.body(16, t),
                    ),
                    const Spacer(),
                    _smallBtn(t, 'Restore', () async {
                      widget.audio.click();
                      await widget.store.restore();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                              'Checking your purchases…'),
                          duration:
                              const Duration(seconds: 2),
                        ),
                      );
                    }),
                  ],
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  /// Persists the profile to the order-preserving JSON key on every
  /// keystroke; [silent] skips the unfocus so typing is uninterrupted.
  void _saveName({bool silent = false}) {
    if (!silent) {
      widget.audio.click();
      FocusScope.of(context).unfocus();
    }
    widget.settings.setPlayerName(_name.text);
    // Commit once more on focus loss so a trimmed final value lands.
    if (silent) return;
    setState(() {});
  }

  void _commitName() {
    widget.settings.setPlayerName(_name.text);
    setState(() {});
  }

  Widget _section(SpiralThemeDef t, String title, List<Widget> kids) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SpiralLook.panel(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SpiralLook.label(12, t)),
          const SizedBox(height: 10),
          ...kids,
        ],
      ),
    );
  }

  Widget _toggleRow(SpiralThemeDef t, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Text(label, style: SpiralLook.body(16, t)),
        const Spacer(),
        Switch(
          value: value,
          activeThumbColor: t.accent,
          onChanged: (v) {
            widget.audio.click();
            onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _smallBtn(SpiralThemeDef t, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [t.woodLight, t.woodMid]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.accent, width: 2),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: t.textOn,
                fontSize: 15)),
      ),
    );
  }
}

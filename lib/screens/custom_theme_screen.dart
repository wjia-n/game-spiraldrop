import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../widgets/spiral_widgets.dart';

/// Custom workshop: design your own tower theme and ball (Pro feature).
class CustomThemeScreen extends StatefulWidget {
  final SpiralAudio audio;
  final SpiralSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _towerKeys = [
    ('bgTop', 'Room top'),
    ('bgBottom', 'Room bottom'),
    ('woodDark', 'Dark wood'),
    ('woodMid', 'Platform wood'),
    ('woodLight', 'Wood highlight'),
    ('accent', 'Gold accent'),
    ('redZone', 'Danger red'),
  ];
  static const _ballKeys = [
    ('ball', 'Ball'),
    ('ballLight', 'Ball shine'),
    ('trail', 'Trail glow'),
  ];

  // A warm, physical palette — no neon.
  static const _swatches = [
    0xFF8B5A2B, 0xFF5C3A21, 0xFF3B2416, 0xFFC89B6A, 0xFFF0D8A8,
    0xFFB3322A, 0xFFD0542A, 0xFFE8B64C, 0xFFF0C060, 0xFFD8A8F0,
    0xFF9B59B6, 0xFF4A6A8A, 0xFF7AB8D4, 0xFF2E7A6A, 0xFF5E9A44,
    0xFF1E2A3A, 0xFF3A3A44, 0xFF8E8E9A, 0xFFF5EFE0, 0xFFFBF6E9,
  ];

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
          title: Text('My Workshop', style: SpiralLook.title(22, t)),
          bottom: TabBar(
            controller: _tabs,
            labelColor: t.accent,
            unselectedLabelColor: t.muted,
            indicatorColor: t.accent,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 15),
            tabs: const [
              Tab(text: '🗼 Tower'),
              Tab(text: '⚽ Ball'),
            ],
          ),
        ),
        body: WoodBackdrop(
          theme: t,
          child: TabBarView(
            controller: _tabs,
            children: [
              _editor(
                keys: _towerKeys,
                get: (k) => s.customThemeColors[k]!,
                set: (k, v) => s.setCustomThemeColor(k, v),
                useIt: () async {
                  widget.audio.click();
                  await s.setTheme('custom');
                  if (mounted) setState(() {});
                },
              ),
              _editor(
                keys: _ballKeys,
                get: (k) => s.customBallColors[k]!,
                set: (k, v) => s.setCustomBallColor(k, v),
                useIt: () async {
                  widget.audio.click();
                  await s.setBallStyle('custom');
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editor({
    required List<(String, String)> keys,
    required int Function(String) get,
    required Future<void> Function(String, int) set,
    required VoidCallback useIt,
  }) {
    final t = widget.settings.theme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (key, label) in keys) ...[
          Text(label, style: SpiralLook.body(15, t)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final sw in _swatches)
                GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    set(key, sw);
                    setState(() {});
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(sw),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: get(key) == sw
                            ? t.accent
                            : Colors.white24,
                        width: get(key) == sw ? 3.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.4),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: get(key) == sw
                        ? const Center(
                            child: Text('✓',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w900)))
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        Center(
          child: SpiralButton(
            label: 'Use my design',
            emoji: '✨',
            primary: true,
            onTap: useIt,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SpiralButton(
            label: 'Reset colors',
            emoji: '↩️',
            onTap: () async {
              widget.audio.click();
              if (_tabs.index == 0) {
                await widget.settings.resetCustomTheme();
              } else {
                await widget.settings.resetCustomBall();
              }
              if (mounted) setState(() {});
            },
          ),
        ),
      ],
    );
  }
}

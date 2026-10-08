import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const SpiralDropApp());

class SpiralDropApp extends StatelessWidget {
  const SpiralDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Spiral Drop',
      tagline: 'Spin the tower. Thread the gaps. Go nuclear.',
      emoji: '🌀',
      slug: 'spiraldrop',
      howToPlay:
          '• DRAG left/right to rotate the tower.\n• Drop the ball through the gaps — red zones smash you! 🔴\n• Fall through 3+ platforms without bouncing to become a FIREBALL and smash everything. 🔥\n• Clear all platforms to climb to the next level. 50+ levels of doom.',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => SpiralDropScreen(players: players, callbacks: cb),
    );
  }
}

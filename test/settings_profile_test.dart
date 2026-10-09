import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiraldrop/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpiralSettings profile', () {
    test('profile encodes/decodes as ONE JSON string (roundtrip)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final s = SpiralSettings();
      await s.load();
      await s.setPlayerName('Tower Queen');
      await s.setTheme('classic');
      await s.setBallStyle('ember');
      await s.setVolume(0.5);
      await s.setDifficulty(2);

      // The persisted profile must be a single JSON string key.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('spiraldrop_player_names_json');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!);
      expect(decoded, isA<Map>());
      expect(decoded['name'], 'Tower Queen');
      expect(decoded['ballStyleId'], 'ember');
      expect(decoded['difficulty'], 2);

      // Reload from disk: everything survives.
      final s2 = SpiralSettings();
      await s2.load();
      expect(s2.playerName, 'Tower Queen');
      expect(s2.ballStyleId, 'ember');
      expect(s2.volume, 0.5);
      expect(s2.difficulty, 2);
    });

    test('legacy best keys migrate into the profile once', () async {
      SharedPreferences.setMockInitialValues({
        'spiraldrop_best': 1234,
        'spiraldrop_best_level': 7,
      });
      final s = SpiralSettings();
      await s.load();
      expect(s.bestClassic, 1234);
      expect(s.bestLevel, 7);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('spiraldrop_best'), isFalse);
      expect(prefs.containsKey('spiraldrop_best_level'), isFalse);
      // And the migrated profile is now the JSON key.
      expect(prefs.containsKey('spiraldrop_player_names_json'), isTrue);
    });

    test('corrupt profile JSON falls back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'spiraldrop_player_names_json': 'not-json{{{',
      });
      final s = SpiralSettings();
      await s.load();
      expect(s.playerName, SpiralSettings.defaultName);
      expect(s.themeId, 'classic');
      expect(s.musicOn, isTrue);
    });

    test('free tier clamps Pro-only choices', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SpiralSettings();
      await s.load();
      // Free tier: setting a Pro theme is silently ignored.
      await s.setTheme('marble');
      expect(s.themeId, isNot('marble'));
      await s.setBallStyle('golden');
      expect(s.ballStyleId, isNot('golden'));
      // Inferno is clamped to Turbo for free users.
      await s.setDifficulty(3);
      expect(s.difficulty, 2);
      // Pro unlocks everything.
      await s.setPro(true);
      await s.setTheme('marble');
      expect(s.themeId, 'marble');
      await s.setBallStyle('golden');
      expect(s.ballStyleId, 'golden');
      await s.setDifficulty(3);
      expect(s.difficulty, 3);
    });

    test('empty name falls back to default', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SpiralSettings();
      await s.load();
      await s.setPlayerName('   ');
      expect(s.playerName, SpiralSettings.defaultName);
    });
  });
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/spiral_engine.dart';
import '../theme/spiral_themes.dart';

/// Persisted settings + profile + stats for Spiral Drop.
///
/// The player's profile is ONE JSON string under [_kProfile] — never
/// setStringList: Android stores StringLists as an unordered StringSet, which
/// scrambles ordered data. Everything order-sensitive lives in the JSON.
///
/// Legacy keys from older builds (spiraldrop_best, spiraldrop_best_level)
/// are migrated into the profile once, then removed.
class SpiralSettings extends ChangeNotifier {
  // Order-preserving JSON string for the player profile (player names are
  // the order-sensitive part). NEVER setStringList: Android persists
  // StringLists as an unordered StringSet, scrambling ordered data.
  static const _kProfile = 'spiraldrop_player_names_json';

  // Legacy keys (migrated once, then removed).
  static const _kLegacyBest = 'spiraldrop_best';
  static const _kLegacyBestLevel = 'spiraldrop_best_level';

  static const defaultName = 'Player';

  static String encodeProfile(Map<String, dynamic> profile) =>
      jsonEncode(profile);

  static Map<String, dynamic>? decodeProfile(String? raw) {
    if (raw == null) return null;
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return null;
  }

  String playerName = defaultName;
  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String themeId = 'classic';
  String ballStyleId = 'marble';
  int difficulty = SpiralDifficulty.classic;
  SpiralMode mode = SpiralMode.classic;
  bool isPro = true; // everything unlocked — no Pro version
  int gamesPlayed = 0;
  int bestClassic = 0;
  int bestEndless = 0; // best depth in endless
  int bestLevel = 0; // highest classic level reached
  int newBestCelebrated = 0; // how many times we celebrated a best

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Oak.
  Map<String, int> customThemeColors = Map.of(CustomThemeDefaults.colors);

  /// Custom ball-style colors (ARGB ints).
  Map<String, int> customBallColors = Map.of(CustomBallDefaults.colors);

  SpiralThemeDef get customTheme {
    Color c(String k) => Color(customThemeColors[k] ?? 0xFF000000);
    return SpiralThemeDef(
      id: 'custom',
      name: 'My Workshop',
      bgTop: c('bgTop'),
      bgBottom: c('bgBottom'),
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodLight: c('woodLight'),
      accent: c('accent'),
      redZone: c('redZone'),
      textOn: c('textOn'),
      muted: c('muted'),
    );
  }

  BallStyleDef get customBall {
    Color c(String k) => Color(customBallColors[k] ?? 0xFF000000);
    return BallStyleDef(
      id: 'custom',
      name: 'My Ball',
      isPro: true,
      ball: c('ball'),
      ballLight: c('ballLight'),
      trail: c('trail'),
    );
  }

  SpiralThemeDef get theme =>
      SpiralThemes.byId(themeId, custom: customTheme);

  BallStyleDef get ballStyle =>
      BallStyles.byId(ballStyleId, custom: customBall);

  int get bestForMode =>
      mode == SpiralMode.classic ? bestClassic : bestEndless;

  SharedPreferences? _prefs;

  Map<String, dynamic> _toJson() => {
        'name': playerName,
        'musicOn': musicOn,
        'sfxOn': sfxOn,
        'volume': volume,
        'themeId': themeId,
        'ballStyleId': ballStyleId,
        'difficulty': difficulty,
        'mode': mode.name,
        'isPro': isPro,
        'gamesPlayed': gamesPlayed,
        'bestClassic': bestClassic,
        'bestEndless': bestEndless,
        'bestLevel': bestLevel,
        'newBestCelebrated': newBestCelebrated,
        'customTheme': customThemeColors,
        'customBall': customBallColors,
      };

  void _fromJson(Map<String, dynamic> d) {
    String str(String k, String fallback) =>
        d[k] is String && (d[k] as String).isNotEmpty
            ? (d[k] as String).trim()
            : fallback;
    playerName = str('name', defaultName);
    musicOn = d['musicOn'] is bool ? d['musicOn'] as bool : true;
    sfxOn = d['sfxOn'] is bool ? d['sfxOn'] as bool : true;
    volume = (d['volume'] is num ? (d['volume'] as num).toDouble() : 0.8)
        .clamp(0.0, 1.0);
    themeId = str('themeId', 'classic');
    ballStyleId = str('ballStyleId', 'marble');
    difficulty = (d['difficulty'] is int ? d['difficulty'] as int : 1)
        .clamp(0, 3);
    mode = d['mode'] == 'endless' ? SpiralMode.endless : SpiralMode.classic;
    isPro = d['isPro'] is bool ? d['isPro'] as bool : false;
    gamesPlayed = d['gamesPlayed'] is int ? d['gamesPlayed'] as int : 0;
    bestClassic = d['bestClassic'] is int ? d['bestClassic'] as int : 0;
    bestEndless = d['bestEndless'] is int ? d['bestEndless'] as int : 0;
    bestLevel = d['bestLevel'] is int ? d['bestLevel'] as int : 0;
    newBestCelebrated =
        d['newBestCelebrated'] is int ? d['newBestCelebrated'] as int : 0;
    if (d['customTheme'] is Map) {
      for (final k in CustomThemeDefaults.colors.keys) {
        final v = (d['customTheme'] as Map)[k];
        if (v is int) customThemeColors[k] = v;
      }
    }
    if (d['customBall'] is Map) {
      for (final k in CustomBallDefaults.colors.keys) {
        final v = (d['customBall'] as Map)[k];
        if (v is int) customBallColors[k] = v;
      }
    }
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    final raw = p.getString(_kProfile);
    final d = decodeProfile(raw);
    if (d != null) {
      _fromJson(d);
    } else {
      // One-time migration of legacy flat keys from older builds.
      final legacyBest = p.getInt(_kLegacyBest);
      final legacyBestLevel = p.getInt(_kLegacyBestLevel);
      if (legacyBest != null && legacyBest > 0) {
        bestClassic = legacyBest;
      }
      if (legacyBestLevel != null && legacyBestLevel > 0) {
        bestLevel = legacyBestLevel;
      }
    }
    await p.remove(_kLegacyBest);
    await p.remove(_kLegacyBestLevel);
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kProfile, encodeProfile(_toJson()));
  }

  /// Free-tier limits: clamp Pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || SpiralThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (ballStyleId == 'custom' || BallStyles.isPro(ballStyleId)) {
      ballStyleId = 'marble';
      changed = true;
    }
    if (difficulty > SpiralDifficulty.turbo) {
      difficulty = SpiralDifficulty.turbo;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. custom) require Pro; silently ignore otherwise.
    if (!isPro && (id == 'custom' || SpiralThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBallStyle(String id) async {
    if (!isPro && (id == 'custom' || BallStyles.isPro(id))) return;
    ballStyleId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomThemeColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!CustomThemeDefaults.colors.containsKey(key)) return;
    customThemeColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomTheme() async {
    customThemeColors = Map.of(CustomThemeDefaults.colors);
    notifyListeners();
    await _save();
  }

  Future<void> setCustomBallColor(String key, int argb) async {
    if (!isPro) return; // custom ball creator is a Pro feature
    if (!CustomBallDefaults.colors.containsKey(key)) return;
    customBallColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomBall() async {
    customBallColors = Map.of(CustomBallDefaults.colors);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int d) async {
    difficulty = d.clamp(0, 3);
    // Inferno is a Pro feature.
    if (!isPro && difficulty > SpiralDifficulty.turbo) {
      difficulty = SpiralDifficulty.turbo;
    }
    notifyListeners();
    await _save();
  }

  Future<void> setMode(SpiralMode m) async {
    mode = m;
    notifyListeners();
    await _save();
  }

  /// Record a finished run. Returns true if it set a new best.
  Future<bool> recordRun(
      {required SpiralMode runMode, required int score, required int level}) async {
    gamesPlayed++;
    var newBest = false;
    if (runMode == SpiralMode.classic) {
      if (score > bestClassic) {
        bestClassic = score;
        newBest = true;
      }
      if (level > bestLevel) bestLevel = level;
    } else {
      if (score > bestEndless) {
        bestEndless = score;
        newBest = true;
      }
    }
    notifyListeners();
    await _save();
    return newBest;
  }

  Future<void> markBestCelebrated() async {
    newBestCelebrated++;
    notifyListeners();
    await _save();
  }
}

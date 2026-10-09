import 'package:flutter/material.dart';

/// Theme + ball-style catalog for Spiral Drop.
///
/// Every theme stays inside the physical-material world (real woods, stone,
/// clay, brass) — the variety comes from different woods, metals and room
/// light, never neon or synthetic looks.
class SpiralThemeDef {
  final String id;
  final String name;
  final Color bgTop; // room backdrop gradient
  final Color bgBottom;
  final Color woodDark; // column + platform edges
  final Color woodMid; // platform face
  final Color woodLight; // platform highlight
  final Color accent; // gap trim, HUD accents
  final Color redZone; // danger material
  final Color textOn;
  final Color muted;

  const SpiralThemeDef({
    required this.id,
    required this.name,
    required this.bgTop,
    required this.bgBottom,
    required this.woodDark,
    required this.woodMid,
    required this.woodLight,
    required this.accent,
    required this.redZone,
    required this.textOn,
    required this.muted,
  });
}

class SpiralThemes {
  /// First 4 are FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'mahogany',
    'walnut',
    'maple',
  ];

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';

  static const List<SpiralThemeDef> all = [
    SpiralThemeDef(
      id: 'classic',
      name: 'Classic Oak',
      bgTop: Color(0xFF2E1D10),
      bgBottom: Color(0xFF1A1009),
      woodDark: Color(0xFF4A2C14),
      woodMid: Color(0xFF8B5A2B),
      woodLight: Color(0xFFC89B6A),
      accent: Color(0xFFE8B64C),
      redZone: Color(0xFFB3322A),
      textOn: Color(0xFFF7EBD7),
      muted: Color(0xFF9A7B58),
    ),
    SpiralThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      bgTop: Color(0xFF33140E),
      bgBottom: Color(0xFF1C0B06),
      woodDark: Color(0xFF5A1F12),
      woodMid: Color(0xFF9E3B20),
      woodLight: Color(0xFFD47A55),
      accent: Color(0xFFF0C060),
      redZone: Color(0xFFC22E2E),
      textOn: Color(0xFFFAEEDD),
      muted: Color(0xFFA87B60),
    ),
    SpiralThemeDef(
      id: 'walnut',
      name: 'Walnut Night',
      bgTop: Color(0xFF23262E),
      bgBottom: Color(0xFF121418),
      woodDark: Color(0xFF2E2A24),
      woodMid: Color(0xFF5E544A),
      woodLight: Color(0xFF9A8B76),
      accent: Color(0xFFD8C29A),
      redZone: Color(0xFFA83232),
      textOn: Color(0xFFF2ECE0),
      muted: Color(0xFF8A8578),
    ),
    SpiralThemeDef(
      id: 'maple',
      name: 'Autumn Maple',
      bgTop: Color(0xFF3A2413),
      bgBottom: Color(0xFF201206),
      woodDark: Color(0xFF6E441C),
      woodMid: Color(0xFFC07F34),
      woodLight: Color(0xFFF0B96E),
      accent: Color(0xFFB3452A),
      redZone: Color(0xFF9E2B1E),
      textOn: Color(0xFFFBF0DC),
      muted: Color(0xFFB08A5E),
    ),
    SpiralThemeDef(
      id: 'marble',
      name: 'Marble Palace',
      bgTop: Color(0xFF2A2A30),
      bgBottom: Color(0xFF141416),
      woodDark: Color(0xFF4A4A52),
      woodMid: Color(0xFF8E8E9A),
      woodLight: Color(0xFFCFCFDA),
      accent: Color(0xFFE0B64F),
      redZone: Color(0xFFB03040),
      textOn: Color(0xFFFBF8F0),
      muted: Color(0xFF9A9AA4),
    ),
    SpiralThemeDef(
      id: 'ocean',
      name: 'Ocean Deep',
      bgTop: Color(0xFF0F2A33),
      bgBottom: Color(0xFF071418),
      woodDark: Color(0xFF14333C),
      woodMid: Color(0xFF2A5A64),
      woodLight: Color(0xFF5E9AA4),
      accent: Color(0xFF7FD4C1),
      redZone: Color(0xFFC0392B),
      textOn: Color(0xFFF0F7F4),
      muted: Color(0xFF6E9AA0),
    ),
    SpiralThemeDef(
      id: 'candy',
      name: 'Candy Shop',
      bgTop: Color(0xFF3B1E2E),
      bgBottom: Color(0xFF1E0E16),
      woodDark: Color(0xFF6E2E44),
      woodMid: Color(0xFFC05A78),
      woodLight: Color(0xFFF09AB0),
      accent: Color(0xFFF7D774),
      redZone: Color(0xFFB02A3A),
      textOn: Color(0xFFFFF2F6),
      muted: Color(0xFFB07E92),
    ),
    SpiralThemeDef(
      id: 'desert',
      name: 'Desert Sand',
      bgTop: Color(0xFF3A2A18),
      bgBottom: Color(0xFF1E1408),
      woodDark: Color(0xFF5E4420),
      woodMid: Color(0xFFA87E44),
      woodLight: Color(0xFFE0B878),
      accent: Color(0xFFD0543A),
      redZone: Color(0xFFA02E1E),
      textOn: Color(0xFFFBF2DE),
      muted: Color(0xFFB09662),
    ),
    SpiralThemeDef(
      id: 'forest',
      name: 'Forest Moss',
      bgTop: Color(0xFF1E2E1A),
      bgBottom: Color(0xFF0E160C),
      woodDark: Color(0xFF2E4024),
      woodMid: Color(0xFF5E7A44),
      woodLight: Color(0xFF9AB86E),
      accent: Color(0xFFD8B24A),
      redZone: Color(0xFFB03A2A),
      textOn: Color(0xFFF2F6E8),
      muted: Color(0xFF8AA070),
    ),
    SpiralThemeDef(
      id: 'ruby',
      name: 'Royal Ruby',
      bgTop: Color(0xFF33141E),
      bgBottom: Color(0xFF180810),
      woodDark: Color(0xFF521E2E),
      woodMid: Color(0xFF94405A),
      woodLight: Color(0xFFD07A96),
      accent: Color(0xFFF0C060),
      redZone: Color(0xFF8E1E2E),
      textOn: Color(0xFFFAEEF2),
      muted: Color(0xFFA8728A),
    ),
    SpiralThemeDef(
      id: 'clay',
      name: 'Terracotta Clay',
      bgTop: Color(0xFF33200F),
      bgBottom: Color(0xFF181006),
      woodDark: Color(0xFF5E3A1E),
      woodMid: Color(0xFFA86834),
      woodLight: Color(0xFFE0A068),
      accent: Color(0xFF4A7A6A),
      redZone: Color(0xFF96301E),
      textOn: Color(0xFFFBF0DE),
      muted: Color(0xFFA8845E),
    ),
    SpiralThemeDef(
      id: 'porcelain',
      name: 'Blush Porcelain',
      bgTop: Color(0xFF33242A),
      bgBottom: Color(0xFF181016),
      woodDark: Color(0xFF4E3440),
      woodMid: Color(0xFF8E5E70),
      woodLight: Color(0xFFD09AAE),
      accent: Color(0xFFE8C87A),
      redZone: Color(0xFFA83A44),
      textOn: Color(0xFFFFF4F6),
      muted: Color(0xFF9E7E8E),
    ),
  ];

  static SpiralThemeDef byId(String id, {SpiralThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Ball + trail visual style. Free: first 4. Pro: rest + custom creator.
class BallStyleDef {
  final String id;
  final String name;
  final bool isPro;
  final Color ball; // main sphere color
  final Color ballLight; // highlight
  final Color trail; // trail/glow color
  final bool marbled; // draw marble veins

  const BallStyleDef({
    required this.id,
    required this.name,
    required this.isPro,
    required this.ball,
    required this.ballLight,
    required this.trail,
    this.marbled = false,
  });
}

class BallStyles {
  static const List<BallStyleDef> all = [
    BallStyleDef(
      id: 'marble', name: 'Marble', isPro: false,
      ball: Color(0xFFDDE4EA), ballLight: Color(0xFFFFFFFF),
      trail: Color(0xFF9FB4C8), marbled: true,
    ),
    BallStyleDef(
      id: 'ember', name: 'Ember', isPro: false,
      ball: Color(0xFFD0542A), ballLight: Color(0xFFFFC06E),
      trail: Color(0xFFFF7A2A),
    ),
    BallStyleDef(
      id: 'frost', name: 'Frost', isPro: false,
      ball: Color(0xFF7AB8D4), ballLight: Color(0xFFD8F0FC),
      trail: Color(0xFF4A9AC4),
    ),
    BallStyleDef(
      id: 'steel', name: 'Steel', isPro: false,
      ball: Color(0xFF6E7680), ballLight: Color(0xFFC8D0DA),
      trail: Color(0xFF8A94A0),
    ),
    BallStyleDef(
      id: 'oak', name: 'Oakwood', isPro: true,
      ball: Color(0xFF8B5A2B), ballLight: Color(0xFFD8A868),
      trail: Color(0xFFA8703A),
    ),
    BallStyleDef(
      id: 'ocean', name: 'Deep Sea', isPro: true,
      ball: Color(0xFF1E6A8A), ballLight: Color(0xFF7AD4E8),
      trail: Color(0xFF2A9AC4),
    ),
    BallStyleDef(
      id: 'candy', name: 'Candy', isPro: true,
      ball: Color(0xFFD44A7A), ballLight: Color(0xFFFFB0CC),
      trail: Color(0xFFFF7AAE),
    ),
    BallStyleDef(
      id: 'golden', name: 'Golden', isPro: true,
      ball: Color(0xFFC8922A), ballLight: Color(0xFFFFE8A8),
      trail: Color(0xFFF0B83A),
    ),
  ];

  static BallStyleDef byId(String id, {BallStyleDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  static bool isPro(String id) =>
      id == 'custom' || all.any((s) => s.id == id && s.isPro);
}

/// Default custom-creator colors (ARGB ints) for the custom ball style.
class CustomBallDefaults {
  static const Map<String, int> colors = {
    'ball': 0xFF9B59B6,
    'ballLight': 0xFFD8A8F0,
    'trail': 0xFF7A3AC4,
  };
}

/// Default custom-creator theme colors (ARGB ints) for the custom theme.
class CustomThemeDefaults {
  static const Map<String, int> colors = {
    'bgTop': 0xFF2E1D10,
    'bgBottom': 0xFF1A1009,
    'woodDark': 0xFF4A2C14,
    'woodMid': 0xFF8B5A2B,
    'woodLight': 0xFFC89B6A,
    'accent': 0xFFE8B64C,
    'redZone': 0xFFB3322A,
    'textOn': 0xFFF7EBD7,
    'muted': 0xFF9A7B58,
  };
}

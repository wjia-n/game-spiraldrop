import 'package:flutter/material.dart';
import '../theme/spiral_themes.dart';

/// Shared physical-material look helpers for Spiral Drop.
class SpiralLook {
  static TextStyle display(double size, SpiralThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: t.textOn,
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 6),
        ],
      );

  static TextStyle title(double size, SpiralThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: t.textOn,
        shadows: const [
          Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, SpiralThemeDef t, {Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? t.textOn.withValues(alpha: 0.92),
      );

  static TextStyle label(double size, SpiralThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: t.accent,
        letterSpacing: 2.0,
      );

  static BoxDecoration panel(SpiralThemeDef t) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.woodDark, t.woodDark.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.accent.withValues(alpha: 0.55), width: 2),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, offset: Offset(0, 8), blurRadius: 20),
          BoxShadow(
              color: Colors.white10,
              offset: Offset(0, 1),
              blurRadius: 0,
              spreadRadius: 0),
        ],
      );
}

/// Chunky wooden arcade button with physical press feedback.
class SpiralButton extends StatefulWidget {
  final String label;
  final String emoji;
  final VoidCallback onTap;
  final bool primary;
  final bool locked;
  final double width;

  const SpiralButton({
    super.key,
    required this.label,
    required this.onTap,
    this.emoji = '',
    this.primary = false,
    this.locked = false,
    this.width = 260,
  });

  @override
  State<SpiralButton> createState() => _SpiralButtonState();
}

class _SpiralButtonState extends State<SpiralButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = SpiralThemeHolder.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.locked ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        transform: Matrix4.translationValues(
            0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.primary
                ? [t.woodLight, t.woodMid]
                : [t.woodMid.withValues(alpha: 0.95), t.woodDark],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.primary
                ? t.accent
                : t.accent.withValues(alpha: 0.6),
            width: widget.primary ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: Offset(0, _pressed ? 1 : 6),
              blurRadius: _pressed ? 3 : 12,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.12),
              offset: const Offset(0, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.locked)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('🔒', style: TextStyle(fontSize: 18)),
              )
            else if (widget.emoji.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(widget.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: t.textOn,
                  letterSpacing: 0.6,
                  shadows: const [
                    Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inherited holder so widgets can grab the active theme cheaply.
class SpiralThemeHolder extends InheritedWidget {
  final SpiralThemeDef theme;
  const SpiralThemeHolder(
      {super.key, required this.theme, required super.child});

  static SpiralThemeDef of(BuildContext context) {
    final h =
        context.dependOnInheritedWidgetOfExactType<SpiralThemeHolder>();
    assert(h != null, 'No SpiralThemeHolder in tree');
    return h!.theme;
  }

  @override
  bool updateShouldNotify(SpiralThemeHolder old) => old.theme != theme;
}

/// Wooden backdrop: room gradient + vignette + subtle floorboards.
class WoodBackdrop extends StatelessWidget {
  final SpiralThemeDef theme;
  final Widget child;
  const WoodBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.bgTop, theme.bgBottom],
        ),
      ),
      child: Stack(
        children: [
          // soft vignette
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

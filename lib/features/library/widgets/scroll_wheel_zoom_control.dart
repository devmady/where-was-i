import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A small metal-gear-styled control for zooming the Library grid's
/// card size — a side view of a rotating toothed cylinder, shaded to
/// read as a genuinely 3D glossy metal object rather than a flat
/// painted bar (drop shadow, glossy highlight cap, beveled teeth,
/// double-line rim). Drag left/right (or scroll your real mouse
/// wheel while hovering) to zoom; the teeth and a specular highlight
/// scroll in sync to read as rotation, independent of the clamped
/// zoom value, so it keeps turning even at the min/max size limits.
///
/// Intentionally uses fixed grey/silver tones instead of
/// Theme.of(context).colorScheme — meant to read as a physical metal
/// object, which shouldn't tint with the app's teal/terracotta
/// accents in dark mode.
class ScrollWheelZoomControl extends StatefulWidget {
  const ScrollWheelZoomControl({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  State<ScrollWheelZoomControl> createState() => _ScrollWheelZoomControlState();
}

class _ScrollWheelZoomControlState extends State<ScrollWheelZoomControl> {
  double _scrollOffset = 0;

  void _applyDelta(double delta) {
    final range = widget.max - widget.min;
    final next = (widget.value + delta / 200 * range).clamp(widget.min, widget.max);
    widget.onChanged(next);
    setState(() => _scrollOffset += delta);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _applyDelta(-event.scrollDelta.dy);
        }
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) => _applyDelta(details.delta.dx),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: SizedBox(
            width: 72,
            height: 40,
            child: CustomPaint(
              size: const Size(72, 40),
              painter: _WheelSidePainter(scrollOffset: _scrollOffset),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelSidePainter extends CustomPainter {
  _WheelSidePainter({required this.scrollOffset});

  final double scrollOffset;

  static const double _toothSpacing = 10;
  static const double _toothWidth = 7;
  static const double _toothFlatTop = 3;
  static const double _toothHeight = 5;
  static const double _highlightSpacing = 34;
  static const double _highlightWidth = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = Rect.fromLTWH(0, _toothHeight + 3, size.width, size.height - (_toothHeight + 3) * 2);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(bodyRect.height / 2));

    // Drop shadow — lifts the whole wheel off the background.
    canvas.drawRRect(
      bodyRRect.shift(const Offset(0, 2.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    canvas.save();
    canvas.clipRRect(bodyRRect);

    // Base metal — vertical gradient, light band near the top.
    const metalGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFC2C2C2),
        Color(0xFFF6F6F6),
        Color(0xFFA0A0A0),
        Color(0xFF6E6E6E),
        Color(0xFF444444),
      ],
      stops: [0.0, 0.18, 0.5, 0.8, 1.0],
    );
    canvas.drawRect(bodyRect, Paint()..shader = metalGradient.createShader(bodyRect));

    // Glossy highlight cap — the classic skeuomorphic "shine" band
    // that makes a flat gradient read as a rounded, glossy surface.
    final glossRect = Rect.fromLTWH(
      bodyRect.left + bodyRect.width * 0.06,
      bodyRect.top + bodyRect.height * 0.08,
      bodyRect.width * 0.88,
      bodyRect.height * 0.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, Radius.circular(glossRect.height / 2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.0)],
        ).createShader(glossRect),
    );

    // Ambient occlusion — faint darkening near the bottom edge, so
    // the surface reads as curving away into shadow.
    final shadeRect = Rect.fromLTWH(
      bodyRect.left,
      bodyRect.bottom - bodyRect.height * 0.22,
      bodyRect.width,
      bodyRect.height * 0.22,
    );
    canvas.drawRect(
      shadeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.22)],
        ).createShader(shadeRect),
    );

    // Rotating specular streaks — scroll in sync with the teeth so
    // the whole thing reads as turning, not just a sliding pattern.
    final highlightShift = scrollOffset % _highlightSpacing;
    for (var x = -_highlightSpacing + highlightShift; x < size.width + _highlightSpacing; x += _highlightSpacing) {
      final streakRect = Rect.fromLTWH(x, bodyRect.top, _highlightWidth, bodyRect.height);
      canvas.drawRect(
        streakRect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(streakRect),
      );
    }
    canvas.restore();

    // Teeth — flat-topped trapezoids with a small top-edge highlight
    // so each tooth reads as a 3D block, not a flat grey shape.
    final toothFill = Paint()..color = const Color(0xFF5E5E5E);
    final toothHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.5);
    final leadIn = (_toothWidth - _toothFlatTop) / 2;
    final shift = scrollOffset % _toothSpacing;

    for (var x = -_toothSpacing + shift; x < size.width + _toothSpacing; x += _toothSpacing) {
      final topPeak = bodyRect.top - _toothHeight;
      final topTip1 = Offset(x + leadIn, topPeak);
      final topTip2 = Offset(x + leadIn + _toothFlatTop, topPeak);
      final topTooth = Path()
        ..moveTo(x, bodyRect.top)
        ..lineTo(topTip1.dx, topTip1.dy)
        ..lineTo(topTip2.dx, topTip2.dy)
        ..lineTo(x + _toothWidth, bodyRect.top)
        ..close();
      canvas.drawPath(topTooth, toothFill);
      canvas.drawLine(topTip1, topTip2, toothHighlight);

      final bottomPeak = bodyRect.bottom + _toothHeight;
      final bottomTooth = Path()
        ..moveTo(x, bodyRect.bottom)
        ..lineTo(x + leadIn, bottomPeak)
        ..lineTo(x + leadIn + _toothFlatTop, bottomPeak)
        ..lineTo(x + _toothWidth, bodyRect.bottom)
        ..close();
      canvas.drawPath(bottomTooth, toothFill);
    }

    // Double-line rim — a dark outer edge plus a thin bright inner
    // line just inside it, like a polished metal lip.
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF2E2E2E).withValues(alpha: 0.75),
    );
    canvas.drawRRect(
      bodyRRect.deflate(1.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelSidePainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}
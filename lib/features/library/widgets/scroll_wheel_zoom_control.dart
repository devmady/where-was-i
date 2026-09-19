import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A small metal-styled control for zooming the Library grid's card
/// size — a smooth horizontal cylinder with knurled ridges cut into
/// its curved surface and a rounded (elliptical, foreshortened) end
/// on the right so it reads as round rather than a flat bar. Drag
/// left/right (or scroll your real mouse wheel while hovering) to
/// zoom; the ridges and surface shading scroll along the body like a
/// tread — the physically correct way to show a cylinder spinning on
/// its own axis viewed from the side — independent of the clamped
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
            width: 86,
            height: 40,
            child: CustomPaint(
              size: const Size(86, 40),
              painter: _WheelCylinderPainter(scrollOffset: _scrollOffset),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelCylinderPainter extends CustomPainter {
  _WheelCylinderPainter({required this.scrollOffset});

  final double scrollOffset;

  static const double _endRadiusX = 9;
  static const double _ridgeSpacing = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = Rect.fromLTWH(0, 3, size.width, size.height - 6);
    final mainRight = size.width - _endRadiusX;
    final barrelRect = Rect.fromLTWH(0, bodyRect.top, mainRight, bodyRect.height);

    // One combined silhouette — straight barrel unioned with a
    // foreshortened ellipse at the right end — so the fill gradient
    // and shading flow across both as a single continuous surface.
    final barrelPath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        barrelRect,
        topLeft: const Radius.circular(3),
        bottomLeft: const Radius.circular(3),
      ));
    final endEllipseRect = Rect.fromCenter(
      center: Offset(mainRight, bodyRect.top + bodyRect.height / 2),
      width: _endRadiusX * 2,
      height: bodyRect.height,
    );
    final endPath = Path()..addOval(endEllipseRect);
    final wholePath = Path.combine(PathOperation.union, barrelPath, endPath);

    // Drop shadow.
    canvas.drawPath(
      wholePath.shift(const Offset(0, 2.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    canvas.save();
    canvas.clipPath(wholePath);

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
    final fullBounds = Rect.fromLTWH(0, bodyRect.top, size.width, bodyRect.height);
    canvas.drawRect(fullBounds, Paint()..shader = metalGradient.createShader(fullBounds));

    // Knurled ridges — grooves cut into the curved surface. Each is
    // a dark shadow line with a bright lip just after it, which is
    // what reads as a raised edge catching light. They're inset from
    // the top/bottom edges because on a real cylinder the ridges
    // curve away and flatten out of view near the silhouette.
    final ridgeInset = bodyRect.height * 0.16;
    final ridgeTop = bodyRect.top + ridgeInset;
    final ridgeBottom = bodyRect.bottom - ridgeInset;
    final ridgeShift = scrollOffset % _ridgeSpacing;

    for (var x = -_ridgeSpacing + ridgeShift; x < size.width; x += _ridgeSpacing) {
      // Groove shadow.
      canvas.drawLine(
        Offset(x, ridgeTop),
        Offset(x, ridgeBottom),
        Paint()
          ..strokeWidth = 1.2
          ..color = Colors.black.withValues(alpha: 0.16),
      );
      // Highlight lip on the trailing side of the groove.
      canvas.drawLine(
        Offset(x + 1.4, ridgeTop),
        Offset(x + 1.4, ridgeBottom),
        Paint()
          ..strokeWidth = 0.8
          ..color = Colors.white.withValues(alpha: 0.22),
      );
    }

    // Glossy highlight cap — drawn over the ridges so the whole
    // surface still reads as one continuous glossy cylinder.
    final glossRect = Rect.fromLTWH(
      2,
      bodyRect.top + bodyRect.height * 0.06,
      size.width - 4,
      bodyRect.height * 0.34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, Radius.circular(glossRect.height / 2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.0)],
        ).createShader(glossRect),
    );

    // Edge darkening top and bottom — the surface curving away from
    // the viewer at the silhouette, which is what sells roundness.
    final topEdge = Rect.fromLTWH(0, bodyRect.top, size.width, bodyRect.height * 0.2);
    canvas.drawRect(
      topEdge,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.3), Colors.black.withValues(alpha: 0.0)],
        ).createShader(topEdge),
    );
    final bottomEdge = Rect.fromLTWH(
      0,
      bodyRect.bottom - bodyRect.height * 0.26,
      size.width,
      bodyRect.height * 0.26,
    );
    canvas.drawRect(
      bottomEdge,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.42)],
        ).createShader(bottomEdge),
    );

    canvas.restore();

    // Outer rim — dark outline plus a thin bright inner line, like a
    // polished metal lip catching light.
    canvas.drawPath(
      wholePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF262626).withValues(alpha: 0.8),
    );

    // Seam where the rounded end meets the barrel — a subtle arc that
    // hints at the cylinder's end cap without drawing a hard edge.
    canvas.drawArc(
      endEllipseRect,
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelCylinderPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

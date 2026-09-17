import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A small vertical control styled like a mouse's scroll wheel —
/// a ridged capsule you drag vertically (or scroll over, on
/// desktop/web) to zoom the Library grid's card size in and out.
///
/// Dragging/scrolling up = bigger cards (zoom in, fewer columns).
/// Dragging/scrolling down = smaller cards (zoom out, more columns).
class ScrollWheelZoomControl extends StatelessWidget {
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

  void _applyDelta(double dyDelta) {
    final range = max - min;
    // Dragging/scrolling UP (negative dy) increases value (zoom in).
    final next = (value - dyDelta / 200 * range).clamp(min, max);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _applyDelta(-event.scrollDelta.dy);
        }
      },
      child: GestureDetector(
        onVerticalDragUpdate: (details) => _applyDelta(details.delta.dy),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: Container(
            width: 26,
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (_) {
                return Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

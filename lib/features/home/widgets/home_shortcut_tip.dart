import 'package:flutter/material.dart';

import '../state/home_tip_store.dart';

/// A small bubble above the floating nav that explains the press and hold
/// shortcut on the Home icon. Place it inside a Positioned.fill in a Stack.
class HomeShortcutTip extends StatelessWidget {
  const HomeShortcutTip({super.key});

  /// Space kept clear for the floating nav pill.
  static const double _navClearance = 100;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<bool>(
      valueListenable: HomeTipStore.instance.visible,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: _navClearance),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 262),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      decoration: BoxDecoration(
                        color: colors.inverseSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Tip: press and hold Home to add a book from '
                            'anywhere.',
                            style: textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                              color: colors.onInverseSurface,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: HomeTipStore.instance.dismiss,
                              style: TextButton.styleFrom(
                                foregroundColor: colors.inversePrimary,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Got it'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(18, 9),
                    painter: _CaretPainter(color: colors.inverseSurface),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => oldDelegate.color != color;
}

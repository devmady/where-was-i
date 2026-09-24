import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';

/// The reader's avatar: a library stamp — their initial inside a dashed
/// ring — or a photo from this device when one is set.
class MonogramAvatar extends StatelessWidget {
  const MonogramAvatar({
    super.key,
    required this.initial,
    required this.size,
    this.photoPath,
  });

  final String initial;
  final double size;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ringInset = size * 0.083;

    final stamp = Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(ringInset),
            child: CustomPaint(
              painter: _DashedRingPainter(
                color: colors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        Text(
          initial,
          style: AppFonts.serifStyle(
            size: size * 0.41,
            color: colors.onPrimaryContainer,
          ),
        ),
      ],
    );

    final path = photoPath;

    return Semantics(
      image: true,
      label: 'Profile picture',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primaryContainer,
          border: Border.all(
            color: colors.primary,
            width: size > 100 ? 2 : 1.5,
          ),
        ),
        child: path == null
            ? stamp
            : ClipOval(
                child: Image.file(
                  File(path),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  // Photo deleted or moved: fall back to the stamp.
                  errorBuilder: (context, error, stackTrace) => stamp,
                ),
              ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  static const double _dash = 2;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final ring = Path()..addOval(Offset.zero & size);
    for (final metric in ring.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

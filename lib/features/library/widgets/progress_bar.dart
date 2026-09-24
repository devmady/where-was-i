import 'package:flutter/material.dart';

/// A slim progress bar. Terracotta means where you are now, matching the
/// spines on the profile shelf.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 4});

  /// From 0.0 to 1.0.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: colors.outlineVariant,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0).toDouble(),
              child: ColoredBox(color: colors.secondary),
            ),
          ),
        ),
      ),
    );
  }
}

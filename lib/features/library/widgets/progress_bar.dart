import 'package:flutter/material.dart';

/// A slim progress bar. Teal fill means where you are now, matching the
/// app's primary accent used for active state elsewhere (nav bar, buttons).
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 4});

  /// From 0.0 to 1.0.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clamped = value.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: colors.surfaceContainerHigh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * clamped,
                  height: height,
                  color: colors.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

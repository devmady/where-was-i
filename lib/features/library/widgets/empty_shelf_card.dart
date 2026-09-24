import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/dashed_border.dart';

/// Shown when there are no books yet: an empty shelf with a dashed slot for
/// the first book, and one clear action.
class EmptyShelfCard extends StatelessWidget {
  const EmptyShelfCard({super.key, required this.onAdd});

  final VoidCallback onAdd;

  static const List<double> _heights = [34, 42, 30, 38, 44, 32, 40, 36, 30];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final height in _heights) ...[
                      Container(
                        width: 14,
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: colors.outline, width: 1.25),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    DashedBorder(
                      color: colors.primary,
                      radius: 3,
                      child: const SizedBox(width: 14, height: 46),
                    ),
                  ],
                ),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your shelf is empty',
            style: AppFonts.serifStyle(
              size: 24,
              height: 1.25,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add the book you are reading and we will keep your place.',
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              height: 1.45,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add your first book'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

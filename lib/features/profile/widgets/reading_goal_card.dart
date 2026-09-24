import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../state/profile_store.dart';

/// 12 of 24 books with a shelf of book spines underneath.
///
/// Each spine is one book toward the yearly goal:
///  * filled teal  = finished
///  * part-filled terracotta = in progress (fill height = how far through)
///  * outlined = still to go
///
/// Finished vs. in-progress differ by fill pattern as well as color, so the
/// card doesn't depend on color perception alone.
class ReadingGoalCard extends StatelessWidget {
  const ReadingGoalCard({super.key});

  /// Above this many books, individual spines get too thin to read, so the
  /// card switches to a plain progress bar.
  static const int _maxSpines = 36;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final store = ProfileStore.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([store.profile, store.progress]),
      builder: (context, _) {
        final goal = store.profile.value.yearlyGoal;
        final progress = store.progress.value;
        final finished = progress.finished;
        final reading = progress.inProgressCount;
        final year = DateTime.now().year;

        final title = '$finished of $goal ${goal == 1 ? 'book' : 'books'}';
        final caption = reading == 0
            ? 'finished in $year'
            : 'finished in $year, with $reading in progress';

        return Semantics(
          container: true,
          label: '$title $caption',
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.serifStyle(
                      size: 24,
                      height: 1.25,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (goal <= _maxSpines)
                    _Shelf(
                      goal: goal,
                      finished: finished,
                      inProgress: progress.inProgress,
                    )
                  else
                    _ProgressBar(
                      goal: goal,
                      finished: finished,
                      inProgress: reading,
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

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.goal,
    required this.finished,
    required this.inProgress,
  });

  final int goal;
  final int finished;
  final List<double> inProgress;

  /// Varied heights so the row reads as books, not a bar chart. Height is
  /// per position, never tied to page count.
  static const List<double> _heights = [
    34, 42, 30, 38, 44, 32, 40, 36, 44, 30, 38, 42, //
    34, 40, 32, 38, 44, 30, 36, 42, 34, 40, 32, 38,
  ];

  static const double _minGap = 3;
  static const double _maxSpineWidth = 10;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = (constraints.maxWidth - (goal - 1) * _minGap) / goal;
        final width = math.max(3.0, math.min(_maxSpineWidth, fit));

        final spines = <Widget>[
          for (var i = 0; i < goal; i++)
            _Spine(
              width: width,
              height: _heights[i % _heights.length],
              fraction: _fractionFor(i),
            ),
        ];

        return Column(
          children: [
            SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: spines,
              ),
            ),
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 1 = finished, 0 = to go, in between = in progress.
  double _fractionFor(int index) {
    if (index < finished) return 1;
    final reading = index - finished;
    if (reading < inProgress.length) {
      // Clamp away 0 / 1 so an in-progress book never looks unstarted or done.
      return inProgress[reading].clamp(0.08, 0.92).toDouble();
    }
    return 0;
  }
}

class _Spine extends StatelessWidget {
  const _Spine({
    required this.width,
    required this.height,
    required this.fraction,
  });

  final double width;
  final double height;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(2);

    if (fraction >= 1) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: colors.primary, borderRadius: radius),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.outline, width: 1.25),
      ),
      child: fraction <= 0
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: fraction,
                  child: ColoredBox(color: colors.secondary),
                ),
              ),
            ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.goal,
    required this.finished,
    required this.inProgress,
  });

  final int goal;
  final int finished;
  final int inProgress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = finished.clamp(0, goal).toInt();
    final reading = inProgress.clamp(0, goal - done).toInt();
    final rest = goal - done - reading;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: ColoredBox(
          color: colors.outlineVariant,
          child: Row(
            children: [
              if (done > 0)
                Expanded(
                  flex: done,
                  child: ColoredBox(color: colors.primary),
                ),
              if (reading > 0)
                Expanded(
                  flex: reading,
                  child: ColoredBox(color: colors.secondary),
                ),
              if (rest > 0) Spacer(flex: rest),
            ],
          ),
        ),
      ),
    );
  }
}

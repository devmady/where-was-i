import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../library/models/week_stats.dart';
import '../../profile/widgets/settings_widgets.dart';

/// This week at a glance: pages read and which days had reading. Seven dots,
/// filled for days read and ringed for today. It is not a streak, so a missed
/// day never looks like a broken chain.
class WeekCard extends StatelessWidget {
  const WeekCard({super.key, required this.stream});

  final Stream<WeekStats> stream;

  static const String _letters = 'MTWTFSS';

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now().weekday;

    return SettingsSection(
      label: 'This week',
      child: StreamBuilder<WeekStats>(
        stream: stream,
        builder: (context, snapshot) {
          final stats = snapshot.data ?? const WeekStats(pages: 0, days: {});
          final pages = stats.pages;
          final dayCount = stats.days.length;

          final headline = pages == 0
              ? 'No pages yet'
              : '$pages ${pages == 1 ? 'page' : 'pages'}';
          final detail = pages == 0
              ? 'Log a page to start your week'
              : 'read on $dayCount ${dayCount == 1 ? 'day' : 'days'}';

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: AppFonts.serifStyle(
                    size: 28,
                    height: 1.2,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var day = DateTime.monday;
                        day <= DateTime.sunday;
                        day++)
                      _DayDot(
                        letter: _letters[day - 1],
                        name: _dayNames[day - 1],
                        read: stats.days.contains(day),
                        today: day == today,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.letter,
    required this.name,
    required this.read,
    required this.today,
  });

  final String letter;
  final String name;
  final bool read;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final label = '$name${read ? ', read' : ''}${today ? ', today' : ''}';

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: read ? colors.primary : null,
            border: read
                ? null
                : Border.all(
                    color: today ? colors.primary : colors.outline,
                    width: today ? 2 : 1,
                  ),
          ),
          child: Text(
            letter,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: (read || today) ? FontWeight.w600 : FontWeight.w500,
              color: read
                  ? colors.onPrimary
                  : (today ? colors.primary : colors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

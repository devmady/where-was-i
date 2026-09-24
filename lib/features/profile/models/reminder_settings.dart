import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show setEquals;

/// Daily reading reminder. Scheduled locally on the device — nothing here
/// ever leaves it.
@immutable
class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.time,
    required this.weekdays,
  });

  /// Off until the reader opts in (turning it on also needs the OS
  /// notification permission).
  static const ReminderSettings defaults = ReminderSettings(
    enabled: false,
    time: TimeOfDay(hour: 21, minute: 0),
    weekdays: {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    },
  );

  static const List<String> dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _dayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final bool enabled;
  final TimeOfDay time;

  /// DateTime.monday (1) through DateTime.sunday (7). Never empty.
  final Set<int> weekdays;

  ReminderSettings copyWith({
    bool? enabled,
    TimeOfDay? time,
    Set<int>? weekdays,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  /// Flips one weekday. The last selected day can't be turned off — a
  /// reminder with no days would silently do nothing.
  ReminderSettings toggleDay(int weekday) {
    final next = {...weekdays};
    if (!next.remove(weekday)) {
      next.add(weekday);
    } else if (next.isEmpty) {
      return this;
    }
    return copyWith(weekdays: next);
  }

  String daysLabel() {
    if (weekdays.length == 7) return 'Every day';
    if (setEquals(weekdays, const {1, 2, 3, 4, 5})) return 'Weekdays';
    if (setEquals(weekdays, const {6, 7})) return 'Weekends';
    final sorted = weekdays.toList()..sort();
    return sorted.map((d) => _dayShort[d - 1]).join(', ');
  }

  /// One-line summary for the settings list, e.g. Weekdays at 9:00 pm.
  String summary(BuildContext context) {
    if (!enabled) return 'Off';
    return '${daysLabel()} at ${time.format(context)}';
  }
}

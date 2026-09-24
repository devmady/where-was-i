const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Short month and year, like Mar 2026. English only until the app is localized.
String monthYearLabel(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.year}';
}

/// Short month, day and year, like Mar 14, 2026.
String monthDayYearLabel(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

/// Today, Yesterday, a weekday name within the last week, or month and day.
String friendlyDayLabel(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime.utc(current.year, current.month, current.day);
  final day = DateTime.utc(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  if (difference > 1 && difference < 7) return _weekdayNames[day.weekday - 1];
  return '${_monthNames[day.month - 1]} ${day.day}';
}

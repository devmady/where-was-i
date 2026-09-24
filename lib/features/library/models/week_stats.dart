/// What the reader did this week, Monday to Sunday.
class WeekStats {
  const WeekStats({required this.pages, required this.days});

  /// Pages read across all books this week.
  final int pages;

  /// Weekdays with at least one page logged, 1 for Monday through 7 for
  /// Sunday.
  final Set<int> days;
}

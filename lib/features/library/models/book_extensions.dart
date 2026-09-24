import '../../../core/database/app_database.dart';

/// Names for the four reserved tag colors, in the same order as the tag color
/// list in the theme file.
const List<String> kTagColorNames = [
  'Burgundy',
  'Dusty blue',
  'Teal',
  'Terracotta',
];

extension BookProgress on Book {
  /// How far through the book the reader is, from 0.0 to 1.0, or null when
  /// the page count is unknown.
  double? get progressFraction {
    final total = totalPages;
    if (total == null || total <= 0) return null;
    return (currentPage / total).clamp(0.0, 1.0).toDouble();
  }
}

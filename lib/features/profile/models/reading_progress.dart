import 'package:flutter/foundation.dart';

/// What the reading-goal card needs to know about the reader's year.
///
/// Placeholder until the Drift layer exists: derive this from the books
/// table (finished this year / currently reading) and feed it into
/// ProfileStore.progress.
@immutable
class ReadingProgress {
  const ReadingProgress({this.finished = 0, this.inProgress = const []});

  static const ReadingProgress empty = ReadingProgress();

  /// Books finished this calendar year.
  final int finished;

  /// One entry per book being read right now; each value is how far through
  /// that book the reader is, from 0.0 to 1.0.
  final List<double> inProgress;

  int get inProgressCount => inProgress.length;
}

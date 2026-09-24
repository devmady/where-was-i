import 'package:flutter/foundation.dart';

/// The locally stored reader profile. There is no account: everything here
/// lives on the device.
@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.yearlyGoal,
    required this.since,
    this.photoPath,
  });

  static const String defaultName = 'Reader';
  static const int minGoal = 1;
  static const int maxGoal = 365;

  final String name;

  /// Books the reader wants to finish this calendar year.
  final int yearlyGoal;

  /// When the reader started using the app on this device.
  final DateTime since;

  /// Path to a photo stored on this device, or null to show the initial.
  final String? photoPath;

  String get initial => initialFor(name);

  /// First letter of name, falling back to defaultName when blank.
  static String initialFor(String name) {
    final trimmed = name.trim();
    final source = trimmed.isEmpty ? defaultName : trimmed;
    return String.fromCharCode(source.runes.first).toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    int? yearlyGoal,
    DateTime? since,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      yearlyGoal: yearlyGoal ?? this.yearlyGoal,
      since: since ?? this.since,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }
}

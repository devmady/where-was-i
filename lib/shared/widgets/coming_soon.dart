import 'package:flutter/material.dart';

/// Placeholder feedback for actions whose plumbing doesn't exist yet
/// (file picking, sharing, opening links, ...).
///
/// Search the project for showComingSoon and remove each call site as the
/// real flow lands.
void showComingSoon(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

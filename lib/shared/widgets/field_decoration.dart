import 'package:flutter/material.dart';

/// The outlined text field look used across the app: rounded, a quiet border,
/// and a teal border while focused.
InputDecoration appFieldDecoration(
  BuildContext context, {
  required String label,
  String? helper,
  String? error,
  Widget? suffixIcon,
}) {
  final colors = Theme.of(context).colorScheme;

  OutlineInputBorder border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    helperText: helper,
    errorText: error,
    counterText: '',
    suffixIcon: suffixIcon,
    border: border(colors.outline, 1),
    enabledBorder: border(colors.outline, 1),
    focusedBorder: border(colors.primary, 2),
    errorBorder: border(colors.error, 1),
    focusedErrorBorder: border(colors.error, 2),
  );
}

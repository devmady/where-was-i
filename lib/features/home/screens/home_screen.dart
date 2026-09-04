import 'package:flutter/material.dart';

/// Home screen — center of the Library / Home / Profile strip.
///
/// Shows a time-aware, reading-themed greeting based on the device's
/// local clock (DateTime.now() reads system time directly — no
/// permissions or network calls needed).
///
/// Will later also hold unique content (continue-reading card, stats)
/// not duplicated elsewhere in the app — see nav structure notes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'Ready for a new chapter?';
    } else if (hour >= 12 && hour < 17) {
      return 'A page or two before it gets busy?';
    } else if (hour >= 17 && hour < 21) {
      return 'Golden hour, good for reading.';
    } else {
      // 9pm–5am
      return "It's past your bedtime... one more chapter?";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final greeting = _greetingForHour(DateTime.now().hour);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              greeting,
              textAlign: TextAlign.left,
              style: textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }
}

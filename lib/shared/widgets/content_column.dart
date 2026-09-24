import 'package:flutter/material.dart';

/// Keeps page content at a comfortable reading width.
///
/// On phones this changes nothing. On wide windows (macOS, Windows, Linux,
/// tablets) the content stays centered instead of stretching edge to edge.
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

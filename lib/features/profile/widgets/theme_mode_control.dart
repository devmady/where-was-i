import 'package:flutter/material.dart';

import '../../../main.dart' show themeModeNotifier;

/// System / Light / Dark as a one-tap segmented control, wired to the
/// app-wide themeModeNotifier so changes apply instantly everywhere.
class ThemeModeControl extends StatelessWidget {
  const ThemeModeControl({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              for (final option in _options)
                Expanded(
                  child: _Segment(
                    icon: option.icon,
                    label: option.label,
                    selected: mode == option.mode,
                    onTap: () => themeModeNotifier.value = option.mode,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static const _options = [
    (
      mode: ThemeMode.system,
      label: 'System',
      icon: Icons.brightness_auto_outlined,
    ),
    (
      mode: ThemeMode.light,
      label: 'Light',
      icon: Icons.light_mode_outlined,
    ),
    (
      mode: ThemeMode.dark,
      label: 'Dark',
      icon: Icons.dark_mode_outlined,
    ),
  ];
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground =
        selected ? colors.onPrimaryContainer : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A small label above a SettingsGroup (Preferences, Your data, ...),
/// with an optional footnote underneath.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.label,
    required this.child,
    this.footnote,
  });

  final String label;
  final Widget child;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        child,
        if (footnote != null) SettingsFootnote(footnote!),
      ],
    );
  }
}

/// Small explanatory text under a group.
class SettingsFootnote extends StatelessWidget {
  const SettingsFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
      child: Text(
        text,
        style: textTheme.bodySmall?.copyWith(
          fontSize: 13,
          height: 1.4,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One rounded surface holding a stack of rows, separated by hairlines that
/// start after the leading icon.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.dividerIndent = 54,
  });

  final List<Widget> children;

  /// Where the hairlines between rows start. Rows with a wider leading
  /// element, like a cover, need a bigger value.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: dividerIndent,
                color: colors.outlineVariant,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

enum SettingsTrailing { none, chevron, external }

/// A standard settings row: leading icon, title, optional subtitle, optional
/// value, and a chevron / external-link marker.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing = SettingsTrailing.chevron,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Short current value shown before the chevron (e.g. a time).
  final String? value;
  final SettingsTrailing trailing;

  /// Renders the row in the error color (erase, delete, ...).
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: destructive ? colors.error : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: destructive ? colors.error : colors.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              Text(
                value!,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
            if (trailing != SettingsTrailing.none) ...[
              const SizedBox(width: 8),
              Icon(
                trailing == SettingsTrailing.external
                    ? Icons.open_in_new
                    : Icons.chevron_right,
                size: 20,
                color: colors.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

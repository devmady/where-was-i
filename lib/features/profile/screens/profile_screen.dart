import 'package:flutter/material.dart';
import '../../../main.dart' show themeModeNotifier;

/// Profile screen — right of the Home center.
///
/// No login/account system (local-only app), so the profile card
/// shows a locally-set nickname + optional local photo only.
/// Below it: a settings list (theme, notifications, backup, about).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: const [
            _ProfileCard(),
            SizedBox(height: 28),
            _SettingsSection(),
          ],
        ),
      ),
    );
  }
}

/// Profile card: photo circle on the right, name + detail on the left.
///
/// name/photo are hardcoded placeholders for now — wire up to local
/// storage (a simple key-value prefs entry, not Drift) once the
/// "edit profile" flow exists.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reader', // placeholder nickname
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to edit profile', // placeholder detail line
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person_outline,
              size: 32,
              color: colorScheme.primary,
            ),
            // swap for a real local photo (Image provider) once
            // photo picking is wired up. Falls back to this icon when
            // no photo is set.
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Theme',
          trailing: _ThemeModeSelector(),
        ),
        const Divider(height: 1),
        const _SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
        ),
        const Divider(height: 1),
        const _SettingsTile(
          icon: Icons.download_outlined,
          title: 'Export / Backup Data',
        ),
        const Divider(height: 1),
        const _SettingsTile(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'Where Was I? — v0.1.0',
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.7)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: trailing == null
          ? () {
              // wire up Notifications / Export / About actions
              // once their respective flows exist.
            }
          : null,
    );
  }
}


/// Theme mode selector: light / dark / system, wired to the app-wide
/// ValueNotifier in main.dart so changes apply instantly everywhere.
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return DropdownButton<ThemeMode>(
          value: currentMode,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
          ],
          onChanged: (mode) {
            if (mode != null) themeModeNotifier.value = mode;
          },
        );
      },
    );
  }
}

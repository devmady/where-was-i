import 'package:flutter/material.dart';

import '../../../core/app_info.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/content_column.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
import '../state/profile_store.dart';
import '../widgets/monogram_avatar.dart';
import '../widgets/reading_goal_card.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/theme_mode_control.dart';
import 'about_screen.dart';
import 'backup_screen.dart';
import 'edit_profile_screen.dart';
import 'reminders_screen.dart';

/// Profile screen — right of the Home center.
///
/// No login/account system (local-only app): the header shows a locally-set
/// name and optional local photo. Below it, the reading-goal shelf and the
/// settings list (appearance, reminders, backup, about). Every sub-screen is
/// pushed on top of the shell, so the floating nav pill hides while editing.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Bottom space kept clear for the floating nav pill in AppShell.
  static const double _navClearance = 112;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final store = ProfileStore.instance;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ContentColumn(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, _navClearance),
            children: [
              const _IdentityHeader(),
              const SizedBox(height: 28),
              const ReadingGoalCard(),
              const SizedBox(height: 28),
              SettingsSection(
                label: 'Preferences',
                child: SettingsGroup(
                  children: [
                    const _AppearanceRow(),
                    ValueListenableBuilder<ReminderSettings>(
                      valueListenable: store.reminders,
                      builder: (context, reminders, _) => SettingsRow(
                        icon: Icons.notifications_outlined,
                        title: 'Reminders',
                        subtitle: reminders.summary(context),
                        onTap: () => _push(context, const RemindersScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SettingsSection(
                label: 'Your data',
                footnote:
                    'Your library lives on this device. No account needed.',
                child: SettingsGroup(
                  children: [
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: store.lastBackup,
                      builder: (context, last, _) => SettingsRow(
                        icon: Icons.download_outlined,
                        title: 'Back up & export',
                        subtitle: last == null
                            ? 'Last backup: never'
                            : 'Last backup: ${MaterialLocalizations.of(context).formatShortMonthDay(last)}',
                        onTap: () => _push(context, const BackupScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SettingsSection(
                label: 'About',
                child: SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.info_outline,
                      title: 'About $kAppName',
                      subtitle: 'Version $kAppVersion',
                      onTap: () => _push(context, const AboutScreen()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _push(BuildContext context, Widget screen) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => screen),
  );
}

// English-only until the app is localized.
const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _monthYear(DateTime date) => '${_months[date.month - 1]} ${date.year}';

/// Monogram + name + On this device since ..., with an explicit edit button
/// (no hidden tap target).
class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<UserProfile>(
      valueListenable: ProfileStore.instance.profile,
      builder: (context, profile, _) {
        return Row(
          children: [
            MonogramAvatar(
              size: 72,
              initial: profile.initial,
              photoPath: profile.photoPath,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.serifStyle(
                      size: 28,
                      height: 1.2,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'On this device since ${_monthYear(profile.since)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.outlined(
              tooltip: 'Edit profile',
              onPressed: () => _push(context, const EditProfileScreen()),
              icon: const Icon(Icons.edit_outlined, size: 18),
              style: IconButton.styleFrom(
                fixedSize: const Size(40, 40),
                side: BorderSide(color: colors.outline),
                foregroundColor: colors.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 22, color: colors.onSurfaceVariant),
              const SizedBox(width: 16),
              Text(
                'Appearance',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const ThemeModeControl(),
        ],
      ),
    );
  }
}

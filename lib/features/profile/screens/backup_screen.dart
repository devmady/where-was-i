import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/coming_soon.dart';
import '../../library/state/book_repository.dart';
import '../state/profile_store.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/sub_screen_scaffold.dart';

/// Back up, restore, export, and erase.
///
/// Everything here is UI-only until the Drift layer exists.
/// Pending: backup = serialize books + progress to one JSON file the
/// reader saves wherever they like; restore = read that file back; CSV export
/// = titles/authors/dates for spreadsheets. On a successful backup, set
/// ProfileStore.lastBackup.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubScreenScaffold(
      title: 'Back up & export',
      children: [
        const _BackupStatus(),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.download_outlined,
              title: 'Create a backup',
              subtitle: 'Your books and progress, in one file',
              onTap: () => showComingSoon(
                context,
                'Backups arrive with the database layer.',
              ),
            ),
            SettingsRow(
              icon: Icons.upload_outlined,
              title: 'Restore from a backup',
              subtitle: 'Replaces what is in the app right now',
              onTap: () => showComingSoon(
                context,
                'Restore arrives with the database layer.',
              ),
            ),
            SettingsRow(
              icon: Icons.description_outlined,
              title: 'Export reading list',
              subtitle: 'Titles, authors and dates, as CSV',
              onTap: () => showComingSoon(
                context,
                'CSV export arrives with the database layer.',
              ),
            ),
          ],
        ),
        SettingsSection(
          label: 'Start over',
          footnote: 'Back up first. Erasing cannot be undone.',
          child: SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.delete_outline,
                title: 'Erase all data',
                subtitle: 'Deletes every book and all progress',
                destructive: true,
                trailing: SettingsTrailing.none,
                onTap: () => _confirmErase(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmErase(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text(
          'This deletes every book and all reading progress from this '
          'device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await BookRepository.instance.eraseAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All books and progress erased.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Big plain-language status: No backup yet / Backed up Sep 12.
class _BackupStatus extends StatelessWidget {
  const _BackupStatus();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<DateTime?>(
      valueListenable: ProfileStore.instance.lastBackup,
      builder: (context, last, _) {
        final headline = last == null
            ? 'No backup yet'
            : 'Backed up ${MaterialLocalizations.of(context).formatShortMonthDay(last)}';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: AppFonts.serifStyle(
                  size: 28,
                  height: 1.2,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your library lives only on this device, so a backup is '
                'your safety copy.',
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  height: 1.45,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/coming_soon.dart';
import '../../library/state/book_repository.dart';
import '../state/profile_store.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/sub_screen_scaffold.dart';

/// Back up, restore, export, and erase.
///
/// Backup and restore are wired to the real database (see
/// BookRepository.exportBackupJson / importBackupJson). CSV export is
/// still a separate, later item. On a successful backup, sets
/// ProfileStore.lastBackup.
///
/// Cover images are not part of the backup file. A restore brings back
/// every book and all reading progress, but not the cover pictures
/// themselves — the UI says this before a restore happens.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _working = false;

  Future<void> _createBackup() async {
    if (_working) return;
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final json = await BookRepository.instance.exportBackupJson();

      final directory = await getTemporaryDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/where-was-i-backup-$stamp.json');
      await file.writeAsString(json);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Where Was I? backup',
        ),
      );

      ProfileStore.instance.lastBackup.value = DateTime.now();
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not create a backup: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_working) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _working = true);

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = files.isEmpty ? null : files.first.path;
      if (path == null) {
        setState(() => _working = false);
        return;
      }

      final json = await File(path).readAsString();
      final preview = await BookRepository.instance.peekBackupJson(json);

      if (!mounted) return;
      final proceed = await _confirmRestore(context, preview);
      if (proceed != true) {
        setState(() => _working = false);
        return;
      }

      await BookRepository.instance.importBackupJson(json);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Backup restored.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on BackupFormatException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not restore that backup: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool?> _confirmRestore(BuildContext context, BackupPreview preview) {
    final colors = Theme.of(context).colorScheme;
    final exportedAt = preview.exportedAt;
    final whenText = exportedAt == null
        ? ''
        : ' made on ${MaterialLocalizations.of(context).formatShortMonthDay(exportedAt)}';
    final bookWord = preview.bookCount == 1 ? 'book' : 'books';

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore from a backup?'),
        content: Text(
          'This backup$whenText has ${preview.bookCount} $bookWord. '
          'Restoring replaces every book and all reading progress '
          'currently in the app with what is in this file. Cover images '
          "are not included in backups, so they won't come back with a "
          'restore. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

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
              onTap: _working ? null : _createBackup,
            ),
            SettingsRow(
              icon: Icons.upload_outlined,
              title: 'Restore from a backup',
              subtitle: 'Replaces what is in the app right now',
              onTap: _working ? null : _restoreBackup,
            ),
            SettingsRow(
              icon: Icons.description_outlined,
              title: 'Export reading list',
              subtitle: 'Titles, authors and dates, as CSV',
              onTap: () => showComingSoon(
                context,
                'CSV export is coming in a later update.',
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
                'your safety copy. Backup files do not include cover '
                'images.',
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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_info.dart';
import '../../../core/theme/app_fonts.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/sub_screen_scaffold.dart';

/// App identity, version, and links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Opens url in the default browser; says so if that fails.
  Future<void> _openLink(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open the link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SubScreenScaffold(
      title: 'About',
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              // Pending: replace with the real launcher icon once it exists.
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(
                  Icons.bookmark_border,
                  size: 44,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                kAppName,
                textAlign: TextAlign.center,
                style: AppFonts.serifStyle(
                  size: 30,
                  height: 1.2,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $kAppVersion',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A quiet reading tracker that keeps everything on your device.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  height: 1.45,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.code,
              title: 'Source code',
              subtitle: 'Free and open source',
              trailing: SettingsTrailing.external,
              onTap: () => _openLink(context, kSourceUrl),
            ),
            SettingsRow(
              icon: Icons.flag_outlined,
              title: 'Report a problem',
              subtitle: 'Opens the issue tracker',
              trailing: SettingsTrailing.external,
              onTap: () => _openLink(context, kIssuesUrl),
            ),
            SettingsRow(
              icon: Icons.description_outlined,
              title: 'Open-source licences',
              onTap: () => showLicensePage(
                context: context,
                applicationName: kAppName,
                applicationVersion: kAppVersion,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

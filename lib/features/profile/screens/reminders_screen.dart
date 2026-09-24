import 'package:flutter/material.dart';

import '../../../core/app_info.dart';
import '../models/reminder_settings.dart';
import '../state/profile_store.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/sub_screen_scaffold.dart';

/// Daily reading reminder: on/off, time, and which days.
///
/// Pending: turning this on must (1) ask for the OS notification
/// permission and (2) schedule local notifications (e.g. with
/// flutter_local_notifications); changing time/days must reschedule. Also
/// handle the permission denied case with a way to open system settings.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProfileStore.instance;

    return ValueListenableBuilder<ReminderSettings>(
      valueListenable: store.reminders,
      builder: (context, reminders, _) {
        return SubScreenScaffold(
          title: 'Reminders',
          children: [
            SettingsGroup(
              children: [
                _ReminderSwitchRow(
                  value: reminders.enabled,
                  onChanged: (on) {
                    store.reminders.value = reminders.copyWith(enabled: on);
                  },
                ),
              ],
            ),
            // Time, days and preview stay visible but inert while off.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: reminders.enabled ? 1 : 0.4,
              child: IgnorePointer(
                ignoring: !reminders.enabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsGroup(
                      children: [
                        SettingsRow(
                          icon: Icons.schedule_outlined,
                          title: 'Time',
                          value: reminders.time.format(context),
                          onTap: () => _pickTime(context),
                        ),
                        _DaysRow(reminders: reminders),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SettingsSection(
                      label: 'How it will look',
                      child: _NotificationPreview(time: reminders.time),
                    ),
                  ],
                ),
              ),
            ),
            const SettingsFootnote(
              'Reminders are scheduled on this device. '
              'Nothing is sent to a server.',
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final store = ProfileStore.instance;
    final picked = await showTimePicker(
      context: context,
      initialTime: store.reminders.value.time,
    );
    if (picked == null) return;
    store.reminders.value = store.reminders.value.copyWith(time: picked);
  }
}

class _ReminderSwitchRow extends StatelessWidget {
  const _ReminderSwitchRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily reading reminder',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A nudge to pick your book back up.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysRow extends StatelessWidget {
  const _DaysRow({required this.reminders});

  final ReminderSettings reminders;

  static const String _letters = 'MTWTFSS';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final store = ProfileStore.instance;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 22,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Text(
                'Days',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++)
                _DayChip(
                  letter: _letters[weekday - 1],
                  name: ReminderSettings.dayNames[weekday - 1],
                  selected: reminders.weekdays.contains(weekday),
                  onTap: () {
                    store.reminders.value = reminders.toggleDay(weekday);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.letter,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? colors.primaryContainer : Colors.transparent,
          shape: CircleBorder(
            side: selected
                ? BorderSide.none
                : BorderSide(color: colors.outline),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  letter,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mock of the notification the reader will get.
///
/// Pending: use the real current book and page instead of this sample.
class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.time});

  final TimeOfDay time;

  static const String _sampleBody =
      'Piranesi, page 143. Pick up where you left off.';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.bookmark_border,
                  size: 12,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kAppName,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                time.format(context),
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Time to read',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _sampleBody,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

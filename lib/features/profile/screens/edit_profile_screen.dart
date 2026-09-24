import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../shared/state/image_storage.dart';
import '../models/user_profile.dart';
import '../state/profile_store.dart';
import '../widgets/monogram_avatar.dart';
import '../widgets/sub_screen_scaffold.dart';

/// Edit the local profile: name, optional photo, yearly reading goal.
/// Everything is saved on this device only.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _store = ProfileStore.instance;

  late final TextEditingController _name;
  late int _goal;
  String? _photoPath;
  String? _originalPhotoPath;
  bool _pickingPhoto = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final profile = _store.profile.value;
    _name = TextEditingController(text: profile.name);
    _goal = profile.yearlyGoal;
    _photoPath = profile.photoPath;
    _originalPhotoPath = profile.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);
    final path = await ImageStorage.pickAndSave(prefix: 'profile');
    if (!mounted) return;
    setState(() => _pickingPhoto = false);
    if (path == null) return;
    final previous = _photoPath;
    setState(() => _photoPath = path);
    if (previous != null && previous != path) {
      await ImageStorage.deleteIfExists(previous);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _photoPath = null);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Add a name to show on your profile.');
      return;
    }
    // ProfileStore saves to this device automatically on every change.
    _store.profile.value = _store.profile.value.copyWith(
      name: name,
      yearlyGoal: _goal,
      photoPath: _photoPath,
      clearPhoto: _photoPath == null,
    );
    if (_photoPath != _originalPhotoPath) {
      ImageStorage.deleteIfExists(_originalPhotoPath);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final finished = _store.progress.value.finished;

    return SubScreenScaffold(
      title: 'Edit profile',
      bottom: FilledButton(
        onPressed: _save,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: const Text('Save changes'),
      ),
      children: [
        // Avatar + photo actions
        Column(
          children: [
            ListenableBuilder(
              listenable: _name,
              builder: (context, _) => MonogramAvatar(
                size: 112,
                initial: UserProfile.initialFor(_name.text),
                photoPath: _photoPath,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickingPhoto ? null : _pickPhoto,
                  icon: _pickingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined, size: 18),
                  label: Text(_pickingPhoto ? 'Choosing...' : 'Choose photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.outline),
                    shape: const StadiumBorder(),
                  ),
                ),
                TextButton(
                  onPressed: _photoPath == null ? null : _removePhoto,
                  child: const Text('Use my initial'),
                ),
              ],
            ),
          ],
        ),

        // Name
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 30,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: 'Name',
            helperText: 'Shown on your profile. Stays on this device.',
            errorText: _nameError,
            counterText: '',
            border: _border(colors.outline, 1),
            enabledBorder: _border(colors.outline, 1),
            focusedBorder: _border(colors.primary, 2),
            errorBorder: _border(colors.error, 1),
            focusedErrorBorder: _border(colors.error, 2),
          ),
        ),

        // Yearly goal
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yearly reading goal',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$finished finished in ${DateTime.now().year} so far',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _GoalStepper(
                value: _goal,
                onChanged: (value) => setState(() => _goal = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _GoalStepper extends StatelessWidget {
  const _GoalStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = IconButton.styleFrom(
      fixedSize: const Size(40, 40),
      side: BorderSide(color: colors.outline),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Fewer books',
          onPressed: value > UserProfile.minGoal
              ? () => onChanged(value - 1)
              : null,
          icon: const Icon(Icons.remove, size: 18),
          style: style,
        ),
        Semantics(
          label: 'Yearly reading goal',
          value: '$value books',
          child: ExcludeSemantics(
            child: SizedBox(
              width: 44,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppFonts.serifStyle(
                  size: 22,
                  height: 1.2,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ),
        IconButton.outlined(
          tooltip: 'More books',
          onPressed: value < UserProfile.maxGoal
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.add, size: 18),
          style: style,
        ),
      ],
    );
  }
}

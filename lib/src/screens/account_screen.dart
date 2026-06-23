import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_shell.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  late final TextEditingController _aliasController;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(
      text: ref.read(mysteryControllerProvider).localAlias,
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final state = ref.watch(mysteryControllerProvider);
    final stats = ref.watch(playerStatsProvider);
    final achievements = ref.watch(achievementsProvider);
    final settings = ref.watch(appSettingsProvider);
    final animationDuration = settings.animationsEnabled
        ? const Duration(milliseconds: 220)
        : Duration.zero;
    final friendSuggestions = _buildFriendSuggestions(state);

    if (_aliasController.text != state.localAlias) {
      _aliasController.text = state.localAlias;
      _aliasController.selection = TextSelection.fromPosition(
        TextPosition(offset: _aliasController.text.length),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: strings.accountProfileTitle,
            subtitle: strings.accountProfileSubtitle,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final profile = _ProfilePanel(
                  strings: strings,
                  aliasController: _aliasController,
                  onSave: _saveAlias,
                );
                final statSummary = _StatsSummary(
                  strings: strings,
                  stats: stats,
                );

                if (!isWide) {
                  return Column(
                    children: [
                      profile,
                      const SizedBox(height: 16),
                      statSummary,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: profile),
                    const SizedBox(width: 16),
                    Expanded(child: statSummary),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TwoColumnLayout(
            primary: [
              SectionPanel(
                title: strings.accountFriendsTitle,
                subtitle: strings.accountFriendsSubtitle,
                trailing: FilledButton.icon(
                  onPressed: () => _openFriendEditor(
                    suggestions: friendSuggestions,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(strings.addFriend),
                ),
                child: AnimatedSwitcher(
                  duration: animationDuration,
                  child: state.friends.isEmpty
                      ? _EmptyFriendsState(
                          key: const ValueKey('empty-friends'),
                          strings: strings,
                          suggestions: friendSuggestions,
                          onAddFriend: () => _openFriendEditor(
                            suggestions: friendSuggestions,
                          ),
                        )
                      : Column(
                          key: const ValueKey('friend-list'),
                          children: state.friends.map((friend) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FriendCard(
                                strings: strings,
                                friend: friend,
                                onEdit: () => _openFriendEditor(
                                  friend: friend,
                                  suggestions: friendSuggestions,
                                ),
                                onDelete: () => _confirmDeleteFriend(friend),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
              SectionPanel(
                title: strings.accountSettingsTitle,
                subtitle: strings.accountSettingsSubtitle,
                child: _SettingsPanel(
                  strings: strings,
                  settings: settings,
                ),
              ),
            ],
            secondary: [
              SectionPanel(
                title: strings.achievementsTitle,
                subtitle: strings.achievementsSubtitle,
                child: Column(
                  children: achievements.map((achievement) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AchievementCard(
                        strings: strings,
                        achievement: achievement,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SectionPanel(
                title: strings.accountHintTitle,
                child: Text(strings.accountHintBody),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_FriendSuggestion> _buildFriendSuggestions(MysteryState state) {
    final existingNames =
        state.friends.map((friend) => friend.name.toLowerCase()).toSet();
    final suggestions = <_FriendSuggestion>[];
    final addedNames = <String>{};

    for (final entry in state.roleArchive) {
      final normalizedName = entry.playerName.toLowerCase();
      if (normalizedName == state.localAlias.toLowerCase() ||
          existingNames.contains(normalizedName) ||
          addedNames.contains(normalizedName)) {
        continue;
      }

      suggestions.add(
        _FriendSuggestion(
          name: entry.playerName,
          favoriteScenario: entry.caseTitle,
          favoriteRole: entry.characterName,
        ),
      );
      addedNames.add(normalizedName);
    }

    return suggestions;
  }

  Future<void> _openFriendEditor({
    FriendProfile? friend,
    required List<_FriendSuggestion> suggestions,
  }) async {
    final strings = ref.read(appStringsProvider);
    final draft = await showDialog<_FriendDraft>(
      context: context,
      builder: (context) {
        return _FriendEditorDialog(
          strings: strings,
          friend: friend,
          suggestions: suggestions,
        );
      },
    );
    if (!mounted || draft == null) {
      return;
    }

    final controller = ref.read(mysteryControllerProvider.notifier);
    final error = friend == null
        ? controller.addFriend(
            name: draft.name,
            favoriteScenario: draft.favoriteScenario,
            favoriteRole: draft.favoriteRole,
            note: draft.note,
          )
        : controller.updateFriend(
            friendId: friend.id,
            name: draft.name,
            favoriteScenario: draft.favoriteScenario,
            favoriteRole: draft.favoriteRole,
            note: draft.note,
          );

    if (error != null) {
      _showFeedback(error);
      return;
    }

    _showFeedback(
      friend == null ? strings.friendSaved : strings.friendUpdated,
    );
  }

  Future<void> _confirmDeleteFriend(FriendProfile friend) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.removeFriendTitle),
          content: Text(strings.removeFriendBody(friend.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.removeFriend),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    ref.read(mysteryControllerProvider.notifier).removeFriend(friend.id);
    _showFeedback(strings.friendRemoved);
  }

  void _saveAlias() {
    final strings = ref.read(appStringsProvider);
    final trimmed = _aliasController.text.trim();
    if (trimmed.isEmpty) {
      _showFeedback(strings.displayNameEmpty);
      return;
    }

    ref.read(mysteryControllerProvider.notifier).updateAlias(trimmed);
    _showFeedback(strings.profileSaved);
  }

  void _showFeedback(String message) {
    if (!mounted) {
      return;
    }
    final notificationsEnabled =
        ref.read(appSettingsProvider).notificationsEnabled;
    if (!notificationsEnabled) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.strings,
    required this.aliasController,
    required this.onSave,
  });

  final AppStrings strings;
  final TextEditingController aliasController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.profileCardTitle,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: aliasController,
            onSubmitted: (_) => onSave(),
            decoration: InputDecoration(
              labelText: strings.displayNameLabel,
              helperText: strings.displayNameHelper,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: Text(strings.saveProfile),
          ),
        ],
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({
    required this.strings,
    required this.stats,
  });

  final AppStrings strings;
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.statsTitle,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricTile(
                  label: strings.startedLabel, value: '${stats.gamesPlayed}'),
              MetricTile(
                label: strings.completedLabel,
                value: '${stats.casesSolved}',
              ),
              MetricTile(
                  label: strings.cluesLabel, value: '${stats.detectiveFinds}'),
              MetricTile(
                  label: strings.friendsLabel, value: '${stats.friendCount}'),
            ],
          ),
          const SizedBox(height: 16),
          Text(strings.favoriteRoleLabel(stats.favoriteRole)),
          const SizedBox(height: 6),
          Text(strings.favoriteCaseLabel(stats.favoriteScenario)),
          const SizedBox(height: 6),
          Text(
            strings.statsFooter(
              roles: stats.distinctRolesManaged,
              activeLobbies: stats.activeLobbies,
              hours: stats.hoursPlayed.toStringAsFixed(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState({
    super.key,
    required this.strings,
    required this.suggestions,
    required this.onAddFriend,
  });

  final AppStrings strings;
  final List<_FriendSuggestion> suggestions;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppPalette.gold.withOpacity(0.14),
                ),
                child: const Icon(
                  Icons.group_off_rounded,
                  color: AppPalette.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.emptyFriendsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(strings.emptyFriendsBody),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              strings.friendSuggestionsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.take(3).map((suggestion) {
                final role = suggestion.favoriteRole;
                final label = role == null || role.isEmpty
                    ? suggestion.name
                    : '${suggestion.name} · $role';
                return ActionChip(
                  onPressed: onAddFriend,
                  label: Text(label),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddFriend,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(strings.addFriend),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.strings,
    required this.friend,
    required this.onEdit,
    required this.onDelete,
  });

  final AppStrings strings;
  final FriendProfile friend;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (friend.favoriteScenario != null &&
        friend.favoriteScenario!.isNotEmpty) {
      subtitleParts.add(friend.favoriteScenario!);
    }
    if (friend.favoriteRole != null && friend.favoriteRole!.isNotEmpty) {
      subtitleParts.add(friend.favoriteRole!);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppPalette.gold.withOpacity(0.18),
            child: Text(friend.name[0].toUpperCase()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitleParts.join(' · ')),
                ],
                const SizedBox(height: 4),
                Text(
                  strings.savedOn(_formatDate(friend.createdAt)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (friend.note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(friend.note),
                ],
              ],
            ),
          ),
          PopupMenuButton<_FriendAction>(
            onSelected: (action) {
              if (action == _FriendAction.edit) {
                onEdit();
                return;
              }
              onDelete();
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: _FriendAction.edit,
                  child: Text(strings.editFriend),
                ),
                PopupMenuItem(
                  value: _FriendAction.delete,
                  child: Text(strings.removeFriend),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.strings,
    required this.achievement,
  });

  final AppStrings strings;
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(achievement.icon, color: AppPalette.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              InfoPill(
                label: achievement.isUnlocked
                    ? strings.achievementUnlocked
                    : strings.achievementInProgress,
                icon: achievement.isUnlocked
                    ? Icons.verified_rounded
                    : Icons.timelapse_rounded,
                accent: achievement.isUnlocked
                    ? Colors.tealAccent
                    : AppPalette.gold,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(achievement.description),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(value: achievement.completion),
              ),
              const SizedBox(width: 12),
              Text(
                '${achievement.progress.toStringAsFixed(0)}/${achievement.target.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends ConsumerWidget {
  const _SettingsPanel({
    required this.strings,
    required this.settings,
  });

  final AppStrings strings;
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appSettingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.themeLabel,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SegmentedButton<ThemeMode>(
          segments: ThemeMode.values
              .map(
                (mode) => ButtonSegment<ThemeMode>(
                  value: mode,
                  label: Text(strings.themeModeLabel(mode)),
                ),
              )
              .toList(),
          selected: {settings.themeMode},
          onSelectionChanged: (selection) {
            controller.setThemeMode(selection.first);
          },
        ),
        const SizedBox(height: 18),
        Text(strings.languageLabel,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SegmentedButton<AppLanguage>(
          segments: AppLanguage.values
              .map(
                (language) => ButtonSegment<AppLanguage>(
                  value: language,
                  label: Text(strings.languageOptionLabel(language)),
                ),
              )
              .toList(),
          selected: {settings.language},
          onSelectionChanged: (selection) {
            controller.setLanguage(selection.first);
          },
        ),
        const SizedBox(height: 18),
        Text(
          strings.musicVolumeLabel((settings.musicVolume * 100).round()),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: settings.musicVolume,
          onChanged: controller.setMusicVolume,
        ),
        Text(
          strings.sfxVolumeLabel((settings.sfxVolume * 100).round()),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: settings.sfxVolume,
          onChanged: controller.setSfxVolume,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: settings.animationsEnabled,
          onChanged: controller.toggleAnimations,
          title: Text(strings.animationsTitle),
          subtitle: Text(strings.animationsSubtitle),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: settings.notificationsEnabled,
          onChanged: controller.toggleNotifications,
          title: Text(strings.notificationsTitle),
          subtitle: Text(strings.notificationsSubtitle),
        ),
      ],
    );
  }
}

class _FriendEditorDialog extends StatefulWidget {
  const _FriendEditorDialog({
    required this.strings,
    this.friend,
    required this.suggestions,
  });

  final AppStrings strings;
  final FriendProfile? friend;
  final List<_FriendSuggestion> suggestions;

  @override
  State<_FriendEditorDialog> createState() => _FriendEditorDialogState();
}

class _FriendEditorDialogState extends State<_FriendEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _scenarioController;
  late final TextEditingController _roleController;
  late final TextEditingController _noteController;

  bool get _isEditing => widget.friend != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.friend?.name ?? '');
    _scenarioController = TextEditingController(
      text: widget.friend?.favoriteScenario ?? '',
    );
    _roleController = TextEditingController(
      text: widget.friend?.favoriteRole ?? '',
    );
    _noteController = TextEditingController(text: widget.friend?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scenarioController.dispose();
    _roleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          _isEditing ? widget.strings.editFriend : widget.strings.addFriend),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing && widget.suggestions.isNotEmpty) ...[
                Text(
                  widget.strings.friendSuggestionsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.suggestions.take(6).map((suggestion) {
                    final role = suggestion.favoriteRole;
                    final label = role == null || role.isEmpty
                        ? suggestion.name
                        : '${suggestion.name} · $role';
                    return ActionChip(
                      onPressed: () {
                        _nameController.text = suggestion.name;
                        _scenarioController.text =
                            suggestion.favoriteScenario ?? '';
                        _roleController.text = suggestion.favoriteRole ?? '';
                      },
                      label: Text(label),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
              ],
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: widget.strings.nameLabel,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _scenarioController,
                decoration: InputDecoration(
                  labelText: widget.strings.optionalFavoriteCaseLabel,
                  prefixIcon: const Icon(Icons.auto_stories_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roleController,
                decoration: InputDecoration(
                  labelText: widget.strings.optionalFavoriteRoleLabel,
                  prefixIcon: const Icon(Icons.theater_comedy_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: widget.strings.optionalNoteLabel,
                  prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _FriendDraft(
                name: _nameController.text,
                favoriteScenario: _scenarioController.text,
                favoriteRole: _roleController.text,
                note: _noteController.text,
              ),
            );
          },
          child:
              Text(_isEditing ? widget.strings.save : widget.strings.addFriend),
        ),
      ],
    );
  }
}

enum _FriendAction { edit, delete }

class _FriendDraft {
  const _FriendDraft({
    required this.name,
    required this.favoriteScenario,
    required this.favoriteRole,
    required this.note,
  });

  final String name;
  final String favoriteScenario;
  final String favoriteRole;
  final String note;
}

class _FriendSuggestion {
  const _FriendSuggestion({
    required this.name,
    this.favoriteScenario,
    this.favoriteRole,
  });

  final String name;
  final String? favoriteScenario;
  final String? favoriteRole;
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}

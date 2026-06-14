import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final state = ref.watch(mysteryControllerProvider);
    final stats = ref.watch(playerStatsProvider);
    final achievements = ref.watch(achievementsProvider);
    final settings = ref.watch(appSettingsProvider);

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
            title: 'Profil und Ermittlungshistorie',
            subtitle:
                'Passe deinen Anzeigenamen an, behalte deine Stärken im Blick und lade Freunde zu neuen Fällen ein.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final profile = _ProfilePanel(
                  aliasController: _aliasController,
                  onSave: _saveAlias,
                );
                final statSummary = _StatsSummary(stats: stats);

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
                title: 'Freundesystem',
                subtitle:
                    'Online-Status, Lieblingsfälle und letzte Aktivität liegen bereit für spätere Einladungs- und Matchmaking-Flows.',
                child: Column(
                  children: state.friends.map((friend) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Colors.white.withOpacity(0.04),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: friend.isOnline
                                ? AppPalette.gold.withOpacity(0.18)
                                : Colors.white.withOpacity(0.08),
                            child: Text(friend.name[0]),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${friend.favoriteScenario} · ${friend.favoriteRole}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  friend.lastSeen,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          InfoPill(
                            label: friend.isOnline ? 'Online' : 'Offline',
                            icon: friend.isOnline
                                ? Icons.circle_rounded
                                : Icons.access_time_rounded,
                            accent: friend.isOnline
                                ? AppPalette.gold
                                : AppPalette.wine,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              SectionPanel(
                title: 'Einstellungen',
                subtitle:
                    'Dark Mode, Light Mode, Sprache, Lautstärken und Hinweise bleiben lokal gespeichert.',
                child: _SettingsPanel(settings: settings),
              ),
            ],
            secondary: [
              SectionPanel(
                title: 'Achievements',
                subtitle: 'Fortschritt über alle Lobbys und Rollen hinweg.',
                child: Column(
                  children: achievements.map((achievement) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                '${achievement.progress.toStringAsFixed(0)}/${achievement.target.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(achievement.description),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                              value: achievement.completion),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SectionPanel(
                title: 'Impressum & Datenschutz',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MYSTERY NIGHT Demo Build'),
                    SizedBox(height: 8),
                    Text(
                      'Diese Beispielanwendung speichert in diesem Projekt nur lokale Demo-Daten für Rollen, Lobbys und Einstellungen. Produktiv lassen sich Authentifizierung, Firestore, Storage und Push-Benachrichtigungen im gleichen Architekturrahmen anschließen.',
                    ),
                    SizedBox(height: 12),
                    Text('Kontakt: studio@mysterynight.app'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveAlias() {
    ref
        .read(mysteryControllerProvider.notifier)
        .updateAlias(_aliasController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dein Anzeigename wurde aktualisiert.')),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.aliasController,
    required this.onSave,
  });

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
          Text('Dein Profil', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: aliasController,
            decoration: const InputDecoration(
              labelText: 'Anzeigename',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Profil speichern'),
          ),
        ],
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.stats});

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
          Text('Statistiken', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricTile(label: 'Spiele', value: '${stats.gamesPlayed}'),
              MetricTile(label: 'Siege', value: '${stats.gamesWon}'),
              MetricTile(label: 'Hinweise', value: '${stats.detectiveFinds}'),
            ],
          ),
          const SizedBox(height: 16),
          Text('Lieblingsrolle: ${stats.favoriteRole}'),
          const SizedBox(height: 6),
          Text('Lieblingsszenario: ${stats.favoriteScenario}'),
        ],
      ),
    );
  }
}

class _SettingsPanel extends ConsumerWidget {
  const _SettingsPanel({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appSettingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (selection) {
            controller.setThemeMode(selection.first);
          },
        ),
        const SizedBox(height: 18),
        Text('Sprache', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SegmentedButton<AppLanguage>(
          segments: AppLanguage.values
              .map((language) => ButtonSegment<AppLanguage>(
                    value: language,
                    label: Text(language.label),
                  ))
              .toList(),
          selected: {settings.language},
          onSelectionChanged: (selection) {
            controller.setLanguage(selection.first);
          },
        ),
        const SizedBox(height: 18),
        Text('Musiklautstärke', style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: settings.musicVolume,
          onChanged: controller.setMusicVolume,
        ),
        Text('Effektlautstärke',
            style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: settings.sfxVolume,
          onChanged: controller.setSfxVolume,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: settings.animationsEnabled,
          onChanged: controller.toggleAnimations,
          title: const Text('Animationen aktivieren'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: settings.notificationsEnabled,
          onChanged: controller.toggleNotifications,
          title: const Text('Benachrichtigungen'),
        ),
      ],
    );
  }
}

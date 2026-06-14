import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mysteryControllerProvider);
    final stats = ref.watch(playerStatsProvider);
    final cases = ref.watch(mysteryCatalogProvider);
    final latestLobby = state.lobbies.isEmpty ? null : state.lobbies.first;
    final latestCase = latestLobby == null
        ? null
        : ref.watch(mysteryCaseProvider(latestLobby.caseId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Der Abend beginnt im Nebel',
            subtitle:
                'Plane neue Krimi-Runden, teile Einladungen und halte die Atmosphäre von der ersten Minute an hoch.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final storyColumn = _StoryHero(
                  alias: state.localAlias,
                  latestLobbyCode: latestLobby?.code,
                );
                final actionColumn = _ActionDeck(
                  onExploreCases: () => context.go('/cases'),
                  onOpenLobbies: () => context.go('/lobbies'),
                  onReviewRoles: () => context.go('/roles'),
                );

                if (!isWide) {
                  return Column(
                    children: [
                      storyColumn,
                      const SizedBox(height: 16),
                      actionColumn,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: storyColumn),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: actionColumn),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 760
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: columns == 1 ? 2.2 : 1.2,
                children: [
                  MetricTile(
                    label: 'Gespielte Fälle',
                    value: '${stats.gamesPlayed}',
                    icon: Icons.movie_filter_rounded,
                    caption: 'Demo-Historie plus aktive Sessions',
                  ),
                  MetricTile(
                    label: 'Entdeckte Hinweise',
                    value: '${stats.detectiveFinds}',
                    icon: Icons.search_rounded,
                    caption: 'Freigegebene Hinweise über alle Lobbys',
                  ),
                  MetricTile(
                    label: 'Lieblingsrolle',
                    value: stats.favoriteRole,
                    icon: Icons.person_pin_rounded,
                    caption: 'Zuletzt gespielte oder archivierte Persona',
                  ),
                  MetricTile(
                    label: 'Spielzeit',
                    value: '${stats.hoursPlayed.toStringAsFixed(1)} h',
                    icon: Icons.schedule_rounded,
                    caption: 'Ausgelegt für lange Dinner-Abende',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TwoColumnLayout(
            primary: [
              SectionPanel(
                title: 'Krimi-Welten',
                subtitle:
                    'Die App ist so angelegt, dass du saisonale, klassische und experimentelle Settings nebeneinander kuratieren kannst.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: MysteryCategory.values
                      .map(
                        (category) => InfoPill(
                          label: category.label,
                          accent: category == MysteryCategory.custom
                              ? AppPalette.wine
                              : AppPalette.gold,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SectionPanel(
                title: 'Warum diese Architektur passt',
                subtitle:
                    'Die App-Struktur ist für den Sprung auf Firebase vorbereitet, läuft aber lokal sofort mit Demo-Daten.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ArchitectureLine(
                      title: 'Flutter Frontend',
                      text:
                          'Eine Codebasis für Web, Android und später iOS/Desktop.',
                    ),
                    _ArchitectureLine(
                      title: 'Riverpod State',
                      text:
                          'Klare Trennung zwischen UI, Lobby-Logik und Einstellungen.',
                    ),
                    _ArchitectureLine(
                      title: 'GoRouter Navigation',
                      text:
                          'Deep Links wie /join/ABCD1234 lassen sich direkt anbinden.',
                    ),
                    _ArchitectureLine(
                      title: 'Firebase-ready',
                      text:
                          'Repository-Logik kann später an Firestore, Auth und Cloud Functions andocken.',
                    ),
                  ],
                ),
              ),
            ],
            secondary: [
              SectionPanel(
                title: 'Aktuelle Zentrale',
                subtitle: latestLobby == null
                    ? 'Sobald du eine Lobby öffnest, erscheint sie hier als Schnellzugriff.'
                    : 'Dein letzter Raum bleibt direkt von hier aus erreichbar.',
                child: latestLobby == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Noch keine aktive Lobby vorhanden.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => context.go('/cases'),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Ersten Fall starten'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoPill(
                            label: 'Code ${latestLobby.code}',
                            icon: Icons.key_rounded,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            latestCase?.title ?? 'Unbekannter Fall',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            latestCase?.tagline ??
                                'Der Raum steht bereit für neue Ermittler.',
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () =>
                                context.go('/lobbies/room/${latestLobby.code}'),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Zur Lobby'),
                          ),
                        ],
                      ),
              ),
              const SectionPanel(
                title: 'Premium-Gefühl auf jeder Seite',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExperienceLine('Dezente Animationen statt Formular-Optik'),
                    _ExperienceLine(
                        'Luxuriöses Farbsystem mit Gold, Noir und Weinrot'),
                    _ExperienceLine(
                        'Rollen, Hinweise und Host-Steuerung aufeinander abgestimmt'),
                    _ExperienceLine(
                        'Responsiv für Tablet, Smartphone und großes Desktop-Layout'),
                  ],
                ),
              ),
              SectionPanel(
                title: 'Live-Fälle im Archiv',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cases
                      .take(3)
                      .map(
                        (mysteryCase) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => context.go('/cases/${mysteryCase.id}'),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withOpacity(0.03),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: LinearGradient(
                                        colors: mysteryCase.coverColors,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mysteryCase.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mysteryCase.category.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryHero extends StatelessWidget {
  const _StoryHero({
    required this.alias,
    required this.latestLobbyCode,
  });

  final String alias;
  final String? latestLobbyCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.midnight.withOpacity(0.9),
            AppPalette.noir.withOpacity(0.8),
            AppPalette.wine.withOpacity(0.76),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoPill(
            label: 'Host-Perspektive bereit',
            icon: Icons.visibility_rounded,
            accent: AppPalette.gold,
          ),
          const SizedBox(height: 18),
          Text(
            'Willkommen zurück, $alias.',
            style:
                textTheme.headlineMedium?.copyWith(color: AppPalette.parchment),
          ),
          const SizedBox(height: 12),
          Text(
            latestLobbyCode == null
                ? 'Dein naechster Abend kann sofort starten: einen Fall auswaehlen, Lobby erstellen und echte Gaeste per Einladungslink dazu holen.'
                : 'Die letzte Session mit Code $latestLobbyCode ist nur einen Klick entfernt. Rolle verteilen, Countdown starten und Hinweise elegant ausspielen.',
            style: textTheme.bodyLarge?.copyWith(color: AppPalette.parchment),
          ),
        ],
      ),
    );
  }
}

class _ActionDeck extends StatelessWidget {
  const _ActionDeck({
    required this.onExploreCases,
    required this.onOpenLobbies,
    required this.onReviewRoles,
  });

  final VoidCallback onExploreCases;
  final VoidCallback onOpenLobbies;
  final VoidCallback onReviewRoles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          title: 'Neues Spiel',
          subtitle: 'Wähle einen Fall und öffne eine neue Premium-Lobby.',
          icon: Icons.add_circle_outline_rounded,
          onTap: onExploreCases,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          title: 'Lobby beitreten',
          subtitle: 'Per Code, Link oder QR direkt in laufende Fälle springen.',
          icon: Icons.login_rounded,
          onTap: onOpenLobbies,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          title: 'Meine Rollen',
          subtitle: 'Jede geheime Identität bleibt für dich dokumentiert.',
          icon: Icons.style_rounded,
          onTap: onReviewRoles,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppPalette.gold.withOpacity(0.16),
              ),
              child: Icon(icon, color: AppPalette.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

class _ArchitectureLine extends StatelessWidget {
  const _ArchitectureLine({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _ExperienceLine extends StatelessWidget {
  const _ExperienceLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: AppPalette.gold),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

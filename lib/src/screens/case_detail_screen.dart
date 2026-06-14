import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_shell.dart';

class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({
    super.key,
    required this.caseId,
  });

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mysteryCase = ref.watch(mysteryCaseProvider(caseId));
    final state = ref.watch(mysteryControllerProvider);

    if (mysteryCase == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              const Text('Dieser Fall wurde nicht gefunden.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/cases'),
                child: const Text('Zurueck zum Archiv'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: mysteryCase.coverColors,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    InfoPill(
                      label: mysteryCase.category.label,
                      icon: Icons.style_rounded,
                      accent: Colors.white,
                    ),
                    InfoPill(
                      label: mysteryCase.difficulty.label,
                      icon: Icons.auto_graph_rounded,
                      accent: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  mysteryCase.title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppPalette.parchment,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  mysteryCase.tagline,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppPalette.parchment,
                      ),
                ),
                const SizedBox(height: 14),
                Text(
                  mysteryCase.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppPalette.parchment.withOpacity(0.94),
                      ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricBadge(
                        label: '${mysteryCase.durationMinutes} Minuten'),
                    _MetricBadge(
                      label:
                          '${mysteryCase.playerMin}-${mysteryCase.playerMax} Spieler',
                    ),
                    _MetricBadge(
                        label: 'Empfohlen ab ${mysteryCase.recommendedAge}'),
                    _MetricBadge(label: mysteryCase.atmosphere),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    final code = ref
                        .read(mysteryControllerProvider.notifier)
                        .createLobby(
                          mysteryCase: mysteryCase,
                          hostName: state.localAlias,
                        );
                    context.go('/lobbies/room/$code');
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Lobby erstellen'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TwoColumnLayout(
            primary: [
              SectionPanel(
                title: 'Spielprofil',
                subtitle:
                    'Diese Akte ist fuer elegante Rollenrunden mit klarer Dramaturgie und starken Geheimnissen gebaut.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mysteryCase.atmosphere,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: mysteryCase.materials
                          .map((item) => InfoPill(label: item))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    ...mysteryCase.highlights.map(
                      (highlight) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: AppPalette.gold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(highlight)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SectionPanel(
                title: 'Rollen-Vorschau',
                subtitle:
                    'Im Spiel sieht jeder nur die eigene Akte. Hier im Archiv bekommst du eine spoilerarme Kurzübersicht.',
                child: Column(
                  children: mysteryCase.roles
                      .map(
                        (role) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withOpacity(0.04),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    AppPalette.gold.withOpacity(0.18),
                                child: Text(
                                  role.avatar,
                                  style: const TextStyle(
                                    color: AppPalette.gold,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(role.persona),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        InfoPill(
                                          label: role.outfit.budget.label,
                                          icon: Icons.checkroom_rounded,
                                        ),
                                        InfoPill(
                                          label:
                                              role.outfit.palette.join(' / '),
                                          icon: Icons.palette_outlined,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            secondary: [
              SectionPanel(
                title: 'Phasenregie',
                child: Column(
                  children: List.generate(mysteryCase.phases.length, (index) {
                    final phase = mysteryCase.phases[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppPalette.gold.withOpacity(0.16),
                            ),
                            alignment: Alignment.center,
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  phase.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${phase.durationMinutes} Min · ${phase.musicCue}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(phase.description),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              SectionPanel(
                title: 'Kostuemempfehlungen',
                subtitle:
                    'Jede Rolle bringt direkt verwertbare Outfit-Ideen mit verschiedenen Budgets mit.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: mysteryCase.roles.take(3).map((role) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text('Neutral: ${role.outfit.neutral}'),
                          const SizedBox(height: 4),
                          Text(
                              'Accessoires: ${role.outfit.accessories.join(', ')}'),
                          const SizedBox(height: 4),
                          Text('Frisur: ${role.outfit.hairstyle}'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              SectionPanel(
                title: 'Hinweissystem',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: mysteryCase.hints
                      .map(
                        (hint) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoPill(label: 'Phase ${hint.unlockPhase + 1}'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hint.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(hint.detail),
                                  ],
                                ),
                              ),
                            ],
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

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppPalette.parchment,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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
                      label:
                          '${mysteryCase.playerMin}-${mysteryCase.playerMax} Spieler',
                      icon: Icons.groups_rounded,
                      accent: Colors.white,
                    ),
                    InfoPill(
                      label: '${mysteryCase.durationMinutes} Min',
                      icon: Icons.schedule_rounded,
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
                  'Waehle zuerst den Fall. Die eigentlichen Rollenakten, Geheimnisse und persoenlichen Hinweise werden erst spaeter ueber die Einladungen sichtbar.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppPalette.parchment.withOpacity(0.94),
                      ),
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
          SectionPanel(
            title: 'Worum geht es?',
            subtitle:
                'Hier bleibt es absichtlich kompakt: nur die Szene und der grobe Rahmen.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mysteryCase.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricBadge(
                      label:
                          '${mysteryCase.playerMin}-${mysteryCase.playerMax} Spieler',
                    ),
                    _MetricBadge(label: '${mysteryCase.durationMinutes} Minuten'),
                    _MetricBadge(label: mysteryCase.atmosphere),
                  ],
                ),
                if (mysteryCase.highlights.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  ...mysteryCase.highlights.take(3).map(
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionPanel(
            title: 'Figuren in dieser Runde',
            subtitle:
                'Spoilerarm und bewusst schlicht. Private Details sehen nur die eingeladenen Spieler.',
            child: Column(
              children: mysteryCase.roles
                  .map((role) => _RolePreviewCard(role: role))
                  .toList(),
            ),
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RolePreviewCard extends StatelessWidget {
  const _RolePreviewCard({required this.role});

  final MysteryRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppPalette.gold.withOpacity(0.18),
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(role.persona),
                const SizedBox(height: 10),
                InfoPill(
                  label: _rolePresentationHint(role),
                  icon: Icons.person_outline_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _rolePresentationHint(MysteryRole role) {
  final lowerName = role.name.toLowerCase();
  const feminineMarkers = [
    'isabel',
    'nora',
    'amara',
    'sofia',
    'nadia',
    'baronin',
    'mila',
    'celeste',
    'opal',
    'iris',
    'sera',
    'vesper',
  ];
  const masculineMarkers = [
    'lucien',
    'pater',
    'matthias',
    'captain',
    'elias',
    'gabriel',
    'leon',
    'enzo',
    'gideon',
    'julian',
    'theo',
    'inspector',
  ];

  if (feminineMarkers.any(lowerName.contains)) {
    return 'Eher weiblich lesbar';
  }
  if (masculineMarkers.any(lowerName.contains)) {
    return 'Eher maennlich lesbar';
  }
  return 'Offen spielbar';
}

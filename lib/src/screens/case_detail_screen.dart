import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
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
    final strings = ref.watch(appStringsProvider);
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
              Text(strings.caseNotFound),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/cases'),
                child: Text(strings.backToArchive),
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
                      label: strings.categoryLabel(mysteryCase.category),
                      icon: Icons.style_rounded,
                      accent: Colors.white,
                    ),
                    InfoPill(
                      label:
                          strings.playersLabel(mysteryCase.playerMin, mysteryCase.playerMax),
                      icon: Icons.groups_rounded,
                      accent: Colors.white,
                    ),
                    InfoPill(
                      label: strings.minutesShort(mysteryCase.durationMinutes),
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
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    final code = ref.read(mysteryControllerProvider.notifier).createLobby(
                          mysteryCase: mysteryCase,
                          hostName: state.localAlias,
                        );
                    context.go('/lobbies/room/$code');
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: Text(strings.createLobbyLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionPanel(
            title: strings.caseOverviewTitle,
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
                          strings.playersLabel(mysteryCase.playerMin, mysteryCase.playerMax),
                    ),
                    _MetricBadge(
                      label: strings.minutesLong(mysteryCase.durationMinutes),
                    ),
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
            title: strings.caseCharactersTitle,
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
        style: const TextStyle(fontWeight: FontWeight.w700),
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
            backgroundColor: AppPalette.gold.withOpacity(0.16),
            child: Text(role.avatar),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

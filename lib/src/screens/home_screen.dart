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
            title: 'Guten Abend, ${state.localAlias}',
            subtitle:
                'Starte ruhig und ohne Umwege in den Abend. Alles Weitere erscheint erst, sobald du in einer Lobby bist.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final welcomeCard = _WelcomeCard(
                  latestLobby: latestLobby,
                  latestCase: latestCase,
                );
                final quickActions = _QuickActions(
                  latestLobby: latestLobby,
                  onCreateGame: () => context.go('/cases'),
                  onJoinLobby: () => context.go('/lobbies'),
                  onResumeLobby: latestLobby == null
                      ? null
                      : () => context.go('/lobbies/room/${latestLobby.code}'),
                );

                if (!isWide) {
                  return Column(
                    children: [
                      welcomeCard,
                      const SizedBox(height: 16),
                      quickActions,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: welcomeCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: quickActions),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.latestLobby,
    required this.latestCase,
  });

  final LobbySession? latestLobby;
  final MysteryCase? latestCase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.midnight.withOpacity(0.9),
            AppPalette.noir.withOpacity(0.84),
            AppPalette.wine.withOpacity(0.72),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoPill(
            label: 'Salon',
            icon: Icons.nightlight_round,
            accent: AppPalette.gold,
          ),
          const SizedBox(height: 18),
          Text(
            latestLobby == null
                ? 'Hier beginnt dein naechster Krimi-Abend.'
                : 'Deine letzte Runde ist noch griffbereit.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppPalette.parchment,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            latestLobby == null
                ? 'Erstelle ein neues Spiel oder tritt direkt ueber einen Code oder Link einer Lobby bei.'
                : 'Die Lobby ${latestLobby!.code} wartet noch auf dich. Wenn du magst, kannst du direkt dort weitermachen.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppPalette.parchment,
                ),
          ),
          if (latestLobby != null && latestCase != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoPill(
                    label: 'Offene Lobby ${latestLobby!.code}',
                    icon: Icons.key_rounded,
                    accent: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    latestCase!.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppPalette.parchment,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    latestCase!.tagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.parchment.withOpacity(0.92),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.latestLobby,
    required this.onCreateGame,
    required this.onJoinLobby,
    required this.onResumeLobby,
  });

  final LobbySession? latestLobby;
  final VoidCallback onCreateGame;
  final VoidCallback onJoinLobby;
  final VoidCallback? onResumeLobby;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StartActionCard(
          title: 'Neues Spiel erstellen',
          subtitle: 'Fall auswaehlen und direkt eine neue Lobby starten.',
          icon: Icons.add_circle_outline_rounded,
          onTap: onCreateGame,
        ),
        const SizedBox(height: 12),
        _StartActionCard(
          title: 'Lobby beitreten',
          subtitle: 'Per Code oder Einladungslink sofort in eine Runde gehen.',
          icon: Icons.login_rounded,
          onTap: onJoinLobby,
        ),
        if (latestLobby != null && onResumeLobby != null) ...[
          const SizedBox(height: 12),
          _StartActionCard(
            title: 'Letzte Lobby fortsetzen',
            subtitle: 'Zur offenen Runde mit dem Code ${latestLobby!.code}.',
            icon: Icons.arrow_forward_rounded,
            onTap: onResumeLobby!,
            compact: true,
          ),
        ],
      ],
    );
  }
}

class _StartActionCard extends StatelessWidget {
  const _StartActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 48 : 52,
              height: compact ? 48 : 52,
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
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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

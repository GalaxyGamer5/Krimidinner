import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../state/app_providers.dart';
import 'mystery_shell.dart';

class GuestShell extends ConsumerWidget {
  const GuestShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mysteryControllerProvider);
    final lobbyCode = _extractLobbyCode(context);
    final lobby = lobbyCode == null ? null : ref.watch(lobbyProvider(lobbyCode));
    final mysteryCase =
        lobby == null ? null : ref.watch(mysteryCaseProvider(lobby.caseId));
    final eventTitle = mysteryCase?.title ?? 'MYSTERY NIGHT';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const MysteryBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _GuestTopBar(
                  eventTitle: eventTitle,
                  localAlias: state.localAlias,
                  lobbyCode: lobbyCode,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _extractLobbyCode(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final segments = uri.pathSegments;
    // Path: /guest/room/:code
    final roomIndex = segments.indexOf('room');
    if (roomIndex != -1 && roomIndex + 1 < segments.length) {
      return segments[roomIndex + 1];
    }
    return null;
  }
}

class _GuestTopBar extends StatelessWidget {
  const _GuestTopBar({
    required this.eventTitle,
    required this.localAlias,
    required this.lobbyCode,
  });

  final String eventTitle;
  final String localAlias;
  final String? lobbyCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: MysteryDecor.panel(context, opacity: 0.74),
      child: Row(
        children: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? AppPalette.gold : AppPalette.midnight,
              size: 26,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            color: isDark
                ? AppPalette.ash.withOpacity(0.97)
                : Colors.white.withOpacity(0.97),
            offset: const Offset(0, 48),
            onSelected: (value) => _handleMenuSelection(context, value),
            itemBuilder: (context) => [
              _menuItem(context, 'hub', Icons.home_rounded, 'Salon'),
              _menuItem(
                  context, 'cases', Icons.auto_stories_rounded, 'Fälle'),
              _menuItem(
                  context, 'roles', Icons.person_search_rounded, 'Meine Rollen'),
              _menuItem(context, 'account', Icons.tune_rounded, 'Konto'),
              const PopupMenuDivider(),
              _menuItem(
                  context, 'leave', Icons.logout_rounded, 'Lobby verlassen'),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventTitle,
                  style: textTheme.titleLarge?.copyWith(
                    letterSpacing: 1.4,
                    color: isDark ? AppPalette.gold : AppPalette.midnight,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Gastansicht · $localAlias',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    BuildContext context,
    String value,
    IconData icon,
    String label,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDestructive = value == 'leave';
    final color = isDestructive
        ? const Color(0xFFE76B74)
        : (isDark ? AppPalette.parchment : AppPalette.midnight);

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'hub':
        context.go('/hub');
      case 'cases':
        context.go('/cases');
      case 'roles':
        context.go('/roles');
      case 'account':
        context.go('/account');
      case 'leave':
        _confirmLeaveLobby(context);
    }
  }

  void _confirmLeaveLobby(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lobby verlassen?'),
        content: const Text(
          'Deine Rolle bleibt noch 24 Stunden reserviert. Du kannst mit demselben Namen wieder beitreten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Bleiben'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              context.go('/hub');
            },
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
  }
}

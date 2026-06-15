import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_shell.dart';

class GuestInvitationScreen extends ConsumerStatefulWidget {
  const GuestInvitationScreen({
    super.key,
    required this.invitationId,
    required this.lobbyCode,
  });

  final String invitationId;
  final String lobbyCode;

  @override
  ConsumerState<GuestInvitationScreen> createState() =>
      _GuestInvitationScreenState();
}

class _GuestInvitationScreenState
    extends ConsumerState<GuestInvitationScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final lobby = widget.lobbyCode.isEmpty
        ? null
        : ref.read(lobbyProvider(widget.lobbyCode));
    final invitation = lobby?.invitations
        .where((entry) => entry.id == widget.invitationId)
        .firstOrNull;
    final alias = invitation?.recipientName ??
        ref.read(mysteryControllerProvider).localAlias;
    _nameController = TextEditingController(text: alias);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobby = widget.lobbyCode.isEmpty
        ? null
        : ref.watch(lobbyProvider(widget.lobbyCode));
    final invitation = _findInvitation(lobby);
    final mysteryCase =
        lobby == null ? null : ref.watch(mysteryCaseProvider(lobby.caseId));
    final isLoggedIn = ref.watch(isLoggedInProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const MysteryBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: lobby == null ||
                          invitation == null ||
                          mysteryCase == null
                      ? _buildNotFound(context, textTheme)
                      : _buildLetter(
                          context,
                          textTheme,
                          isDark,
                          lobby,
                          invitation,
                          mysteryCase,
                          isLoggedIn,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: MysteryDecor.panel(context, opacity: 0.82),
      child: Column(
        children: [
          Icon(Icons.mail_lock_rounded,
              size: 64, color: AppPalette.wine.withOpacity(0.6)),
          const SizedBox(height: 20),
          Text(
            'Einladung nicht gefunden',
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Der Link ist abgelaufen, wurde zurückgezogen oder die Lobby ist lokal nicht verfügbar.',
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/hub'),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Zum Salon'),
          ),
        ],
      ),
    );
  }

  Widget _buildLetter(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
    LobbySession lobby,
    LobbyInvitation invitation,
    MysteryCase mysteryCase,
    bool isLoggedIn,
  ) {
    final assignedRole = mysteryCase.roles
        .where((role) => role.id == invitation.assignedRoleId)
        .firstOrNull;

    final alreadyAccepted =
        invitation.status == LobbyInvitationStatus.accepted;
    final isRevoked = invitation.status == LobbyInvitationStatus.revoked;

    return Column(
      children: [
        // ── Wax-seal header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: mysteryCase.coverColors,
            ),
          ),
          child: Column(
            children: [
              // Seal icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 36,
                  color: AppPalette.parchment,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Persönliche Einladung',
                style: textTheme.titleMedium?.copyWith(
                  color: AppPalette.parchment.withOpacity(0.85),
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mysteryCase.title,
                style: textTheme.displaySmall?.copyWith(
                  color: AppPalette.parchment,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                mysteryCase.tagline,
                style: textTheme.headlineSmall?.copyWith(
                  color: AppPalette.parchment.withOpacity(0.88),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // ── Letter body ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(30)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.07),
                      Colors.white.withOpacity(0.03),
                    ]
                  : [
                      Colors.white.withOpacity(0.92),
                      Colors.white.withOpacity(0.78),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppPalette.midnight.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Liebe/r ${invitation.recipientName},',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'du wirst herzlich zu einem unvergesslichen Krimi-Dinner-Abend eingeladen. '
                'Ein mysteriöser Fall wartet auf dich — mit einer Rolle, die speziell für dich ausgewählt wurde.',
                style: textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 20),

              // Case details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : AppPalette.ivory,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : AppPalette.midnight.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Über den Fall',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppPalette.gold,
                        )),
                    const SizedBox(height: 10),
                    Text(
                      mysteryCase.description,
                      style: textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        InfoPill(
                          label: '${mysteryCase.durationMinutes} Min',
                          icon: Icons.schedule_rounded,
                        ),
                        InfoPill(
                          label:
                              '${mysteryCase.playerMin}–${mysteryCase.playerMax} Spieler',
                          icon: Icons.groups_rounded,
                        ),
                        InfoPill(
                          label: mysteryCase.difficulty.label,
                          icon: Icons.local_fire_department_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Atmosphäre: ${mysteryCase.atmosphere}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Role teaser
              if (assignedRole != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppPalette.gold.withOpacity(isDark ? 0.1 : 0.08),
                        AppPalette.wine.withOpacity(isDark ? 0.08 : 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: AppPalette.gold.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_pin_circle_rounded,
                          color: AppPalette.gold, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deine Rolle wurde vorbereitet',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Eine besondere Figur wartet auf dich. Alle Details erfährst du nach dem Beitritt.',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Name input + accept button
              if (!alreadyAccepted && !isRevoked) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Dein Name',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    hintText: invitation.recipientName,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _acceptInvitation(lobby),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Einladung annehmen'),
                  ),
                ),
                if (!isLoggedIn) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => context.go('/register'),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Konto erstellen'),
                    ),
                  ),
                ],
              ],

              if (alreadyAccepted) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.green.withOpacity(isDark ? 0.12 : 0.08),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Diese Einladung wurde bereits angenommen.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.go('/guest/room/${lobby.code}'),
                    icon: const Icon(Icons.meeting_room_rounded),
                    label: const Text('Zur Lobby'),
                  ),
                ),
              ],

              if (isRevoked) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppPalette.wine.withOpacity(isDark ? 0.15 : 0.08),
                    border: Border.all(
                        color: AppPalette.wine.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel_rounded,
                          color: AppPalette.wine.withOpacity(0.8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Diese Einladung wurde vom Spielleiter zurückgezogen.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Closing
              const SizedBox(height: 24),
              Text(
                'Wir freuen uns auf dich!',
                style: textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '— Das Mystery Night Team',
                style: textTheme.titleMedium?.copyWith(
                  color: AppPalette.gold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _acceptInvitation(LobbySession lobby) {
    final error = ref.read(mysteryControllerProvider.notifier).joinLobby(
          code: lobby.code,
          alias: _nameController.text,
          invitationId: widget.invitationId,
        );

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Willkommen! Du bist jetzt in der Lobby.')),
    );
    context.go('/guest/room/${lobby.code}');
  }

  LobbyInvitation? _findInvitation(LobbySession? lobby) {
    if (lobby == null) return null;
    return lobby.invitations
        .where((entry) => entry.id == widget.invitationId)
        .firstOrNull;
  }
}

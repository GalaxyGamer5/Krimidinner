import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_shell.dart';

class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({
    super.key,
    required this.invitationId,
    required this.lobbyCode,
  });

  final String invitationId;
  final String lobbyCode;

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
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
    final state = ref.watch(mysteryControllerProvider);
    final lobby = widget.lobbyCode.isEmpty
        ? null
        : ref.watch(lobbyProvider(widget.lobbyCode));
    final invitation = _invitationForLobby(lobby, widget.invitationId);
    final mysteryCase =
        lobby == null ? null : ref.watch(mysteryCaseProvider(lobby.caseId));

    if (lobby == null || invitation == null || mysteryCase == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SectionPanel(
          title: 'Einladung nicht gefunden',
          subtitle:
              'Der Link ist abgelaufen, wurde zurueckgezogen oder die Lobby ist lokal nicht verfuegbar.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Oeffne die Lobbyzentrale und pruefe den Code oder bitte den Spielleiter um einen neuen Link.',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go(
                  widget.lobbyCode.isEmpty
                      ? '/lobbies'
                      : '/lobbies?invite=${widget.lobbyCode}',
                ),
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Zur Lobbyzentrale'),
              ),
            ],
          ),
        ),
      );
    }

    final assignedRole = _roleForInvitation(mysteryCase, invitation);
    final acceptedPlayer = invitation.acceptedByPlayerId == null
        ? null
        : lobby.players
            .where((player) => player.id == invitation.acceptedByPlayerId)
            .firstOrNull;
    final acceptedByCurrentAlias = acceptedPlayer != null &&
        acceptedPlayer.name.toLowerCase() == state.localAlias.toLowerCase();
    final showWaitingRoom =
        invitation.status == LobbyInvitationStatus.accepted &&
            acceptedByCurrentAlias;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InvitationHero(
            mysteryCase: mysteryCase,
            lobby: lobby,
            invitation: invitation,
            showWaitingRoom: showWaitingRoom,
          ),
          const SizedBox(height: 16),
          if (showWaitingRoom)
            TwoColumnLayout(
              primary: [
                SectionPanel(
                  title: 'Deine Rolle',
                  subtitle:
                      'Der Spielleiter hat diese Figur fuer dich vorbereitet.',
                  trailing: assignedRole == null
                      ? null
                      : InfoPill(
                          label: assignedRole.name,
                          icon: Icons.person_pin_circle_rounded,
                        ),
                  child: assignedRole == null
                      ? const Text('Deine Rolle wird gerade vorbereitet.')
                      : _RolePreview(role: assignedRole),
                ),
                SectionPanel(
                  title: 'Warteraum',
                  subtitle: lobby.hasStarted
                      ? 'Die Runde wurde gestartet. Du kannst jetzt in den Lobbyraum wechseln.'
                      : 'Bitte warte hier, bis der Spielleiter die Runde startet.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lobby.hasStarted
                            ? 'Der Fall laeuft bereits. Deine Hinweise und das volle Dossier warten im Lobbyraum auf dich.'
                            : 'Sobald die Runde beginnt, schaltet sich dein voller Lobbyraum frei. Bis dahin bleiben Szene und Rolle fuer dich sichtbar.',
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: lobby.hasStarted
                            ? () => context.go('/lobbies/room/${lobby.code}')
                            : null,
                        icon: const Icon(Icons.meeting_room_rounded),
                        label: Text(
                          lobby.hasStarted
                              ? 'Zur aktiven Lobby'
                              : 'Warte auf den Start',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              secondary: [
                SectionPanel(
                  title: 'Fallueberblick',
                  subtitle: 'Das ist die Szene, zu der du eingeladen wurdest.',
                  child: _CaseOverview(mysteryCase: mysteryCase),
                ),
                SectionPanel(
                  title: 'Lobbystatus',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      MetricTile(
                        label: 'Spieler',
                        value:
                            '${lobby.players.length}/${mysteryCase.roles.length}',
                        icon: Icons.groups_rounded,
                      ),
                      MetricTile(
                        label: 'Status',
                        value: lobby.hasStarted ? 'Gestartet' : 'Bereit',
                        icon: lobby.hasStarted
                            ? Icons.play_circle_outline_rounded
                            : Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            TwoColumnLayout(
              primary: [
                SectionPanel(
                  title: 'Einladung annehmen',
                  subtitle:
                      'Gib den Namen ein, unter dem du in der Runde erscheinen sollst.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Dein Name',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          hintText: invitation.recipientName,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed:
                            invitation.status == LobbyInvitationStatus.pending
                                ? () => _acceptInvitation(lobby)
                                : null,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Einladung annehmen'),
                      ),
                      if (invitation.status == LobbyInvitationStatus.accepted &&
                          !acceptedByCurrentAlias) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Diese Einladung wurde bereits angenommen.',
                        ),
                      ],
                      if (invitation.status ==
                          LobbyInvitationStatus.revoked) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Diese Einladung wurde vom Spielleiter zurueckgezogen.',
                        ),
                      ],
                    ],
                  ),
                ),
                SectionPanel(
                  title: 'Was dich erwartet',
                  subtitle:
                      'Vor dem Start bekommst du den Fall, die Stimmung und deine Rolle angezeigt.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nach dem Annehmen landest du direkt im Warteraum. Dort siehst du die grobe Szene des Falls und deine persoenliche Charakterrolle.',
                      ),
                      const SizedBox(height: 12),
                      InfoPill(
                        label:
                            'Rolle vorbereitet fuer ${invitation.recipientName}',
                        icon: Icons.lock_clock_rounded,
                      ),
                    ],
                  ),
                ),
              ],
              secondary: [
                SectionPanel(
                  title: 'Fallueberblick',
                  subtitle: 'Der Spielleiter laedt dich in diese Szene ein.',
                  child: _CaseOverview(mysteryCase: mysteryCase),
                ),
                SectionPanel(
                  title: 'Schnelldaten',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      MetricTile(
                        label: 'Dauer',
                        value: '${mysteryCase.durationMinutes} Min',
                        icon: Icons.schedule_rounded,
                      ),
                      MetricTile(
                        label: 'Mitspieler',
                        value:
                            '${mysteryCase.playerMin}-${mysteryCase.playerMax}',
                        icon: Icons.person_add_alt_1_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _acceptInvitation(LobbySession lobby) {
    final error = ref.read(mysteryControllerProvider.notifier).joinLobby(
          code: lobby.code,
          alias: _nameController.text,
          invitationId: widget.invitationId,
        );

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage('Einladung angenommen. Du bist jetzt im Warteraum.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  LobbyInvitation? _invitationForLobby(
    LobbySession? lobby,
    String invitationId,
  ) {
    if (lobby == null) {
      return null;
    }
    return lobby.invitations
        .where((entry) => entry.id == invitationId)
        .firstOrNull;
  }

  MysteryRole? _roleForInvitation(
    MysteryCase mysteryCase,
    LobbyInvitation invitation,
  ) {
    return mysteryCase.roles
        .where((role) => role.id == invitation.assignedRoleId)
        .firstOrNull;
  }
}

class _InvitationHero extends StatelessWidget {
  const _InvitationHero({
    required this.mysteryCase,
    required this.lobby,
    required this.invitation,
    required this.showWaitingRoom,
  });

  final MysteryCase mysteryCase;
  final LobbySession lobby;
  final LobbyInvitation invitation;
  final bool showWaitingRoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                label: 'Lobby ${lobby.code}',
                icon: Icons.key_rounded,
                accent: Colors.white,
              ),
              InfoPill(
                label: showWaitingRoom ? 'Warteraum' : 'Einladung',
                icon: showWaitingRoom
                    ? Icons.hourglass_top_rounded
                    : Icons.mail_outline_rounded,
                accent: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            showWaitingRoom
                ? 'Du bist dabei'
                : 'Du bist eingeladen zu ${mysteryCase.title}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppPalette.parchment,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            mysteryCase.tagline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPalette.parchment,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            showWaitingRoom
                ? 'Die Szene steht fest. Deine persoenliche Rolle wurde fuer dich reserviert. Jetzt fehlt nur noch der Startschuss des Spielleiters.'
                : 'Der Spielleiter hat bereits eine persoenliche Einladung fuer ${invitation.recipientName} vorbereitet.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppPalette.parchment.withOpacity(0.92),
                ),
          ),
        ],
      ),
    );
  }
}

class _CaseOverview extends StatelessWidget {
  const _CaseOverview({required this.mysteryCase});

  final MysteryCase mysteryCase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mysteryCase.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            InfoPill(
              label: mysteryCase.difficulty.label,
              icon: Icons.local_fire_department_outlined,
            ),
            InfoPill(
              label: mysteryCase.recommendedAge,
              icon: Icons.cake_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Atmosphaere: ${mysteryCase.atmosphere}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _RolePreview extends StatelessWidget {
  const _RolePreview({required this.role});

  final MysteryRole role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            InfoPill(label: role.name, icon: Icons.person_outline_rounded),
            InfoPill(
              label: role.outfit.budget.label,
              icon: Icons.style_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PreviewLine(title: 'Persoenlichkeit', text: role.persona),
        _PreviewLine(title: 'Ziel', text: role.goal),
        _PreviewLine(title: 'Auftreten', text: role.outfit.neutral),
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}

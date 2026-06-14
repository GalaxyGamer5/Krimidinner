import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_shell.dart';

class LobbyRoomScreen extends ConsumerStatefulWidget {
  const LobbyRoomScreen({
    super.key,
    required this.code,
  });

  final String code;

  @override
  ConsumerState<LobbyRoomScreen> createState() => _LobbyRoomScreenState();
}

class _LobbyRoomScreenState extends ConsumerState<LobbyRoomScreen> {
  late final TextEditingController _chatController;
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobby = ref.watch(lobbyProvider(widget.code));
    if (lobby == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Die Lobby ${widget.code} wurde nicht gefunden.'),
        ),
      );
    }

    final mysteryCase = ref.watch(mysteryCaseProvider(lobby.caseId));
    if (mysteryCase == null) {
      return const Center(
        child: Text('Der zugehoerige Fall ist nicht verfuegbar.'),
      );
    }

    final state = ref.watch(mysteryControllerProvider);
    final viewer = _playerByName(lobby, state.localAlias);
    final currentRole =
        viewer == null ? null : _roleForPlayer(lobby, mysteryCase, viewer);
    final currentPhase = mysteryCase.phases[lobby.phaseIndex];
    final remaining = _phaseRemaining(lobby, currentPhase);
    final isHost = viewer?.id == lobby.hostId;
    final pendingInvitations = lobby.invitations
        .where(
            (invitation) => invitation.status == LobbyInvitationStatus.pending)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: mysteryCase.coverColors,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final info = _LobbyHeaderInfo(
                  lobby: lobby,
                  mysteryCase: mysteryCase,
                  currentPhase: currentPhase,
                  remaining: remaining,
                  pendingInvitationCount: pendingInvitations.length,
                );
                final controls = _HostControls(
                  lobby: lobby,
                  isHost: isHost,
                  onStart: () => _runHostAction(
                    ref
                        .read(mysteryControllerProvider.notifier)
                        .startGame(widget.code),
                  ),
                  onAdvance: () => _runHostAction(
                    ref
                        .read(mysteryControllerProvider.notifier)
                        .advancePhase(widget.code),
                  ),
                  onReshuffle: () => _runHostAction(
                    ref
                        .read(mysteryControllerProvider.notifier)
                        .reshuffleRoles(widget.code),
                  ),
                  onInviteGuests: () => _openInviteSheet(lobby, mysteryCase),
                );

                if (!isWide) {
                  return Column(
                    children: [
                      info,
                      const SizedBox(height: 18),
                      controls,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: info),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: controls),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TwoColumnLayout(
            primary: [
              if (viewer != null && !isHost && !lobby.hasStarted)
                SectionPanel(
                  title: 'Warteraum',
                  subtitle:
                      'Du bist bereits in der Runde. Jetzt fehlt nur noch der Start durch den Spielleiter.',
                  child: _WaitingPanel(
                    mysteryCase: mysteryCase,
                    role: currentRole,
                  ),
                ),
              SectionPanel(
                title: 'Deine geheime Rolle',
                subtitle: currentRole == null
                    ? 'Sobald du Teil dieser Lobby bist, erscheint dein persoenliches Dossier hier.'
                    : 'Nur fuer ${viewer!.name} sichtbar. Die Rolle wird lokal im Archiv gespeichert.',
                trailing: currentRole == null
                    ? null
                    : InfoPill(
                        label: currentRole.outfit.budget.label,
                        icon: Icons.lock_rounded,
                      ),
                child: currentRole == null
                    ? const Text('Noch keine Rolle verfuegbar.')
                    : _RoleDossier(role: currentRole),
              ),
              SectionPanel(
                title: 'Chat',
                subtitle:
                    'Lobby-, Rollen- und Systemmeldungen laufen hier zusammen. Perfekt fuer die Moderation waehrend des Spiels.',
                child: _ChatPanel(
                  lobby: lobby,
                  chatController: _chatController,
                  onSend: _sendChat,
                ),
              ),
            ],
            secondary: [
              SectionPanel(
                title: 'Spielerliste & Einladungen',
                subtitle:
                    'Persoenliche Einladungen, Rollenbindungen und Wartestatus laufen hier zusammen.',
                child: _RosterPanel(
                  lobby: lobby,
                  mysteryCase: mysteryCase,
                  isHost: isHost,
                  onKick: (playerId) => _runHostAction(
                    ref.read(mysteryControllerProvider.notifier).kickPlayer(
                          widget.code,
                          playerId,
                        ),
                  ),
                  onShareInvitation: (invitation) => _openInviteSheet(
                      lobby, mysteryCase,
                      invitation: invitation),
                  onRevokeInvitation: (invitationId) => _runHostAction(
                    ref
                        .read(mysteryControllerProvider.notifier)
                        .revokeInvitation(
                          widget.code,
                          invitationId,
                        ),
                  ),
                ),
              ),
              if (lobby.hasStarted)
                SectionPanel(
                  title: 'Hinweise & Phasen',
                  subtitle:
                      'Automatische Hinweise werden pro Phase freigeschaltet. Der Host kann jederzeit manuell nachlegen.',
                  child: _HintsPanel(
                    lobby: lobby,
                    mysteryCase: mysteryCase,
                    currentPhase: currentPhase,
                    isHost: isHost,
                    onReveal: (hintId) => _runHostAction(
                      ref.read(mysteryControllerProvider.notifier).revealHint(
                            widget.code,
                            hintId,
                          ),
                    ),
                  ),
                ),
              SectionPanel(
                title: 'Gastzugang & QR',
                subtitle:
                    'Der allgemeine Lobby-Link bleibt verfuergbar. Fuer echte Einladungen nutze den Button "Gaeste einladen".',
                child: _InviteOverviewPanel(
                  lobby: lobby,
                  pendingInvitationCount: pendingInvitations.length,
                  onCopyLobbyLink: () => _copyToClipboard(lobby.inviteLink),
                  onOpenInvitationTool: () =>
                      _openInviteSheet(lobby, mysteryCase),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendChat() {
    final alias = ref.read(mysteryControllerProvider).localAlias;
    ref.read(mysteryControllerProvider.notifier).sendLobbyMessage(
          code: widget.code,
          sender: alias,
          body: _chatController.text,
        );
    _chatController.clear();
  }

  Future<void> _openInviteSheet(
    LobbySession lobby,
    MysteryCase mysteryCase, {
    LobbyInvitation? invitation,
  }) async {
    final guestController =
        TextEditingController(text: invitation?.recipientName ?? '');
    final initialLobby = ref.read(lobbyProvider(widget.code)) ?? lobby;
    final availableRoles = _availableRolesForLobby(initialLobby, mysteryCase);
    var selectedRoleId =
        invitation?.assignedRoleId ?? availableRoles.firstOrNull?.id;
    var activeInvitation = invitation;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final latestLobby = ref.read(lobbyProvider(widget.code)) ?? lobby;
            if (activeInvitation != null) {
              activeInvitation = latestLobby.invitations
                      .where((entry) => entry.id == activeInvitation!.id)
                      .firstOrNull ??
                  activeInvitation;
            }
            final latestAvailableRoles =
                _availableRolesForLobby(latestLobby, mysteryCase);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  decoration: MysteryDecor.panel(context, opacity: 0.96),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activeInvitation == null
                                    ? 'Gaeste einladen'
                                    : 'Einladung teilen',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeInvitation == null
                              ? 'Lege einen Gast und eine feste Rolle fest. Danach kannst du den persoenlichen Link direkt verschicken.'
                              : 'Oben findest du den persoenlichen Einladungslink. Darunter stehen die typischen Teiloptionen fuer deine Gaeste bereit.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        if (activeInvitation == null) ...[
                          TextField(
                            controller: guestController,
                            decoration: const InputDecoration(
                              labelText: 'Gastname',
                              prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: selectedRoleId,
                            items: latestAvailableRoles
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role.id,
                                    child: Text(role.name),
                                  ),
                                )
                                .toList(),
                            onChanged: latestAvailableRoles.isEmpty
                                ? null
                                : (value) {
                                    setModalState(() {
                                      selectedRoleId = value;
                                    });
                                  },
                            decoration: const InputDecoration(
                              labelText: 'Charakterrolle',
                              prefixIcon: Icon(Icons.theater_comedy_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: latestAvailableRoles.isEmpty
                                ? null
                                : () {
                                    final roleId = selectedRoleId;
                                    if (roleId == null) {
                                      _showMessage(
                                        'Bitte waehle eine freie Rolle aus.',
                                      );
                                      return;
                                    }

                                    final result = ref
                                        .read(
                                            mysteryControllerProvider.notifier)
                                        .createInvitation(
                                          code: widget.code,
                                          recipientName: guestController.text,
                                          roleId: roleId,
                                        );

                                    if (result.error != null) {
                                      _showMessage(result.error!);
                                      return;
                                    }

                                    setModalState(() {
                                      activeInvitation = result.invitation;
                                    });
                                    _showMessage(
                                      'Einladung erstellt. Der persoenliche Link ist jetzt bereit.',
                                    );
                                  },
                            icon: const Icon(Icons.mark_email_unread_outlined),
                            label: const Text('Einladung erstellen'),
                          ),
                          if (latestAvailableRoles.isEmpty) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Alle Rollen sind bereits vergeben oder reserviert.',
                            ),
                          ],
                        ] else ...[
                          _InvitationReadyPanel(
                            invitation: activeInvitation!,
                            mysteryCase: mysteryCase,
                            inviteLink: _buildInviteLink(
                              latestLobby.code,
                              activeInvitation!.id,
                            ),
                            onCopyLink: () => _copyToClipboard(
                              _buildInviteLink(
                                latestLobby.code,
                                activeInvitation!.id,
                              ),
                            ),
                            onShareTarget: (target) => _shareInvitation(
                              latestLobby,
                              mysteryCase,
                              activeInvitation!,
                              target,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    guestController.dispose();
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage('Link kopiert.');
  }

  Future<void> _shareInvitation(
    LobbySession lobby,
    MysteryCase mysteryCase,
    LobbyInvitation invitation,
    _ShareTarget target,
  ) async {
    final link = _buildInviteLink(lobby.code, invitation.id);
    final message = _buildInviteMessage(mysteryCase, invitation, link);

    switch (target) {
      case _ShareTarget.system:
        await SharePlus.instance.share(ShareParams(text: message));
        return;
      case _ShareTarget.whatsapp:
        await _launchShareUrl(
          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}'),
        );
        return;
      case _ShareTarget.facebook:
        await _launchShareUrl(
          Uri.parse(
            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}&quote=${Uri.encodeComponent("Du bist zu ${mysteryCase.title} eingeladen.")}',
          ),
        );
        return;
      case _ShareTarget.discord:
        await SharePlus.instance.share(ShareParams(text: message));
        _showMessage('Bitte waehle im Teilen-Menue Discord aus.');
        return;
      case _ShareTarget.instagram:
        await SharePlus.instance.share(ShareParams(text: message));
        _showMessage('Bitte waehle im Teilen-Menue Instagram aus.');
        return;
    }
  }

  Future<void> _launchShareUrl(Uri url) async {
    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      _showMessage('Die Freigabe konnte nicht geoeffnet werden.');
    }
  }

  String _buildInviteLink(String lobbyCode, String invitationId) {
    return buildLobbyInviteLink(lobbyCode, invitationId: invitationId);
  }

  String _buildInviteMessage(
    MysteryCase mysteryCase,
    LobbyInvitation invitation,
    String inviteLink,
  ) {
    return 'Du bist zu "${mysteryCase.title}" eingeladen. '
        'Oeffne den persoenlichen Einladungslink und tritt der Lobby bei: '
        '$inviteLink';
  }

  void _runHostAction(String? error) {
    if (error != null && error.isNotEmpty) {
      _showMessage(error);
      return;
    }
    setState(() {
      _now = DateTime.now();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  LobbyPlayer? _playerByName(LobbySession lobby, String alias) {
    for (final player in lobby.players) {
      if (player.name.toLowerCase() == alias.toLowerCase()) {
        return player;
      }
    }
    return null;
  }

  MysteryRole? _roleForPlayer(
    LobbySession lobby,
    MysteryCase mysteryCase,
    LobbyPlayer player,
  ) {
    final roleId = lobby.roleAssignments[player.id];
    if (roleId == null) {
      return null;
    }
    for (final role in mysteryCase.roles) {
      if (role.id == roleId) {
        return role;
      }
    }
    return null;
  }

  List<MysteryRole> _availableRolesForLobby(
    LobbySession lobby,
    MysteryCase mysteryCase,
  ) {
    final reservedRoleIds = {
      ...lobby.roleAssignments.values,
      ...lobby.invitations
          .where((invitation) =>
              invitation.status == LobbyInvitationStatus.pending)
          .map((invitation) => invitation.assignedRoleId),
    };

    return mysteryCase.roles
        .where((role) => !reservedRoleIds.contains(role.id))
        .toList();
  }

  Duration _phaseRemaining(LobbySession lobby, GamePhase phase) {
    if (!lobby.hasStarted || lobby.phaseStartedAt == null) {
      return Duration(minutes: phase.durationMinutes);
    }
    final phaseEnd =
        lobby.phaseStartedAt!.add(Duration(minutes: phase.durationMinutes));
    final remaining = phaseEnd.difference(_now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

class _LobbyHeaderInfo extends StatelessWidget {
  const _LobbyHeaderInfo({
    required this.lobby,
    required this.mysteryCase,
    required this.currentPhase,
    required this.remaining,
    required this.pendingInvitationCount,
  });

  final LobbySession lobby;
  final MysteryCase mysteryCase;
  final GamePhase currentPhase;
  final Duration remaining;
  final int pendingInvitationCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            InfoPill(
              label: 'Code ${lobby.code}',
              icon: Icons.key_rounded,
              accent: Colors.white,
            ),
            InfoPill(
              label: lobby.hasStarted
                  ? 'Phase ${lobby.phaseIndex + 1}'
                  : 'Noch nicht gestartet',
              icon: Icons.timer_outlined,
              accent: Colors.white,
            ),
            InfoPill(
              label: '$pendingInvitationCount offene Einladungen',
              icon: Icons.mark_email_unread_outlined,
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
        const SizedBox(height: 10),
        Text(
          lobby.hasStarted ? currentPhase.title : 'Warten auf Spielbeginn',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppPalette.parchment,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          lobby.hasStarted ? currentPhase.description : mysteryCase.tagline,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppPalette.parchment.withOpacity(0.94),
              ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _LightMetric(
              label: 'Restzeit',
              value:
                  '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
            _LightMetric(label: 'Spieler', value: '${lobby.players.length}'),
            _LightMetric(
              label: 'Hinweise offen',
              value: '${lobby.revealedHintIds.length}',
            ),
          ],
        ),
      ],
    );
  }
}

class _HostControls extends StatelessWidget {
  const _HostControls({
    required this.lobby,
    required this.isHost,
    required this.onStart,
    required this.onAdvance,
    required this.onReshuffle,
    required this.onInviteGuests,
  });

  final LobbySession lobby;
  final bool isHost;
  final VoidCallback onStart;
  final VoidCallback onAdvance;
  final VoidCallback onReshuffle;
  final VoidCallback onInviteGuests;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHost ? 'Host-Steuerung' : 'Spieleransicht',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPalette.parchment,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isHost
                ? 'Starte Phasen, verteile Rollen neu und sende persoenliche Einladungen mit festen Charakterrollen.'
                : 'Du siehst die Live-Session, aber nur der Host kann den Ablauf steuern.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.parchment.withOpacity(0.92),
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: isHost && !lobby.hasStarted ? onStart : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Spiel starten'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isHost && lobby.hasStarted ? onAdvance : null,
            icon: const Icon(Icons.skip_next_rounded),
            label: Text(
              lobby.isCompleted ? 'Fall abgeschlossen' : 'Naechste Phase',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isHost ? onReshuffle : null,
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Rollen neu verteilen'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isHost ? onInviteGuests : null,
            icon: const Icon(Icons.mark_email_unread_outlined),
            label: const Text('Gaeste einladen'),
          ),
        ],
      ),
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  const _WaitingPanel({
    required this.mysteryCase,
    required this.role,
  });

  final MysteryCase mysteryCase;
  final MysteryRole? role;

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
              label: mysteryCase.tagline,
              icon: Icons.local_activity_outlined,
            ),
            if (role != null)
              InfoPill(
                label: 'Deine Rolle: ${role!.name}',
                icon: Icons.person_pin_circle_outlined,
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Bitte warte hier, bis der Spielleiter die Runde startet. Danach geht es mit den vollen Dossiers und dem Live-Ablauf weiter.',
        ),
      ],
    );
  }
}

class _InviteOverviewPanel extends StatelessWidget {
  const _InviteOverviewPanel({
    required this.lobby,
    required this.pendingInvitationCount,
    required this.onCopyLobbyLink,
    required this.onOpenInvitationTool,
  });

  final LobbySession lobby;
  final int pendingInvitationCount;
  final VoidCallback onCopyLobbyLink;
  final VoidCallback onOpenInvitationTool;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        QrImageView(
          data: lobby.inviteLink,
          version: QrVersions.auto,
          size: 170,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 12),
        SelectableText(
          lobby.inviteLink,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onCopyLobbyLink,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Lobby-Link kopieren'),
            ),
            FilledButton.icon(
              onPressed: onOpenInvitationTool,
              icon: const Icon(Icons.mail_lock_outlined),
              label: Text(
                pendingInvitationCount == 0
                    ? 'Gaeste einladen'
                    : 'Einladungstool oeffnen',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LightMetric extends StatelessWidget {
  const _LightMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.parchment,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.parchment.withOpacity(0.86),
                ),
          ),
        ],
      ),
    );
  }
}

class _InvitationReadyPanel extends StatelessWidget {
  const _InvitationReadyPanel({
    required this.invitation,
    required this.mysteryCase,
    required this.inviteLink,
    required this.onCopyLink,
    required this.onShareTarget,
  });

  final LobbyInvitation invitation;
  final MysteryCase mysteryCase;
  final String inviteLink;
  final VoidCallback onCopyLink;
  final ValueChanged<_ShareTarget> onShareTarget;

  @override
  Widget build(BuildContext context) {
    final role = mysteryCase.roles
        .where((entry) => entry.id == invitation.assignedRoleId)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Einladungslink senden',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  InfoPill(
                    label: invitation.recipientName,
                    icon: Icons.person_outline_rounded,
                  ),
                  if (role != null)
                    InfoPill(
                      label: role.name,
                      icon: Icons.theater_comedy_outlined,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(inviteLink),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onCopyLink,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Link kopieren'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Teilen ueber',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _ShareTarget.values
              .map(
                (target) => _ShareActionTile(
                  target: target,
                  onTap: () => onShareTarget(target),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.target,
    required this.onTap,
  });

  final _ShareTarget target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(target.icon, color: AppPalette.gold),
            const SizedBox(height: 12),
            Text(
              target.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              target.caption,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDossier extends StatelessWidget {
  const _RoleDossier({required this.role});

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
            InfoPill(label: role.name, icon: Icons.person_pin_rounded),
            InfoPill(
              label: role.outfit.palette.join(' / '),
              icon: Icons.palette_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DossierLine(title: 'Persoenlichkeit', text: role.persona),
        _DossierLine(title: 'Geheimnis', text: role.secret),
        _DossierLine(title: 'Motiv', text: role.motive),
        _DossierLine(title: 'Beziehungen', text: role.relationships),
        _DossierLine(title: 'Ziel', text: role.goal),
        _DossierLine(title: 'Alibi', text: role.alibi),
        _DossierLine(title: 'Verdachtsmoment', text: role.suspicion),
        const SizedBox(height: 8),
        Text(
          'Versteckte Hinweise',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...role.hiddenClues.map(
          (clue) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.circle, size: 8, color: AppPalette.gold),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(clue)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kostuemempfehlung',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text('Neutral: ${role.outfit.neutral}'),
        const SizedBox(height: 4),
        Text('Accessoires: ${role.outfit.accessories.join(', ')}'),
        const SizedBox(height: 4),
        Text('Make-up: ${role.outfit.makeup}'),
        const SizedBox(height: 4),
        Text('Frisur: ${role.outfit.hairstyle}'),
      ],
    );
  }
}

class _DossierLine extends StatelessWidget {
  const _DossierLine({
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

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.lobby,
    required this.chatController,
    required this.onSend,
  });

  final LobbySession lobby;
  final TextEditingController chatController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.03),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lobby.messages.length,
            itemBuilder: (context, index) {
              final message = lobby.messages[index];
              final isSystem = message.type == ChatMessageType.system;
              return Align(
                alignment:
                    isSystem ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: isSystem
                        ? AppPalette.gold.withOpacity(0.12)
                        : AppPalette.midnight.withOpacity(0.28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.sender,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(message.body),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: chatController,
                decoration: const InputDecoration(
                  labelText: 'Nachricht an die Lobby',
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onSend,
              child: const Text('Senden'),
            ),
          ],
        ),
      ],
    );
  }
}

class _RosterPanel extends StatelessWidget {
  const _RosterPanel({
    required this.lobby,
    required this.mysteryCase,
    required this.isHost,
    required this.onKick,
    required this.onShareInvitation,
    required this.onRevokeInvitation,
  });

  final LobbySession lobby;
  final MysteryCase mysteryCase;
  final bool isHost;
  final ValueChanged<String> onKick;
  final ValueChanged<LobbyInvitation> onShareInvitation;
  final ValueChanged<String> onRevokeInvitation;

  @override
  Widget build(BuildContext context) {
    final activeInvitations = lobby.invitations
        .where(
            (invitation) => invitation.status != LobbyInvitationStatus.revoked)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...lobby.players.map((player) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.03),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppPalette.gold.withOpacity(0.18),
                  child: Text(
                    player.name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: AppPalette.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(player.isHost ? 'Host' : 'Ermittler'),
                    ],
                  ),
                ),
                if (player.isHost)
                  const InfoPill(
                      label: 'Host', icon: Icons.shield_moon_outlined),
                if (!player.isHost && isHost)
                  IconButton(
                    onPressed: () => onKick(player.id),
                    icon: const Icon(Icons.person_remove_alt_1_rounded),
                    tooltip: 'Spieler entfernen',
                  ),
              ],
            ),
          );
        }),
        if (activeInvitations.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Einladungen',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...activeInvitations.map(
            (invitation) {
              final role = mysteryCase.roles
                  .where((entry) => entry.id == invitation.assignedRoleId)
                  .firstOrNull;
              final isPending =
                  invitation.status == LobbyInvitationStatus.pending;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.03),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invitation.recipientName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role == null
                                    ? 'Rolle wird vorbereitet'
                                    : 'Reserviert fuer ${role.name}',
                              ),
                            ],
                          ),
                        ),
                        InfoPill(
                          label: isPending ? 'Offen' : 'Angenommen',
                          icon: isPending
                              ? Icons.mark_email_unread_outlined
                              : Icons.check_circle_outline_rounded,
                        ),
                      ],
                    ),
                    if (isHost) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => onShareInvitation(invitation),
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Teilen'),
                          ),
                          if (isPending)
                            OutlinedButton.icon(
                              onPressed: () =>
                                  onRevokeInvitation(invitation.id),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Zurueckziehen'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _HintsPanel extends StatelessWidget {
  const _HintsPanel({
    required this.lobby,
    required this.mysteryCase,
    required this.currentPhase,
    required this.isHost,
    required this.onReveal,
  });

  final LobbySession lobby;
  final MysteryCase mysteryCase;
  final GamePhase currentPhase;
  final bool isHost;
  final ValueChanged<String> onReveal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            InfoPill(
              label: currentPhase.title,
              icon: Icons.movie_filter_outlined,
            ),
            InfoPill(
              label: currentPhase.musicCue,
              icon: Icons.music_note_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...mysteryCase.hints.map((hint) {
          final revealed = lobby.revealedHintIds.contains(hint.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: revealed
                  ? AppPalette.gold.withOpacity(0.12)
                  : Colors.white.withOpacity(0.03),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hint.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text('Vorgesehen ab Phase ${hint.unlockPhase + 1}'),
                        ],
                      ),
                    ),
                    if (revealed)
                      const InfoPill(
                        label: 'Freigegeben',
                        icon: Icons.mark_email_read_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  revealed
                      ? hint.detail
                      : 'Dieser Hinweis ist noch versiegelt.',
                ),
                if (!revealed && isHost) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => onReveal(hint.id),
                    icon: const Icon(Icons.drafts_rounded),
                    label: const Text('Hinweis freigeben'),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

enum _ShareTarget {
  system(
    label: 'Mehr',
    caption: 'System-Menue',
    icon: Icons.ios_share_rounded,
  ),
  whatsapp(
    label: 'WhatsApp',
    caption: 'Direkt oeffnen',
    icon: Icons.chat_rounded,
  ),
  instagram(
    label: 'Instagram',
    caption: 'Im Teilen-Menue',
    icon: Icons.camera_alt_outlined,
  ),
  discord(
    label: 'Discord',
    caption: 'Im Teilen-Menue',
    icon: Icons.forum_outlined,
  ),
  facebook(
    label: 'Facebook',
    caption: 'Direkt oeffnen',
    icon: Icons.thumb_up_alt_outlined,
  );

  const _ShareTarget({
    required this.label,
    required this.caption,
    required this.icon,
  });

  final String label;
  final String caption;
  final IconData icon;
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}

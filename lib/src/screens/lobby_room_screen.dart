import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_strings.dart';
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
    final strings = ref.watch(appStringsProvider);
    final lobby = ref.watch(lobbyProvider(widget.code));
    if (lobby == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            strings.tr(
              de: 'Die Lobby ${widget.code} wurde nicht gefunden.',
              en: 'Lobby ${widget.code} could not be found.',
              fr: 'La lobby ${widget.code} est introuvable.',
              es: 'No se encontro el lobby ${widget.code}.',
            ),
          ),
        ),
      );
    }

    final mysteryCase = ref.watch(mysteryCaseProvider(lobby.caseId));
    if (mysteryCase == null) {
      return Center(
        child: Text(
          strings.tr(
            de: 'Der zugehoerige Fall ist nicht verfuegbar.',
            en: 'The linked case is not available.',
            fr: 'L affaire liee n est pas disponible.',
            es: 'El caso vinculado no esta disponible.',
          ),
        ),
      );
    }

    final state = ref.watch(mysteryControllerProvider);
    final viewer = _playerByName(lobby, state.localAlias);
    final rejoinPlayer = _rejoinPlayerByName(lobby, state.localAlias);
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
                  onStart: () {
                    final error = ref
                        .read(mysteryControllerProvider.notifier)
                        .startGame(widget.code);
                    if (error != null) {
                      _showMessage(error);
                    } else {
                      context.go('/lobbies/room/${widget.code}/play');
                    }
                  },
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
              if (viewer == null && rejoinPlayer != null)
                SectionPanel(
                  title: strings.tr(
                    de: 'Wiederbeitritt',
                    en: 'Rejoin',
                    fr: 'Rejoindre a nouveau',
                    es: 'Volver a entrar',
                  ),
                  child: _RejoinLobbyPanel(
                    player: rejoinPlayer,
                    mysteryCase: mysteryCase,
                    onRejoin: () => _rejoinLobby(rejoinPlayer.name),
                  ),
                ),
              if (viewer != null && !isHost && !lobby.hasStarted)
                SectionPanel(
                  title: strings.tr(
                    de: 'Warteraum',
                    en: 'Waiting room',
                    fr: 'Salle d attente',
                    es: 'Sala de espera',
                  ),
                  child: _WaitingPanel(
                    mysteryCase: mysteryCase,
                    role: currentRole,
                  ),
                ),
              if (currentRole != null)
                SectionPanel(
                  title: strings.tr(
                    de: 'Deine geheime Rolle',
                    en: 'Your secret role',
                    fr: 'Ton role secret',
                    es: 'Tu rol secreto',
                  ),
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: () => context.go('/lobbies/room/${widget.code}/role/${currentRole.id}'),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(
                        strings.tr(
                          de: 'Rollenakte oeffnen',
                          en: 'Open role dossier',
                          fr: 'Ouvrir le dossier du role',
                          es: 'Abrir dossier del rol',
                        ),
                      ),
                    ),
                  ),
                ),
              if (viewer != null)
                SectionPanel(
                  title: strings.tr(
                    de: 'Lobby',
                    en: 'Lobby',
                    fr: 'Lobby',
                    es: 'Lobby',
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _confirmLeaveLobby(viewer),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        strings.tr(
                          de: 'Lobby verlassen',
                          en: 'Leave lobby',
                          fr: 'Quitter la lobby',
                          es: 'Salir del lobby',
                        ),
                      ),
                    ),
                  ),
                ),
              if (viewer != null)
                SectionPanel(
                  title: strings.tr(
                    de: 'Chat',
                    en: 'Chat',
                    fr: 'Chat',
                    es: 'Chat',
                  ),
                  child: _ChatPanel(
                    lobby: lobby,
                    chatController: _chatController,
                    onSend: _sendChat,
                  ),
                )
              else
                SectionPanel(
                  title: strings.tr(
                    de: 'Chat',
                    en: 'Chat',
                    fr: 'Chat',
                    es: 'Chat',
                  ),
                  child: Text(
                    strings.tr(
                      de: 'Der Lobbychat wird wieder freigeschaltet, sobald du der Runde erneut beigetreten bist.',
                      en: 'Lobby chat will unlock again as soon as you rejoin the round.',
                      fr: 'Le chat de la lobby sera de nouveau active des que tu auras rejoint la partie.',
                      es: 'El chat del lobby volvera a activarse en cuanto entres otra vez en la partida.',
                    ),
                  ),
                ),
            ],
            secondary: [
              SectionPanel(
                  title: strings.tr(
                    de: 'Spielerliste & Einladungen',
                    en: 'Players & invitations',
                    fr: 'Joueurs et invitations',
                    es: 'Jugadores e invitaciones',
                  ),
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
                  title: strings.tr(
                    de: 'Hinweise & Phasen',
                    en: 'Clues & phases',
                    fr: 'Indices et phases',
                    es: 'Pistas y fases',
                  ),
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
                title: strings.tr(
                  de: 'Gastzugang & QR',
                  en: 'Guest access & QR',
                  fr: 'Acces invite et QR',
                  es: 'Acceso para invitados y QR',
                ),
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

  Future<void> _confirmLeaveLobby(LobbyPlayer viewer) async {
    final strings = ref.read(appStringsProvider);
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            strings.tr(
              de: 'Lobby wirklich verlassen?',
              en: 'Leave lobby now?',
              fr: 'Quitter vraiment la lobby ?',
              es: 'Salir realmente del lobby?',
            ),
          ),
          content: Text(
            strings.tr(
              de: 'Deine Rolle bleibt noch 24 Stunden fuer dich reserviert. In dieser Zeit kannst du mit demselben Namen wieder beitreten.',
              en: 'Your role stays reserved for you for 24 hours. During that time you can rejoin with the same name.',
              fr: 'Ton role reste reserve pour toi pendant 24 heures. Pendant ce temps, tu peux revenir avec le meme nom.',
              es: 'Tu rol seguira reservado durante 24 horas. Durante ese tiempo podras volver a entrar con el mismo nombre.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                strings.tr(
                  de: 'Bleiben',
                  en: 'Stay',
                  fr: 'Rester',
                  es: 'Quedarse',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                strings.tr(
                  de: 'Lobby verlassen',
                  en: 'Leave lobby',
                  fr: 'Quitter la lobby',
                  es: 'Salir del lobby',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true || !mounted) {
      return;
    }

    final error = ref.read(mysteryControllerProvider.notifier).leaveLobby(
          code: widget.code,
          playerId: viewer.id,
        );
    if (error != null) {
      _showMessage(error);
      return;
    }

    context.go('/lobbies');
    _showMessage(
      strings.tr(
        de: 'Lobby verlassen. Wiederbeitritt mit demselben Namen ist 24 Stunden moeglich.',
        en: 'Lobby left. Rejoining with the same name is possible for 24 hours.',
        fr: 'Lobby quittee. Rejoindre avec le meme nom reste possible pendant 24 heures.',
        es: 'Has salido del lobby. Podras volver a entrar con el mismo nombre durante 24 horas.',
      ),
    );
  }

  void _rejoinLobby(String alias) {
    final error = ref.read(mysteryControllerProvider.notifier).rejoinLobby(
          code: widget.code,
          alias: alias,
        );
    if (error != null) {
      _showMessage(error);
    }
  }

  Future<void> _openInviteSheet(
    LobbySession lobby,
    MysteryCase mysteryCase, {
    LobbyInvitation? invitation,
  }) async {
    final strings = ref.read(appStringsProvider);
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
                                    ? strings.tr(
                                        de: 'Gaeste einladen',
                                        en: 'Invite guests',
                                        fr: 'Inviter des guests',
                                        es: 'Invitar a invitados',
                                      )
                                    : strings.tr(
                                        de: 'Einladung teilen',
                                        en: 'Share invitation',
                                        fr: 'Partager l invitation',
                                        es: 'Compartir invitacion',
                                      ),
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
                              ? strings.tr(
                                  de: 'Lege einen Gast und eine feste Rolle fest. Danach kannst du den persoenlichen Link direkt verschicken.',
                                  en: 'Choose a guest and a fixed role. After that you can send the personal link directly.',
                                  fr: 'Definis un invite et un role fixe. Ensuite tu peux envoyer directement le lien personnel.',
                                  es: 'Define un invitado y un rol fijo. Despues podras enviar directamente el enlace personal.',
                                )
                              : strings.tr(
                                  de: 'Oben findest du den persoenlichen Einladungslink. Darunter stehen die typischen Teiloptionen fuer deine Gaeste bereit.',
                                  en: 'At the top you will find the personal invitation link. Below are the common sharing options for your guests.',
                                  fr: 'En haut tu trouveras le lien d invitation personnel. En dessous se trouvent les options de partage habituelles pour tes invites.',
                                  es: 'Arriba encontraras el enlace de invitacion personal. Debajo tienes las opciones habituales para compartir con tus invitados.',
                                ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        if (activeInvitation == null) ...[
                          TextField(
                            controller: guestController,
                            decoration: InputDecoration(
                              labelText: strings.tr(
                                de: 'Gastname',
                                en: 'Guest name',
                                fr: 'Nom de l invite',
                                es: 'Nombre del invitado',
                              ),
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
                            decoration: InputDecoration(
                              labelText: strings.tr(
                                de: 'Charakterrolle',
                                en: 'Character role',
                                fr: 'Role du personnage',
                                es: 'Rol del personaje',
                              ),
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
                                        strings.tr(
                                          de: 'Bitte waehle eine freie Rolle aus.',
                                          en: 'Please choose an available role.',
                                          fr: 'Merci de choisir un role libre.',
                                          es: 'Elige un rol disponible.',
                                        ),
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
                                      strings.tr(
                                        de: 'Einladung erstellt. Der persoenliche Link ist jetzt bereit.',
                                        en: 'Invitation created. The personal link is now ready.',
                                        fr: 'Invitation creee. Le lien personnel est maintenant pret.',
                                        es: 'Invitacion creada. El enlace personal ya esta listo.',
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.mark_email_unread_outlined),
                            label: Text(
                              strings.tr(
                                de: 'Einladung erstellen',
                                en: 'Create invitation',
                                fr: 'Creer invitation',
                                es: 'Crear invitacion',
                              ),
                            ),
                          ),
                          if (latestAvailableRoles.isEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              strings.tr(
                                de: 'Alle Rollen sind bereits vergeben oder reserviert.',
                                en: 'All roles are already assigned or reserved.',
                                fr: 'Tous les roles sont deja attribues ou reserves.',
                                es: 'Todos los roles ya estan asignados o reservados.',
                              ),
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
    final strings = ref.read(appStringsProvider);
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage(
      strings.tr(
        de: 'Link kopiert.',
        en: 'Link copied.',
        fr: 'Lien copie.',
        es: 'Enlace copiado.',
      ),
    );
  }

  Future<void> _shareInvitation(
    LobbySession lobby,
    MysteryCase mysteryCase,
    LobbyInvitation invitation,
    _ShareTarget target,
  ) async {
    final strings = ref.read(appStringsProvider);
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
            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}&quote=${Uri.encodeComponent(strings.tr(de: "Du bist zu ${mysteryCase.title} eingeladen.", en: "You are invited to ${mysteryCase.title}.", fr: "Tu es invite a ${mysteryCase.title}.", es: "Estas invitado a ${mysteryCase.title}."))}',
          ),
        );
        return;
      case _ShareTarget.discord:
        await SharePlus.instance.share(ShareParams(text: message));
        _showMessage(
          strings.tr(
            de: 'Bitte waehle im Teilen-Menue Discord aus.',
            en: 'Please choose Discord in the share menu.',
            fr: 'Merci de choisir Discord dans le menu de partage.',
            es: 'Elige Discord en el menu de compartir.',
          ),
        );
        return;
      case _ShareTarget.instagram:
        await SharePlus.instance.share(ShareParams(text: message));
        _showMessage(
          strings.tr(
            de: 'Bitte waehle im Teilen-Menue Instagram aus.',
            en: 'Please choose Instagram in the share menu.',
            fr: 'Merci de choisir Instagram dans le menu de partage.',
            es: 'Elige Instagram en el menu de compartir.',
          ),
        );
        return;
    }
  }

  Future<void> _launchShareUrl(Uri url) async {
    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      _showMessage(
        ref.read(appStringsProvider).tr(
              de: 'Die Freigabe konnte nicht geoeffnet werden.',
              en: 'Sharing could not be opened.',
              fr: 'Le partage na pas pu etre ouvert.',
              es: 'No se pudo abrir la opcion de compartir.',
            ),
      );
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
    final strings = ref.read(appStringsProvider);
    return strings.tr(
      de: 'Du bist zu "${mysteryCase.title}" eingeladen. Oeffne den persoenlichen Einladungslink und tritt der Lobby bei: $inviteLink',
      en: 'You are invited to "${mysteryCase.title}". Open the personal invitation link and join the lobby: $inviteLink',
      fr: 'Tu es invite a "${mysteryCase.title}". Ouvre le lien dinvitation personnel et rejoins la lobby : $inviteLink',
      es: 'Estas invitado a "${mysteryCase.title}". Abre el enlace personal de invitacion y entra al lobby: $inviteLink',
    );
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
      if (player.isOnline && player.name.toLowerCase() == alias.toLowerCase()) {
        return player;
      }
    }
    return null;
  }

  LobbyPlayer? _rejoinPlayerByName(LobbySession lobby, String alias) {
    for (final player in lobby.players) {
      if (!player.isOnline &&
          player.canRejoin &&
          player.name.toLowerCase() == alias.toLowerCase()) {
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
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            InfoPill(
              label: strings.tr(
                de: 'Code ${lobby.code}',
                en: 'Code ${lobby.code}',
                fr: 'Code ${lobby.code}',
                es: 'Codigo ${lobby.code}',
              ),
              icon: Icons.key_rounded,
              accent: Colors.white,
            ),
            InfoPill(
              label: lobby.hasStarted
                  ? strings.tr(
                      de: 'Phase ${lobby.phaseIndex + 1}',
                      en: 'Phase ${lobby.phaseIndex + 1}',
                      fr: 'Phase ${lobby.phaseIndex + 1}',
                      es: 'Fase ${lobby.phaseIndex + 1}',
                    )
                  : strings.tr(
                      de: 'Noch nicht gestartet',
                      en: 'Not started yet',
                      fr: 'Pas encore commence',
                      es: 'Todavia no ha empezado',
                    ),
              icon: Icons.timer_outlined,
              accent: Colors.white,
            ),
            InfoPill(
              label: strings.tr(
                de: '$pendingInvitationCount offene Einladungen',
                en: '$pendingInvitationCount open invitations',
                fr: '$pendingInvitationCount invitations ouvertes',
                es: '$pendingInvitationCount invitaciones abiertas',
              ),
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
          lobby.hasStarted
              ? currentPhase.title
              : strings.tr(
                  de: 'Warten auf Spielbeginn',
                  en: 'Waiting for game start',
                  fr: 'En attente du debut de partie',
                  es: 'Esperando el inicio de la partida',
                ),
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
              label: strings.tr(
                de: 'Restzeit',
                en: 'Time left',
                fr: 'Temps restant',
                es: 'Tiempo restante',
              ),
              value:
                  '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
            _LightMetric(
              label: strings.tr(
                de: 'Spieler',
                en: 'Players',
                fr: 'Joueurs',
                es: 'Jugadores',
              ),
              value: '${lobby.players.length}',
            ),
            _LightMetric(
              label: strings.tr(
                de: 'Hinweise offen',
                en: 'Clues open',
                fr: 'Indices ouverts',
                es: 'Pistas abiertas',
              ),
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
    required this.onReshuffle,
    required this.onInviteGuests,
  });

  final LobbySession lobby;
  final bool isHost;
  final VoidCallback onStart;
  final VoidCallback onReshuffle;
  final VoidCallback onInviteGuests;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
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
            isHost
                ? strings.tr(
                    de: 'Host-Steuerung',
                    en: 'Host controls',
                    fr: 'Controle de l hote',
                    es: 'Controles del host',
                  )
                : strings.tr(
                    de: 'Spieleransicht',
                    en: 'Player view',
                    fr: 'Vue joueur',
                    es: 'Vista de jugador',
                  ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPalette.parchment,
                ),
          ),
          const SizedBox(height: 18),
          if (!lobby.hasStarted)
            FilledButton.icon(
              onPressed: isHost ? onStart : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                strings.tr(
                  de: 'Spiel starten',
                  en: 'Start game',
                  fr: 'Commencer la partie',
                  es: 'Iniciar partida',
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: () => context.go('/lobbies/room/${lobby.code}/play'),
              icon: const Icon(Icons.dashboard_rounded),
              label: Text(
                strings.tr(
                  de: 'Zum Spielbrett',
                  en: 'Open game board',
                  fr: 'Ouvrir le plateau',
                  es: 'Abrir tablero',
                ),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isHost && !lobby.hasStarted ? onReshuffle : null,
            icon: const Icon(Icons.shuffle_rounded),
            label: Text(
              strings.tr(
                de: 'Rollen neu verteilen',
                en: 'Reshuffle roles',
                fr: 'Redistribuer les roles',
                es: 'Repartir roles',
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isHost ? onInviteGuests : null,
            icon: const Icon(Icons.mark_email_unread_outlined),
            label: Text(
              strings.tr(
                de: 'Gaeste einladen',
                en: 'Invite guests',
                fr: 'Inviter des guests',
                es: 'Invitar a invitados',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejoinLobbyPanel extends StatelessWidget {
  const _RejoinLobbyPanel({
    required this.player,
    required this.mysteryCase,
    required this.onRejoin,
  });

  final LobbyPlayer player;
  final MysteryCase mysteryCase;
  final VoidCallback onRejoin;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
    final deadline = player.rejoinAvailableUntil;
    final deadlineLabel = deadline == null
        ? strings.tr(
            de: 'fuer kurze Zeit',
            en: 'for a short time',
            fr: 'pour un court moment',
            es: 'por poco tiempo',
          )
        : '${deadline.day.toString().padLeft(2, '0')}.${deadline.month.toString().padLeft(2, '0')} um ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.tr(
            de: 'Dein Platz in ${mysteryCase.title} ist noch bis $deadlineLabel fuer dich reserviert.',
            en: 'Your spot in ${mysteryCase.title} is reserved for you until $deadlineLabel.',
            fr: 'Ta place dans ${mysteryCase.title} est reservee pour toi jusqu a $deadlineLabel.',
            es: 'Tu plaza en ${mysteryCase.title} esta reservada para ti hasta $deadlineLabel.',
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onRejoin,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            strings.tr(
              de: 'Wieder beitreten',
              en: 'Rejoin',
              fr: 'Rejoindre',
              es: 'Volver a entrar',
            ),
          ),
        ),
      ],
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
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
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
                label: strings.tr(
                  de: 'Deine Rolle: ${role!.name}',
                  en: 'Your role: ${role!.name}',
                  fr: 'Ton role : ${role!.name}',
                  es: 'Tu rol: ${role!.name}',
                ),
                icon: Icons.person_pin_circle_outlined,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          strings.tr(
            de: 'Bitte warte hier, bis der Spielleiter die Runde startet. Danach geht es mit den vollen Dossiers und dem Live-Ablauf weiter.',
            en: 'Please wait here until the host starts the round. After that, the full dossiers and live flow will continue.',
            fr: 'Merci d attendre ici jusqu a ce que l hote lance la partie. Ensuite, les dossiers complets et le deroulement en direct continueront.',
            es: 'Espera aqui hasta que el host inicie la ronda. Despues seguiran los dossiers completos y el flujo en vivo.',
          ),
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
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
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
              label: Text(
                strings.tr(
                  de: 'Lobby-Link kopieren',
                  en: 'Copy lobby link',
                  fr: 'Copier le lien de la lobby',
                  es: 'Copiar enlace del lobby',
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onOpenInvitationTool,
              icon: const Icon(Icons.mail_lock_outlined),
              label: Text(
                pendingInvitationCount == 0
                    ? strings.tr(
                        de: 'Gaeste einladen',
                        en: 'Invite guests',
                        fr: 'Inviter des guests',
                        es: 'Invitar a invitados',
                      )
                    : strings.tr(
                        de: 'Einladungstool oeffnen',
                        en: 'Open invitation tool',
                        fr: 'Ouvrir l outil d invitation',
                        es: 'Abrir herramienta de invitacion',
                      ),
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
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
    final role = mysteryCase.roles
        .where((entry) => entry.id == invitation.assignedRoleId)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.tr(
            de: 'Einladungslink senden',
            en: 'Send invitation link',
            fr: 'Envoyer le lien d invitation',
            es: 'Enviar enlace de invitacion',
          ),
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
                label: Text(
                  strings.tr(
                    de: 'Link kopieren',
                    en: 'Copy link',
                    fr: 'Copier le lien',
                    es: 'Copiar enlace',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          strings.tr(
            de: 'Teilen ueber',
            en: 'Share via',
            fr: 'Partager via',
            es: 'Compartir por',
          ),
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
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
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
              target.label(strings),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              target.caption(strings),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
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
                decoration: InputDecoration(
                  labelText: strings.tr(
                    de: 'Nachricht an die Lobby',
                    en: 'Message to the lobby',
                    fr: 'Message a la lobby',
                    es: 'Mensaje al lobby',
                  ),
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onSend,
              child: Text(
                strings.tr(
                  de: 'Senden',
                  en: 'Send',
                  fr: 'Envoyer',
                  es: 'Enviar',
                ),
              ),
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
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
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
                      Text(
                        player.isHost
                            ? 'Host'
                            : strings.tr(
                                de: 'Ermittler',
                                en: 'Investigator',
                                fr: 'Enqueteur',
                                es: 'Investigador',
                              ),
                      ),
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
                    tooltip: strings.tr(
                      de: 'Spieler entfernen',
                      en: 'Remove player',
                      fr: 'Retirer le joueur',
                      es: 'Quitar jugador',
                    ),
                  ),
              ],
            ),
          );
        }),
        if (activeInvitations.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            strings.tr(
              de: 'Einladungen',
              en: 'Invitations',
              fr: 'Invitations',
              es: 'Invitaciones',
            ),
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
                                    ? strings.tr(
                                        de: 'Rolle wird vorbereitet',
                                        en: 'Role is being prepared',
                                        fr: 'Le role est en preparation',
                                        es: 'El rol se esta preparando',
                                      )
                                    : strings.tr(
                                        de: 'Reserviert fuer ${role.name}',
                                        en: 'Reserved for ${role.name}',
                                        fr: 'Reserve pour ${role.name}',
                                        es: 'Reservado para ${role.name}',
                                      ),
                              ),
                            ],
                          ),
                        ),
                        InfoPill(
                          label: isPending
                              ? strings.tr(
                                  de: 'Offen',
                                  en: 'Open',
                                  fr: 'Ouverte',
                                  es: 'Abierta',
                                )
                              : strings.tr(
                                  de: 'Angenommen',
                                  en: 'Accepted',
                                  fr: 'Acceptee',
                                  es: 'Aceptada',
                                ),
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
                            label: Text(
                              strings.tr(
                                de: 'Teilen',
                                en: 'Share',
                                fr: 'Partager',
                                es: 'Compartir',
                              ),
                            ),
                          ),
                          if (isPending)
                            OutlinedButton.icon(
                              onPressed: () =>
                                  onRevokeInvitation(invitation.id),
                              icon: const Icon(Icons.close_rounded),
                              label: Text(
                                strings.tr(
                                  de: 'Zurueckziehen',
                                  en: 'Revoke',
                                  fr: 'Retirer',
                                  es: 'Revocar',
                                ),
                              ),
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
    final strings = ProviderScope.containerOf(context).read(appStringsProvider);
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
                          Text(
                            strings.tr(
                              de: 'Vorgesehen ab Phase ${hint.unlockPhase + 1}',
                              en: 'Scheduled from phase ${hint.unlockPhase + 1}',
                              fr: 'Prevu a partir de la phase ${hint.unlockPhase + 1}',
                              es: 'Previsto desde la fase ${hint.unlockPhase + 1}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (revealed)
                      InfoPill(
                        label: strings.tr(
                          de: 'Freigegeben',
                          en: 'Released',
                          fr: 'Debloque',
                          es: 'Liberada',
                        ),
                        icon: Icons.mark_email_read_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  revealed
                      ? hint.detail
                      : strings.tr(
                          de: 'Dieser Hinweis ist noch versiegelt.',
                          en: 'This clue is still sealed.',
                          fr: 'Cet indice est encore scelle.',
                          es: 'Esta pista sigue sellada.',
                        ),
                ),
                if (!revealed && isHost) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => onReveal(hint.id),
                    icon: const Icon(Icons.drafts_rounded),
                    label: Text(
                      strings.tr(
                        de: 'Hinweis freigeben',
                        en: 'Reveal clue',
                        fr: 'Reveler l indice',
                        es: 'Revelar pista',
                      ),
                    ),
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
    icon: Icons.ios_share_rounded,
  ),
  whatsapp(
    icon: Icons.chat_rounded,
  ),
  instagram(
    icon: Icons.camera_alt_outlined,
  ),
  discord(
    icon: Icons.forum_outlined,
  ),
  facebook(
    icon: Icons.thumb_up_alt_outlined,
  );

  const _ShareTarget({
    required this.icon,
  });

  final IconData icon;

  String label(AppStrings strings) {
    switch (this) {
      case _ShareTarget.system:
        return strings.tr(
          de: 'Mehr',
          en: 'More',
          fr: 'Plus',
          es: 'Mas',
        );
      case _ShareTarget.whatsapp:
        return 'WhatsApp';
      case _ShareTarget.instagram:
        return 'Instagram';
      case _ShareTarget.discord:
        return 'Discord';
      case _ShareTarget.facebook:
        return 'Facebook';
    }
  }

  String caption(AppStrings strings) {
    switch (this) {
      case _ShareTarget.system:
        return strings.tr(
          de: 'System-Menue',
          en: 'System menu',
          fr: 'Menu systeme',
          es: 'Menu del sistema',
        );
      case _ShareTarget.whatsapp:
      case _ShareTarget.facebook:
        return strings.tr(
          de: 'Direkt oeffnen',
          en: 'Open directly',
          fr: 'Ouvrir directement',
          es: 'Abrir directamente',
        );
      case _ShareTarget.instagram:
      case _ShareTarget.discord:
        return strings.tr(
          de: 'Im Teilen-Menue',
          en: 'Inside the share menu',
          fr: 'Dans le menu de partage',
          es: 'En el menu de compartir',
        );
    }
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


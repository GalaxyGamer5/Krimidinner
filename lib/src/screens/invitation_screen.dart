import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
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
    final strings = ref.watch(appStringsProvider);
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
          title: strings.tr(
            de: 'Einladung nicht gefunden',
            en: 'Invitation not found',
            fr: 'Invitation introuvable',
            es: 'Invitacion no encontrada',
          ),
          subtitle: strings.tr(
            de: 'Der Link ist abgelaufen, wurde zurueckgezogen oder die Lobby ist lokal nicht verfuegbar.',
            en: 'The link expired, was revoked or the lobby is not available locally.',
            fr: 'Le lien a expire, a ete revoque ou la lobby nest pas disponible localement.',
            es: 'El enlace ha caducado, fue revocado o el lobby no esta disponible localmente.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tr(
                  de: 'Oeffne die Lobbyzentrale und pruefe den Code oder bitte den Spielleiter um einen neuen Link.',
                  en: 'Open the lobby hub, check the code or ask the host for a new link.',
                  fr: 'Ouvre le centre des lobbies, verifie le code ou demande un nouveau lien au maitre du jeu.',
                  es: 'Abre el centro de lobbies, revisa el codigo o pide al anfitrion un enlace nuevo.',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go(
                  widget.lobbyCode.isEmpty
                      ? '/lobbies'
                      : '/lobbies?invite=${widget.lobbyCode}',
                ),
                icon: const Icon(Icons.groups_rounded),
                label: Text(
                  strings.tr(
                    de: 'Zur Lobbyzentrale',
                    en: 'Back to lobby hub',
                    fr: 'Retour au centre des lobbies',
                    es: 'Volver al centro de lobbies',
                  ),
                ),
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
    final canRejoin = acceptedPlayer != null && acceptedPlayer.canRejoin;
    final showWaitingRoom =
        invitation.status == LobbyInvitationStatus.accepted &&
            acceptedByCurrentAlias &&
            !canRejoin;
    final showRejoinPanel =
        invitation.status == LobbyInvitationStatus.accepted &&
            acceptedByCurrentAlias &&
            canRejoin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InvitationHero(
            strings: strings,
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
                  title: strings.tr(
                    de: 'Deine Rolle',
                    en: 'Your role',
                    fr: 'Ton role',
                    es: 'Tu rol',
                  ),
                  subtitle: strings.tr(
                    de: 'Der Spielleiter hat diese Figur fuer dich vorbereitet.',
                    en: 'The host prepared this character for you.',
                    fr: 'Le maitre du jeu a prepare ce personnage pour toi.',
                    es: 'El anfitrion ha preparado este personaje para ti.',
                  ),
                  trailing: assignedRole == null
                      ? null
                      : InfoPill(
                          label: assignedRole.name,
                          icon: Icons.person_pin_circle_rounded,
                        ),
                  child: assignedRole == null
                      ? Text(
                          strings.tr(
                            de: 'Deine Rolle wird gerade vorbereitet.',
                            en: 'Your role is still being prepared.',
                            fr: 'Ton role est encore en preparation.',
                            es: 'Tu rol se esta preparando todavia.',
                          ),
                        )
                      : _RolePreview(strings: strings, role: assignedRole),
                ),
                SectionPanel(
                  title: strings.tr(
                    de: 'Warteraum',
                    en: 'Waiting room',
                    fr: 'Salle dattente',
                    es: 'Sala de espera',
                  ),
                  subtitle: lobby.hasStarted
                      ? strings.tr(
                          de: 'Die Runde wurde gestartet. Du kannst jetzt in den Lobbyraum wechseln.',
                          en: 'The round has started. You can now enter the lobby room.',
                          fr: 'La partie a commence. Tu peux maintenant entrer dans la salle de lobby.',
                          es: 'La ronda ha empezado. Ahora puedes entrar en la sala del lobby.',
                        )
                      : strings.tr(
                          de: 'Bitte warte hier, bis der Spielleiter die Runde startet.',
                          en: 'Please wait here until the host starts the round.',
                          fr: 'Merci dattendre ici jusqua ce que le maitre du jeu commence la partie.',
                          es: 'Espera aqui hasta que el anfitrion inicie la ronda.',
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lobby.hasStarted
                            ? strings.tr(
                                de: 'Der Fall laeuft bereits. Deine Hinweise und das volle Dossier warten im Lobbyraum auf dich.',
                                en: 'The case is already live. Your clues and full dossier are waiting in the lobby room.',
                                fr: 'Laffaire est deja en cours. Tes indices et ton dossier complet tattendent dans la salle du lobby.',
                                es: 'El caso ya esta en marcha. Tus pistas y tu dossier completo te esperan en la sala del lobby.',
                              )
                            : strings.tr(
                                de: 'Sobald die Runde beginnt, schaltet sich dein voller Lobbyraum frei. Bis dahin bleiben Szene und Rolle fuer dich sichtbar.',
                                en: 'As soon as the round starts, your full lobby room unlocks. Until then, the scene and your role remain visible.',
                                fr: 'Des que la partie commence, ta salle de lobby complete se debloque. En attendant, la scene et ton role restent visibles.',
                                es: 'En cuanto empiece la ronda, se desbloqueara tu sala completa. Hasta entonces, la escena y tu rol siguen visibles.',
                              ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: lobby.hasStarted
                            ? () => context.go('/lobbies/room/${lobby.code}')
                            : null,
                        icon: const Icon(Icons.meeting_room_rounded),
                        label: Text(
                          lobby.hasStarted
                              ? strings.tr(
                                  de: 'Zur aktiven Lobby',
                                  en: 'Open active lobby',
                                  fr: 'Ouvrir la lobby active',
                                  es: 'Abrir lobby activo',
                                )
                              : strings.tr(
                                  de: 'Warte auf den Start',
                                  en: 'Wait for start',
                                  fr: 'Attendre le debut',
                                  es: 'Esperar al inicio',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              secondary: [
                SectionPanel(
                  title: strings.tr(
                    de: 'Fallueberblick',
                    en: 'Case overview',
                    fr: 'Apercu de laffaire',
                    es: 'Resumen del caso',
                  ),
                  subtitle: strings.tr(
                    de: 'Das ist die Szene, zu der du eingeladen wurdest.',
                    en: 'This is the scenario you were invited to.',
                    fr: 'Voici la scene a laquelle tu as ete invite.',
                    es: 'Esta es la escena a la que has sido invitado.',
                  ),
                  child:
                      _CaseOverview(strings: strings, mysteryCase: mysteryCase),
                ),
                SectionPanel(
                  title: strings.tr(
                    de: 'Lobbystatus',
                    en: 'Lobby status',
                    fr: 'Statut de la lobby',
                    es: 'Estado del lobby',
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      MetricTile(
                        label: strings.tr(
                          de: 'Spieler',
                          en: 'Players',
                          fr: 'Joueurs',
                          es: 'Jugadores',
                        ),
                        value:
                            '${lobby.players.length}/${mysteryCase.roles.length}',
                        icon: Icons.groups_rounded,
                      ),
                      MetricTile(
                        label: strings.tr(
                          de: 'Status',
                          en: 'Status',
                          fr: 'Statut',
                          es: 'Estado',
                        ),
                        value: lobby.hasStarted
                            ? strings.tr(
                                de: 'Gestartet',
                                en: 'Started',
                                fr: 'Commence',
                                es: 'Iniciado')
                            : strings.tr(
                                de: 'Bereit',
                                en: 'Ready',
                                fr: 'Pret',
                                es: 'Listo'),
                        icon: lobby.hasStarted
                            ? Icons.play_circle_outline_rounded
                            : Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else if (showRejoinPanel)
            TwoColumnLayout(
              primary: [
                SectionPanel(
                  title: strings.tr(
                    de: 'Wiederbeitritt',
                    en: 'Rejoin',
                    fr: 'Reconnexion',
                    es: 'Reingreso',
                  ),
                  subtitle: strings.tr(
                    de: 'Deine Einladung ist bereits angenommen und deine Rolle bleibt noch kurz reserviert.',
                    en: 'Your invitation has already been accepted and your role remains reserved for a little while.',
                    fr: 'Ton invitation a deja ete acceptee et ton role reste reserve pendant un court instant.',
                    es: 'Tu invitacion ya fue aceptada y tu rol sigue reservado por un rato.',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.tr(
                          de: 'Du kannst mit demselben Namen direkt wieder in den Warteraum oder in die laufende Lobby zurueckkehren.',
                          en: 'You can return directly to the waiting room or the live lobby with the same name.',
                          fr: 'Tu peux revenir directement dans la salle dattente ou la lobby en cours avec le meme nom.',
                          es: 'Puedes volver directamente a la sala de espera o al lobby en curso con el mismo nombre.',
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => _rejoinInvitation(lobby),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          strings.tr(
                            de: 'Wieder beitreten',
                            en: 'Rejoin now',
                            fr: 'Rejoindre a nouveau',
                            es: 'Volver a entrar',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SectionPanel(
                  title: strings.tr(
                    de: 'Deine Rolle',
                    en: 'Your role',
                    fr: 'Ton role',
                    es: 'Tu rol',
                  ),
                  subtitle: strings.tr(
                    de: 'Diese Figur bleibt waehrend des 24-Stunden-Fensters fuer dich reserviert.',
                    en: 'This character stays reserved for you during the 24-hour window.',
                    fr: 'Ce personnage reste reserve pour toi pendant la fenetre de 24 heures.',
                    es: 'Este personaje queda reservado para ti durante la ventana de 24 horas.',
                  ),
                  trailing: assignedRole == null
                      ? null
                      : InfoPill(
                          label: assignedRole.name,
                          icon: Icons.person_pin_circle_rounded,
                        ),
                  child: assignedRole == null
                      ? Text(
                          strings.tr(
                            de: 'Deine Rolle wird gerade vorbereitet.',
                            en: 'Your role is still being prepared.',
                            fr: 'Ton role est encore en preparation.',
                            es: 'Tu rol se esta preparando todavia.',
                          ),
                        )
                      : _RolePreview(strings: strings, role: assignedRole),
                ),
              ],
              secondary: [
                SectionPanel(
                  title: strings.tr(
                    de: 'Fallueberblick',
                    en: 'Case overview',
                    fr: 'Apercu de laffaire',
                    es: 'Resumen del caso',
                  ),
                  subtitle: strings.tr(
                    de: 'Das ist die Szene, in die du zurueckkehren kannst.',
                    en: 'This is the scenario you can return to.',
                    fr: 'Voici la scene dans laquelle tu peux revenir.',
                    es: 'Esta es la escena a la que puedes volver.',
                  ),
                  child:
                      _CaseOverview(strings: strings, mysteryCase: mysteryCase),
                ),
              ],
            )
          else
            TwoColumnLayout(
              primary: [
                SectionPanel(
                  title: strings.tr(
                    de: 'Einladung annehmen',
                    en: 'Accept invitation',
                    fr: 'Accepter linvitation',
                    es: 'Aceptar invitacion',
                  ),
                  subtitle: strings.tr(
                    de: 'Gib den Namen ein, unter dem du in der Runde erscheinen sollst.',
                    en: 'Enter the name that should appear for you in the round.',
                    fr: 'Saisis le nom sous lequel tu dois apparaitre dans la partie.',
                    es: 'Introduce el nombre con el que debes aparecer en la ronda.',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: strings.tr(
                            de: 'Dein Name',
                            en: 'Your name',
                            fr: 'Ton nom',
                            es: 'Tu nombre',
                          ),
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
                        label: Text(
                          strings.tr(
                            de: 'Einladung annehmen',
                            en: 'Accept invitation',
                            fr: 'Accepter linvitation',
                            es: 'Aceptar invitacion',
                          ),
                        ),
                      ),
                      if (invitation.status == LobbyInvitationStatus.accepted &&
                          !acceptedByCurrentAlias) ...[
                        const SizedBox(height: 14),
                        Text(
                          strings.tr(
                            de: 'Diese Einladung wurde bereits angenommen.',
                            en: 'This invitation has already been accepted.',
                            fr: 'Cette invitation a deja ete acceptee.',
                            es: 'Esta invitacion ya fue aceptada.',
                          ),
                        ),
                      ],
                      if (invitation.status ==
                          LobbyInvitationStatus.revoked) ...[
                        const SizedBox(height: 14),
                        Text(
                          strings.tr(
                            de: 'Diese Einladung wurde vom Spielleiter zurueckgezogen.',
                            en: 'This invitation was revoked by the host.',
                            fr: 'Cette invitation a ete retiree par le maitre du jeu.',
                            es: 'Esta invitacion fue retirada por el anfitrion.',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SectionPanel(
                  title: strings.tr(
                    de: 'Was dich erwartet',
                    en: 'What to expect',
                    fr: 'Ce qui tattend',
                    es: 'Que te espera',
                  ),
                  subtitle: strings.tr(
                    de: 'Vor dem Start bekommst du den Fall, die Stimmung und deine Rolle angezeigt.',
                    en: 'Before the start, you can already see the case, the mood and your role.',
                    fr: 'Avant le debut, tu peux deja voir laffaire, lambiance et ton role.',
                    es: 'Antes del inicio ya puedes ver el caso, el ambiente y tu rol.',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.tr(
                          de: 'Nach dem Annehmen landest du direkt im Warteraum. Dort siehst du die grobe Szene des Falls und deine persoenliche Charakterrolle.',
                          en: 'After accepting, you land directly in the waiting room where you can already see the case setup and your personal character role.',
                          fr: 'Apres acceptation, tu arrives directement dans la salle dattente ou tu vois deja la scene generale et ton role personnel.',
                          es: 'Despues de aceptar entraras directamente en la sala de espera, donde ya veras la escena general y tu rol personal.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      InfoPill(
                        label: strings.tr(
                          de: 'Rolle vorbereitet fuer ${invitation.recipientName}',
                          en: 'Role prepared for ${invitation.recipientName}',
                          fr: 'Role prepare pour ${invitation.recipientName}',
                          es: 'Rol preparado para ${invitation.recipientName}',
                        ),
                        icon: Icons.lock_clock_rounded,
                      ),
                    ],
                  ),
                ),
              ],
              secondary: [
                SectionPanel(
                  title: strings.tr(
                    de: 'Fallueberblick',
                    en: 'Case overview',
                    fr: 'Apercu de laffaire',
                    es: 'Resumen del caso',
                  ),
                  subtitle: strings.tr(
                    de: 'Der Spielleiter laedt dich in diese Szene ein.',
                    en: 'The host is inviting you into this scenario.',
                    fr: 'Le maitre du jeu tinvite dans cette scene.',
                    es: 'El anfitrion te invita a esta escena.',
                  ),
                  child:
                      _CaseOverview(strings: strings, mysteryCase: mysteryCase),
                ),
                SectionPanel(
                  title: strings.tr(
                    de: 'Schnelldaten',
                    en: 'Quick facts',
                    fr: 'Infos rapides',
                    es: 'Datos rapidos',
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      MetricTile(
                        label: strings.tr(
                          de: 'Dauer',
                          en: 'Duration',
                          fr: 'Duree',
                          es: 'Duracion',
                        ),
                        value:
                            strings.minutesShort(mysteryCase.durationMinutes),
                        icon: Icons.schedule_rounded,
                      ),
                      MetricTile(
                        label: strings.tr(
                          de: 'Mitspieler',
                          en: 'Players',
                          fr: 'Joueurs',
                          es: 'Jugadores',
                        ),
                        value: strings.playersLabel(
                            mysteryCase.playerMin, mysteryCase.playerMax),
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
    final strings = ref.read(appStringsProvider);
    final error = ref.read(mysteryControllerProvider.notifier).joinLobby(
          code: lobby.code,
          alias: _nameController.text,
          invitationId: widget.invitationId,
        );

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage(
      strings.tr(
        de: 'Einladung angenommen. Du bist jetzt im Warteraum.',
        en: 'Invitation accepted. You are now in the waiting room.',
        fr: 'Invitation acceptee. Tu es maintenant dans la salle dattente.',
        es: 'Invitacion aceptada. Ahora estas en la sala de espera.',
      ),
    );
  }

  void _rejoinInvitation(LobbySession lobby) {
    final strings = ref.read(appStringsProvider);
    final error = ref.read(mysteryControllerProvider.notifier).rejoinLobby(
          code: lobby.code,
          alias: _nameController.text,
        );

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage(
      strings.tr(
        de: 'Wiederbeitritt erfolgreich. Dein Platz ist wieder aktiv.',
        en: 'Rejoin successful. Your slot is active again.',
        fr: 'Reconnexion reussie. Ta place est de nouveau active.',
        es: 'Reingreso correcto. Tu plaza vuelve a estar activa.',
      ),
    );
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
    required this.strings,
    required this.mysteryCase,
    required this.lobby,
    required this.invitation,
    required this.showWaitingRoom,
  });

  final AppStrings strings;
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
                label: strings.lobbyLabel(lobby.code),
                icon: Icons.key_rounded,
                accent: Colors.white,
              ),
              InfoPill(
                label: showWaitingRoom
                    ? strings.tr(
                        de: 'Warteraum',
                        en: 'Waiting room',
                        fr: 'Salle dattente',
                        es: 'Sala de espera',
                      )
                    : strings.tr(
                        de: 'Einladung',
                        en: 'Invitation',
                        fr: 'Invitation',
                        es: 'Invitacion',
                      ),
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
                ? strings.tr(
                    de: 'Du bist dabei',
                    en: 'You are in',
                    fr: 'Tu en fais partie',
                    es: 'Ya estas dentro',
                  )
                : strings.tr(
                    de: 'Du bist eingeladen zu ${mysteryCase.title}',
                    en: 'You are invited to ${mysteryCase.title}',
                    fr: 'Tu es invite a ${mysteryCase.title}',
                    es: 'Estas invitado a ${mysteryCase.title}',
                  ),
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
                ? strings.tr(
                    de: 'Die Szene steht fest. Deine persoenliche Rolle wurde fuer dich reserviert. Jetzt fehlt nur noch der Startschuss des Spielleiters.',
                    en: 'The scenario is set. Your personal role has been reserved for you. Now only the hosts start signal is missing.',
                    fr: 'La scene est fixee. Ton role personnel a ete reserve pour toi. Il ne manque plus que le signal de depart du maitre du jeu.',
                    es: 'La escena ya esta definida. Tu rol personal ha quedado reservado para ti. Ahora solo falta la senal de inicio del anfitrion.',
                  )
                : strings.tr(
                    de: 'Der Spielleiter hat bereits eine persoenliche Einladung fuer ${invitation.recipientName} vorbereitet.',
                    en: 'The host has already prepared a personal invitation for ${invitation.recipientName}.',
                    fr: 'Le maitre du jeu a deja prepare une invitation personnelle pour ${invitation.recipientName}.',
                    es: 'El anfitrion ya ha preparado una invitacion personal para ${invitation.recipientName}.',
                  ),
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
  const _CaseOverview({
    required this.strings,
    required this.mysteryCase,
  });

  final AppStrings strings;
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
              label: strings.difficultyLabel(mysteryCase.difficulty),
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
          strings.tr(
            de: 'Atmosphaere: ${mysteryCase.atmosphere}',
            en: 'Atmosphere: ${mysteryCase.atmosphere}',
            fr: 'Atmosphere : ${mysteryCase.atmosphere}',
            es: 'Atmosfera: ${mysteryCase.atmosphere}',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _RolePreview extends StatelessWidget {
  const _RolePreview({
    required this.strings,
    required this.role,
  });

  final AppStrings strings;
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
        _PreviewLine(
          title: strings.tr(
            de: 'Persoenlichkeit',
            en: 'Personality',
            fr: 'Personnalite',
            es: 'Personalidad',
          ),
          text: role.persona,
        ),
        _PreviewLine(
          title: strings.tr(
            de: 'Ziel',
            en: 'Goal',
            fr: 'Objectif',
            es: 'Objetivo',
          ),
          text: role.goal,
        ),
        _PreviewLine(
          title: strings.tr(
            de: 'Auftreten',
            en: 'Presentation',
            fr: 'Apparence',
            es: 'Apariencia',
          ),
          text: role.outfit.neutral,
        ),
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

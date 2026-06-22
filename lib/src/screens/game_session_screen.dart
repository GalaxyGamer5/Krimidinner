import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_strings.dart';
import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_window.dart';

enum _WindowId { chat, notes, evidence, role }

const _reactionChoices = ['👀', '🤔', '😱', '🎯'];

const _culpritRoleIds = <String, String>{
  'villa_no_7': 'amara',
  'aurelia_express': 'gabriel',
  'crimson_masquerade': 'julian',
  'lantern_society': 'rowan',
};

AppStrings _stringsOf(BuildContext context) =>
    ProviderScope.containerOf(context).read(appStringsProvider);

class GameSessionScreen extends ConsumerStatefulWidget {
  const GameSessionScreen({
    super.key,
    required this.code,
  });

  final String code;

  @override
  ConsumerState<GameSessionScreen> createState() => _GameSessionScreenState();
}

class _GameSessionScreenState extends ConsumerState<GameSessionScreen> {
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _generalNotesController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  final Set<_WindowId> _openWindows = {_WindowId.chat};
  final Set<String> _dismissedEvidenceIds = <String>{};

  Timer? _clock;
  DateTime _now = DateTime.now();

  String? _selectedRecipientPlayerId;
  String? _expandedEvidenceId;
  String? _lastAutoOpenedEvidenceId;
  bool _dismissalsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadGeneralNotes();
    _loadDismissedEvidenceIds();
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
    _saveGeneralNotes();
    _chatController.dispose();
    _generalNotesController.dispose();
    _chatScrollController.dispose();
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _loadGeneralNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notes = prefs.getString(_generalNotesKey) ?? '';
    if (mounted) {
      _generalNotesController.text = notes;
    }
  }

  Future<void> _saveGeneralNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_generalNotesKey, _generalNotesController.text);
  }

  Future<void> _loadDismissedEvidenceIds() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_dismissedEvidenceKey) ?? const [];
    if (!mounted) {
      return;
    }
    setState(() {
      _dismissedEvidenceIds
        ..clear()
        ..addAll(values);
      _dismissalsLoaded = true;
    });
  }

  Future<void> _persistDismissedEvidenceIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dismissedEvidenceKey,
      _dismissedEvidenceIds.toList(),
    );
  }

  String get _generalNotesKey => 'game_notes_${widget.code}';

  String get _dismissedEvidenceKey {
    final alias = ref.read(mysteryControllerProvider).localAlias;
    final normalizedAlias =
        alias.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return 'dismissed_evidence_${widget.code}_$normalizedAlias';
  }

  void _toggleWindow(_WindowId id) {
    setState(() {
      if (_openWindows.contains(id)) {
        _openWindows.remove(id);
      } else {
        _openWindows.add(id);
      }
    });
  }

  void _selectRecipient(String? playerId) {
    setState(() {
      _selectedRecipientPlayerId = playerId;
    });
  }

  void _sendChatMessage(LobbySession lobby, LobbyPlayer? viewer) {
    if (viewer == null) {
      return;
    }

    final text = _chatController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final recipient = _selectedRecipientPlayerId == null
        ? null
        : lobby.players
            .where((player) => player.id == _selectedRecipientPlayerId)
            .firstOrNull;

    ref.read(mysteryControllerProvider.notifier).sendLobbyMessage(
          code: widget.code,
          sender: viewer.name,
          body: text,
          recipientPlayerId: recipient?.id,
          recipientPlayerName: recipient?.name,
        );

    _chatController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openEvidence(GameEvidence evidence) {
    setState(() {
      _expandedEvidenceId = evidence.id;
      _lastAutoOpenedEvidenceId = evidence.id;
    });
  }

  void _closeEvidence() {
    final evidenceId = _expandedEvidenceId;
    if (evidenceId != null) {
      _dismissedEvidenceIds.add(evidenceId);
      _persistDismissedEvidenceIds();
    }

    setState(() {
      _expandedEvidenceId = null;
    });
  }

  void _maybeAutoOpenEvidence(LobbySession lobby) {
    if (!_dismissalsLoaded || lobby.evidences.isEmpty) {
      return;
    }

    final latestEvidence = lobby.evidences.last;
    if (_dismissedEvidenceIds.contains(latestEvidence.id)) {
      return;
    }
    if (_lastAutoOpenedEvidenceId == latestEvidence.id) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _expandedEvidenceId = latestEvidence.id;
        _lastAutoOpenedEvidenceId = latestEvidence.id;
      });
    });
  }

  void _toggleReaction(
    ChatMessage message,
    LobbyPlayer viewer,
    String emoji,
  ) {
    ref.read(mysteryControllerProvider.notifier).toggleMessageReaction(
          code: widget.code,
          messageId: message.id,
          playerId: viewer.id,
          playerName: viewer.name,
          emoji: emoji,
        );
  }

  Future<void> _openReactionPicker(
    BuildContext context,
    ChatMessage message,
    LobbyPlayer viewer,
  ) async {
    final strings = ref.read(appStringsProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF16111F),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.tr(
                      de: 'Reaktion waehlen',
                      en: 'Choose reaction',
                      fr: 'Choisir une reaction',
                      es: 'Elegir reaccion',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _reactionChoices
                        .map(
                          (emoji) => InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _toggleReaction(message, viewer, emoji);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 60,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _castVote(LobbyPlayer viewer, MysteryRole role) {
    ref.read(mysteryControllerProvider.notifier).castVote(
          code: widget.code,
          voterPlayerId: viewer.id,
          suspectRoleId: role.id,
        );
  }

  void _advancePhase(LobbySession lobby, MysteryCase mysteryCase) {
    final strings = ref.read(appStringsProvider);
    final error = ref.read(mysteryControllerProvider.notifier).advancePhase(
          widget.code,
        );
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final isFinalVisiblePhase = lobby.phaseIndex >= mysteryCase.phases.length - 1;
    if (isFinalVisiblePhase) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.tr(
              de: 'Der Fall wurde abgeschlossen.',
              en: 'The case has been completed.',
              fr: 'L affaire a ete terminee.',
              es: 'El caso ha finalizado.',
            ),
          ),
        ),
      );
    }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.go('/lobbies');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.tr(
            de: 'Lobby verlassen. Wiederbeitritt mit demselben Namen ist 24 Stunden moeglich.',
            en: 'Lobby left. Rejoining with the same name is possible for 24 hours.',
            fr: 'Lobby quittee. Rejoindre avec le meme nom reste possible pendant 24 heures.',
            es: 'Has salido del lobby. Podras volver a entrar con el mismo nombre durante 24 horas.',
          ),
        ),
      ),
    );
  }

  void _rejoinLobby(String alias) {
    final error = ref.read(mysteryControllerProvider.notifier).rejoinLobby(
          code: widget.code,
          alias: alias,
        );
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  LobbyPlayer? _activeViewer(LobbySession lobby, String alias) {
    return lobby.players
        .where(
          (player) =>
              player.isOnline &&
              player.name.toLowerCase() == alias.toLowerCase(),
        )
        .firstOrNull;
  }

  LobbyPlayer? _rejoinCandidate(LobbySession lobby, String alias) {
    return lobby.players
        .where(
          (player) =>
              !player.isOnline &&
              player.canRejoin &&
              player.name.toLowerCase() == alias.toLowerCase(),
        )
        .firstOrNull;
  }

  Widget _buildRejoinFallback(
    BuildContext context,
    LobbySession lobby,
    MysteryCase mysteryCase,
    LobbyPlayer player,
  ) {
    final strings = ref.read(appStringsProvider);
    final roleId = lobby.roleAssignments[player.id];
    final role = roleId == null
        ? null
        : mysteryCase.roles.where((entry) => entry.id == roleId).firstOrNull;
    final deadline = player.rejoinAvailableUntil;
    final timeLabel = deadline == null
        ? strings.tr(
            de: 'fuer kurze Zeit',
            en: 'for a short time',
            fr: 'pour un court moment',
            es: 'por poco tiempo',
          )
        : '${deadline.day.toString().padLeft(2, '0')}.${deadline.month.toString().padLeft(2, '0')} um ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tr(
                  de: 'Wiederbeitritt moeglich',
                  en: 'Rejoin available',
                  fr: 'Retour possible',
                  es: 'Reingreso disponible',
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.tr(
                  de: 'Dein Platz in ${mysteryCase.title} ist noch bis $timeLabel fuer dich reserviert.',
                  en: 'Your spot in ${mysteryCase.title} is reserved for you until $timeLabel.',
                  fr: 'Ta place dans ${mysteryCase.title} est reservee pour toi jusqu a $timeLabel.',
                  es: 'Tu plaza en ${mysteryCase.title} esta reservada para ti hasta $timeLabel.',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (role != null) ...[
                const SizedBox(height: 14),
                Text(
                  strings.tr(
                    de: 'Reservierte Rolle: ${role.name}',
                    en: 'Reserved role: ${role.name}',
                    fr: 'Role reserve : ${role.name}',
                    es: 'Rol reservado: ${role.name}',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppPalette.gold,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => _rejoinLobby(player.name),
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mysteryControllerProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final strings = ref.watch(appStringsProvider);
    final lobby = state.lobbies.where((entry) => entry.code == widget.code).firstOrNull;
    final mysteryCase =
        lobby == null ? null : ref.watch(mysteryCaseProvider(lobby.caseId));

    if (lobby == null || mysteryCase == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            strings.tr(
              de: 'Spielsitzung',
              en: 'Game session',
              fr: 'Session de jeu',
              es: 'Sesion de juego',
            ),
          ),
        ),
        body: Center(
          child: Text(
            strings.tr(
              de: 'Lobby oder Fall nicht gefunden.',
              en: 'Lobby or case not found.',
              fr: 'Lobby ou affaire introuvable.',
              es: 'No se encontro el lobby o el caso.',
            ),
          ),
        ),
      );
    }

    final viewer = _activeViewer(lobby, state.localAlias);
    final rejoinPlayer = _rejoinCandidate(lobby, state.localAlias);
    final isHost = viewer?.id == lobby.hostId;
    final currentPhase = mysteryCase.phases[lobby.phaseIndex];
    final viewerRoleId = viewer == null ? null : lobby.roleAssignments[viewer.id];
    final viewerRole = viewerRoleId == null
        ? null
        : mysteryCase.roles.where((role) => role.id == viewerRoleId).firstOrNull;

    if (viewer == null && rejoinPlayer != null) {
      return Scaffold(
        backgroundColor: AppPalette.noir,
        appBar: AppBar(
          title: Text(
            strings.tr(
              de: 'Spielsitzung',
              en: 'Game session',
              fr: 'Session de jeu',
              es: 'Sesion de juego',
            ),
          ),
        ),
        body: _buildRejoinFallback(
          context,
          lobby,
          mysteryCase,
          rejoinPlayer,
        ),
      );
    }

    if (viewer == null) {
      return Scaffold(
        backgroundColor: AppPalette.noir,
        appBar: AppBar(
          title: Text(
            strings.tr(
              de: 'Spielsitzung',
              en: 'Game session',
              fr: 'Session de jeu',
              es: 'Sesion de juego',
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              strings.tr(
                de: 'Du bist aktuell nicht als aktiver Spieler mit dieser Lobby verbunden.',
                en: 'You are currently not connected to this lobby as an active player.',
                fr: 'Tu n es actuellement pas connecte a cette lobby en tant que joueur actif.',
                es: 'Ahora mismo no estas conectado a este lobby como jugador activo.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_selectedRecipientPlayerId != null &&
        !lobby.players.any(
          (player) =>
              player.isOnline && player.id == _selectedRecipientPlayerId,
        )) {
      _selectedRecipientPlayerId = null;
    }

    _maybeAutoOpenEvidence(lobby);

    final remaining = _phaseRemaining(lobby, currentPhase);
    final expandedEvidence = _expandedEvidenceId == null
        ? null
        : lobby.evidences.where((evidence) => evidence.id == _expandedEvidenceId).firstOrNull;

    return Scaffold(
      backgroundColor: AppPalette.noir,
      appBar: _buildAppBar(
        context,
        mysteryCase,
        lobby,
        viewer,
        viewerRole,
        remaining,
      ),
      body: Stack(
        children: [
          _buildGameBoard(
            context,
            lobby,
            mysteryCase,
            currentPhase,
            viewer,
            isHost,
          ),
          if (_openWindows.contains(_WindowId.chat))
            FloatingWindow(
              title: strings.tr(
                de: 'Chat',
                en: 'Chat',
                fr: 'Chat',
                es: 'Chat',
              ),
              icon: Icons.chat_rounded,
              initialOffset: const Offset(36, 90),
              width: 420,
              height: 560,
              accentColor: AppPalette.gold,
              onClose: () => _toggleWindow(_WindowId.chat),
              child: _ChatWindowContent(
                lobby: lobby,
                viewer: viewer,
                selectedRecipientPlayerId: _selectedRecipientPlayerId,
                chatController: _chatController,
                chatScrollController: _chatScrollController,
                animationsEnabled: appSettings.animationsEnabled,
                onSelectRecipient: _selectRecipient,
                onSend: () => _sendChatMessage(lobby, viewer),
                onOpenReactionPicker: (message) =>
                    _openReactionPicker(context, message, viewer),
                onOpenEvidence: _openEvidence,
              ),
            ),
          if (_openWindows.contains(_WindowId.notes))
            FloatingWindow(
              title: strings.tr(
                de: 'Eigene Notizen',
                en: 'My notes',
                fr: 'Mes notes',
                es: 'Mis notas',
              ),
              icon: Icons.edit_note_rounded,
              initialOffset: const Offset(120, 110),
              width: 440,
              height: 560,
              accentColor: Colors.tealAccent,
              onClose: () => _toggleWindow(_WindowId.notes),
              child: _NotesWindowContent(
                lobbyCode: widget.code,
                lobby: lobby,
                mysteryCase: mysteryCase,
                generalNotesController: _generalNotesController,
                onSaveGeneral: _saveGeneralNotes,
              ),
            ),
          if (_openWindows.contains(_WindowId.evidence))
            FloatingWindow(
              title: strings.tr(
                de: 'Beweise',
                en: 'Evidence',
                fr: 'Preuves',
                es: 'Pruebas',
              ),
              icon: Icons.inventory_2_rounded,
              initialOffset: const Offset(210, 120),
              width: 420,
              height: 540,
              accentColor: const Color(0xFFE4B969),
              onClose: () => _toggleWindow(_WindowId.evidence),
              child: _EvidenceWindowContent(
                evidences: lobby.evidences,
                onOpenEvidence: _openEvidence,
              ),
            ),
          if (_openWindows.contains(_WindowId.role) && viewerRole != null)
            FloatingWindow(
              title: strings.tr(
                de: 'Meine Rolle',
                en: 'My role',
                fr: 'Mon role',
                es: 'Mi rol',
              ),
              icon: Icons.menu_book_rounded,
              initialOffset: const Offset(300, 80),
              width: 420,
              height: 600,
              accentColor: Colors.purpleAccent,
              onClose: () => _toggleWindow(_WindowId.role),
              child: _RoleDossierContent(role: viewerRole),
            ),
          if (expandedEvidence != null)
            _EvidenceOverlay(
              evidence: expandedEvidence,
              onClose: _closeEvidence,
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MysteryCase mysteryCase,
    LobbySession lobby,
    LobbyPlayer viewer,
    MysteryRole? viewerRole,
    Duration remaining,
  ) {
    final strings = ref.read(appStringsProvider);
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return AppBar(
      backgroundColor: AppPalette.midnight,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: strings.tr(
          de: 'Zurueck zur Lobby',
          en: 'Back to lobby',
          fr: 'Retour a la lobby',
          es: 'Volver al lobby',
        ),
        onPressed: () => context.go('/lobbies/room/${widget.code}'),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mysteryCase.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          Text(
            strings.tr(
              de: 'Phase ${lobby.phaseIndex + 1}/${mysteryCase.phases.length} | $minutes:$seconds',
              en: 'Phase ${lobby.phaseIndex + 1}/${mysteryCase.phases.length} | $minutes:$seconds',
              fr: 'Phase ${lobby.phaseIndex + 1}/${mysteryCase.phases.length} | $minutes:$seconds',
              es: 'Fase ${lobby.phaseIndex + 1}/${mysteryCase.phases.length} | $minutes:$seconds',
            ),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.58),
            ),
          ),
        ],
      ),
      actions: [
        _AppBarToggle(
          icon: Icons.chat_rounded,
          label: strings.tr(
            de: 'Chat',
            en: 'Chat',
            fr: 'Chat',
            es: 'Chat',
          ),
          isActive: _openWindows.contains(_WindowId.chat),
          activeColor: AppPalette.gold,
          onTap: () => _toggleWindow(_WindowId.chat),
        ),
        const SizedBox(width: 6),
        _AppBarToggle(
          icon: Icons.edit_note_rounded,
          label: strings.tr(
            de: 'Notizen',
            en: 'Notes',
            fr: 'Notes',
            es: 'Notas',
          ),
          isActive: _openWindows.contains(_WindowId.notes),
          activeColor: Colors.tealAccent,
          onTap: () => _toggleWindow(_WindowId.notes),
        ),
        const SizedBox(width: 6),
        _AppBarToggle(
          icon: Icons.inventory_2_rounded,
          label: strings.tr(
            de: 'Beweise',
            en: 'Evidence',
            fr: 'Preuves',
            es: 'Pruebas',
          ),
          isActive: _openWindows.contains(_WindowId.evidence),
          activeColor: const Color(0xFFE4B969),
          onTap: () => _toggleWindow(_WindowId.evidence),
        ),
        const SizedBox(width: 6),
        if (viewerRole != null)
          _AppBarToggle(
            icon: Icons.menu_book_rounded,
            label: strings.tr(
              de: 'Meine Rolle',
              en: 'My role',
              fr: 'Mon role',
              es: 'Mi rol',
            ),
            isActive: _openWindows.contains(_WindowId.role),
            activeColor: Colors.purpleAccent,
            onTap: () => _toggleWindow(_WindowId.role),
          ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: strings.tr(
            de: 'Lobby verlassen',
            en: 'Leave lobby',
            fr: 'Quitter la lobby',
            es: 'Salir del lobby',
          ),
          onPressed: () => _confirmLeaveLobby(viewer),
          icon: const Icon(Icons.logout_rounded),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildGameBoard(
    BuildContext context,
    LobbySession lobby,
    MysteryCase mysteryCase,
    GamePhase currentPhase,
    LobbyPlayer? viewer,
    bool isHost,
  ) {
    final strings = ref.read(appStringsProvider);
    final isVotePhase = currentPhase.id == 'vote';
    final isTheoryPhase = currentPhase.id == 'theory' && !lobby.isCompleted;
    final isRevealPhase = currentPhase.id == 'reveal' || lobby.isCompleted;
    final visibleEvidenceCount = lobby.evidences.length;
    final submittedVotes = lobby.votes.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 920,
                minHeight: constraints.maxHeight - 60,
              ),
              child: Column(
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _BoardChip(
                        label: strings.tr(
                          de: 'Phase ${lobby.phaseIndex + 1}',
                          en: 'Phase ${lobby.phaseIndex + 1}',
                          fr: 'Phase ${lobby.phaseIndex + 1}',
                          es: 'Fase ${lobby.phaseIndex + 1}',
                        ),
                        icon: Icons.auto_awesome_mosaic_rounded,
                      ),
                      _BoardChip(
                        label: strings.tr(
                          de: '$visibleEvidenceCount Beweise',
                          en: '$visibleEvidenceCount evidence',
                          fr: '$visibleEvidenceCount preuves',
                          es: '$visibleEvidenceCount pruebas',
                        ),
                        icon: Icons.inventory_2_outlined,
                      ),
                      _BoardChip(
                        label: strings.tr(
                          de: '$submittedVotes Stimmen',
                          en: '$submittedVotes votes',
                          fr: '$submittedVotes votes',
                          es: '$submittedVotes votos',
                        ),
                        icon: Icons.how_to_vote_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    currentPhase.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppPalette.parchment,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      currentPhase.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            height: 1.6,
                            color: AppPalette.parchment.withOpacity(0.9),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (isVotePhase && viewer != null)
                    _VotePanel(
                      lobby: lobby,
                      mysteryCase: mysteryCase,
                      viewer: viewer,
                      onVote: _castVote,
                    ),
                  if (isTheoryPhase)
                    _TheoryPanel(
                      lobby: lobby,
                      mysteryCase: mysteryCase,
                    ),
                  if (isRevealPhase)
                    _ResultsPanel(
                      lobby: lobby,
                      mysteryCase: mysteryCase,
                    ),
                  const SizedBox(height: 28),
                  if (isHost)
                    FilledButton.icon(
                      onPressed: lobby.isCompleted
                          ? null
                          : () => _advancePhase(lobby, mysteryCase),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.gold,
                        foregroundColor: AppPalette.noir,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      icon: const Icon(Icons.skip_next_rounded),
                      label: Text(
                        _hostActionLabel(lobby, mysteryCase, currentPhase),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withOpacity(0.04),
                      ),
                      child: Text(
                        strings.tr(
                          de: 'Warte auf den Spielleiter...',
                          en: 'Waiting for the host...',
                          fr: 'En attente de l hote...',
                          es: 'Esperando al host...',
                        ),
                        style: TextStyle(color: Colors.white.withOpacity(0.58)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Duration _phaseRemaining(LobbySession lobby, GamePhase currentPhase) {
    if (!lobby.hasStarted || lobby.phaseStartedAt == null) {
      return Duration(minutes: currentPhase.durationMinutes);
    }

    final phaseEnd =
        lobby.phaseStartedAt!.add(Duration(minutes: currentPhase.durationMinutes));
    final remaining = phaseEnd.difference(_now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _hostActionLabel(
    LobbySession lobby,
    MysteryCase mysteryCase,
    GamePhase currentPhase,
  ) {
    final strings = ref.read(appStringsProvider);
    if (lobby.phaseIndex >= mysteryCase.phases.length - 1) {
      return strings.tr(
        de: 'Fall abschliessen',
        en: 'Complete case',
        fr: 'Clore l affaire',
        es: 'Cerrar caso',
      );
    }
    if (currentPhase.id == 'vote') {
      return strings.tr(
        de: 'Moerder offenlegen',
        en: 'Reveal culprit',
        fr: 'Reveler le coupable',
        es: 'Revelar al culpable',
      );
    }
    if (currentPhase.id == 'theory') {
      return strings.tr(
        de: 'Tathergang aufdecken',
        en: 'Reveal reconstruction',
        fr: 'Reveler la reconstruction',
        es: 'Revelar la reconstruccion',
      );
    }
    return strings.tr(
      de: 'Naechste Phase',
      en: 'Next phase',
      fr: 'Phase suivante',
      es: 'Siguiente fase',
    );
  }
}

class _ChatWindowContent extends ConsumerWidget {
  const _ChatWindowContent({
    required this.lobby,
    required this.viewer,
    required this.selectedRecipientPlayerId,
    required this.chatController,
    required this.chatScrollController,
    required this.animationsEnabled,
    required this.onSelectRecipient,
    required this.onSend,
    required this.onOpenReactionPicker,
    required this.onOpenEvidence,
  });

  final LobbySession lobby;
  final LobbyPlayer? viewer;
  final String? selectedRecipientPlayerId;
  final TextEditingController chatController;
  final ScrollController chatScrollController;
  final bool animationsEnabled;
  final ValueChanged<String?> onSelectRecipient;
  final VoidCallback onSend;
  final ValueChanged<ChatMessage>? onOpenReactionPicker;
  final ValueChanged<GameEvidence> onOpenEvidence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final visibleMessages = lobby.messages
        .where((message) => _isVisibleForViewer(message, viewer))
        .toList();
    final selectedRecipient = selectedRecipientPlayerId == null
        ? null
        : lobby.players
            .where(
              (player) =>
                  player.isOnline && player.id == selectedRecipientPlayerId,
            )
            .firstOrNull;
    final recipients = viewer == null
        ? const <LobbyPlayer>[]
        : lobby.players
            .where((player) => player.isOnline && player.id != viewer!.id)
            .toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          color: Colors.white.withOpacity(0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tr(
                  de: 'Senden an',
                  en: 'Send to',
                  fr: 'Envoyer a',
                  es: 'Enviar a',
                ),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withOpacity(0.62),
                    ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TargetChip(
                      label: strings.tr(
                        de: 'Lobby',
                        en: 'Lobby',
                        fr: 'Lobby',
                        es: 'Lobby',
                      ),
                      isSelected: selectedRecipient == null,
                      onTap: () => onSelectRecipient(null),
                    ),
                    const SizedBox(width: 8),
                    ...recipients.map(
                      (player) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TargetChip(
                          label: player.name,
                          avatar: player.name.characters.first.toUpperCase(),
                          isSelected: selectedRecipientPlayerId == player.id,
                          onTap: () => onSelectRecipient(player.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        Expanded(
          child: ListView.builder(
            controller: chatScrollController,
            padding: const EdgeInsets.all(14),
            itemCount: visibleMessages.length,
            itemBuilder: (context, index) {
              final message = visibleMessages[index];
              final evidence = message.evidenceId == null
                  ? null
                  : lobby.evidences
                      .where((entry) => entry.id == message.evidenceId)
                      .firstOrNull;
              final isMine = viewer != null &&
                  message.sender.toLowerCase() == viewer!.name.toLowerCase();

              if (message.type == ChatMessageType.system) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Center(
                    child: Text(
                      message.body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.36),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return _ChatBubble(
                message: message,
                evidence: evidence,
                isMine: isMine,
                viewer: viewer,
                animationsEnabled: animationsEnabled,
                onOpenEvidence: evidence == null ? null : () => onOpenEvidence(evidence),
                onReact: onOpenReactionPicker == null
                    ? null
                    : () => onOpenReactionPicker!(message),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedRecipient != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    strings.tr(
                      de: 'Privat an ${selectedRecipient.name}',
                      en: 'Private to ${selectedRecipient.name}',
                      fr: 'Prive pour ${selectedRecipient.name}',
                      es: 'Privado para ${selectedRecipient.name}',
                    ),
                    style: TextStyle(
                      color: Colors.tealAccent.withOpacity(0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chatController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: selectedRecipient == null
                            ? strings.tr(
                                de: 'Nachricht an die Runde...',
                                en: 'Message to the group...',
                                fr: 'Message au groupe...',
                                es: 'Mensaje al grupo...',
                              )
                            : strings.tr(
                                de: 'Geheimnachricht an ${selectedRecipient.name}...',
                                en: 'Secret message to ${selectedRecipient.name}...',
                                fr: 'Message secret pour ${selectedRecipient.name}...',
                                es: 'Mensaje secreto para ${selectedRecipient.name}...',
                              ),
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSend,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppPalette.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: AppPalette.gold,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isVisibleForViewer(ChatMessage message, LobbyPlayer? viewer) {
    if (message.type != ChatMessageType.direct) {
      return true;
    }
    if (viewer == null) {
      return false;
    }
    return message.sender.toLowerCase() == viewer.name.toLowerCase() ||
        message.recipientPlayerId == viewer.id;
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.evidence,
    required this.isMine,
    required this.viewer,
    required this.animationsEnabled,
    required this.onOpenEvidence,
    required this.onReact,
  });

  final ChatMessage message;
  final GameEvidence? evidence;
  final bool isMine;
  final LobbyPlayer? viewer;
  final bool animationsEnabled;
  final VoidCallback? onOpenEvidence;
  final VoidCallback? onReact;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    final bubbleColor = switch (message.type) {
      ChatMessageType.direct => Colors.tealAccent.withOpacity(isMine ? 0.18 : 0.12),
      ChatMessageType.evidence => const Color(0xFFE4B969).withOpacity(0.12),
      _ => isMine
          ? AppPalette.gold.withOpacity(0.18)
          : Colors.white.withOpacity(0.07),
    };

    final crossAlignment =
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: crossAlignment,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                color: bubbleColor,
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: crossAlignment,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message.sender,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isMine
                                ? AppPalette.gold
                                : Colors.white.withOpacity(0.58),
                          ),
                        ),
                      ),
                      if (message.type == ChatMessageType.direct) ...[
                        const SizedBox(width: 8),
                        _InlineTypePill(
                          label: isMine
                              ? strings.tr(
                                  de: 'Privat an ${message.recipientPlayerName ?? '...'}',
                                  en: 'Private to ${message.recipientPlayerName ?? '...'}',
                                  fr: 'Prive pour ${message.recipientPlayerName ?? '...'}',
                                  es: 'Privado para ${message.recipientPlayerName ?? '...'}',
                                )
                              : strings.tr(
                                  de: 'Privat',
                                  en: 'Private',
                                  fr: 'Prive',
                                  es: 'Privado',
                                ),
                          color: Colors.tealAccent,
                        ),
                      ],
                      if (message.type == ChatMessageType.evidence) ...[
                        const SizedBox(width: 8),
                        _InlineTypePill(
                          label: strings.tr(
                            de: 'Beweis',
                            en: 'Evidence',
                            fr: 'Preuve',
                            es: 'Prueba',
                          ),
                          color: Color(0xFFE4B969),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (message.type == ChatMessageType.evidence && evidence != null)
                    _EvidenceMessageCard(
                      evidence: evidence!,
                      message: message,
                      onOpen: onOpenEvidence,
                    )
                  else
                    Text(
                      message.body,
                      textAlign: isMine ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._buildReactionChips(message.reactions, animationsEnabled),
                if (onReact != null)
                  InkWell(
                    onTap: onReact,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Icon(
                        Icons.add_reaction_outlined,
                        size: 16,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReactionChips(
    List<ChatReaction> reactions,
    bool animationsEnabled,
  ) {
    if (reactions.isEmpty) {
      return const [];
    }

    final counts = <String, int>{};
    for (final reaction in reactions) {
      counts.update(reaction.emoji, (value) => value + 1, ifAbsent: () => 1);
    }

    final orderedEntries = [
      for (final emoji in _reactionChoices)
        if (counts.containsKey(emoji)) MapEntry(emoji, counts[emoji]!),
    ];

    return orderedEntries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _ReactionChip(
              emoji: entry.key,
              count: entry.value,
              animate: animationsEnabled,
            ),
          ),
        )
        .toList();
  }
}

class _VotePanel extends StatelessWidget {
  const _VotePanel({
    required this.lobby,
    required this.mysteryCase,
    required this.viewer,
    required this.onVote,
  });

  final LobbySession lobby;
  final MysteryCase mysteryCase;
  final LobbyPlayer viewer;
  final void Function(LobbyPlayer viewer, MysteryRole role) onVote;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    final activePlayerCount = lobby.players.where((player) => player.isOnline).length;
    final viewerVote = lobby.votes
        .where((vote) => vote.voterPlayerId == viewer.id)
        .firstOrNull;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr(
              de: 'Abstimmung',
              en: 'Voting',
              fr: 'Vote',
              es: 'Votacion',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              de: 'Wen haeltst du fuer den Moerder? Deine Stimme kann bis zur Aufloesung noch geaendert werden.',
              en: 'Who do you think is the culprit? You can still change your vote until the reveal.',
              fr: 'Qui penses-tu etre le coupable ? Tu peux encore modifier ton vote jusqu a la revelation.',
              es: 'Quien crees que es el culpable? Aun puedes cambiar tu voto hasta la revelacion.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: mysteryCase.roles
                .map(
                  (role) => _VoteRoleCard(
                    role: role,
                    isSelected: viewerVote?.suspectRoleId == role.id,
                    onTap: () => onVote(viewer, role),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Text(
            strings.tr(
              de: '${lobby.votes.length}/$activePlayerCount Stimmen abgegeben',
              en: '${lobby.votes.length}/$activePlayerCount votes submitted',
              fr: '${lobby.votes.length}/$activePlayerCount votes soumis',
              es: '${lobby.votes.length}/$activePlayerCount votos enviados',
            ),
            style: TextStyle(
              color: Colors.white.withOpacity(0.64),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

MysteryRole? _culpritRoleForCase(MysteryCase mysteryCase) {
  final culpritRoleId = _culpritRoleIds[mysteryCase.id];
  if (culpritRoleId == null) {
    return null;
  }
  return mysteryCase.roles.where((role) => role.id == culpritRoleId).firstOrNull;
}

List<_RevealBeat> _buildRevealBeats(
  MysteryCase mysteryCase,
  MysteryRole culpritRole,
  AppStrings strings,
) {
  switch (mysteryCase.id) {
    case 'villa_no_7':
      return [
        _RevealBeat(
          title: strings.tr(
            de: 'Vor dem Dinner',
            en: 'Before dinner',
            fr: 'Avant le diner',
            es: 'Antes de la cena',
          ),
          body: strings.tr(
            de: '${culpritRole.name} merkte frueh, dass sich der Abend nicht mehr kontrollieren liess. ${culpritRole.motive}',
            en: '${culpritRole.name} realized early that the evening could no longer be controlled. ${culpritRole.motive}',
            fr: '${culpritRole.name} a compris tres tot que la soiree ne pouvait plus etre maitrisee. ${culpritRole.motive}',
            es: '${culpritRole.name} se dio cuenta pronto de que la noche ya no podia controlarse. ${culpritRole.motive}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Der entscheidende Augenblick',
            en: 'The decisive moment',
            fr: 'Le moment decisif',
            es: 'El momento decisivo',
          ),
          body: strings.tr(
            de: 'Als die Stimmung in der Villa kippte, nutzte ${culpritRole.name} einen kurzen unbeobachteten Moment im Schutz der Unruhe. ${culpritRole.secret}',
            en: 'As the mood in the villa shifted, ${culpritRole.name} used a brief unwatched moment under cover of the unrest. ${culpritRole.secret}',
            fr: 'Quand l atmosphere a bascule dans la villa, ${culpritRole.name} a profite d un bref instant sans surveillance a l abri du desordre. ${culpritRole.secret}',
            es: 'Cuando el ambiente en la villa cambio, ${culpritRole.name} aprovecho un breve momento sin ser visto al amparo del caos. ${culpritRole.secret}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Die falsche Spur',
            en: 'The false trail',
            fr: 'La fausse piste',
            es: 'La pista falsa',
          ),
          body: strings.tr(
            de: 'Direkt danach stuetzte sich ${culpritRole.name} auf das eigene Alibi und liess die Runde auf andere Konflikte schauen: ${culpritRole.alibi}',
            en: 'Right after that, ${culpritRole.name} leaned on their alibi and pushed the group toward other conflicts: ${culpritRole.alibi}',
            fr: 'Juste apres, ${culpritRole.name} s est appuye sur son alibi et a pousse le groupe a regarder d autres conflits : ${culpritRole.alibi}',
            es: 'Justo despues, ${culpritRole.name} se apoyo en su coartada e hizo que el grupo mirara otros conflictos: ${culpritRole.alibi}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Warum es aufflog',
            en: 'Why it unraveled',
            fr: 'Pourquoi tout a craque',
            es: 'Por que se descubrio',
          ),
          body: strings.tr(
            de: 'Die Widersprueche wurden am Ende zu deutlich. Besonders dieser Verdachtsmoment konnte nicht mehr erklaert werden: ${culpritRole.suspicion}',
            en: 'In the end, the contradictions became too obvious. This clue in particular could no longer be explained away: ${culpritRole.suspicion}',
            fr: 'A la fin, les contradictions sont devenues trop evidentes. Cet element en particulier ne pouvait plus etre explique : ${culpritRole.suspicion}',
            es: 'Al final, las contradicciones se volvieron demasiado evidentes. Este indicio en particular ya no pudo explicarse: ${culpritRole.suspicion}',
          ),
        ),
      ];
    case 'aurelia_express':
      return [
        _RevealBeat(
          title: strings.tr(
            de: 'Noch vor Mitternacht',
            en: 'Before midnight',
            fr: 'Avant minuit',
            es: 'Antes de medianoche',
          ),
          body: strings.tr(
            de: '${culpritRole.name} bereitete den Abend auf dem Zug lange vor und hielt den Druck bis zuletzt verborgen. ${culpritRole.motive}',
            en: '${culpritRole.name} prepared the evening on the train long in advance and kept the pressure hidden until the end. ${culpritRole.motive}',
            fr: '${culpritRole.name} a prepare la soiree dans le train bien a l avance et a cache la pression jusqu au bout. ${culpritRole.motive}',
            es: '${culpritRole.name} preparo la noche en el tren con mucha antelacion y oculto la presion hasta el final. ${culpritRole.motive}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Im Rhythmus des Zuges',
            en: 'In the rhythm of the train',
            fr: 'Au rythme du train',
            es: 'Al ritmo del tren',
          ),
          body: strings.tr(
            de: 'Zwischen Umsteigen, Geraeuschen und Bewegung bot der Zug genau das Zeitfenster, das fuer die Tat noetig war. ${culpritRole.secret}',
            en: 'Between transfers, noise and motion, the train offered exactly the window needed for the crime. ${culpritRole.secret}',
            fr: 'Entre les correspondances, les bruits et le mouvement, le train a offert exactement la fenetre necessaire au crime. ${culpritRole.secret}',
            es: 'Entre transbordos, ruidos y movimiento, el tren ofrecio exactamente la ventana necesaria para el crimen. ${culpritRole.secret}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Deckung',
            en: 'Cover',
            fr: 'Couverture',
            es: 'Cobertura',
          ),
          body: strings.tr(
            de: 'Danach stellte ${culpritRole.name} die eigene Version des Abends in den Vordergrund und klammerte sich an dieses Alibi: ${culpritRole.alibi}',
            en: 'Afterward, ${culpritRole.name} pushed their own version of the evening and clung to this alibi: ${culpritRole.alibi}',
            fr: 'Ensuite, ${culpritRole.name} a mis en avant sa propre version de la soiree et s est accroche a cet alibi : ${culpritRole.alibi}',
            es: 'Despues, ${culpritRole.name} puso en primer plano su propia version de la noche y se aferro a esta coartada: ${culpritRole.alibi}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Der Bruch in der Geschichte',
            en: 'The break in the story',
            fr: 'La faille dans le recit',
            es: 'La grieta en la historia',
          ),
          body: strings.tr(
            de: 'Erst spaeter fiel auf, dass ein Detail nie zu den restlichen Aussagen passte: ${culpritRole.suspicion}',
            en: 'Only later did it become clear that one detail never matched the other statements: ${culpritRole.suspicion}',
            fr: 'Ce n est que plus tard qu on a remarque qu un detail ne collait jamais avec les autres declarations : ${culpritRole.suspicion}',
            es: 'Solo mas tarde se noto que un detalle nunca encajaba con las otras declaraciones: ${culpritRole.suspicion}',
          ),
        ),
      ];
    case 'crimson_masquerade':
      return [
        _RevealBeat(
          title: strings.tr(
            de: 'Hinter der Maske',
            en: 'Behind the mask',
            fr: 'Derriere le masque',
            es: 'Detras de la mascara',
          ),
          body: strings.tr(
            de: 'Noch waehrend des Festes schob ${culpritRole.name} die eigenen Interessen ueber jede Loyalitaet. ${culpritRole.motive}',
            en: 'Even during the celebration, ${culpritRole.name} placed personal interests above every loyalty. ${culpritRole.motive}',
            fr: 'Pendant la fete, ${culpritRole.name} a place ses propres interets au-dessus de toute loyaute. ${culpritRole.motive}',
            es: 'Incluso durante la fiesta, ${culpritRole.name} puso sus propios intereses por encima de cualquier lealtad. ${culpritRole.motive}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Im Schatten des Balls',
            en: 'In the shadow of the ball',
            fr: 'Dans l ombre du bal',
            es: 'En la sombra del baile',
          ),
          body: strings.tr(
            de: 'Die Verkleidungen und die vielen Bewegungen im Saal verschafften genau die Tarnung, die fuer den Angriff gebraucht wurde. ${culpritRole.secret}',
            en: 'The disguises and constant movement in the hall created exactly the cover needed for the attack. ${culpritRole.secret}',
            fr: 'Les deguisements et les nombreux mouvements dans la salle ont offert exactement la couverture necessaire a l attaque. ${culpritRole.secret}',
            es: 'Los disfraces y el constante movimiento en el salon dieron exactamente la cobertura necesaria para el ataque. ${culpritRole.secret}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Inszenierte Ruhe',
            en: 'Staged calm',
            fr: 'Calme mis en scene',
            es: 'Calma fingida',
          ),
          body: strings.tr(
            de: 'Anschliessend praesentierte ${culpritRole.name} der Runde eine kontrollierte Version des Abends: ${culpritRole.alibi}',
            en: 'Afterward, ${culpritRole.name} presented the group with a controlled version of the evening: ${culpritRole.alibi}',
            fr: 'Ensuite, ${culpritRole.name} a presente au groupe une version maitrisee de la soiree : ${culpritRole.alibi}',
            es: 'Despues, ${culpritRole.name} presento al grupo una version controlada de la noche: ${culpritRole.alibi}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Der verratene Fehler',
            en: 'The betraying mistake',
            fr: 'L erreur revelatrice',
            es: 'El error revelador',
          ),
          body: strings.tr(
            de: 'Am Ende blieb eine Spur uebrig, die nicht mehr zu erklaeren war und alles umdrehte: ${culpritRole.suspicion}',
            en: 'In the end, one trace remained that could no longer be explained and turned everything around: ${culpritRole.suspicion}',
            fr: 'A la fin, il est reste une trace impossible a expliquer qui a tout fait basculer : ${culpritRole.suspicion}',
            es: 'Al final quedo un rastro que ya no pudo explicarse y lo cambio todo: ${culpritRole.suspicion}',
          ),
        ),
      ];
    case 'lantern_society':
      return [
        _RevealBeat(
          title: strings.tr(
            de: 'Vor der Zeremonie',
            en: 'Before the ceremony',
            fr: 'Avant la ceremonie',
            es: 'Antes de la ceremonia',
          ),
          body: strings.tr(
            de: '${culpritRole.name} trug den Konflikt schon in den ersten Minuten des Abends in sich. ${culpritRole.motive}',
            en: '${culpritRole.name} carried the conflict within from the very first minutes of the evening. ${culpritRole.motive}',
            fr: '${culpritRole.name} portait deja le conflit en lui des les premieres minutes de la soiree. ${culpritRole.motive}',
            es: '${culpritRole.name} ya llevaba el conflicto dentro desde los primeros minutos de la noche. ${culpritRole.motive}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Der Zugriff',
            en: 'The strike',
            fr: 'Le passage a l acte',
            es: 'La ejecucion',
          ),
          body: strings.tr(
            de: 'Zwischen Ritual, Kerzenlicht und Ablenkung entstand die Gelegenheit, den Plan umzusetzen. ${culpritRole.secret}',
            en: 'Between ritual, candlelight and distraction, the opportunity arose to carry out the plan. ${culpritRole.secret}',
            fr: 'Entre le rituel, les bougies et la diversion, l occasion de mettre le plan a execution est apparue. ${culpritRole.secret}',
            es: 'Entre el ritual, la luz de las velas y la distraccion, surgio la oportunidad de ejecutar el plan. ${culpritRole.secret}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Verdeckte Spuren',
            en: 'Hidden traces',
            fr: 'Traces couvertes',
            es: 'Huellas ocultas',
          ),
          body: strings.tr(
            de: 'Danach setzte ${culpritRole.name} darauf, dass dieses Alibi und die vielen Geheimnisse der Gruppe genug Schutz bieten wuerden: ${culpritRole.alibi}',
            en: 'Afterward, ${culpritRole.name} relied on this alibi and the group s many secrets to provide enough cover: ${culpritRole.alibi}',
            fr: 'Ensuite, ${culpritRole.name} a compte sur cet alibi et sur les nombreux secrets du groupe pour fournir une protection suffisante : ${culpritRole.alibi}',
            es: 'Despues, ${culpritRole.name} confio en que esta coartada y los muchos secretos del grupo le darian suficiente cobertura: ${culpritRole.alibi}',
          ),
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Die letzte Unstimmigkeit',
            en: 'The final inconsistency',
            fr: 'La derniere incoherence',
            es: 'La ultima incoherencia',
          ),
          body: strings.tr(
            de: 'Doch ausgerechnet ein scheinbar kleines Detail riss die Fassade ein: ${culpritRole.suspicion}',
            en: 'But of all things, one seemingly small detail tore down the facade: ${culpritRole.suspicion}',
            fr: 'Pourtant, un detail apparemment minime a fait tomber la facade : ${culpritRole.suspicion}',
            es: 'Pero justo un detalle aparentemente pequeno hizo caer la fachada: ${culpritRole.suspicion}',
          ),
        ),
      ];
    default:
      return [
        _RevealBeat(
          title: strings.tr(
            de: 'Motiv',
            en: 'Motive',
            fr: 'Mobile',
            es: 'Motivo',
          ),
          body: culpritRole.motive,
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Verdecktes Geheimnis',
            en: 'Hidden secret',
            fr: 'Secret cache',
            es: 'Secreto oculto',
          ),
          body: culpritRole.secret,
        ),
        _RevealBeat(
          title: strings.tr(
            de: 'Alibi und Bruchstelle',
            en: 'Alibi and weak point',
            fr: 'Alibi et faille',
            es: 'Coartada y punto debil',
          ),
          body: '${culpritRole.alibi}\n\n${culpritRole.suspicion}',
        ),
      ];
  }
}

@immutable
class _RevealBeat {
  const _RevealBeat({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class _TheoryPanel extends StatelessWidget {
  const _TheoryPanel({
    required this.lobby,
    required this.mysteryCase,
  });

  final LobbySession lobby;
  final MysteryCase mysteryCase;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    final culpritRole = _culpritRoleForCase(mysteryCase);
    if (culpritRole == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 22),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          strings.tr(
            de: 'Die Aufloesung fuer diesen Fall ist noch nicht hinterlegt.',
            en: 'The reveal for this case has not been added yet.',
            fr: 'La revelation pour cette affaire n est pas encore renseignee.',
            es: 'La resolucion de este caso todavia no esta preparada.',
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: AppPalette.gold.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr(
              de: 'Tathergang diskutieren',
              en: 'Discuss the reconstruction',
              fr: 'Discuter de la reconstruction',
              es: 'Debatir la reconstruccion',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppPalette.gold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.tr(
              de: '${culpritRole.name} war der Moerder.',
              en: '${culpritRole.name} was the culprit.',
              fr: '${culpritRole.name} etait le coupable.',
              es: '${culpritRole.name} era el culpable.',
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              de: 'Bevor die finale Rekonstruktion sichtbar wird, sammelt die Runde jetzt ihre Theorie zum Ablauf der Tat.',
              en: 'Before the final reconstruction becomes visible, the group now shares its theory about how the crime happened.',
              fr: 'Avant que la reconstruction finale ne devienne visible, le groupe rassemble maintenant sa theorie sur le deroulement du crime.',
              es: 'Antes de que se vea la reconstruccion final, el grupo comparte ahora su teoria sobre como ocurrio el crimen.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TheoryPromptChip(
                icon: Icons.schedule_rounded,
                label: strings.tr(
                  de: 'Wann kippte der Abend?',
                  en: 'When did the evening turn?',
                  fr: 'Quand la soiree a-t-elle bascule ?',
                  es: 'Cuando cambio la noche?',
                ),
              ),
              _TheoryPromptChip(
                icon: Icons.visibility_off_rounded,
                label: strings.tr(
                  de: 'Welche Gelegenheit wurde genutzt?',
                  en: 'What opportunity was used?',
                  fr: 'Quelle occasion a ete utilisee ?',
                  es: 'Que oportunidad se aprovecho?',
                ),
              ),
              _TheoryPromptChip(
                icon: Icons.alt_route_rounded,
                label: strings.tr(
                  de: 'Welche falsche Spur blieb zurueck?',
                  en: 'Which false trail was left behind?',
                  fr: 'Quelle fausse piste est restee ?',
                  es: 'Que pista falsa quedo atras?',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.03),
            ),
            child: Text(
              strings.tr(
                de: 'Diskutiert jetzt gemeinsam im Chat. Der Spielleiter kann anschliessend den genauen Tathergang aufdecken.',
                en: 'Discuss it together in the chat now. Afterwards, the host can reveal the exact reconstruction.',
                fr: 'Discutez-en maintenant ensemble dans le chat. Ensuite, l hote pourra reveler la reconstruction exacte.',
                es: 'Comentadlo ahora juntos en el chat. Despues, el host podra revelar la reconstruccion exacta.',
              ),
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.lobby,
    required this.mysteryCase,
  });

  final LobbySession lobby;
  final MysteryCase mysteryCase;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    final culpritRole = _culpritRoleForCase(mysteryCase);

    if (culpritRole == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 22),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          strings.tr(
            de: 'Die Aufloesung fuer diesen Fall ist noch nicht hinterlegt.',
            en: 'The reveal for this case has not been added yet.',
            fr: 'La revelation pour cette affaire n est pas encore renseignee.',
            es: 'La resolucion de este caso todavia no esta preparada.',
          ),
        ),
      );
    }

    final voteCounts = <String, int>{};
    for (final vote in lobby.votes) {
      voteCounts.update(vote.suspectRoleId, (value) => value + 1, ifAbsent: () => 1);
    }

    final sortedRoles = [...mysteryCase.roles]
      ..sort(
        (a, b) => (voteCounts[b.id] ?? 0).compareTo(voteCounts[a.id] ?? 0),
      );

    final messageCounts = <String, int>{};
    final directMessageCounts = <String, int>{};
    final reactionCounts = <String, int>{};
    for (final message in lobby.messages) {
      if (message.type == ChatMessageType.system ||
          message.type == ChatMessageType.evidence) {
        continue;
      }
      messageCounts.update(message.sender, (value) => value + 1, ifAbsent: () => 1);
      if (message.type == ChatMessageType.direct) {
        directMessageCounts.update(
          message.sender,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      for (final reaction in message.reactions) {
        reactionCounts.update(
          reaction.playerName,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final revealBeats = _buildRevealBeats(mysteryCase, culpritRole, strings);

    final playerRows = lobby.players.map((player) {
      final vote = lobby.votes.where((entry) => entry.voterPlayerId == player.id).firstOrNull;
      final guessedRole = vote == null
          ? null
          : mysteryCase.roles.where((role) => role.id == vote.suspectRoleId).firstOrNull;
      final guessedCorrectly = guessedRole?.id == culpritRole.id;
      return _PlayerSummaryRow(
        playerName: player.name,
        guessLabel: guessedRole?.name ??
            strings.tr(
              de: 'Keine Stimme',
              en: 'No vote',
              fr: 'Aucun vote',
              es: 'Sin voto',
            ),
        guessedCorrectly: guessedCorrectly,
        messageCount: messageCounts[player.name] ?? 0,
        directMessageCount: directMessageCounts[player.name] ?? 0,
        reactionCount: reactionCounts[player.name] ?? 0,
      );
    }).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.gold.withOpacity(0.16),
            Colors.purpleAccent.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: AppPalette.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr(
              de: 'Aufloesung',
              en: 'Reveal',
              fr: 'Revelation',
              es: 'Resolucion',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppPalette.gold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.tr(
              de: '${culpritRole.name} war der Moerder.',
              en: '${culpritRole.name} was the culprit.',
              fr: '${culpritRole.name} etait le coupable.',
              es: '${culpritRole.name} era el culpable.',
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              de: 'Motiv: ${culpritRole.motive}',
              en: 'Motive: ${culpritRole.motive}',
              fr: 'Mobile : ${culpritRole.motive}',
              es: 'Motivo: ${culpritRole.motive}',
            ),
          ),
          const SizedBox(height: 22),
          Text(
            strings.tr(
              de: 'Rekonstruktion des Abends',
              en: 'Reconstruction of the evening',
              fr: 'Reconstruction de la soiree',
              es: 'Reconstruccion de la noche',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          ...revealBeats.map(
            (beat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RevealBeatCard(beat: beat),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ResultMetric(
                label: strings.tr(
                  de: 'Richtige Tipps',
                  en: 'Correct guesses',
                  fr: 'Bons pronostics',
                  es: 'Aciertos',
                ),
                value: '${playerRows.where((row) => row.guessedCorrectly).length}',
              ),
              _ResultMetric(
                label: strings.tr(
                  de: 'Nachrichten',
                  en: 'Messages',
                  fr: 'Messages',
                  es: 'Mensajes',
                ),
                value: '${messageCounts.values.fold<int>(0, (a, b) => a + b)}',
              ),
              _ResultMetric(
                label: strings.tr(
                  de: 'Beweise',
                  en: 'Evidence',
                  fr: 'Preuves',
                  es: 'Pruebas',
                ),
                value: '${lobby.evidences.length}',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            strings.tr(
              de: 'Abstimmungsergebnis',
              en: 'Voting result',
              fr: 'Resultat du vote',
              es: 'Resultado de la votacion',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          ...sortedRoles.map(
            (role) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VoteResultBar(
                roleName: role.name,
                votes: voteCounts[role.id] ?? 0,
                totalPlayers: lobby.players.length,
                isCulprit: role.id == culpritRole.id,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.tr(
              de: 'Statistiken zum Schluss',
              en: 'Final statistics',
              fr: 'Statistiques finales',
              es: 'Estadisticas finales',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          ...playerRows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: row,
            ),
          ),
        ],
      ),
    );
  }
}

class _TheoryPromptChip extends StatelessWidget {
  const _TheoryPromptChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppPalette.gold),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _RevealBeatCard extends StatelessWidget {
  const _RevealBeatCard({
    required this.beat,
  });

  final _RevealBeat beat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            beat.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            beat.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceWindowContent extends StatelessWidget {
  const _EvidenceWindowContent({
    required this.evidences,
    required this.onOpenEvidence,
  });

  final List<GameEvidence> evidences;
  final ValueChanged<GameEvidence> onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    if (evidences.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            strings.tr(
              de: 'Noch keine Beweise freigegeben. Neue Briefe tauchen waehrend der naechsten Phasen auf.',
              en: 'No evidence has been released yet. New letters will appear during the next phases.',
              fr: 'Aucune preuve n a encore ete revelee. De nouvelles lettres apparaitront pendant les prochaines phases.',
              es: 'Todavia no se ha revelado ninguna prueba. Apareceran nuevas cartas durante las siguientes fases.',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.86,
      ),
      itemCount: evidences.length,
      itemBuilder: (context, index) {
        final evidence = evidences[index];
        return InkWell(
          onTap: () => onOpenEvidence(evidence),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Image.asset(
                      evidence.assetPath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evidence.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.tr(
                          de: 'Phase ${evidence.unlockedInPhase + 1}',
                          en: 'Phase ${evidence.unlockedInPhase + 1}',
                          fr: 'Phase ${evidence.unlockedInPhase + 1}',
                          es: 'Fase ${evidence.unlockedInPhase + 1}',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.58),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EvidenceOverlay extends StatelessWidget {
  const _EvidenceOverlay({
    required this.evidence,
    required this.onClose,
  });

  final GameEvidence evidence;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    final maxHeight = MediaQuery.of(context).size.height - 48;
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: maxHeight,
            ),
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFF151018),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 18, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              evidence.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close_rounded),
                            tooltip: strings.tr(
                              de: 'Fenster schliessen',
                              en: 'Close window',
                              fr: 'Fermer la fenetre',
                              es: 'Cerrar ventana',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          evidence.assetPath,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                      child: Text(
                        evidence.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      child: Text(
                        strings.tr(
                          de: 'Dieser Brief kann spaeter durch einen echten Hinweistext des Falls ersetzt werden.',
                          en: 'This letter can later be replaced by a real case clue text.',
                          fr: 'Cette lettre pourra plus tard etre remplacee par un vrai texte d indice du cas.',
                          es: 'Esta carta podra sustituirse mas tarde por un texto real de pista del caso.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.58),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleDossierContent extends StatelessWidget {
  const _RoleDossierContent({required this.role});

  final MysteryRole role;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DossierPill(label: role.name, icon: Icons.person_pin_rounded),
              _DossierPill(
                label: strings.tr(
                  de: 'Nur fuer dich',
                  en: 'Only for you',
                  fr: 'Seulement pour toi',
                  es: 'Solo para ti',
                ),
                icon: Icons.lock_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DossierEntry(
            title: strings.tr(
              de: 'Persoenlichkeit',
              en: 'Personality',
              fr: 'Personnalite',
              es: 'Personalidad',
            ),
            text: role.persona,
          ),
          _DossierEntry(
            title: strings.tr(
              de: 'Geheimnis',
              en: 'Secret',
              fr: 'Secret',
              es: 'Secreto',
            ),
            text: role.secret,
          ),
          _DossierEntry(
            title: strings.tr(
              de: 'Motiv',
              en: 'Motive',
              fr: 'Mobile',
              es: 'Motivo',
            ),
            text: role.motive,
          ),
          _DossierEntry(
            title: strings.tr(
              de: 'Beziehungen',
              en: 'Relationships',
              fr: 'Relations',
              es: 'Relaciones',
            ),
            text: role.relationships,
          ),
          _DossierEntry(
            title: strings.tr(
              de: 'Ziel',
              en: 'Goal',
              fr: 'Objectif',
              es: 'Objetivo',
            ),
            text: role.goal,
          ),
          _DossierEntry(
            title: strings.tr(
              de: 'Alibi',
              en: 'Alibi',
              fr: 'Alibi',
              es: 'Coartada',
            ),
            text: role.alibi,
          ),
          _DossierEntry(
            title: strings.tr(
              de: 'Verdachtsmoment',
              en: 'Suspicion',
              fr: 'Soupcon',
              es: 'Sospecha',
            ),
            text: role.suspicion,
          ),
          if (role.hiddenClues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              strings.tr(
                de: 'Versteckte Hinweise',
                en: 'Hidden clues',
                fr: 'Indices caches',
                es: 'Pistas ocultas',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            ...role.hiddenClues.map(
              (clue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: Colors.purpleAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        clue,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            strings.tr(
              de: 'Kostuemempfehlung',
              en: 'Outfit suggestion',
              fr: 'Suggestion de tenue',
              es: 'Sugerencia de vestuario',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.tr(
              de: 'Neutral: ${role.outfit.neutral}',
              en: 'Neutral: ${role.outfit.neutral}',
              fr: 'Neutre : ${role.outfit.neutral}',
              es: 'Neutro: ${role.outfit.neutral}',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tr(
              de: 'Maskulin: ${role.outfit.masculine}',
              en: 'Masculine: ${role.outfit.masculine}',
              fr: 'Masculin : ${role.outfit.masculine}',
              es: 'Masculino: ${role.outfit.masculine}',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tr(
              de: 'Feminin: ${role.outfit.feminine}',
              en: 'Feminine: ${role.outfit.feminine}',
              fr: 'Feminin : ${role.outfit.feminine}',
              es: 'Femenino: ${role.outfit.feminine}',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tr(
              de: 'Accessoires: ${role.outfit.accessories.join(', ')}',
              en: 'Accessories: ${role.outfit.accessories.join(', ')}',
              fr: 'Accessoires : ${role.outfit.accessories.join(', ')}',
              es: 'Accesorios: ${role.outfit.accessories.join(', ')}',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tr(
              de: 'Make-up: ${role.outfit.makeup}',
              en: 'Makeup: ${role.outfit.makeup}',
              fr: 'Maquillage : ${role.outfit.makeup}',
              es: 'Maquillaje: ${role.outfit.makeup}',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tr(
              de: 'Frisur: ${role.outfit.hairstyle}',
              en: 'Hairstyle: ${role.outfit.hairstyle}',
              fr: 'Coiffure : ${role.outfit.hairstyle}',
              es: 'Peinado: ${role.outfit.hairstyle}',
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NotesWindowContent extends StatefulWidget {
  const _NotesWindowContent({
    required this.lobbyCode,
    required this.lobby,
    required this.mysteryCase,
    required this.generalNotesController,
    required this.onSaveGeneral,
  });

  final String lobbyCode;
  final LobbySession lobby;
  final MysteryCase mysteryCase;
  final TextEditingController generalNotesController;
  final VoidCallback onSaveGeneral;

  @override
  State<_NotesWindowContent> createState() => _NotesWindowContentState();
}

class _NotesWindowContentState extends State<_NotesWindowContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _playerControllers = {};

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  void _initTabs() {
    final count = 1 + widget.lobby.players.length;
    _tabController = TabController(length: count, vsync: this);

    for (final player in widget.lobby.players) {
      if (_playerControllers.containsKey(player.id)) {
        continue;
      }
      final controller = TextEditingController();
      _playerControllers[player.id] = controller;
      _loadPlayerNotes(player);
    }
  }

  @override
  void didUpdateWidget(covariant _NotesWindowContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lobby.players.length != widget.lobby.players.length) {
      _tabController.dispose();
      _initTabs();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _playerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPlayerNotes(LobbyPlayer player) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'player_notes_${widget.lobbyCode}_${player.id}';
    final saved = prefs.getString(key);
    if (saved != null) {
      _playerControllers[player.id]?.text = saved;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final role = _roleNameForPlayer(player);
    final strings = _stringsOf(context);
    final defaultText =
        strings.tr(
          de: 'Echter Name: ${player.name}${role == null ? '' : '\nRolle: $role'}\n\n',
          en: 'Real name: ${player.name}${role == null ? '' : '\nRole: $role'}\n\n',
          fr: 'Nom reel : ${player.name}${role == null ? '' : '\nRole : $role'}\n\n',
          es: 'Nombre real: ${player.name}${role == null ? '' : '\nRol: $role'}\n\n',
        );
    _playerControllers[player.id]?.text = defaultText;
    await prefs.setString(key, defaultText);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _savePlayerNotes(LobbyPlayer player) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'player_notes_${widget.lobbyCode}_${player.id}';
    await prefs.setString(key, _playerControllers[player.id]?.text ?? '');
  }

  String? _roleNameForPlayer(LobbyPlayer player) {
    final roleId = widget.lobby.roleAssignments[player.id];
    if (roleId == null) {
      return null;
    }
    return widget.mysteryCase.roles
        .where((role) => role.id == roleId)
        .firstOrNull
        ?.name;
  }

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    final players = widget.lobby.players;
    return Column(
      children: [
        Container(
          color: Colors.white.withOpacity(0.03),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.tealAccent,
            indicatorWeight: 2,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            dividerColor: Colors.white12,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notes_rounded, size: 14),
                    SizedBox(width: 6),
                    Text(
                      strings.tr(
                        de: 'Allgemein',
                        en: 'General',
                        fr: 'General',
                        es: 'General',
                      ),
                    ),
                  ],
                ),
              ),
              ...players.map((player) {
                final roleName = _roleNameForPlayer(player);
                return Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        roleName ?? player.name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (roleName != null)
                        Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.42),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _NoteEditor(
                controller: widget.generalNotesController,
                hint: strings.tr(
                  de: 'Allgemeine Notizen: Verdaechtige, Alibis, offene Fragen...',
                  en: 'General notes: suspects, alibis, open questions...',
                  fr: 'Notes generales : suspects, alibis, questions ouvertes...',
                  es: 'Notas generales: sospechosos, coartadas, preguntas abiertas...',
                ),
                accentColor: Colors.tealAccent,
                onChanged: widget.onSaveGeneral,
              ),
              ...players.map((player) {
                final controller =
                    _playerControllers[player.id] ?? TextEditingController();
                final roleName = _roleNameForPlayer(player);
                return _NoteEditor(
                  controller: controller,
                  hint: strings.tr(
                    de: 'Notizen zu ${roleName ?? player.name} (${player.name})...',
                    en: 'Notes about ${roleName ?? player.name} (${player.name})...',
                    fr: 'Notes sur ${roleName ?? player.name} (${player.name})...',
                    es: 'Notas sobre ${roleName ?? player.name} (${player.name})...',
                  ),
                  accentColor: Colors.tealAccent,
                  headerText:
                      roleName == null ? player.name : '$roleName | ${player.name}',
                  onChanged: () => _savePlayerNotes(player),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteEditor extends StatelessWidget {
  const _NoteEditor({
    required this.controller,
    required this.hint,
    required this.accentColor,
    required this.onChanged,
    this.headerText,
  });

  final TextEditingController controller;
  final String hint;
  final Color accentColor;
  final VoidCallback onChanged;
  final String? headerText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (headerText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: accentColor.withOpacity(0.08),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Text(
                headerText!,
                style: TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              onChanged: (_) => onChanged(),
              style: const TextStyle(fontSize: 13, height: 1.6),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor.withOpacity(0.4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarToggle extends StatelessWidget {
  const _AppBarToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isActive
                ? activeColor.withOpacity(0.18)
                : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: isActive ? activeColor.withOpacity(0.45) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? activeColor : Colors.white54,
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: activeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardChip extends StatelessWidget {
  const _BoardChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppPalette.gold.withOpacity(0.08),
        border: Border.all(color: AppPalette.gold.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.gold),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.avatar,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.tealAccent : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isSelected
              ? Colors.tealAccent.withOpacity(0.16)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color:
                isSelected ? Colors.tealAccent.withOpacity(0.35) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              CircleAvatar(
                radius: 11,
                backgroundColor: Colors.white.withOpacity(0.08),
                child: Text(
                  avatar!,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineTypePill extends StatelessWidget {
  const _InlineTypePill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EvidenceMessageCard extends StatelessWidget {
  const _EvidenceMessageCard({
    required this.evidence,
    required this.message,
    required this.onOpen,
  });

  final GameEvidence evidence;
  final ChatMessage message;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.asset(
                evidence.assetPath,
                width: double.infinity,
                height: 132,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evidence.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.body,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.tr(
                      de: 'Zum Oeffnen antippen',
                      en: 'Tap to open',
                      fr: 'Toucher pour ouvrir',
                      es: 'Tocar para abrir',
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppPalette.gold,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.animate,
  });

  final String emoji;
  final int count;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    if (!animate) {
      return chip;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: chip,
    );
  }
}

class _VoteRoleCard extends StatelessWidget {
  const _VoteRoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final MysteryRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected
              ? AppPalette.gold.withOpacity(0.16)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: isSelected
                ? AppPalette.gold.withOpacity(0.45)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              role.persona,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.gold,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _VoteResultBar extends StatelessWidget {
  const _VoteResultBar({
    required this.roleName,
    required this.votes,
    required this.totalPlayers,
    required this.isCulprit,
  });

  final String roleName;
  final int votes;
  final int totalPlayers;
  final bool isCulprit;

  @override
  Widget build(BuildContext context) {
    final ratio = totalPlayers == 0 ? 0.0 : votes / totalPlayers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                roleName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (isCulprit)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.gpp_maybe_rounded,
                  size: 18,
                  color: AppPalette.gold,
                ),
              ),
            Text('$votes'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: ratio,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              isCulprit ? AppPalette.gold : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerSummaryRow extends StatelessWidget {
  const _PlayerSummaryRow({
    required this.playerName,
    required this.guessLabel,
    required this.guessedCorrectly,
    required this.messageCount,
    required this.directMessageCount,
    required this.reactionCount,
  });

  final String playerName;
  final String guessLabel;
  final bool guessedCorrectly;
  final int messageCount;
  final int directMessageCount;
  final int reactionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  playerName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Icon(
                guessedCorrectly
                    ? Icons.check_circle_rounded
                    : Icons.cancel_outlined,
                size: 18,
                color: guessedCorrectly ? AppPalette.gold : Colors.white54,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.tr(
              de: 'Tipp: $guessLabel',
              en: 'Guess: $guessLabel',
              fr: 'Choix : $guessLabel',
              es: 'Sospecha: $guessLabel',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallStatPill(
                label: strings.tr(
                  de: '$messageCount Nachrichten',
                  en: '$messageCount messages',
                  fr: '$messageCount messages',
                  es: '$messageCount mensajes',
                ),
              ),
              _SmallStatPill(
                label: strings.tr(
                  de: '$directMessageCount privat',
                  en: '$directMessageCount private',
                  fr: '$directMessageCount prives',
                  es: '$directMessageCount privados',
                ),
              ),
              _SmallStatPill(
                label: strings.tr(
                  de: '$reactionCount Reaktionen',
                  en: '$reactionCount reactions',
                  fr: '$reactionCount reactions',
                  es: '$reactionCount reacciones',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStatPill extends StatelessWidget {
  const _SmallStatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _DossierEntry extends StatelessWidget {
  const _DossierEntry({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.purpleAccent.withOpacity(0.9),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DossierPill extends StatelessWidget {
  const _DossierPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.purpleAccent.withOpacity(0.12),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.purpleAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.purpleAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
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



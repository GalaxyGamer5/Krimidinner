import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_window.dart';
import '../widgets/mystery_shell.dart';

// Which floating windows are currently open
enum _WindowId { chat, notes, role }

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
  final ScrollController _chatScrollCtrl = ScrollController();

  final Set<_WindowId> _openWindows = {};

  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadGeneralNotes();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _saveGeneralNotes();
    _chatController.dispose();
    _generalNotesController.dispose();
    _chatScrollCtrl.dispose();
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _loadGeneralNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notes = prefs.getString('game_notes_${widget.code}') ?? '';
    if (mounted) _generalNotesController.text = notes;
  }

  Future<void> _saveGeneralNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'game_notes_${widget.code}', _generalNotesController.text);
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    final state = ref.read(mysteryControllerProvider);
    if (text.isNotEmpty) {
      ref.read(mysteryControllerProvider.notifier).sendLobbyMessage(
            code: widget.code,
            sender: state.localAlias,
            body: text,
          );
      _chatController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollCtrl.hasClients) {
          _chatScrollCtrl.animateTo(
            _chatScrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mysteryControllerProvider);
    final lobby =
        state.lobbies.where((l) => l.code == widget.code).firstOrNull;
    final mysteryCase =
        lobby != null ? ref.watch(mysteryCaseProvider(lobby.caseId)) : null;

    if (lobby == null || mysteryCase == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spielsitzung')),
        body: const Center(child: Text('Lobby oder Fall nicht gefunden.')),
      );
    }

    final viewer = lobby.players
        .where((p) => p.name.toLowerCase() == state.localAlias.toLowerCase())
        .firstOrNull;
    final isHost = viewer?.id == lobby.hostId;
    final currentPhase = mysteryCase.phases[lobby.phaseIndex];

    String? viewerRoleId;
    if (viewer != null) viewerRoleId = lobby.roleAssignments[viewer.id];
    final viewerRole = viewerRoleId != null
        ? mysteryCase.roles
            .where((r) => r.id == viewerRoleId)
            .firstOrNull
        : null;

    Duration remaining = Duration.zero;
    if (lobby.hasStarted && lobby.phaseStartedAt != null) {
      final phaseEnd = lobby.phaseStartedAt!
          .add(Duration(minutes: currentPhase.durationMinutes));
      final rem = phaseEnd.difference(_now);
      remaining = rem.isNegative ? Duration.zero : rem;
    }

    return Scaffold(
      backgroundColor: AppPalette.noir,
      appBar: _buildAppBar(
          context, mysteryCase, lobby, viewerRole, isHost, remaining),
      body: Stack(
        children: [
          // ── Main Game Board ──
          _buildGameBoard(
              context, lobby, mysteryCase, currentPhase, isHost),

          // ── Floating: Chat ──
          if (_openWindows.contains(_WindowId.chat))
            FloatingWindow(
              title: 'Chat & Spielerliste',
              icon: Icons.chat_rounded,
              initialOffset: const Offset(40, 100),
              width: 360,
              height: 520,
              accentColor: AppPalette.gold,
              onClose: () => _toggleWindow(_WindowId.chat),
              child: _buildChatContent(context, lobby),
            ),

          // ── Floating: Notes (tabbed) ──
          if (_openWindows.contains(_WindowId.notes))
            FloatingWindow(
              title: 'Meine Notizen',
              icon: Icons.edit_note_rounded,
              initialOffset: const Offset(120, 100),
              width: 420,
              height: 520,
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

          // ── Floating: Role Dossier ──
          if (_openWindows.contains(_WindowId.role) && viewerRole != null)
            FloatingWindow(
              title: 'Meine Rolle: ${viewerRole.name}',
              icon: Icons.menu_book_rounded,
              initialOffset: const Offset(200, 80),
              width: 400,
              height: 560,
              accentColor: Colors.purpleAccent,
              onClose: () => _toggleWindow(_WindowId.role),
              child: _buildRoleDossierContent(context, viewerRole),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // App Bar
  // ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MysteryCase mysteryCase,
    LobbySession lobby,
    MysteryRole? viewerRole,
    bool isHost,
    Duration remaining,
  ) {
    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return AppBar(
      backgroundColor: AppPalette.midnight,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Zurück zur Lobby',
        onPressed: () => context.go('/lobbies/room/${widget.code}'),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mysteryCase.title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(
            'Phase ${lobby.phaseIndex + 1}/${mysteryCase.phases.length}  ·  $mm:$ss',
            style:
                TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
          ),
        ],
      ),
      actions: [
        _AppBarToggle(
          icon: Icons.chat_rounded,
          label: 'Chat',
          isActive: _openWindows.contains(_WindowId.chat),
          activeColor: AppPalette.gold,
          onTap: () => _toggleWindow(_WindowId.chat),
        ),
        const SizedBox(width: 4),
        _AppBarToggle(
          icon: Icons.edit_note_rounded,
          label: 'Notizen',
          isActive: _openWindows.contains(_WindowId.notes),
          activeColor: Colors.tealAccent,
          onTap: () => _toggleWindow(_WindowId.notes),
        ),
        const SizedBox(width: 4),
        if (viewerRole != null)
          _AppBarToggle(
            icon: Icons.menu_book_rounded,
            label: 'Meine Rolle',
            isActive: _openWindows.contains(_WindowId.role),
            activeColor: Colors.purpleAccent,
            onTap: () => _toggleWindow(_WindowId.role),
          ),
        const SizedBox(width: 12),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Game Board
  // ─────────────────────────────────────────────────────────────

  Widget _buildGameBoard(
    BuildContext context,
    LobbySession lobby,
    MysteryCase mysteryCase,
    GamePhase currentPhase,
    bool isHost,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border:
                      Border.all(color: AppPalette.gold.withOpacity(0.4)),
                  color: AppPalette.gold.withOpacity(0.08),
                ),
                child: Text(
                  'Phase ${lobby.phaseIndex + 1} von ${mysteryCase.phases.length}',
                  style: const TextStyle(
                    color: AppPalette.gold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                currentPhase.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppPalette.parchment,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  currentPhase.description,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        height: 1.65,
                        color: AppPalette.parchment.withOpacity(0.88),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 52),
              if (isHost)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!lobby.isCompleted)
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(mysteryControllerProvider.notifier)
                            .advancePhase(widget.code),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.gold,
                          foregroundColor: AppPalette.noir,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: Text(
                          lobby.phaseIndex < mysteryCase.phases.length - 1
                              ? 'Nächste Phase'
                              : 'Fall abschließen',
                        ),
                      ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.04),
                  ),
                  child: Text(
                    'Warte auf den Host...',
                    style:
                        TextStyle(color: Colors.white.withOpacity(0.45)),
                  ),
                ),
              if (lobby.isCompleted) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: [
                      AppPalette.gold.withOpacity(0.15),
                      Colors.purpleAccent.withOpacity(0.1),
                    ]),
                    border:
                        Border.all(color: AppPalette.gold.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color: AppPalette.gold, size: 28),
                      SizedBox(width: 14),
                      Text(
                        'Fall gelöst! Herzlichen Glückwunsch!',
                        style: TextStyle(
                          color: AppPalette.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Chat Content
  // ─────────────────────────────────────────────────────────────

  Widget _buildChatContent(BuildContext context, LobbySession lobby) {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white.withOpacity(0.03),
          child: Row(
            children: lobby.players.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Tooltip(
                  message: p.name + (p.isHost ? ' (Host)' : ''),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: p.isHost
                        ? AppPalette.gold.withOpacity(0.25)
                        : Colors.white.withOpacity(0.1),
                    child: Text(
                      p.name[0].toUpperCase(),
                      style: TextStyle(
                        color: p.isHost ? AppPalette.gold : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        Expanded(
          child: ListView.builder(
            controller: _chatScrollCtrl,
            padding: const EdgeInsets.all(14),
            itemCount: lobby.messages.length,
            itemBuilder: (context, index) {
              final msg = lobby.messages[index];
              final isSystem = msg.type == ChatMessageType.system;
              if (isSystem) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Text(
                      msg.body,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final isMine = msg.sender ==
                  ref.read(mysteryControllerProvider).localAlias;
              return Align(
                alignment: isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 270),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    color: isMine
                        ? AppPalette.gold.withOpacity(0.18)
                        : Colors.white.withOpacity(0.07),
                  ),
                  child: Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.sender,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isMine
                              ? AppPalette.gold
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(msg.body,
                          style: const TextStyle(
                              fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: Colors.white12))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nachricht...',
                    hintStyle:
                        TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendChatMessage,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppPalette.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: AppPalette.gold, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Role Dossier Content
  // ─────────────────────────────────────────────────────────────

  Widget _buildRoleDossierContent(
      BuildContext context, MysteryRole role) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DossierPill(
                  label: role.name,
                  icon: Icons.person_pin_rounded),
              _DossierPill(
                  label: role.outfit.palette.join(' / '),
                  icon: Icons.palette_outlined),
            ],
          ),
          const SizedBox(height: 20),
          _DossierEntry(title: 'Persönlichkeit', text: role.persona),
          _DossierEntry(title: 'Geheimnis', text: role.secret),
          _DossierEntry(title: 'Motiv', text: role.motive),
          _DossierEntry(title: 'Ziel', text: role.goal),
          _DossierEntry(title: 'Alibi', text: role.alibi),
          _DossierEntry(
              title: 'Verdachtsmoment', text: role.suspicion),
          _DossierEntry(
              title: 'Beziehungen', text: role.relationships),
          if (role.hiddenClues.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Versteckte Hinweise',
                style: TextStyle(
                    color: Colors.purpleAccent.withOpacity(0.8),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            ...role.hiddenClues.map((clue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle,
                            size: 6,
                            color: Colors.purpleAccent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(clue,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.5))),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 12),
          Text('Kostüm',
              style: TextStyle(
                  color: Colors.purpleAccent.withOpacity(0.8),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text('• ${role.outfit.neutral}',
              style: const TextStyle(fontSize: 13)),
          ...role.outfit.accessories.map(
              (a) => Text('• $a',
                  style: const TextStyle(fontSize: 13))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Tabbed Notes Window
// ══════════════════════════════════════════════════════════════

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

  // playerNotes[playerId] = TextEditingController
  final Map<String, TextEditingController> _playerControllers = {};

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  void _initTabs() {
    // tabs = "Allgemein" + one per player (excluding self? No – include all)
    final count = 1 + widget.lobby.players.length;
    _tabController =
        TabController(length: count, vsync: this);

    // Create controllers & load notes per player
    for (final player in widget.lobby.players) {
      if (!_playerControllers.containsKey(player.id)) {
        final ctrl = TextEditingController();
        _playerControllers[player.id] = ctrl;
        _loadPlayerNotes(player);
      }
    }
  }

  @override
  void didUpdateWidget(_NotesWindowContent old) {
    super.didUpdateWidget(old);
    // If players changed, re-init tabs
    if (old.lobby.players.length != widget.lobby.players.length) {
      _tabController.dispose();
      _initTabs();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final ctrl in _playerControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPlayerNotes(LobbyPlayer player) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'player_notes_${widget.lobbyCode}_${player.id}';
    final saved = prefs.getString(key);
    if (saved != null) {
      _playerControllers[player.id]?.text = saved;
    } else {
      // Default: show the player's real name as first line
      final role = _roleNameForPlayer(player);
      final defaultText =
          'Echter Name: ${player.name}${role != null ? '\nRolle: $role' : ''}\n\n';
      _playerControllers[player.id]?.text = defaultText;
      await prefs.setString(key, defaultText);
    }
    if (mounted) setState(() {});
  }

  Future<void> _savePlayerNotes(LobbyPlayer player) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'player_notes_${widget.lobbyCode}_${player.id}';
    final text = _playerControllers[player.id]?.text ?? '';
    await prefs.setString(key, text);
  }

  String? _roleNameForPlayer(LobbyPlayer player) {
    final roleId = widget.lobby.roleAssignments[player.id];
    if (roleId == null) return null;
    return widget.mysteryCase.roles
        .where((r) => r.id == roleId)
        .firstOrNull
        ?.name;
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.lobby.players;

    return Column(
      children: [
        // ── Tab Bar ──
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
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            dividerColor: Colors.white12,
            tabs: [
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notes_rounded, size: 14),
                    SizedBox(width: 6),
                    Text('Allgemein'),
                  ],
                ),
              ),
              ...players.map((p) {
                final roleName = _roleNameForPlayer(p);
                return Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        roleName ?? p.name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (roleName != null)
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.4),
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

        // ── Tab Views ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // General notes tab
              _NoteEditor(
                controller: widget.generalNotesController,
                hint:
                    'Allgemeine Notizen: Verdächtige, Alibis, offene Fragen...',
                accentColor: Colors.tealAccent,
                onChanged: widget.onSaveGeneral,
              ),

              // One tab per player
              ...players.map((p) {
                final ctrl = _playerControllers[p.id] ??
                    TextEditingController();
                final roleName = _roleNameForPlayer(p);
                return _NoteEditor(
                  controller: ctrl,
                  hint:
                      'Notizen zu ${roleName ?? p.name} (${p.name})...',
                  accentColor: Colors.tealAccent,
                  headerText: roleName != null
                      ? '${roleName}  ·  ${p.name}'
                      : p.name,
                  onChanged: () => _savePlayerNotes(p),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Single note editor (used in each tab)
// ──────────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: accentColor.withOpacity(0.08),
                border:
                    Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Text(
                headerText!,
                style: TextStyle(
                    fontSize: 12,
                    color: accentColor,
                    fontWeight: FontWeight.w700),
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
                hintStyle:
                    TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: accentColor.withOpacity(0.4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Small UI helpers
// ══════════════════════════════════════════════════════════════

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
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isActive
                ? activeColor.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: isActive
                  ? activeColor.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? activeColor : Colors.white54),
              if (isActive) ...[
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: activeColor,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DossierEntry extends StatelessWidget {
  const _DossierEntry({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.purpleAccent.withOpacity(0.8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(text,
              style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _DossierPill extends StatelessWidget {
  const _DossierPill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.purpleAccent.withOpacity(0.12),
        border:
            Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.purpleAccent),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

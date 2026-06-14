import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/demo_catalog.dart';
import '../models/mystery_models.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final appSettingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final mysteryCatalogProvider = Provider<List<MysteryCase>>((ref) {
  return demoMysteryCases;
});

final mysteryCaseProvider =
    Provider.family<MysteryCase?, String>((ref, caseId) {
  return findMysteryCaseById(caseId);
});

final mysteryControllerProvider =
    NotifierProvider<MysteryController, MysteryState>(MysteryController.new);

final lobbyProvider = Provider.family<LobbySession?, String>((ref, code) {
  final lobbies = ref.watch(mysteryControllerProvider).lobbies;
  for (final lobby in lobbies) {
    if (lobby.code == code) {
      return lobby;
    }
  }
  return null;
});

final playerStatsProvider = Provider<PlayerStats>((ref) {
  final state = ref.watch(mysteryControllerProvider);
  final completedGames =
      state.lobbies.where((lobby) => lobby.isCompleted).length;
  final revealedHints = state.lobbies.fold<int>(
    0,
    (total, lobby) => total + lobby.revealedHintIds.length,
  );
  final favoriteRole = state.roleArchive.isNotEmpty
      ? state.roleArchive.last.characterName
      : 'Gastgeber';
  final favoriteScenario = state.roleArchive.isNotEmpty
      ? state.roleArchive.last.caseTitle
      : 'Villa No. 7';

  return PlayerStats(
    gamesPlayed: 3 + completedGames,
    gamesWon: 2 + max(0, completedGames - 1),
    detectiveFinds: 4 + revealedHints,
    hoursPlayed: 6.5 + (state.lobbies.length * 0.8),
    favoriteRole: favoriteRole,
    favoriteScenario: favoriteScenario,
  );
});

final achievementsProvider = Provider<List<Achievement>>((ref) {
  final state = ref.watch(mysteryControllerProvider);
  final stats = ref.watch(playerStatsProvider);
  final totalHints = state.lobbies.fold<int>(
    0,
    (value, lobby) => value + lobby.revealedHintIds.length,
  );
  final activeLobbies =
      state.lobbies.where((lobby) => !lobby.isCompleted).length;

  return [
    Achievement(
      title: 'Meisterdetektiv',
      description: 'Schliesse mehrere Faelle erfolgreich ab.',
      progress: stats.gamesPlayed.toDouble(),
      target: 8,
      icon: Icons.search_rounded,
    ),
    Achievement(
      title: 'Unauffaelliger Taeter',
      description: 'Verwalte mehrere Rollen, ohne deine Spuren preiszugeben.',
      progress: state.roleArchive.length.toDouble(),
      target: 6,
      icon: Icons.visibility_off_rounded,
    ),
    Achievement(
      title: 'Hinweisjaeger',
      description: 'Schalte Hinweise ueber mehrere Partien hinweg frei.',
      progress: totalHints.toDouble(),
      target: 14,
      icon: Icons.local_police_rounded,
    ),
    Achievement(
      title: 'Netzwerk im Nebel',
      description: 'Halte parallel mehrere Lobbys aktiv.',
      progress: activeLobbies.toDouble(),
      target: 3,
      icon: Icons.groups_rounded,
    ),
  ];
});

class SettingsController extends Notifier<AppSettings> {
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _musicKey = 'music_volume';
  static const _sfxKey = 'sfx_volume';
  static const _animationsKey = 'animations_enabled';
  static const _notificationsKey = 'notifications_enabled';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final defaults = AppSettings.defaults();
    return AppSettings(
      themeMode:
          _readThemeMode(_prefs.getString(_themeKey)) ?? defaults.themeMode,
      language:
          _readLanguage(_prefs.getString(_languageKey)) ?? defaults.language,
      musicVolume: _prefs.getDouble(_musicKey) ?? defaults.musicVolume,
      sfxVolume: _prefs.getDouble(_sfxKey) ?? defaults.sfxVolume,
      animationsEnabled:
          _prefs.getBool(_animationsKey) ?? defaults.animationsEnabled,
      notificationsEnabled:
          _prefs.getBool(_notificationsKey) ?? defaults.notificationsEnabled,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString(_themeKey, mode.name);
  }

  void setLanguage(AppLanguage language) {
    state = state.copyWith(language: language);
    _prefs.setString(_languageKey, language.code);
  }

  void setMusicVolume(double value) {
    state = state.copyWith(musicVolume: value);
    _prefs.setDouble(_musicKey, value);
  }

  void setSfxVolume(double value) {
    state = state.copyWith(sfxVolume: value);
    _prefs.setDouble(_sfxKey, value);
  }

  void toggleAnimations(bool enabled) {
    state = state.copyWith(animationsEnabled: enabled);
    _prefs.setBool(_animationsKey, enabled);
  }

  void toggleNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    _prefs.setBool(_notificationsKey, enabled);
  }

  ThemeMode? _readThemeMode(String? raw) {
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return null;
  }

  AppLanguage? _readLanguage(String? raw) {
    for (final language in AppLanguage.values) {
      if (language.code == raw) {
        return language;
      }
    }
    return null;
  }
}

class MysteryController extends Notifier<MysteryState> {
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  static const List<String> _demoGuestNames = [
    'Mara Quinn',
    'Felix Ward',
    'Lina Frost',
    'Jonas Reed',
    'Helena Shaw',
    'Victor Hale',
  ];

  @override
  MysteryState build() {
    return const MysteryState(
      localAlias: 'Detective Nova',
      lobbies: [],
      roleArchive: [],
      friends: [
        FriendProfile(
          name: 'Lea Stern',
          favoriteScenario: 'Villa No. 7',
          favoriteRole: 'Journalistin',
          lastSeen: 'Heute, 19:10',
          isOnline: true,
        ),
        FriendProfile(
          name: 'Jonah Black',
          favoriteScenario: 'Aurelia Express',
          favoriteRole: 'Schaffner',
          lastSeen: 'Gestern, 22:40',
          isOnline: false,
        ),
        FriendProfile(
          name: 'Sofia Vale',
          favoriteScenario: 'Lantern Society',
          favoriteRole: 'Archivarin',
          lastSeen: 'Heute, 16:05',
          isOnline: true,
        ),
      ],
    );
  }

  void updateAlias(String alias) {
    final trimmed = alias.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = state.copyWith(localAlias: trimmed);
  }

  String createLobby({
    required MysteryCase mysteryCase,
    required String hostName,
  }) {
    final trimmed =
        hostName.trim().isEmpty ? state.localAlias : hostName.trim();
    final player = LobbyPlayer(
      id: _uuid.v4(),
      name: trimmed,
      joinedAt: DateTime.now(),
      isHost: true,
      isOnline: true,
    );
    final code = _generateCode();
    final inviteLink = 'https://mysterynight.app/join/$code';

    var lobby = LobbySession(
      code: code,
      caseId: mysteryCase.id,
      inviteLink: inviteLink,
      hostId: player.id,
      createdAt: DateTime.now(),
      players: [player],
      roleAssignments: const {},
      messages: [
        _systemMessage('Lobby $code wurde eroeffnet. Einladungslink bereit.'),
      ],
      revealedHintIds: const [],
      phaseIndex: 0,
      hasStarted: false,
      isCompleted: false,
    );

    lobby = _assignRoles(lobby, mysteryCase);

    var nextState = state.copyWith(
      localAlias: trimmed,
      lobbies: [lobby, ...state.lobbies],
    );
    nextState = _rememberRole(nextState, lobby, trimmed);
    state = nextState;

    return code;
  }

  String? joinLobby({
    required String code,
    required String alias,
  }) {
    final lobbyIndex = _indexOfLobby(code.trim().toUpperCase());
    if (lobbyIndex == -1) {
      return 'Lobby-Code nicht gefunden.';
    }

    final trimmedAlias = alias.trim();
    if (trimmedAlias.isEmpty) {
      return 'Bitte gib einen Spielernamen ein.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return 'Der Fall fuer diese Lobby ist nicht mehr verfuegbar.';
    }

    if (lobby.players.length >= mysteryCase.roles.length) {
      return 'Diese Lobby ist bereits voll.';
    }

    final duplicateName = lobby.players.any(
      (player) => player.name.toLowerCase() == trimmedAlias.toLowerCase(),
    );
    if (duplicateName) {
      return 'Dieser Spielername ist bereits vergeben.';
    }

    final player = LobbyPlayer(
      id: _uuid.v4(),
      name: trimmedAlias,
      joinedAt: DateTime.now(),
      isHost: false,
      isOnline: true,
    );

    var updatedLobby = lobby.copyWith(
      players: [...lobby.players, player],
      messages: [
        ...lobby.messages,
        _systemMessage('$trimmedAlias ist der Lobby beigetreten.'),
      ],
    );
    updatedLobby = _assignRoles(updatedLobby, mysteryCase);

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;

    var nextState = state.copyWith(
      localAlias: trimmedAlias,
      lobbies: updatedLobbies,
    );
    nextState = _rememberRole(nextState, updatedLobby, trimmedAlias);
    state = nextState;

    return null;
  }

  int addDemoGuests(String code) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 0;
    }

    final lobby = state.lobbies[lobbyIndex];
    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return 0;
    }

    final slots = mysteryCase.roles.length - lobby.players.length;
    if (slots <= 0) {
      return 0;
    }

    final availableNames = _demoGuestNames.where(
      (name) => !lobby.players.any(
        (player) => player.name.toLowerCase() == name.toLowerCase(),
      ),
    );

    final toAdd = availableNames.take(min(slots, 3)).toList();
    if (toAdd.isEmpty) {
      return 0;
    }

    final guests = toAdd
        .map(
          (name) => LobbyPlayer(
            id: _uuid.v4(),
            name: name,
            joinedAt: DateTime.now(),
            isHost: false,
            isOnline: true,
          ),
        )
        .toList();

    var updatedLobby = lobby.copyWith(
      players: [...lobby.players, ...guests],
      messages: [
        ...lobby.messages,
        _systemMessage(
          '${guests.length} Demo-Gaeste wurden fuer den Schnelltest hinzugefuegt.',
        ),
      ],
    );
    updatedLobby = _assignRoles(updatedLobby, mysteryCase);

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;

    var nextState = state.copyWith(lobbies: updatedLobbies);
    nextState = _rememberRole(nextState, updatedLobby, state.localAlias);
    state = nextState;

    return guests.length;
  }

  String? reshuffleRoles(String code) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return 'Der zugehoerige Fall fehlt.';
    }

    var updatedLobby = _assignRoles(lobby, mysteryCase).copyWith(
      messages: [
        ...lobby.messages,
        _systemMessage('Die Rollen wurden neu verteilt.'),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;

    var nextState = state.copyWith(lobbies: updatedLobbies);
    nextState = _rememberRole(nextState, updatedLobby, state.localAlias);
    state = nextState;

    return null;
  }

  String? startGame(String code) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    if (lobby.hasStarted) {
      return null;
    }

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return 'Der zugehoerige Fall fehlt.';
    }

    var updatedLobby = lobby.copyWith(
      hasStarted: true,
      phaseIndex: 0,
      phaseStartedAt: DateTime.now(),
      messages: [
        ...lobby.messages,
        _systemMessage(
          'Das Spiel hat begonnen. Phase 1 "${mysteryCase.phases.first.title}" ist aktiv.',
        ),
      ],
    );
    updatedLobby = _applyPhaseHints(updatedLobby, mysteryCase);

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    state = state.copyWith(lobbies: updatedLobbies);

    return null;
  }

  String? advancePhase(String code) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return 'Der zugehoerige Fall fehlt.';
    }

    if (!lobby.hasStarted) {
      return 'Starte zuerst das Spiel.';
    }

    if (lobby.isCompleted) {
      return 'Dieses Spiel wurde bereits aufgeloest.';
    }

    if (lobby.phaseIndex >= mysteryCase.phases.length - 1) {
      final completedLobby = lobby.copyWith(
        isCompleted: true,
        messages: [
          ...lobby.messages,
          _systemMessage('Die Aufloesung ist abgeschlossen. Fall geschlossen.'),
        ],
      );
      final updatedLobbies = [...state.lobbies];
      updatedLobbies[lobbyIndex] = completedLobby;
      state = state.copyWith(lobbies: updatedLobbies);
      return null;
    }

    var updatedLobby = lobby.copyWith(
      phaseIndex: lobby.phaseIndex + 1,
      phaseStartedAt: DateTime.now(),
      messages: [
        ...lobby.messages,
        _systemMessage(
          'Neue Phase: ${mysteryCase.phases[lobby.phaseIndex + 1].title}.',
        ),
      ],
    );
    updatedLobby = _applyPhaseHints(updatedLobby, mysteryCase);

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    state = state.copyWith(lobbies: updatedLobbies);
    return null;
  }

  String? revealHint(String code, String hintId) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    if (lobby.revealedHintIds.contains(hintId)) {
      return null;
    }

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return 'Der zugehoerige Fall fehlt.';
    }

    final hint =
        mysteryCase.hints.where((item) => item.id == hintId).firstOrNull;
    if (hint == null) {
      return 'Hinweis nicht gefunden.';
    }

    final updatedLobby = lobby.copyWith(
      revealedHintIds: [...lobby.revealedHintIds, hintId],
      messages: [
        ...lobby.messages,
        _systemMessage('Hinweis freigegeben: ${hint.title}.'),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    state = state.copyWith(lobbies: updatedLobbies);
    return null;
  }

  String? kickPlayer(String code, String playerId) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final player =
        lobby.players.where((entry) => entry.id == playerId).firstOrNull;
    if (player == null) {
      return 'Spieler nicht gefunden.';
    }
    if (player.isHost) {
      return 'Der Host kann nicht entfernt werden.';
    }

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return 'Der zugehoerige Fall fehlt.';
    }

    var updatedLobby = lobby.copyWith(
      players: lobby.players.where((entry) => entry.id != playerId).toList(),
      messages: [
        ...lobby.messages,
        _systemMessage('${player.name} wurde aus der Lobby entfernt.'),
      ],
    );
    updatedLobby = _assignRoles(updatedLobby, mysteryCase);

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    state = state.copyWith(lobbies: updatedLobbies);
    return null;
  }

  void sendLobbyMessage({
    required String code,
    required String sender,
    required String body,
  }) {
    final message = body.trim();
    if (message.isEmpty) {
      return;
    }

    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return;
    }

    final lobby = state.lobbies[lobbyIndex];
    final updatedLobby = lobby.copyWith(
      messages: [
        ...lobby.messages,
        ChatMessage(
          id: _uuid.v4(),
          sender: sender,
          body: message,
          createdAt: DateTime.now(),
          type: ChatMessageType.lobby,
        ),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    state = state.copyWith(lobbies: updatedLobbies);
  }

  int _indexOfLobby(String code) {
    final normalized = code.trim().toUpperCase();
    for (var index = 0; index < state.lobbies.length; index++) {
      if (state.lobbies[index].code == normalized) {
        return index;
      }
    }
    return -1;
  }

  String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      8,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  LobbySession _assignRoles(LobbySession lobby, MysteryCase mysteryCase) {
    final roles = [...mysteryCase.roles];
    roles.shuffle(Random(DateTime.now().microsecondsSinceEpoch));

    final assignments = <String, String>{};
    for (var index = 0; index < lobby.players.length; index++) {
      assignments[lobby.players[index].id] = roles[index].id;
    }

    return lobby.copyWith(roleAssignments: assignments);
  }

  LobbySession _applyPhaseHints(LobbySession lobby, MysteryCase mysteryCase) {
    final phase = mysteryCase.phases[lobby.phaseIndex];
    final revealed = {...lobby.revealedHintIds};
    revealed.addAll(phase.autoHintIds);

    return lobby.copyWith(
      revealedHintIds: revealed.toList(),
    );
  }

  MysteryState _rememberRole(
    MysteryState baseState,
    LobbySession lobby,
    String alias,
  ) {
    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return baseState;
    }

    LobbyPlayer? player;
    for (final entry in lobby.players) {
      if (entry.name.toLowerCase() == alias.toLowerCase()) {
        player = entry;
        break;
      }
    }
    if (player == null) {
      return baseState;
    }

    final roleId = lobby.roleAssignments[player.id];
    if (roleId == null) {
      return baseState;
    }

    MysteryRole? role;
    for (final entry in mysteryCase.roles) {
      if (entry.id == roleId) {
        role = entry;
        break;
      }
    }
    if (role == null) {
      return baseState;
    }

    final alreadyPresent = baseState.roleArchive.any(
      (entry) =>
          entry.lobbyCode == lobby.code &&
          entry.playerName.toLowerCase() == alias.toLowerCase() &&
          entry.characterName == role!.name,
    );

    if (alreadyPresent) {
      return baseState;
    }

    final archiveEntry = RoleArchiveEntry(
      lobbyCode: lobby.code,
      playerName: alias,
      caseTitle: mysteryCase.title,
      characterName: role.name,
      signature: role.persona,
      goal: role.goal,
      unlockedAt: DateTime.now(),
    );

    return baseState.copyWith(
      roleArchive: [archiveEntry, ...baseState.roleArchive],
    );
  }

  ChatMessage _systemMessage(String body) {
    return ChatMessage(
      id: _uuid.v4(),
      sender: 'System',
      body: body,
      createdAt: DateTime.now(),
      type: ChatMessageType.system,
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

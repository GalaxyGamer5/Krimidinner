import 'dart:convert';
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

String buildLobbyInviteLink(String code, {String? invitationId}) {
  final normalizedCode = code.trim().toUpperCase();
  final query = (invitationId == null || invitationId.isEmpty)
      ? ''
      : '?invite=$invitationId';
  final joinPath = '/join/$normalizedCode$query';
  final base = Uri.base;
  final isHttp = base.scheme == 'http' || base.scheme == 'https';
  if (!isHttp) {
    return 'https://mysterynight.app$joinPath';
  }

  if (base.fragment.startsWith('/')) {
    return '${base.origin}/#$joinPath';
  }

  return '${base.origin}$joinPath';
}

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
      description: 'Schalte Hinweise über mehrere Partien hinweg frei.',
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
  static const _stateKey = 'mystery_state_v2';

  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  MysteryState build() {
    return _restoreState(_prefs.getString(_stateKey)) ?? _defaultState();
  }

  void updateAlias(String alias) {
    final trimmed = alias.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _updateState(state.copyWith(localAlias: trimmed));
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
    final inviteLink = buildLobbyInviteLink(code);

    var lobby = LobbySession(
      code: code,
      caseId: mysteryCase.id,
      inviteLink: inviteLink,
      hostId: player.id,
      createdAt: DateTime.now(),
      players: [player],
      invitations: const [],
      roleAssignments: const {},
      messages: [
        _systemMessage('Lobby $code wurde eroeffnet. Einladungslink bereit.'),
      ],
      revealedHintIds: const [],
      phaseIndex: 0,
      hasStarted: false,
      isCompleted: false,
    );

    lobby = _assignRoleToPlayer(lobby, mysteryCase, player.id) ?? lobby;

    var nextState = state.copyWith(
      localAlias: trimmed,
      lobbies: [lobby, ...state.lobbies],
    );
    nextState = _rememberRole(nextState, lobby, trimmed);
    _updateState(nextState);

    return code;
  }

  String? joinLobby({
    required String code,
    required String alias,
    String? invitationId,
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
      return 'Der Fall für diese Lobby ist nicht mehr verfügbar.';
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

    LobbyInvitation? invitation;
    final normalizedInvitationId = invitationId?.trim();
    if (normalizedInvitationId != null && normalizedInvitationId.isNotEmpty) {
      invitation = lobby.invitations
          .where((entry) => entry.id == normalizedInvitationId)
          .firstOrNull;
      if (invitation == null) {
        return 'Diese Einladung ist nicht mehr verfügbar.';
      }
      switch (invitation.status) {
        case LobbyInvitationStatus.pending:
          break;
        case LobbyInvitationStatus.accepted:
          return 'Diese Einladung wurde bereits angenommen.';
        case LobbyInvitationStatus.revoked:
          return 'Diese Einladung wurde vom Spielleiter zurückgezogen.';
      }
    }

    final assignedRoleId = invitation?.assignedRoleId ??
        _availableRoleIds(lobby, mysteryCase).firstOrNull;
    if (assignedRoleId == null) {
      return 'Alle Rollen in dieser Lobby sind bereits vergeben oder reserviert.';
    }

    final player = LobbyPlayer(
      id: _uuid.v4(),
      name: trimmedAlias,
      joinedAt: DateTime.now(),
      isHost: false,
      isOnline: true,
    );

    final updatedInvitations = invitation == null
        ? lobby.invitations
        : lobby.invitations
            .map(
              (entry) => entry.id == invitation!.id
                  ? entry.copyWith(
                      status: LobbyInvitationStatus.accepted,
                      acceptedAt: DateTime.now(),
                      acceptedByPlayerId: player.id,
                    )
                  : entry,
            )
            .toList();

    final updatedLobby = lobby.copyWith(
      players: [...lobby.players, player],
      invitations: updatedInvitations,
      roleAssignments: {
        ...lobby.roleAssignments,
        player.id: assignedRoleId,
      },
      messages: [
        ...lobby.messages,
        _systemMessage(
          invitation == null
              ? '$trimmedAlias ist der Lobby beigetreten.'
              : '$trimmedAlias hat die Einladung angenommen und ist der Lobby beigetreten.',
        ),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;

    var nextState = state.copyWith(
      localAlias: trimmedAlias,
      lobbies: updatedLobbies,
    );
    nextState = _rememberRole(nextState, updatedLobby, trimmedAlias);
    _updateState(nextState);

    return null;
  }

  ({String? error, LobbyInvitation? invitation}) createInvitation({
    required String code,
    required String recipientName,
    required String roleId,
  }) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return (error: 'Lobby nicht gefunden.', invitation: null);
    }

    final lobby = state.lobbies[lobbyIndex];
    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return (error: 'Der zugehoerige Fall fehlt.', invitation: null);
    }

    final trimmedRecipient = recipientName.trim();
    if (trimmedRecipient.isEmpty) {
      return (error: 'Bitte gib einen Gastnamen ein.', invitation: null);
    }

    final roleExists = mysteryCase.roles.any((role) => role.id == roleId);
    if (!roleExists) {
      return (
        error: 'Die gewählte Rolle ist nicht mehr verfügbar.',
        invitation: null
      );
    }

    final duplicatePlayer = lobby.players.any(
      (player) => player.name.toLowerCase() == trimmedRecipient.toLowerCase(),
    );
    if (duplicatePlayer) {
      return (
        error: 'Dieser Name ist in der Lobby bereits vergeben.',
        invitation: null
      );
    }

    final duplicateInvite = lobby.invitations.any(
      (invitation) =>
          invitation.status == LobbyInvitationStatus.pending &&
          invitation.recipientName.toLowerCase() ==
              trimmedRecipient.toLowerCase(),
    );
    if (duplicateInvite) {
      return (
        error: 'Für diesen Gast gibt es bereits eine offene Einladung.',
        invitation: null,
      );
    }

    final availableRoleIds = _availableRoleIds(lobby, mysteryCase);
    if (!availableRoleIds.contains(roleId)) {
      return (
        error: 'Diese Rolle ist bereits vergeben oder reserviert.',
        invitation: null,
      );
    }

    final invitation = LobbyInvitation(
      id: _uuid.v4(),
      recipientName: trimmedRecipient,
      assignedRoleId: roleId,
      createdAt: DateTime.now(),
      status: LobbyInvitationStatus.pending,
    );

    final updatedLobby = lobby.copyWith(
      invitations: [invitation, ...lobby.invitations],
      messages: [
        ...lobby.messages,
        _systemMessage('Einladung für $trimmedRecipient wurde erstellt.'),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    _updateState(state.copyWith(lobbies: updatedLobbies));

    return (error: null, invitation: invitation);
  }

  String? revokeInvitation(String code, String invitationId) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final invitation = lobby.invitations
        .where((entry) => entry.id == invitationId)
        .firstOrNull;
    if (invitation == null) {
      return 'Einladung nicht gefunden.';
    }
    if (invitation.status == LobbyInvitationStatus.accepted) {
      return 'Bereits angenommene Einladungen können nicht zurückgezogen werden.';
    }
    if (invitation.status == LobbyInvitationStatus.revoked) {
      return null;
    }

    final updatedLobby = lobby.copyWith(
      invitations: lobby.invitations
          .map(
            (entry) => entry.id == invitationId
                ? entry.copyWith(status: LobbyInvitationStatus.revoked)
                : entry,
          )
          .toList(),
      messages: [
        ...lobby.messages,
        _systemMessage(
          'Die Einladung für ${invitation.recipientName} wurde zurückgezogen.',
        ),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    _updateState(state.copyWith(lobbies: updatedLobbies));
    return null;
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

    final updatedLobby = _assignRoles(
      lobby,
      mysteryCase,
      preserveInvitationLocks: true,
    ).copyWith(
      messages: [
        ...lobby.messages,
        _systemMessage('Die Rollen wurden neu verteilt.'),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;

    var nextState = state.copyWith(lobbies: updatedLobbies);
    nextState = _rememberRole(nextState, updatedLobby, state.localAlias);
    _updateState(nextState);

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
    _updateState(state.copyWith(lobbies: updatedLobbies));

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
      _updateState(state.copyWith(lobbies: updatedLobbies));
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
    _updateState(state.copyWith(lobbies: updatedLobbies));
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
    _updateState(state.copyWith(lobbies: updatedLobbies));
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

    final updatedInvitations = lobby.invitations
        .map(
          (entry) => entry.acceptedByPlayerId == playerId
              ? entry.copyWith(
                  status: LobbyInvitationStatus.revoked,
                  clearAcceptedAt: true,
                  clearAcceptedByPlayerId: true,
                )
              : entry,
        )
        .toList();

    final updatedAssignments = {...lobby.roleAssignments}..remove(playerId);

    final updatedLobby = lobby.copyWith(
      players: lobby.players.where((entry) => entry.id != playerId).toList(),
      invitations: updatedInvitations,
      roleAssignments: updatedAssignments,
      messages: [
        ...lobby.messages,
        _systemMessage('${player.name} wurde aus der Lobby entfernt.'),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    _updateState(state.copyWith(lobbies: updatedLobbies));
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
    _updateState(state.copyWith(lobbies: updatedLobbies));
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

  LobbySession _assignRoles(
    LobbySession lobby,
    MysteryCase mysteryCase, {
    bool preserveInvitationLocks = false,
  }) {
    final assignments = <String, String>{};
    final reservedRoleIds = <String>{};

    if (preserveInvitationLocks) {
      for (final invitation in lobby.invitations) {
        if (invitation.status == LobbyInvitationStatus.pending) {
          reservedRoleIds.add(invitation.assignedRoleId);
        }
        if (invitation.status == LobbyInvitationStatus.accepted &&
            invitation.acceptedByPlayerId != null &&
            lobby.players.any(
              (player) => player.id == invitation.acceptedByPlayerId,
            )) {
          assignments[invitation.acceptedByPlayerId!] =
              invitation.assignedRoleId;
        }
      }
    }

    final availableRoleIds = mysteryCase.roles
        .map((role) => role.id)
        .where(
          (roleId) =>
              !assignments.containsValue(roleId) &&
              !reservedRoleIds.contains(roleId),
        )
        .toList()
      ..shuffle(Random(DateTime.now().microsecondsSinceEpoch));

    for (final player in lobby.players) {
      if (assignments.containsKey(player.id)) {
        continue;
      }
      if (availableRoleIds.isEmpty) {
        break;
      }
      assignments[player.id] = availableRoleIds.removeAt(0);
    }

    return lobby.copyWith(roleAssignments: assignments);
  }

  LobbySession? _assignRoleToPlayer(
    LobbySession lobby,
    MysteryCase mysteryCase,
    String playerId, {
    String? preferredRoleId,
  }) {
    final availableRoleIds = _availableRoleIds(lobby, mysteryCase);
    final selectedRoleId = preferredRoleId ?? availableRoleIds.firstOrNull;
    if (selectedRoleId == null || !availableRoleIds.contains(selectedRoleId)) {
      return null;
    }

    return lobby.copyWith(
      roleAssignments: {
        ...lobby.roleAssignments,
        playerId: selectedRoleId,
      },
    );
  }

  List<String> _availableRoleIds(LobbySession lobby, MysteryCase mysteryCase) {
    final unavailableRoleIds = {
      ...lobby.roleAssignments.values,
      ...lobby.invitations
          .where((invitation) =>
              invitation.status == LobbyInvitationStatus.pending)
          .map((invitation) => invitation.assignedRoleId),
    };

    return mysteryCase.roles
        .map((role) => role.id)
        .where((roleId) => !unavailableRoleIds.contains(roleId))
        .toList();
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

  void _updateState(MysteryState nextState) {
    state = nextState;
    _prefs.setString(_stateKey, jsonEncode(_serializeState(nextState)));
  }

  MysteryState _defaultState() {
    return MysteryState(
      localAlias: 'Detective Nova',
      lobbies: const [],
      roleArchive: const [],
      friends: _defaultFriends(),
    );
  }

  List<FriendProfile> _defaultFriends() {
    return const [
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
    ];
  }

  MysteryState? _restoreState(String? rawState) {
    if (rawState == null || rawState.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawState);
      if (decoded is! Map) {
        return null;
      }

      final lobbies = (decoded['lobbies'] as List<dynamic>? ?? const [])
          .map(_deserializeLobby)
          .whereType<LobbySession>()
          .toList();
      final roleArchive = (decoded['roleArchive'] as List<dynamic>? ?? const [])
          .map(_deserializeRoleArchiveEntry)
          .whereType<RoleArchiveEntry>()
          .toList();

      return MysteryState(
        localAlias: decoded['localAlias'] as String? ?? 'Detective Nova',
        lobbies: lobbies,
        roleArchive: roleArchive,
        friends: _defaultFriends(),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _serializeState(MysteryState mysteryState) {
    return {
      'localAlias': mysteryState.localAlias,
      'lobbies': mysteryState.lobbies.map(_serializeLobby).toList(),
      'roleArchive':
          mysteryState.roleArchive.map(_serializeRoleArchiveEntry).toList(),
    };
  }

  Map<String, dynamic> _serializeLobby(LobbySession lobby) {
    return {
      'code': lobby.code,
      'caseId': lobby.caseId,
      'inviteLink': lobby.inviteLink,
      'hostId': lobby.hostId,
      'createdAt': lobby.createdAt.toIso8601String(),
      'players': lobby.players.map(_serializePlayer).toList(),
      'invitations': lobby.invitations.map(_serializeInvitation).toList(),
      'roleAssignments': lobby.roleAssignments,
      'messages': lobby.messages.map(_serializeMessage).toList(),
      'revealedHintIds': lobby.revealedHintIds,
      'phaseIndex': lobby.phaseIndex,
      'hasStarted': lobby.hasStarted,
      'isCompleted': lobby.isCompleted,
      'phaseStartedAt': lobby.phaseStartedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _serializePlayer(LobbyPlayer player) {
    return {
      'id': player.id,
      'name': player.name,
      'joinedAt': player.joinedAt.toIso8601String(),
      'isHost': player.isHost,
      'isOnline': player.isOnline,
    };
  }

  Map<String, dynamic> _serializeInvitation(LobbyInvitation invitation) {
    return {
      'id': invitation.id,
      'recipientName': invitation.recipientName,
      'assignedRoleId': invitation.assignedRoleId,
      'createdAt': invitation.createdAt.toIso8601String(),
      'status': invitation.status.name,
      'acceptedAt': invitation.acceptedAt?.toIso8601String(),
      'acceptedByPlayerId': invitation.acceptedByPlayerId,
    };
  }

  Map<String, dynamic> _serializeMessage(ChatMessage message) {
    return {
      'id': message.id,
      'sender': message.sender,
      'body': message.body,
      'createdAt': message.createdAt.toIso8601String(),
      'type': message.type.name,
    };
  }

  Map<String, dynamic> _serializeRoleArchiveEntry(RoleArchiveEntry entry) {
    return {
      'lobbyCode': entry.lobbyCode,
      'playerName': entry.playerName,
      'caseTitle': entry.caseTitle,
      'characterName': entry.characterName,
      'signature': entry.signature,
      'goal': entry.goal,
      'unlockedAt': entry.unlockedAt.toIso8601String(),
    };
  }

  LobbySession? _deserializeLobby(dynamic rawLobby) {
    if (rawLobby is! Map) {
      return null;
    }

    final code = rawLobby['code'];
    final caseId = rawLobby['caseId'];
    final inviteLink = rawLobby['inviteLink'];
    final hostId = rawLobby['hostId'];
    final createdAt = DateTime.tryParse(rawLobby['createdAt'] as String? ?? '');
    if (code is! String ||
        caseId is! String ||
        inviteLink is! String ||
        hostId is! String ||
        createdAt == null) {
      return null;
    }

    final players = (rawLobby['players'] as List<dynamic>? ?? const [])
        .map(_deserializePlayer)
        .whereType<LobbyPlayer>()
        .toList();
    final invitations = (rawLobby['invitations'] as List<dynamic>? ?? const [])
        .map(_deserializeInvitation)
        .whereType<LobbyInvitation>()
        .toList();
    final messages = (rawLobby['messages'] as List<dynamic>? ?? const [])
        .map(_deserializeMessage)
        .whereType<ChatMessage>()
        .toList();

    final roleAssignments = <String, String>{};
    final rawAssignments = rawLobby['roleAssignments'];
    if (rawAssignments is Map) {
      for (final entry in rawAssignments.entries) {
        if (entry.key is String && entry.value is String) {
          roleAssignments[entry.key as String] = entry.value as String;
        }
      }
    }

    final revealedHintIds =
        (rawLobby['revealedHintIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList();

    return LobbySession(
      code: code,
      caseId: caseId,
      inviteLink: inviteLink,
      hostId: hostId,
      createdAt: createdAt,
      players: players,
      invitations: invitations,
      roleAssignments: roleAssignments,
      messages: messages,
      revealedHintIds: revealedHintIds,
      phaseIndex: (rawLobby['phaseIndex'] as num?)?.toInt() ?? 0,
      hasStarted: rawLobby['hasStarted'] as bool? ?? false,
      isCompleted: rawLobby['isCompleted'] as bool? ?? false,
      phaseStartedAt:
          DateTime.tryParse(rawLobby['phaseStartedAt'] as String? ?? ''),
    );
  }

  LobbyPlayer? _deserializePlayer(dynamic rawPlayer) {
    if (rawPlayer is! Map) {
      return null;
    }

    final id = rawPlayer['id'];
    final name = rawPlayer['name'];
    final joinedAt = DateTime.tryParse(rawPlayer['joinedAt'] as String? ?? '');
    if (id is! String || name is! String || joinedAt == null) {
      return null;
    }

    return LobbyPlayer(
      id: id,
      name: name,
      joinedAt: joinedAt,
      isHost: rawPlayer['isHost'] as bool? ?? false,
      isOnline: rawPlayer['isOnline'] as bool? ?? true,
    );
  }

  LobbyInvitation? _deserializeInvitation(dynamic rawInvitation) {
    if (rawInvitation is! Map) {
      return null;
    }

    final id = rawInvitation['id'];
    final recipientName = rawInvitation['recipientName'];
    final assignedRoleId = rawInvitation['assignedRoleId'];
    final createdAt =
        DateTime.tryParse(rawInvitation['createdAt'] as String? ?? '');
    final rawStatus = rawInvitation['status'] as String?;
    final status = LobbyInvitationStatus.values
        .where((entry) => entry.name == rawStatus)
        .firstOrNull;
    if (id is! String ||
        recipientName is! String ||
        assignedRoleId is! String ||
        createdAt == null ||
        status == null) {
      return null;
    }

    return LobbyInvitation(
      id: id,
      recipientName: recipientName,
      assignedRoleId: assignedRoleId,
      createdAt: createdAt,
      status: status,
      acceptedAt:
          DateTime.tryParse(rawInvitation['acceptedAt'] as String? ?? ''),
      acceptedByPlayerId: rawInvitation['acceptedByPlayerId'] as String?,
    );
  }

  ChatMessage? _deserializeMessage(dynamic rawMessage) {
    if (rawMessage is! Map) {
      return null;
    }

    final id = rawMessage['id'];
    final sender = rawMessage['sender'];
    final body = rawMessage['body'];
    final createdAt =
        DateTime.tryParse(rawMessage['createdAt'] as String? ?? '');
    final rawType = rawMessage['type'] as String?;
    final type = ChatMessageType.values
        .where((entry) => entry.name == rawType)
        .firstOrNull;
    if (id is! String ||
        sender is! String ||
        body is! String ||
        createdAt == null ||
        type == null) {
      return null;
    }

    return ChatMessage(
      id: id,
      sender: sender,
      body: body,
      createdAt: createdAt,
      type: type,
    );
  }

  RoleArchiveEntry? _deserializeRoleArchiveEntry(dynamic rawEntry) {
    if (rawEntry is! Map) {
      return null;
    }

    final lobbyCode = rawEntry['lobbyCode'];
    final playerName = rawEntry['playerName'];
    final caseTitle = rawEntry['caseTitle'];
    final characterName = rawEntry['characterName'];
    final signature = rawEntry['signature'];
    final goal = rawEntry['goal'];
    final unlockedAt =
        DateTime.tryParse(rawEntry['unlockedAt'] as String? ?? '');
    if (lobbyCode is! String ||
        playerName is! String ||
        caseTitle is! String ||
        characterName is! String ||
        signature is! String ||
        goal is! String ||
        unlockedAt == null) {
      return null;
    }

    return RoleArchiveEntry(
      lobbyCode: lobbyCode,
      playerName: playerName,
      caseTitle: caseTitle,
      characterName: characterName,
      signature: signature,
      goal: goal,
      unlockedAt: unlockedAt,
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

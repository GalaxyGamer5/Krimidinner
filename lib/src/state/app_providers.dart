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
  final catalog = ref.watch(mysteryCatalogProvider);
  for (final mysteryCase in catalog) {
    if (mysteryCase.id == caseId) {
      return mysteryCase;
    }
  }
  return null;
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

final userAccountProvider =
    NotifierProvider<UserAccountController, UserAccount?>(
        UserAccountController.new);

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(userAccountProvider) != null;
});

final playerStatsProvider = Provider<PlayerStats>((ref) {
  final state = ref.watch(mysteryControllerProvider);
  final catalog = ref.watch(mysteryCatalogProvider);
  final completedGames =
      state.lobbies.where((lobby) => lobby.isCompleted).length;
  final startedGames = state.lobbies.where((lobby) => lobby.hasStarted).length;
  final revealedHints = state.lobbies.fold<int>(
    0,
    (total, lobby) => total + lobby.revealedHintIds.length,
  );
  final distinctRoles = state.roleArchive
      .map((entry) => '${entry.caseTitle}:${entry.characterName}')
      .toSet()
      .length;
  final favoriteRole = _favoriteValue(
    state.roleArchive.map((entry) => entry.characterName),
  );
  final favoriteScenario = _favoriteValue(
    state.roleArchive.map((entry) => entry.caseTitle),
  );
  final fallbackCaseTitle =
      catalog.isEmpty ? 'Noch kein Fall' : catalog.first.title;

  return PlayerStats(
    gamesPlayed: startedGames,
    casesSolved: completedGames,
    detectiveFinds: revealedHints,
    hoursPlayed: _estimatedHoursPlayed(state, catalog),
    favoriteRole: favoriteRole ?? 'Noch keine Rolle',
    favoriteScenario: favoriteScenario ?? fallbackCaseTitle,
    distinctRolesManaged: distinctRoles,
    activeLobbies: state.lobbies.where((lobby) => !lobby.isCompleted).length,
    friendCount: state.friends.length,
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
      id: 'case_master',
      title: 'Meisterdetektiv',
      description: 'Schliesse mehrere Faelle erfolgreich ab.',
      progress: stats.casesSolved.toDouble(),
      target: 3,
      icon: Icons.search_rounded,
    ),
    Achievement(
      id: 'role_archive',
      title: 'Unauffaelliger Taeter',
      description: 'Verwalte mehrere Rollen, ohne deine Spuren preiszugeben.',
      progress: stats.distinctRolesManaged.toDouble(),
      target: 4,
      icon: Icons.visibility_off_rounded,
    ),
    Achievement(
      id: 'clue_hunter',
      title: 'Hinweisjaeger',
      description: 'Schalte Hinweise über mehrere Partien hinweg frei.',
      progress: totalHints.toDouble(),
      target: 10,
      icon: Icons.local_police_rounded,
    ),
    Achievement(
      id: 'friend_network',
      title: 'Netzwerk im Nebel',
      description: 'Baue dir ein eigenes Ermittlernetzwerk auf.',
      progress: stats.friendCount.toDouble(),
      target: 3,
      icon: Icons.group_add_rounded,
    ),
    Achievement(
      id: 'multi_case_host',
      title: 'Doppelte Buchfuehrung',
      description: 'Halte mehrere aktive Lobbys parallel im Blick.',
      progress: activeLobbies.toDouble(),
      target: 2,
      icon: Icons.dashboard_customize_rounded,
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
  static const _rejoinWindow = Duration(hours: 24);

  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  MysteryState build() {
    final restored =
        _restoreState(_prefs.getString(_stateKey)) ?? _defaultState();
    return _cleanupExpiredRejoins(restored);
  }

  void updateAlias(String alias) {
    final trimmed = alias.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _updateState(state.copyWith(localAlias: trimmed));
  }

  String? addFriend({
    required String name,
    String? favoriteScenario,
    String? favoriteRole,
    String? note,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Bitte gib einen Namen ein.';
    }

    final duplicate = state.friends.any(
      (friend) => friend.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (duplicate) {
      return 'Dieser Freund ist bereits gespeichert.';
    }

    final friend = FriendProfile(
      id: _uuid.v4(),
      name: trimmedName,
      createdAt: DateTime.now(),
      favoriteScenario: _normalizeOptionalText(favoriteScenario),
      favoriteRole: _normalizeOptionalText(favoriteRole),
      note: note?.trim() ?? '',
    );

    _updateState(state.copyWith(friends: [friend, ...state.friends]));
    return null;
  }

  String? updateFriend({
    required String friendId,
    required String name,
    String? favoriteScenario,
    String? favoriteRole,
    String? note,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Bitte gib einen Namen ein.';
    }

    final friendIndex =
        state.friends.indexWhere((friend) => friend.id == friendId);
    if (friendIndex == -1) {
      return 'Freund nicht gefunden.';
    }

    final duplicate = state.friends.any(
      (friend) =>
          friend.id != friendId &&
          friend.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (duplicate) {
      return 'Dieser Freund ist bereits gespeichert.';
    }

    final updatedFriends = [...state.friends];
    updatedFriends[friendIndex] = updatedFriends[friendIndex].copyWith(
      name: trimmedName,
      favoriteScenario: _normalizeOptionalText(favoriteScenario),
      favoriteRole: _normalizeOptionalText(favoriteRole),
      note: note?.trim() ?? '',
      clearFavoriteScenario: _normalizeOptionalText(favoriteScenario) == null,
      clearFavoriteRole: _normalizeOptionalText(favoriteRole) == null,
    );

    _updateState(state.copyWith(friends: updatedFriends));
    return null;
  }

  void removeFriend(String friendId) {
    final updatedFriends =
        state.friends.where((friend) => friend.id != friendId).toList();
    if (updatedFriends.length == state.friends.length) {
      return;
    }
    _updateState(state.copyWith(friends: updatedFriends));
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
      evidences: const [],
      votes: const [],
      revealedHintIds: const [],
      hostChecklist: _buildDefaultChecklist(mysteryCase),
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
    _syncCleanStateIfNeeded();

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

    final normalizedAlias = trimmedAlias.toLowerCase();

    if (lobby.players.length >= mysteryCase.roles.length) {
      return 'Diese Lobby ist bereits voll.';
    }

    final duplicateName = lobby.players.any(
      (player) => player.name.toLowerCase() == normalizedAlias,
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

    final updatedLobby = _syncHostChecklist(
      lobby.copyWith(
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
      ),
      mysteryCase,
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

  String? rejoinLobby({
    required String code,
    required String alias,
  }) {
    _syncCleanStateIfNeeded();

    final lobbyIndex = _indexOfLobby(code.trim().toUpperCase());
    if (lobbyIndex == -1) {
      return 'Lobby-Code nicht gefunden.';
    }

    final trimmedAlias = alias.trim();
    if (trimmedAlias.isEmpty) {
      return 'Bitte gib deinen bisherigen Spielernamen ein.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final player = lobby.players
        .where(
            (entry) => entry.name.toLowerCase() == trimmedAlias.toLowerCase())
        .firstOrNull;
    if (player == null) {
      return 'Fuer diesen Namen ist kein offener Wiederbeitritt hinterlegt.';
    }
    if (!_canPlayerRejoin(player)) {
      return 'Das 24-Stunden-Fenster fuer den Wiederbeitritt ist abgelaufen.';
    }

    _restorePlayerToLobby(
      lobbyIndex: lobbyIndex,
      lobby: lobby,
      player: player,
      alias: trimmedAlias,
    );
    return null;
  }

  String? leaveLobby({
    required String code,
    required String playerId,
  }) {
    _syncCleanStateIfNeeded();

    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final playerIndex =
        lobby.players.indexWhere((player) => player.id == playerId);
    if (playerIndex == -1) {
      return 'Spieler nicht gefunden.';
    }

    final player = lobby.players[playerIndex];
    if (!player.isOnline) {
      return null;
    }

    final now = DateTime.now();
    final rejoinUntil = now.add(_rejoinWindow);
    final updatedPlayers = [...lobby.players];
    updatedPlayers[playerIndex] = player.copyWith(
      isOnline: false,
      leftAt: now,
      rejoinAvailableUntil: rejoinUntil,
    );

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    final updatedLobby = mysteryCase == null
        ? lobby.copyWith(
            players: updatedPlayers,
            votes: lobby.votes
                .where((vote) => vote.voterPlayerId != playerId)
                .toList(),
            messages: [
              ...lobby.messages,
              _systemMessage(
                '${player.name} hat die Lobby verlassen. Wiederbeitritt bis ${_formatDateTime(rejoinUntil)} moeglich.',
              ),
            ],
          )
        : _syncHostChecklist(
            lobby.copyWith(
              players: updatedPlayers,
              votes: lobby.votes
                  .where((vote) => vote.voterPlayerId != playerId)
                  .toList(),
              messages: [
                ...lobby.messages,
                _systemMessage(
                  '${player.name} hat die Lobby verlassen. Wiederbeitritt bis ${_formatDateTime(rejoinUntil)} moeglich.',
                ),
              ],
            ),
            mysteryCase,
          );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    _updateState(state.copyWith(lobbies: updatedLobbies));
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

    final updatedLobby = _syncHostChecklist(
      lobby.copyWith(
        invitations: [invitation, ...lobby.invitations],
        messages: [
          ...lobby.messages,
          _systemMessage('Einladung für $trimmedRecipient wurde erstellt.'),
        ],
      ),
      mysteryCase,
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

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    final updatedLobby = mysteryCase == null
        ? lobby.copyWith(
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
          )
        : _syncHostChecklist(
            lobby.copyWith(
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
            ),
            mysteryCase,
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

    var updatedLobby = _syncHostChecklist(
      lobby.copyWith(
        hasStarted: true,
        phaseIndex: 0,
        phaseStartedAt: DateTime.now(),
        messages: [
          ...lobby.messages,
          _systemMessage(
            'Das Spiel hat begonnen. Phase 1 "${mysteryCase.phases.first.title}" ist aktiv.',
          ),
        ],
      ),
      mysteryCase,
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
      final completedLobby = _syncHostChecklist(
        lobby.copyWith(
          isCompleted: true,
          messages: [
            ...lobby.messages,
            _systemMessage(
              'Die Aufloesung ist abgeschlossen. Fall geschlossen.',
            ),
          ],
        ),
        mysteryCase,
      );
      final updatedLobbies = [...state.lobbies];
      updatedLobbies[lobbyIndex] = completedLobby;
      _updateState(state.copyWith(lobbies: updatedLobbies));
      return null;
    }

    var updatedLobby = _syncHostChecklist(
      lobby.copyWith(
        phaseIndex: lobby.phaseIndex + 1,
        phaseStartedAt: DateTime.now(),
        messages: [
          ...lobby.messages,
          _systemMessage(
            'Neue Phase: ${mysteryCase.phases[lobby.phaseIndex + 1].title}.',
          ),
        ],
      ),
      mysteryCase,
    );
    updatedLobby = _applyPhaseHints(updatedLobby, mysteryCase);
    updatedLobby = _appendPhaseEvidence(updatedLobby, mysteryCase);

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

    final updatedLobby = _syncHostChecklist(
      lobby.copyWith(
        revealedHintIds: [...lobby.revealedHintIds, hintId],
        messages: [
          ...lobby.messages,
          _systemMessage('Hinweis freigegeben: ${hint.title}.'),
        ],
      ),
      mysteryCase,
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

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    final updatedLobby = mysteryCase == null
        ? lobby.copyWith(
            players:
                lobby.players.where((entry) => entry.id != playerId).toList(),
            invitations: updatedInvitations,
            roleAssignments: updatedAssignments,
            votes: lobby.votes
                .where((vote) => vote.voterPlayerId != playerId)
                .toList(),
            messages: [
              ...lobby.messages,
              _systemMessage('${player.name} wurde aus der Lobby entfernt.'),
            ],
          )
        : _syncHostChecklist(
            lobby.copyWith(
              players:
                  lobby.players.where((entry) => entry.id != playerId).toList(),
              invitations: updatedInvitations,
              roleAssignments: updatedAssignments,
              votes: lobby.votes
                  .where((vote) => vote.voterPlayerId != playerId)
                  .toList(),
              messages: [
                ...lobby.messages,
                _systemMessage('${player.name} wurde aus der Lobby entfernt.'),
              ],
            ),
            mysteryCase,
          );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    _updateState(state.copyWith(lobbies: updatedLobbies));
    return null;
  }

  String? toggleChecklistItem({
    required String code,
    required String itemId,
  }) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final itemIndex =
        lobby.hostChecklist.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      return 'Checklistenpunkt nicht gefunden.';
    }

    final item = lobby.hostChecklist[itemIndex];
    if (item.isAuto) {
      return 'Dieser Checklistenpunkt wird automatisch aktualisiert.';
    }

    final updatedChecklist = [...lobby.hostChecklist];
    updatedChecklist[itemIndex] =
        item.copyWith(isCompleted: !item.isCompleted);

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    final updatedLobby = mysteryCase == null
        ? lobby.copyWith(hostChecklist: updatedChecklist)
        : _syncHostChecklist(
            lobby.copyWith(hostChecklist: updatedChecklist),
            mysteryCase,
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
    String? recipientPlayerId,
    String? recipientPlayerName,
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
    final isDirect =
        recipientPlayerId != null && recipientPlayerId.trim().isNotEmpty;
    final updatedLobby = lobby.copyWith(
      messages: [
        ...lobby.messages,
        ChatMessage(
          id: _uuid.v4(),
          sender: sender,
          body: message,
          createdAt: DateTime.now(),
          type: isDirect ? ChatMessageType.direct : ChatMessageType.lobby,
          recipientPlayerId: isDirect ? recipientPlayerId.trim() : null,
          recipientPlayerName: isDirect ? recipientPlayerName?.trim() : null,
        ),
      ],
    );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;
    _updateState(state.copyWith(lobbies: updatedLobbies));
  }

  String? toggleMessageReaction({
    required String code,
    required String messageId,
    required String playerId,
    required String playerName,
    required String emoji,
  }) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final messageIndex =
        lobby.messages.indexWhere((message) => message.id == messageId);
    if (messageIndex == -1) {
      return 'Nachricht nicht gefunden.';
    }

    final message = lobby.messages[messageIndex];
    if (message.type == ChatMessageType.system) {
      return null;
    }

    final reactions = [...message.reactions];
    final existingIndex = reactions.indexWhere(
      (reaction) => reaction.playerId == playerId && reaction.emoji == emoji,
    );

    if (existingIndex >= 0) {
      reactions.removeAt(existingIndex);
    } else {
      reactions.add(
        ChatReaction(
          playerId: playerId,
          playerName: playerName,
          emoji: emoji,
          createdAt: DateTime.now(),
        ),
      );
    }

    final updatedMessages = [...lobby.messages];
    updatedMessages[messageIndex] = message.copyWith(reactions: reactions);

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = lobby.copyWith(messages: updatedMessages);
    _updateState(state.copyWith(lobbies: updatedLobbies));
    return null;
  }

  String? castVote({
    required String code,
    required String voterPlayerId,
    required String suspectRoleId,
  }) {
    final lobbyIndex = _indexOfLobby(code);
    if (lobbyIndex == -1) {
      return 'Lobby nicht gefunden.';
    }

    final lobby = state.lobbies[lobbyIndex];
    final mysteryCase = findMysteryCaseById(lobby.caseId);
    if (mysteryCase == null) {
      return 'Der zugehoerige Fall fehlt.';
    }

    final voterExists =
        lobby.players.any((player) => player.id == voterPlayerId);
    if (!voterExists) {
      return 'Spieler nicht gefunden.';
    }

    final roleExists =
        mysteryCase.roles.any((role) => role.id == suspectRoleId);
    if (!roleExists) {
      return 'Diese Rolle ist nicht Teil des Falls.';
    }

    final updatedVotes = [...lobby.votes];
    final existingIndex = updatedVotes.indexWhere(
      (vote) => vote.voterPlayerId == voterPlayerId,
    );
    final nextVote = SuspectVote(
      voterPlayerId: voterPlayerId,
      suspectRoleId: suspectRoleId,
      createdAt: DateTime.now(),
    );

    if (existingIndex >= 0) {
      updatedVotes[existingIndex] = nextVote;
    } else {
      updatedVotes.add(nextVote);
    }

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = lobby.copyWith(votes: updatedVotes);
    _updateState(state.copyWith(lobbies: updatedLobbies));
    return null;
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

  List<HostChecklistItem> _buildDefaultChecklist(MysteryCase mysteryCase) {
    return [
      const HostChecklistItem(
        id: 'host_intro',
        title: 'Gaeste begruessen',
        description:
            'Begruesse alle Mitspielenden und erklaere kurz, wie die Runde ablaeuft.',
        isCompleted: false,
      ),
      const HostChecklistItem(
        id: 'host_materials',
        title: 'Material und Stimmung vorbereiten',
        description:
            'Getraenke, Licht, Musik und alle noetigen Unterlagen bereitlegen.',
        isCompleted: false,
      ),
      HostChecklistItem(
        id: 'players_ready',
        title: 'Alle ${mysteryCase.roles.length} Rollen besetzt',
        description:
            'Sobald genug Spieler beigetreten sind, wird dieser Punkt automatisch abgehakt.',
        isCompleted: false,
        isAuto: true,
      ),
      const HostChecklistItem(
        id: 'roles_assigned',
        title: 'Rollen verteilt',
        description:
            'Die Lobby prueft automatisch, ob fuer alle anwesenden Spieler Rollen vergeben sind.',
        isCompleted: false,
        isAuto: true,
      ),
      const HostChecklistItem(
        id: 'game_started',
        title: 'Spiel gestartet',
        description:
            'Wird automatisch abgeschlossen, sobald die erste Phase beginnt.',
        isCompleted: false,
        isAuto: true,
      ),
      const HostChecklistItem(
        id: 'case_closed',
        title: 'Fall abgeschlossen',
        description:
            'Dieser Punkt schliesst automatisch, wenn die Aufloesung beendet wurde.',
        isCompleted: false,
        isAuto: true,
      ),
    ];
  }

  LobbySession _syncHostChecklist(
    LobbySession lobby,
    MysteryCase mysteryCase,
  ) {
    final hasEnoughPlayers = lobby.players.length >= mysteryCase.roles.length;
    final allPlayersAssigned = lobby.players.isNotEmpty &&
        lobby.players.every((player) => lobby.roleAssignments[player.id] != null);

    final expectedItems = _buildDefaultChecklist(mysteryCase);
    final currentItems = {for (final item in lobby.hostChecklist) item.id: item};
    final syncedChecklist = expectedItems.map((item) {
      final existing = currentItems[item.id];
      final completed = switch (item.id) {
        'players_ready' => hasEnoughPlayers,
        'roles_assigned' => allPlayersAssigned,
        'game_started' => lobby.hasStarted,
        'case_closed' => lobby.isCompleted,
        _ => existing?.isCompleted ?? item.isCompleted,
      };

      return item.copyWith(
        isCompleted: completed,
        title: item.title,
        description: item.description,
        isAuto: item.isAuto,
      );
    }).toList();

    return lobby.copyWith(hostChecklist: syncedChecklist);
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

    return _syncHostChecklist(
      lobby.copyWith(roleAssignments: assignments),
      mysteryCase,
    );
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

    return _syncHostChecklist(
      lobby.copyWith(
        roleAssignments: {
          ...lobby.roleAssignments,
          playerId: selectedRoleId,
        },
      ),
      mysteryCase,
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

  LobbySession _appendPhaseEvidence(
    LobbySession lobby,
    MysteryCase mysteryCase,
  ) {
    final phase = mysteryCase.phases[lobby.phaseIndex];
    const evidencePhases = {'conversation', 'clues', 'intel', 'accusation'};
    if (!evidencePhases.contains(phase.id)) {
      return lobby;
    }

    final evidenceId = 'brief_${lobby.code}_${phase.id}';
    final alreadyExists =
        lobby.evidences.any((evidence) => evidence.id == evidenceId);
    if (alreadyExists) {
      return lobby;
    }

    final evidence = GameEvidence(
      id: evidenceId,
      title: 'Versiegelter Brief',
      description:
          'Ein neuer Brief wurde zur Phase "${phase.title}" ausgelegt. Hier kann spaeter der eigentliche Hinweistext dieses Falls stehen.',
      assetPath: 'brief.png',
      unlockedInPhase: lobby.phaseIndex,
      unlockedAt: DateTime.now(),
    );

    return lobby.copyWith(
      evidences: [...lobby.evidences, evidence],
      messages: [
        ...lobby.messages,
        ChatMessage(
          id: _uuid.v4(),
          sender: 'Spielbrett',
          body:
              'Ein versiegelter Brief wurde fuer alle Spieler ausgelegt. Tippe ihn an, um ihn zu oeffnen.',
          createdAt: DateTime.now(),
          type: ChatMessageType.evidence,
          evidenceId: evidence.id,
        ),
      ],
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

  bool _canPlayerRejoin(LobbyPlayer player) {
    final deadline = player.rejoinAvailableUntil;
    if (player.isOnline || deadline == null) {
      return false;
    }
    return deadline.isAfter(DateTime.now());
  }

  void _restorePlayerToLobby({
    required int lobbyIndex,
    required LobbySession lobby,
    required LobbyPlayer player,
    required String alias,
  }) {
    final updatedPlayers = lobby.players
        .map(
          (entry) => entry.id == player.id
              ? entry.copyWith(
                  name: alias,
                  isOnline: true,
                  clearLeftAt: true,
                  clearRejoinAvailableUntil: true,
                )
              : entry,
        )
        .toList();

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    final updatedLobby = mysteryCase == null
        ? lobby.copyWith(
            players: updatedPlayers,
            messages: [
              ...lobby.messages,
              _systemMessage('$alias ist wieder in die Lobby zurueckgekehrt.'),
            ],
          )
        : _syncHostChecklist(
            lobby.copyWith(
              players: updatedPlayers,
              messages: [
                ...lobby.messages,
                _systemMessage(
                  '$alias ist wieder in die Lobby zurueckgekehrt.',
                ),
              ],
            ),
            mysteryCase,
          );

    final updatedLobbies = [...state.lobbies];
    updatedLobbies[lobbyIndex] = updatedLobby;

    var nextState = state.copyWith(
      localAlias: alias,
      lobbies: updatedLobbies,
    );
    nextState = _rememberRole(nextState, updatedLobby, alias);
    _updateState(nextState);
  }

  void _syncCleanStateIfNeeded() {
    final cleanedState = _cleanupExpiredRejoins(state);
    if (identical(cleanedState, state)) {
      return;
    }
    _updateState(cleanedState);
  }

  MysteryState _cleanupExpiredRejoins(MysteryState sourceState) {
    var hasChanges = false;
    final now = DateTime.now();
    final cleanedLobbies = <LobbySession>[];

    for (final lobby in sourceState.lobbies) {
      final cleanedLobby = _cleanupLobbyRejoins(lobby, now);
      if (cleanedLobby == null) {
        hasChanges = true;
        continue;
      }
      if (!identical(cleanedLobby, lobby)) {
        hasChanges = true;
      }
      cleanedLobbies.add(cleanedLobby);
    }

    if (!hasChanges) {
      return sourceState;
    }

    return sourceState.copyWith(lobbies: cleanedLobbies);
  }

  LobbySession? _cleanupLobbyRejoins(
    LobbySession lobby,
    DateTime now,
  ) {
    final expiredPlayers = lobby.players
        .where(
          (player) =>
              !player.isOnline &&
              player.rejoinAvailableUntil != null &&
              !player.rejoinAvailableUntil!.isAfter(now),
        )
        .toList();
    if (expiredPlayers.isEmpty) {
      return lobby;
    }

    final expiredPlayerIds = expiredPlayers.map((player) => player.id).toSet();
    if (expiredPlayerIds.contains(lobby.hostId)) {
      return null;
    }

    final updatedPlayers = lobby.players
        .where((player) => !expiredPlayerIds.contains(player.id))
        .toList();
    if (updatedPlayers.isEmpty) {
      return null;
    }

    final updatedAssignments = {...lobby.roleAssignments}
      ..removeWhere((playerId, _) => expiredPlayerIds.contains(playerId));

    final updatedInvitations = lobby.invitations
        .map(
          (invitation) =>
              expiredPlayerIds.contains(invitation.acceptedByPlayerId)
                  ? invitation.copyWith(
                      status: LobbyInvitationStatus.revoked,
                      clearAcceptedAt: true,
                      clearAcceptedByPlayerId: true,
                    )
                  : invitation,
        )
        .toList();

    final updatedVotes = lobby.votes
        .where((vote) => !expiredPlayerIds.contains(vote.voterPlayerId))
        .toList();

    final mysteryCase = findMysteryCaseById(lobby.caseId);
    final updatedLobby = lobby.copyWith(
      players: updatedPlayers,
      invitations: updatedInvitations,
      roleAssignments: updatedAssignments,
      votes: updatedVotes,
    );
    return mysteryCase == null
        ? updatedLobby
        : _syncHostChecklist(updatedLobby, mysteryCase);
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month. $hour:$minute';
  }

  void _updateState(MysteryState nextState) {
    state = nextState;
    _prefs.setString(_stateKey, jsonEncode(_serializeState(nextState)));
  }

  MysteryState _defaultState() {
    return const MysteryState(
      localAlias: 'Detective Nova',
      lobbies: [],
      roleArchive: [],
      friends: [],
    );
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
      final friends = (decoded['friends'] as List<dynamic>? ?? const [])
          .map(_deserializeFriendProfile)
          .whereType<FriendProfile>()
          .toList();

      return MysteryState(
        localAlias: decoded['localAlias'] as String? ?? 'Detective Nova',
        lobbies: lobbies,
        roleArchive: roleArchive,
        friends: friends,
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
      'friends': mysteryState.friends.map(_serializeFriendProfile).toList(),
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
      'evidences': lobby.evidences.map(_serializeEvidence).toList(),
      'votes': lobby.votes.map(_serializeVote).toList(),
      'revealedHintIds': lobby.revealedHintIds,
      'hostChecklist': lobby.hostChecklist.map(_serializeChecklistItem).toList(),
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
      'leftAt': player.leftAt?.toIso8601String(),
      'rejoinAvailableUntil': player.rejoinAvailableUntil?.toIso8601String(),
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
      'recipientPlayerId': message.recipientPlayerId,
      'recipientPlayerName': message.recipientPlayerName,
      'evidenceId': message.evidenceId,
      'reactions': message.reactions.map(_serializeReaction).toList(),
    };
  }

  Map<String, dynamic> _serializeReaction(ChatReaction reaction) {
    return {
      'playerId': reaction.playerId,
      'playerName': reaction.playerName,
      'emoji': reaction.emoji,
      'createdAt': reaction.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _serializeEvidence(GameEvidence evidence) {
    return {
      'id': evidence.id,
      'title': evidence.title,
      'description': evidence.description,
      'assetPath': evidence.assetPath,
      'unlockedInPhase': evidence.unlockedInPhase,
      'unlockedAt': evidence.unlockedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _serializeVote(SuspectVote vote) {
    return {
      'voterPlayerId': vote.voterPlayerId,
      'suspectRoleId': vote.suspectRoleId,
      'createdAt': vote.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _serializeChecklistItem(HostChecklistItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'isCompleted': item.isCompleted,
      'isAuto': item.isAuto,
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

  Map<String, dynamic> _serializeFriendProfile(FriendProfile friend) {
    return {
      'id': friend.id,
      'name': friend.name,
      'createdAt': friend.createdAt.toIso8601String(),
      'favoriteScenario': friend.favoriteScenario,
      'favoriteRole': friend.favoriteRole,
      'note': friend.note,
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
    final evidences = (rawLobby['evidences'] as List<dynamic>? ?? const [])
        .map(_deserializeEvidence)
        .whereType<GameEvidence>()
        .toList();
    final votes = (rawLobby['votes'] as List<dynamic>? ?? const [])
        .map(_deserializeVote)
        .whereType<SuspectVote>()
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
    final mysteryCase = findMysteryCaseById(caseId);
    final hostChecklist = (rawLobby['hostChecklist'] as List<dynamic>? ?? const [])
        .map(_deserializeChecklistItem)
        .whereType<HostChecklistItem>()
        .toList();
    final resolvedChecklist = hostChecklist.isNotEmpty
        ? hostChecklist
        : (mysteryCase == null ? const <HostChecklistItem>[] : _buildDefaultChecklist(mysteryCase));

    final lobby = LobbySession(
      code: code,
      caseId: caseId,
      inviteLink: inviteLink,
      hostId: hostId,
      createdAt: createdAt,
      players: players,
      invitations: invitations,
      roleAssignments: roleAssignments,
      messages: messages,
      evidences: evidences,
      votes: votes,
      revealedHintIds: revealedHintIds,
      hostChecklist: resolvedChecklist,
      phaseIndex: (rawLobby['phaseIndex'] as num?)?.toInt() ?? 0,
      hasStarted: rawLobby['hasStarted'] as bool? ?? false,
      isCompleted: rawLobby['isCompleted'] as bool? ?? false,
      phaseStartedAt:
          DateTime.tryParse(rawLobby['phaseStartedAt'] as String? ?? ''),
    );
    return mysteryCase == null ? lobby : _syncHostChecklist(lobby, mysteryCase);
  }

  HostChecklistItem? _deserializeChecklistItem(dynamic rawItem) {
    if (rawItem is! Map) {
      return null;
    }

    final id = rawItem['id'];
    final title = rawItem['title'];
    if (id is! String || title is! String) {
      return null;
    }

    return HostChecklistItem(
      id: id,
      title: title,
      description: rawItem['description'] as String?,
      isCompleted: rawItem['isCompleted'] as bool? ?? false,
      isAuto: rawItem['isAuto'] as bool? ?? false,
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
      leftAt: DateTime.tryParse(rawPlayer['leftAt'] as String? ?? ''),
      rejoinAvailableUntil:
          DateTime.tryParse(rawPlayer['rejoinAvailableUntil'] as String? ?? ''),
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
      recipientPlayerId: rawMessage['recipientPlayerId'] as String?,
      recipientPlayerName: rawMessage['recipientPlayerName'] as String?,
      evidenceId: rawMessage['evidenceId'] as String?,
      reactions: (rawMessage['reactions'] as List<dynamic>? ?? const [])
          .map(_deserializeReaction)
          .whereType<ChatReaction>()
          .toList(),
    );
  }

  ChatReaction? _deserializeReaction(dynamic rawReaction) {
    if (rawReaction is! Map) {
      return null;
    }

    final playerId = rawReaction['playerId'];
    final playerName = rawReaction['playerName'];
    final emoji = rawReaction['emoji'];
    final createdAt =
        DateTime.tryParse(rawReaction['createdAt'] as String? ?? '');
    if (playerId is! String ||
        playerName is! String ||
        emoji is! String ||
        createdAt == null) {
      return null;
    }

    return ChatReaction(
      playerId: playerId,
      playerName: playerName,
      emoji: emoji,
      createdAt: createdAt,
    );
  }

  GameEvidence? _deserializeEvidence(dynamic rawEvidence) {
    if (rawEvidence is! Map) {
      return null;
    }

    final id = rawEvidence['id'];
    final title = rawEvidence['title'];
    final description = rawEvidence['description'];
    final assetPath = rawEvidence['assetPath'];
    final unlockedAt =
        DateTime.tryParse(rawEvidence['unlockedAt'] as String? ?? '');
    if (id is! String ||
        title is! String ||
        description is! String ||
        assetPath is! String ||
        unlockedAt == null) {
      return null;
    }

    return GameEvidence(
      id: id,
      title: title,
      description: description,
      assetPath: assetPath,
      unlockedInPhase: (rawEvidence['unlockedInPhase'] as num?)?.toInt() ?? 0,
      unlockedAt: unlockedAt,
    );
  }

  SuspectVote? _deserializeVote(dynamic rawVote) {
    if (rawVote is! Map) {
      return null;
    }

    final voterPlayerId = rawVote['voterPlayerId'];
    final suspectRoleId = rawVote['suspectRoleId'];
    final createdAt = DateTime.tryParse(rawVote['createdAt'] as String? ?? '');
    if (voterPlayerId is! String ||
        suspectRoleId is! String ||
        createdAt == null) {
      return null;
    }

    return SuspectVote(
      voterPlayerId: voterPlayerId,
      suspectRoleId: suspectRoleId,
      createdAt: createdAt,
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

  FriendProfile? _deserializeFriendProfile(dynamic rawEntry) {
    if (rawEntry is! Map) {
      return null;
    }

    final id = rawEntry['id'];
    final name = rawEntry['name'];
    final createdAt = DateTime.tryParse(rawEntry['createdAt'] as String? ?? '');
    if (id is! String || name is! String || createdAt == null) {
      return null;
    }

    return FriendProfile(
      id: id,
      name: name,
      createdAt: createdAt,
      favoriteScenario: rawEntry['favoriteScenario'] as String?,
      favoriteRole: rawEntry['favoriteRole'] as String?,
      note: rawEntry['note'] as String? ?? '',
    );
  }
}

String? _favoriteValue(Iterable<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    counts.update(trimmed, (current) => current + 1, ifAbsent: () => 1);
  }

  String? winner;
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      winner = entry.key;
      bestCount = entry.value;
    }
  }
  return winner;
}

double _estimatedHoursPlayed(
  MysteryState state,
  List<MysteryCase> catalog,
) {
  double totalMinutes = 0;
  for (final lobby in state.lobbies) {
    final mysteryCase =
        catalog.where((entry) => entry.id == lobby.caseId).firstOrNull;
    if (mysteryCase == null || !lobby.hasStarted) {
      continue;
    }

    if (lobby.isCompleted) {
      totalMinutes += mysteryCase.phases.fold<double>(
        0,
        (value, phase) => value + phase.durationMinutes,
      );
      continue;
    }

    final visiblePhaseCount =
        (lobby.phaseIndex + 1).clamp(0, mysteryCase.phases.length);
    final phaseMinutes = mysteryCase.phases
        .take(visiblePhaseCount)
        .fold<double>(0, (value, phase) => value + phase.durationMinutes);
    totalMinutes += phaseMinutes;
  }

  if (totalMinutes == 0) {
    return 0;
  }
  return totalMinutes / 60;
}

String? _normalizeOptionalText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}

class UserAccountController extends Notifier<UserAccount?> {
  static const _accountKey = 'user_account_v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  UserAccount? build() {
    final raw = _prefs.getString(_accountKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserAccount.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  void register(UserAccount account) {
    state = account;
    _prefs.setString(_accountKey, jsonEncode(account.toJson()));

    // Auto-populate the local alias from the full name.
    ref.read(mysteryControllerProvider.notifier).updateAlias(account.fullName);
  }

  void logout() {
    state = null;
    _prefs.remove(_accountKey);
  }
}

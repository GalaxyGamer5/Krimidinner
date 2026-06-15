import 'package:flutter/material.dart';

enum MysteryCategory {
  halloween,
  christmas,
  newYearsEve,
  mafia,
  luxuryVilla,
  orientExpress,
  medieval,
  pirates,
  casino,
  twenties,
  vampires,
  wizards,
  detectiveSchool,
  agents,
  zombie,
  custom,
}

extension MysteryCategoryX on MysteryCategory {
  String get label {
    switch (this) {
      case MysteryCategory.halloween:
        return 'Halloween';
      case MysteryCategory.christmas:
        return 'Weihnachten';
      case MysteryCategory.newYearsEve:
        return 'Silvester';
      case MysteryCategory.mafia:
        return 'Mafia';
      case MysteryCategory.luxuryVilla:
        return 'Luxusvilla';
      case MysteryCategory.orientExpress:
        return 'Orient Express';
      case MysteryCategory.medieval:
        return 'Mittelalter';
      case MysteryCategory.pirates:
        return 'Piraten';
      case MysteryCategory.casino:
        return 'Casino';
      case MysteryCategory.twenties:
        return '1920er Jahre';
      case MysteryCategory.vampires:
        return 'Vampire';
      case MysteryCategory.wizards:
        return 'Zauberer';
      case MysteryCategory.detectiveSchool:
        return 'Detektivschule';
      case MysteryCategory.agents:
        return 'Agenten';
      case MysteryCategory.zombie:
        return 'Zombie-Apokalypse';
      case MysteryCategory.custom:
        return 'Eigenes Krimi-Dinner';
    }
  }
}

enum CaseDifficulty { relaxed, medium, sharp, mastermind }

extension CaseDifficultyX on CaseDifficulty {
  String get label {
    switch (this) {
      case CaseDifficulty.relaxed:
        return 'Entspannt';
      case CaseDifficulty.medium:
        return 'Knifflig';
      case CaseDifficulty.sharp:
        return 'Anspruchsvoll';
      case CaseDifficulty.mastermind:
        return 'Meisterhaft';
    }
  }
}

enum BudgetTier { budget, midrange, premium }

extension BudgetTierX on BudgetTier {
  String get label {
    switch (this) {
      case BudgetTier.budget:
        return 'Günstig';
      case BudgetTier.midrange:
        return 'Mittel';
      case BudgetTier.premium:
        return 'Premium';
    }
  }
}

enum AppLanguage { de, en, fr, es }

extension AppLanguageX on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.de:
        return 'Deutsch';
      case AppLanguage.en:
        return 'Englisch';
      case AppLanguage.fr:
        return 'Französisch';
      case AppLanguage.es:
        return 'Spanisch';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.de:
        return 'de';
      case AppLanguage.en:
        return 'en';
      case AppLanguage.fr:
        return 'fr';
      case AppLanguage.es:
        return 'es';
    }
  }
}

@immutable
class OutfitSuggestion {
  const OutfitSuggestion({
    required this.masculine,
    required this.feminine,
    required this.neutral,
    required this.accessories,
    required this.makeup,
    required this.hairstyle,
    required this.budget,
    required this.palette,
  });

  final String masculine;
  final String feminine;
  final String neutral;
  final List<String> accessories;
  final String makeup;
  final String hairstyle;
  final BudgetTier budget;
  final List<String> palette;
}

@immutable
class MysteryRole {
  const MysteryRole({
    required this.id,
    required this.name,
    required this.avatar,
    required this.persona,
    required this.secret,
    required this.motive,
    required this.relationships,
    required this.goal,
    required this.alibi,
    required this.suspicion,
    required this.hiddenClues,
    required this.outfit,
  });

  final String id;
  final String name;
  final String avatar;
  final String persona;
  final String secret;
  final String motive;
  final String relationships;
  final String goal;
  final String alibi;
  final String suspicion;
  final List<String> hiddenClues;
  final OutfitSuggestion outfit;
}

@immutable
class HintCard {
  const HintCard({
    required this.id,
    required this.title,
    required this.detail,
    required this.unlockPhase,
  });

  final String id;
  final String title;
  final String detail;
  final int unlockPhase;
}

@immutable
class GamePhase {
  const GamePhase({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.musicCue,
    required this.soundEffects,
    required this.autoHintIds,
  });

  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String musicCue;
  final List<String> soundEffects;
  final List<String> autoHintIds;
}

@immutable
class MysteryCase {
  const MysteryCase({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.category,
    required this.playerMin,
    required this.playerMax,
    required this.durationMinutes,
    required this.difficulty,
    required this.recommendedAge,
    required this.atmosphere,
    required this.materials,
    required this.coverColors,
    required this.highlights,
    required this.roles,
    required this.hints,
    required this.phases,
  });

  final String id;
  final String title;
  final String tagline;
  final String description;
  final MysteryCategory category;
  final int playerMin;
  final int playerMax;
  final int durationMinutes;
  final CaseDifficulty difficulty;
  final String recommendedAge;
  final String atmosphere;
  final List<String> materials;
  final List<Color> coverColors;
  final List<String> highlights;
  final List<MysteryRole> roles;
  final List<HintCard> hints;
  final List<GamePhase> phases;
}

@immutable
class LobbyPlayer {
  const LobbyPlayer({
    required this.id,
    required this.name,
    required this.joinedAt,
    required this.isHost,
    required this.isOnline,
    this.leftAt,
    this.rejoinAvailableUntil,
  });

  final String id;
  final String name;
  final DateTime joinedAt;
  final bool isHost;
  final bool isOnline;
  final DateTime? leftAt;
  final DateTime? rejoinAvailableUntil;

  bool get canRejoin {
    final deadline = rejoinAvailableUntil;
    return !isOnline && deadline != null && deadline.isAfter(DateTime.now());
  }

  LobbyPlayer copyWith({
    String? id,
    String? name,
    DateTime? joinedAt,
    bool? isHost,
    bool? isOnline,
    DateTime? leftAt,
    DateTime? rejoinAvailableUntil,
    bool clearLeftAt = false,
    bool clearRejoinAvailableUntil = false,
  }) {
    return LobbyPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      joinedAt: joinedAt ?? this.joinedAt,
      isHost: isHost ?? this.isHost,
      isOnline: isOnline ?? this.isOnline,
      leftAt: clearLeftAt ? null : leftAt ?? this.leftAt,
      rejoinAvailableUntil: clearRejoinAvailableUntil
          ? null
          : rejoinAvailableUntil ?? this.rejoinAvailableUntil,
    );
  }
}

enum ChatMessageType { lobby, system, role, direct, evidence }

enum LobbyInvitationStatus { pending, accepted, revoked }

@immutable
class ChatReaction {
  const ChatReaction({
    required this.playerId,
    required this.playerName,
    required this.emoji,
    required this.createdAt,
  });

  final String playerId;
  final String playerName;
  final String emoji;
  final DateTime createdAt;
}

@immutable
class GameEvidence {
  const GameEvidence({
    required this.id,
    required this.title,
    required this.description,
    required this.assetPath,
    required this.unlockedInPhase,
    required this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String assetPath;
  final int unlockedInPhase;
  final DateTime unlockedAt;
}

@immutable
class SuspectVote {
  const SuspectVote({
    required this.voterPlayerId,
    required this.suspectRoleId,
    required this.createdAt,
  });

  final String voterPlayerId;
  final String suspectRoleId;
  final DateTime createdAt;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.createdAt,
    required this.type,
    this.recipientPlayerId,
    this.recipientPlayerName,
    this.evidenceId,
    this.reactions = const [],
  });

  final String id;
  final String sender;
  final String body;
  final DateTime createdAt;
  final ChatMessageType type;
  final String? recipientPlayerId;
  final String? recipientPlayerName;
  final String? evidenceId;
  final List<ChatReaction> reactions;

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? body,
    DateTime? createdAt,
    ChatMessageType? type,
    String? recipientPlayerId,
    String? recipientPlayerName,
    String? evidenceId,
    List<ChatReaction>? reactions,
    bool clearRecipientPlayerId = false,
    bool clearRecipientPlayerName = false,
    bool clearEvidenceId = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      recipientPlayerId: clearRecipientPlayerId
          ? null
          : recipientPlayerId ?? this.recipientPlayerId,
      recipientPlayerName: clearRecipientPlayerName
          ? null
          : recipientPlayerName ?? this.recipientPlayerName,
      evidenceId: clearEvidenceId ? null : evidenceId ?? this.evidenceId,
      reactions: reactions ?? this.reactions,
    );
  }
}

@immutable
class LobbyInvitation {
  const LobbyInvitation({
    required this.id,
    required this.recipientName,
    required this.assignedRoleId,
    required this.createdAt,
    required this.status,
    this.acceptedAt,
    this.acceptedByPlayerId,
  });

  final String id;
  final String recipientName;
  final String assignedRoleId;
  final DateTime createdAt;
  final LobbyInvitationStatus status;
  final DateTime? acceptedAt;
  final String? acceptedByPlayerId;

  LobbyInvitation copyWith({
    String? id,
    String? recipientName,
    String? assignedRoleId,
    DateTime? createdAt,
    LobbyInvitationStatus? status,
    DateTime? acceptedAt,
    String? acceptedByPlayerId,
    bool clearAcceptedAt = false,
    bool clearAcceptedByPlayerId = false,
  }) {
    return LobbyInvitation(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      assignedRoleId: assignedRoleId ?? this.assignedRoleId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      acceptedAt: clearAcceptedAt ? null : acceptedAt ?? this.acceptedAt,
      acceptedByPlayerId: clearAcceptedByPlayerId
          ? null
          : acceptedByPlayerId ?? this.acceptedByPlayerId,
    );
  }
}

@immutable
class LobbySession {
  const LobbySession({
    required this.code,
    required this.caseId,
    required this.inviteLink,
    required this.hostId,
    required this.createdAt,
    required this.players,
    required this.invitations,
    required this.roleAssignments,
    required this.messages,
    required this.evidences,
    required this.votes,
    required this.revealedHintIds,
    required this.phaseIndex,
    required this.hasStarted,
    required this.isCompleted,
    this.phaseStartedAt,
  });

  final String code;
  final String caseId;
  final String inviteLink;
  final String hostId;
  final DateTime createdAt;
  final List<LobbyPlayer> players;
  final List<LobbyInvitation> invitations;
  final Map<String, String> roleAssignments;
  final List<ChatMessage> messages;
  final List<GameEvidence> evidences;
  final List<SuspectVote> votes;
  final List<String> revealedHintIds;
  final int phaseIndex;
  final bool hasStarted;
  final bool isCompleted;
  final DateTime? phaseStartedAt;

  LobbySession copyWith({
    String? code,
    String? caseId,
    String? inviteLink,
    String? hostId,
    DateTime? createdAt,
    List<LobbyPlayer>? players,
    List<LobbyInvitation>? invitations,
    Map<String, String>? roleAssignments,
    List<ChatMessage>? messages,
    List<GameEvidence>? evidences,
    List<SuspectVote>? votes,
    List<String>? revealedHintIds,
    int? phaseIndex,
    bool? hasStarted,
    bool? isCompleted,
    DateTime? phaseStartedAt,
    bool clearPhaseStartedAt = false,
  }) {
    return LobbySession(
      code: code ?? this.code,
      caseId: caseId ?? this.caseId,
      inviteLink: inviteLink ?? this.inviteLink,
      hostId: hostId ?? this.hostId,
      createdAt: createdAt ?? this.createdAt,
      players: players ?? this.players,
      invitations: invitations ?? this.invitations,
      roleAssignments: roleAssignments ?? this.roleAssignments,
      messages: messages ?? this.messages,
      evidences: evidences ?? this.evidences,
      votes: votes ?? this.votes,
      revealedHintIds: revealedHintIds ?? this.revealedHintIds,
      phaseIndex: phaseIndex ?? this.phaseIndex,
      hasStarted: hasStarted ?? this.hasStarted,
      isCompleted: isCompleted ?? this.isCompleted,
      phaseStartedAt:
          clearPhaseStartedAt ? null : phaseStartedAt ?? this.phaseStartedAt,
    );
  }
}

@immutable
class RoleArchiveEntry {
  const RoleArchiveEntry({
    required this.lobbyCode,
    required this.playerName,
    required this.caseTitle,
    required this.characterName,
    required this.signature,
    required this.goal,
    required this.unlockedAt,
  });

  final String lobbyCode;
  final String playerName;
  final String caseTitle;
  final String characterName;
  final String signature;
  final String goal;
  final DateTime unlockedAt;
}

@immutable
class FriendProfile {
  const FriendProfile({
    required this.name,
    required this.favoriteScenario,
    required this.favoriteRole,
    required this.lastSeen,
    required this.isOnline,
  });

  final String name;
  final String favoriteScenario;
  final String favoriteRole;
  final String lastSeen;
  final bool isOnline;
}

@immutable
class Achievement {
  const Achievement({
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.icon,
  });

  final String title;
  final String description;
  final double progress;
  final double target;
  final IconData icon;

  double get completion => target == 0 ? 0 : (progress / target).clamp(0, 1);
}

@immutable
class PlayerStats {
  const PlayerStats({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.detectiveFinds,
    required this.hoursPlayed,
    required this.favoriteRole,
    required this.favoriteScenario,
  });

  final int gamesPlayed;
  final int gamesWon;
  final int detectiveFinds;
  final double hoursPlayed;
  final String favoriteRole;
  final String favoriteScenario;
}

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.musicVolume,
    required this.sfxVolume,
    required this.animationsEnabled,
    required this.notificationsEnabled,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      themeMode: ThemeMode.dark,
      language: AppLanguage.de,
      musicVolume: 0.72,
      sfxVolume: 0.8,
      animationsEnabled: true,
      notificationsEnabled: true,
    );
  }

  final ThemeMode themeMode;
  final AppLanguage language;
  final double musicVolume;
  final double sfxVolume;
  final bool animationsEnabled;
  final bool notificationsEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    double? musicVolume,
    double? sfxVolume,
    bool? animationsEnabled,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

@immutable
class MysteryState {
  const MysteryState({
    required this.localAlias,
    required this.lobbies,
    required this.roleArchive,
    required this.friends,
  });

  final String localAlias;
  final List<LobbySession> lobbies;
  final List<RoleArchiveEntry> roleArchive;
  final List<FriendProfile> friends;

  MysteryState copyWith({
    String? localAlias,
    List<LobbySession>? lobbies,
    List<RoleArchiveEntry>? roleArchive,
    List<FriendProfile>? friends,
  }) {
    return MysteryState(
      localAlias: localAlias ?? this.localAlias,
      lobbies: lobbies ?? this.lobbies,
      roleArchive: roleArchive ?? this.roleArchive,
      friends: friends ?? this.friends,
    );
  }
}

@immutable
class UserAccount {
  const UserAccount({
    required this.fullName,
    required this.dateOfBirth,
    required this.email,
    required this.passwordHash,
  });

  final String fullName;
  final DateTime dateOfBirth;
  final String email;
  final String passwordHash;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'email': email,
        'passwordHash': passwordHash,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        fullName: json['fullName'] as String,
        dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
      );
}

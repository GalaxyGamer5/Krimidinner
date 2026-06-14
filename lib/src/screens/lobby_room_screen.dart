import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
          child: Text('Der zugehörige Fall ist nicht verfügbar.'));
    }

    final state = ref.watch(mysteryControllerProvider);
    final viewer = _playerByName(lobby, state.localAlias);
    final currentRole =
        viewer == null ? null : _roleForPlayer(lobby, mysteryCase, viewer);
    final currentPhase = mysteryCase.phases[lobby.phaseIndex];
    final remaining = _phaseRemaining(lobby, currentPhase);
    final isHost = viewer?.id == lobby.hostId;

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
                  onAddGuests: _addDemoGuests,
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
              SectionPanel(
                title: 'Deine geheime Rolle',
                subtitle: currentRole == null
                    ? 'Sobald du Teil dieser Lobby bist, erscheint dein persönliches Dossier hier.'
                    : 'Nur für ${viewer!.name} sichtbar. Die Rolle wird lokal im Archiv gespeichert.',
                trailing: currentRole == null
                    ? null
                    : InfoPill(
                        label: currentRole.outfit.budget.label,
                        icon: Icons.lock_rounded,
                      ),
                child: currentRole == null
                    ? const Text('Noch keine Rolle verfügbar.')
                    : _RoleDossier(role: currentRole),
              ),
              SectionPanel(
                title: 'Chat',
                subtitle:
                    'Lobby-, Rollen- und Systemmeldungen laufen hier zusammen. Perfekt für die Moderation während des Spiels.',
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
                    'Teile den Code oder den QR direkt mit deiner Runde. Der Host kann Demo-Gäste hinzufügen oder Spieler entfernen.',
                child: _RosterPanel(
                  lobby: lobby,
                  isHost: isHost,
                  onKick: (playerId) => _runHostAction(
                    ref.read(mysteryControllerProvider.notifier).kickPlayer(
                          widget.code,
                          playerId,
                        ),
                  ),
                ),
              ),
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
                title: 'QR- und Link-Einladung',
                child: Column(
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
                  ],
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

  void _addDemoGuests() {
    final added =
        ref.read(mysteryControllerProvider.notifier).addDemoGuests(widget.code);
    if (added == 0) {
      _showMessage('Keine freien Rollenplätze mehr verfügbar.');
      return;
    }
    _showMessage('$added Demo-Gäste wurden hinzugefügt.');
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
  });

  final LobbySession lobby;
  final MysteryCase mysteryCase;
  final GamePhase currentPhase;
  final Duration remaining;

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
                accent: Colors.white),
            InfoPill(
              label: lobby.hasStarted
                  ? 'Phase ${lobby.phaseIndex + 1}'
                  : 'Noch nicht gestartet',
              icon: Icons.timer_outlined,
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
          currentPhase.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppPalette.parchment,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          currentPhase.description,
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
                value: '${lobby.revealedHintIds.length}'),
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
    required this.onAddGuests,
  });

  final LobbySession lobby;
  final bool isHost;
  final VoidCallback onStart;
  final VoidCallback onAdvance;
  final VoidCallback onReshuffle;
  final VoidCallback onAddGuests;

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
                ? 'Starte Phasen, verteile Rollen neu und füge Demo-Gäste für Schnelltests hinzu.'
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
                lobby.isCompleted ? 'Fall abgeschlossen' : 'Nächste Phase'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isHost ? onReshuffle : null,
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Rollen neu verteilen'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isHost ? onAddGuests : null,
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Demo-Gäste hinzufügen'),
          ),
        ],
      ),
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
                icon: Icons.palette_outlined),
          ],
        ),
        const SizedBox(height: 16),
        _DossierLine(title: 'Persönlichkeit', text: role.persona),
        _DossierLine(title: 'Geheimnis', text: role.secret),
        _DossierLine(title: 'Motiv', text: role.motive),
        _DossierLine(title: 'Beziehungen', text: role.relationships),
        _DossierLine(title: 'Ziel', text: role.goal),
        _DossierLine(title: 'Alibi', text: role.alibi),
        _DossierLine(title: 'Verdachtsmoment', text: role.suspicion),
        const SizedBox(height: 8),
        Text('Versteckte Hinweise',
            style: Theme.of(context).textTheme.titleMedium),
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
        Text('Kostümempfehlung',
            style: Theme.of(context).textTheme.titleMedium),
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
    required this.isHost,
    required this.onKick,
  });

  final LobbySession lobby;
  final bool isHost;
  final ValueChanged<String> onKick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lobby.players.map((player) {
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
                    Text(player.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(player.isHost ? 'Host' : 'Ermittler'),
                  ],
                ),
              ),
              if (player.isHost)
                const InfoPill(label: 'Host', icon: Icons.shield_moon_outlined),
              if (!player.isHost && isHost)
                IconButton(
                  onPressed: () => onKick(player.id),
                  icon: const Icon(Icons.person_remove_alt_1_rounded),
                  tooltip: 'Spieler entfernen',
                ),
            ],
          ),
        );
      }).toList(),
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
        InfoPill(
          label: '${currentPhase.title} · ${currentPhase.musicCue}',
          icon: Icons.music_note_rounded,
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
                          icon: Icons.mark_email_read_rounded),
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

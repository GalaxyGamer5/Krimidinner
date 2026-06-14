import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../widgets/mystery_shell.dart';

class LobbiesScreen extends ConsumerStatefulWidget {
  const LobbiesScreen({
    super.key,
    this.prefilledCode,
  });

  final String? prefilledCode;

  @override
  ConsumerState<LobbiesScreen> createState() => _LobbiesScreenState();
}

class _LobbiesScreenState extends ConsumerState<LobbiesScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  String? _selectedCaseId;

  @override
  void initState() {
    super.initState();
    final alias = ref.read(mysteryControllerProvider).localAlias;
    final cases = ref.read(mysteryCatalogProvider);
    _nameController = TextEditingController(text: alias);
    _codeController = TextEditingController(text: widget.prefilledCode ?? '');
    if (cases.isNotEmpty) {
      _selectedCaseId = cases.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobbies = ref.watch(mysteryControllerProvider).lobbies;
    final cases = ref.watch(mysteryCatalogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Lobbyzentrale',
            subtitle:
                'Erstelle einen neuen Raum, teile Einladungslinks oder trete mit einem vorhandenen Code direkt bei.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final createPanel = _CreateLobbyPanel(
                  cases: cases,
                  nameController: _nameController,
                  selectedCaseId: _selectedCaseId,
                  onCaseChanged: (value) =>
                      setState(() => _selectedCaseId = value),
                  onCreate: _createLobby,
                );
                final joinPanel = _JoinLobbyPanel(
                  nameController: _nameController,
                  codeController: _codeController,
                  onJoin: _joinLobby,
                );

                if (!isWide) {
                  return Column(
                    children: [
                      createPanel,
                      const SizedBox(height: 16),
                      joinPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: createPanel),
                    const SizedBox(width: 16),
                    Expanded(child: joinPanel),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SectionPanel(
            title: 'Aktive Raeume',
            subtitle:
                'Alle aktuell im Speicher verfuegbaren Lobbys. Ideal, um den Flow lokal zu testen und Rollen neu zu verteilen.',
            child: lobbies.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Noch keine Lobby angelegt.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Waehle oben einen Fall aus und starte in wenigen Sekunden mit dem ersten Raum.',
                      ),
                    ],
                  )
                : Column(
                    children: lobbies
                        .map(
                          (lobby) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LobbyPreviewCard(lobby: lobby),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _createLobby() {
    final cases = ref.read(mysteryCatalogProvider);
    if (cases.isEmpty) {
      _showMessage('Es stehen aktuell keine Faelle bereit.');
      return;
    }

    final selected =
        cases.where((item) => item.id == _selectedCaseId).firstOrNull;
    if (selected == null) {
      _showMessage('Bitte waehle einen gueltigen Fall aus.');
      return;
    }

    final code = ref.read(mysteryControllerProvider.notifier).createLobby(
          mysteryCase: selected,
          hostName: _nameController.text,
        );
    if (!mounted) {
      return;
    }
    context.go('/lobbies/room/$code');
  }

  void _joinLobby() {
    final error = ref.read(mysteryControllerProvider.notifier).joinLobby(
          code: _codeController.text,
          alias: _nameController.text,
        );

    if (error != null) {
      _showMessage(error);
      return;
    }

    final normalizedCode = _codeController.text.trim().toUpperCase();
    if (!mounted) {
      return;
    }
    context.go('/lobbies/room/$normalizedCode');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CreateLobbyPanel extends StatelessWidget {
  const _CreateLobbyPanel({
    required this.cases,
    required this.nameController,
    required this.selectedCaseId,
    required this.onCaseChanged,
    required this.onCreate,
  });

  final List<MysteryCase> cases;
  final TextEditingController nameController;
  final String? selectedCaseId;
  final ValueChanged<String?> onCaseChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Neues Spiel', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Host-Name vergeben, Fall auswaehlen und in eine frisch erzeugte Lobby springen.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Dein Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: selectedCaseId,
            items: cases
                .map(
                  (mysteryCase) => DropdownMenuItem(
                    value: mysteryCase.id,
                    child: Text(mysteryCase.title),
                  ),
                )
                .toList(),
            onChanged: onCaseChanged,
            decoration: const InputDecoration(
              labelText: 'Krimi-Fall',
              prefixIcon: Icon(Icons.local_library_outlined),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Lobby erstellen'),
          ),
        ],
      ),
    );
  }
}

class _JoinLobbyPanel extends StatelessWidget {
  const _JoinLobbyPanel({
    required this.nameController,
    required this.codeController,
    required this.onJoin,
  });

  final TextEditingController nameController;
  final TextEditingController codeController;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lobby beitreten',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Mit Code, Link oder QR erreichst du denselben Raum. Der Code reicht fuer den lokalen Test sofort aus.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Lobby-Code',
              prefixIcon: Icon(Icons.key_rounded),
              hintText: 'ABCD1234',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Spielername',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onJoin,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Jetzt beitreten'),
          ),
        ],
      ),
    );
  }
}

class _LobbyPreviewCard extends ConsumerWidget {
  const _LobbyPreviewCard({required this.lobby});

  final LobbySession lobby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mysteryCase = ref.watch(mysteryCaseProvider(lobby.caseId));

    return InkWell(
      onTap: () => context.go('/lobbies/room/${lobby.code}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      InfoPill(
                          label: 'Code ${lobby.code}',
                          icon: Icons.qr_code_rounded),
                      InfoPill(
                        label: lobby.hasStarted ? 'Laufend' : 'Bereit',
                        icon: lobby.hasStarted
                            ? Icons.play_circle_outline_rounded
                            : Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mysteryCase?.title ?? 'Unbekannter Fall',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lobby.players.length} Spieler · ${mysteryCase?.durationMinutes ?? 0} Minuten',
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
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

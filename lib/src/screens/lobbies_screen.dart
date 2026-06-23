import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
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
    final strings = ref.watch(appStringsProvider);
    final lobbies = ref.watch(mysteryControllerProvider).lobbies;
    final cases = ref.watch(mysteryCatalogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: strings.tr(
              de: 'Lobbyzentrale',
              en: 'Lobby hub',
              fr: 'Centre des lobbies',
              es: 'Centro de lobbies',
            ),
            subtitle: strings.tr(
              de: 'Erstelle einen neuen Raum, teile Einladungslinks oder trete mit einem vorhandenen Code direkt bei.',
              en: 'Create a new room, share invitation links or join directly with an existing code.',
              fr: 'Cree une nouvelle salle, partage des liens dinvitation ou rejoins directement avec un code existant.',
              es: 'Crea una sala nueva, comparte enlaces de invitacion o entra directamente con un codigo existente.',
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final createPanel = _CreateLobbyPanel(
                  strings: strings,
                  cases: cases,
                  nameController: _nameController,
                  selectedCaseId: _selectedCaseId,
                  onCaseChanged: (value) =>
                      setState(() => _selectedCaseId = value),
                  onCreate: _createLobby,
                );
                final joinPanel = _JoinLobbyPanel(
                  strings: strings,
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
            title: strings.tr(
              de: 'Aktive Raeume',
              en: 'Active rooms',
              fr: 'Salles actives',
              es: 'Salas activas',
            ),
            subtitle: strings.tr(
              de: 'Alle aktuell im Speicher verfuegbaren Lobbys. Ideal, um den Flow lokal zu testen und Rollen neu zu verteilen.',
              en: 'All lobbies currently available in local storage. Great for testing the full flow and reshuffling roles.',
              fr: 'Toutes les lobbies actuellement disponibles dans le stockage local. Ideal pour tester le flux complet et redistribuer les roles.',
              es: 'Todos los lobbies disponibles actualmente en el almacenamiento local. Ideal para probar el flujo completo y reasignar roles.',
            ),
            child: lobbies.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.tr(
                          de: 'Noch keine Lobby angelegt.',
                          en: 'No lobby created yet.',
                          fr: 'Aucune lobby creee pour le moment.',
                          es: 'Todavia no se ha creado ningun lobby.',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.tr(
                          de: 'Waehle oben einen Fall aus und starte in wenigen Sekunden mit dem ersten Raum.',
                          en: 'Pick a case above and start your first room within seconds.',
                          fr: 'Choisis une affaire ci-dessus et lance ta premiere salle en quelques secondes.',
                          es: 'Elige un caso arriba y abre tu primera sala en unos segundos.',
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: lobbies
                        .map(
                          (lobby) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LobbyPreviewCard(
                              strings: strings,
                              lobby: lobby,
                            ),
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
    final strings = ref.read(appStringsProvider);
    final cases = ref.read(mysteryCatalogProvider);
    if (cases.isEmpty) {
      _showMessage(
        strings.tr(
          de: 'Es stehen aktuell keine Faelle bereit.',
          en: 'There are currently no cases available.',
          fr: 'Aucune affaire nest disponible pour le moment.',
          es: 'No hay casos disponibles en este momento.',
        ),
      );
      return;
    }

    final selected =
        cases.where((item) => item.id == _selectedCaseId).firstOrNull;
    if (selected == null) {
      _showMessage(
        strings.tr(
          de: 'Bitte waehle einen gueltigen Fall aus.',
          en: 'Please choose a valid case.',
          fr: 'Merci de choisir une affaire valide.',
          es: 'Elige un caso valido.',
        ),
      );
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
    final controller = ref.read(mysteryControllerProvider.notifier);
    final rejoinError = controller.rejoinLobby(
      code: _codeController.text,
      alias: _nameController.text,
    );
    final error = rejoinError == null
        ? null
        : controller.joinLobby(
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
    required this.strings,
    required this.cases,
    required this.nameController,
    required this.selectedCaseId,
    required this.onCaseChanged,
    required this.onCreate,
  });

  final AppStrings strings;
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
          Text(
            strings.tr(
              de: 'Neues Spiel',
              en: 'New game',
              fr: 'Nouvelle partie',
              es: 'Partida nueva',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              de: 'Host-Name vergeben, Fall auswaehlen und in eine frisch erzeugte Lobby springen.',
              en: 'Choose a host name, pick a case and jump into a freshly created lobby.',
              fr: 'Choisis un nom dhote, selectionne une affaire et entre dans une lobby fraichement creee.',
              es: 'Elige un nombre de anfitrion, selecciona un caso y entra en un lobby recien creado.',
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: strings.tr(
                de: 'Dein Name',
                en: 'Your name',
                fr: 'Ton nom',
                es: 'Tu nombre',
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded),
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
            decoration: InputDecoration(
              labelText: strings.tr(
                de: 'Krimi-Fall',
                en: 'Mystery case',
                fr: 'Affaire mystere',
                es: 'Caso de misterio',
              ),
              prefixIcon: const Icon(Icons.local_library_outlined),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(strings.createLobbyLabel),
          ),
        ],
      ),
    );
  }
}

class _JoinLobbyPanel extends StatelessWidget {
  const _JoinLobbyPanel({
    required this.strings,
    required this.nameController,
    required this.codeController,
    required this.onJoin,
  });

  final AppStrings strings;
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
          Text(
            strings.joinLobby,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              de: 'Mit Code, Link oder QR erreichst du denselben Raum. Der Code reicht fuer den lokalen Test sofort aus.',
              en: 'Code, link or QR all lead to the same room. For local testing, the code is enough right away.',
              fr: 'Code, lien ou QR menent a la meme salle. Pour les tests locaux, le code suffit immediatement.',
              es: 'El codigo, el enlace o el QR llevan a la misma sala. Para pruebas locales, el codigo basta enseguida.',
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: strings.tr(
                de: 'Lobby-Code',
                en: 'Lobby code',
                fr: 'Code de la lobby',
                es: 'Codigo del lobby',
              ),
              prefixIcon: const Icon(Icons.key_rounded),
              hintText: 'ABCD1234',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: strings.tr(
                de: 'Spielername',
                en: 'Player name',
                fr: 'Nom du joueur',
                es: 'Nombre del jugador',
              ),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onJoin,
            icon: const Icon(Icons.login_rounded),
            label: Text(
              strings.tr(
                de: 'Jetzt beitreten',
                en: 'Join now',
                fr: 'Rejoindre maintenant',
                es: 'Unirse ahora',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyPreviewCard extends ConsumerWidget {
  const _LobbyPreviewCard({
    required this.strings,
    required this.lobby,
  });

  final AppStrings strings;
  final LobbySession lobby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mysteryCase = ref.watch(mysteryCaseProvider(lobby.caseId));
    final alias = ref.watch(mysteryControllerProvider).localAlias;
    final rejoinPlayer = lobby.players
        .where(
          (player) =>
              !player.isOnline &&
              player.canRejoin &&
              player.name.toLowerCase() == alias.toLowerCase(),
        )
        .firstOrNull;

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
                        label:
                            '${strings.tr(de: 'Code', en: 'Code', fr: 'Code', es: 'Codigo')} ${lobby.code}',
                        icon: Icons.qr_code_rounded,
                      ),
                      InfoPill(
                        label: rejoinPlayer != null
                            ? strings.tr(
                                de: 'Wiedereinstieg',
                                en: 'Rejoin',
                                fr: 'Reconnexion',
                                es: 'Reingreso',
                              )
                            : lobby.hasStarted
                                ? strings.tr(
                                    de: 'Laufend',
                                    en: 'Live',
                                    fr: 'En cours',
                                    es: 'En curso',
                                  )
                                : strings.tr(
                                    de: 'Bereit',
                                    en: 'Ready',
                                    fr: 'Pret',
                                    es: 'Listo',
                                  ),
                        icon: lobby.hasStarted
                            ? Icons.play_circle_outline_rounded
                            : Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mysteryCase?.title ??
                        strings.tr(
                          de: 'Unbekannter Fall',
                          en: 'Unknown case',
                          fr: 'Affaire inconnue',
                          es: 'Caso desconocido',
                        ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lobby.players.length} ${strings.tr(de: 'Spieler', en: 'players', fr: 'joueurs', es: 'jugadores')} · ${mysteryCase?.durationMinutes ?? 0} ${strings.tr(de: 'Minuten', en: 'minutes', fr: 'minutes', es: 'minutos')}',
                  ),
                ],
              ),
            ),
            Icon(
              rejoinPlayer != null
                  ? Icons.refresh_rounded
                  : Icons.arrow_forward_rounded,
            ),
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

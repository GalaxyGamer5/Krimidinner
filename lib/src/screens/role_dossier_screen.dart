import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_strings.dart';
import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_shell.dart';

class RoleDossierScreen extends ConsumerStatefulWidget {
  const RoleDossierScreen({
    super.key,
    required this.code,
    required this.roleId,
  });

  final String code;
  final String roleId;

  @override
  ConsumerState<RoleDossierScreen> createState() => _RoleDossierScreenState();
}

class _RoleDossierScreenState extends ConsumerState<RoleDossierScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notes = prefs.getString('notes_${widget.code}_${widget.roleId}') ?? '';
    if (mounted) {
      _notesController.text = notes;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes_${widget.code}_${widget.roleId}', _notesController.text);
  }

  @override
  void dispose() {
    _saveNotes();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final state = ref.watch(mysteryControllerProvider);
    final lobby = state.lobbies.where((l) => l.code == widget.code).firstOrNull;
    final mysteryCase = lobby != null ? ref.watch(mysteryCaseProvider(lobby.caseId)) : null;

    if (lobby == null || mysteryCase == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(strings.tr(
            de: 'Rollenakte',
            en: 'Role dossier',
            fr: 'Dossier de role',
            es: 'Dossier del rol',
          )),
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

    final role = mysteryCase.roles.where((r) => r.id == widget.roleId).firstOrNull;
    if (role == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(strings.tr(
            de: 'Rollenakte',
            en: 'Role dossier',
            fr: 'Dossier de role',
            es: 'Dossier del rol',
          )),
        ),
        body: Center(
          child: Text(
            strings.tr(
              de: 'Rolle nicht gefunden.',
              en: 'Role not found.',
              fr: 'Role introuvable.',
              es: 'Rol no encontrado.',
            ),
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.tr(
            de: 'Streng geheim: ${role.name}',
            en: 'Top secret: ${role.name}',
            fr: 'Strictement secret : ${role.name}',
            es: 'Alto secreto: ${role.name}',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/lobbies/room/${widget.code}'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          InfoPill(label: role.name, icon: Icons.person_pin_rounded),
                          InfoPill(
                            label: role.outfit.palette.join(' / '),
                            icon: Icons.palette_outlined,
                          ),
                          InfoPill(
                            label: role.outfit.budget.label,
                            icon: Icons.lock_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildDossierSection(
                        context,
                        strings.tr(
                          de: 'Persoenlichkeit',
                          en: 'Personality',
                          fr: 'Personnalite',
                          es: 'Personalidad',
                        ),
                        role.persona,
                      ),
                      _buildDossierSection(
                        context,
                        strings.tr(
                          de: 'Geheimnis',
                          en: 'Secret',
                          fr: 'Secret',
                          es: 'Secreto',
                        ),
                        role.secret,
                      ),
                      _buildDossierSection(
                        context,
                        strings.tr(
                          de: 'Motiv',
                          en: 'Motive',
                          fr: 'Mobile',
                          es: 'Motivo',
                        ),
                        role.motive,
                      ),
                      _buildDossierSection(
                        context,
                        strings.tr(
                          de: 'Beziehungen',
                          en: 'Relationships',
                          fr: 'Relations',
                          es: 'Relaciones',
                        ),
                        role.relationships,
                      ),
                      _buildDossierSection(
                        context,
                        strings.tr(
                          de: 'Ziel',
                          en: 'Goal',
                          fr: 'Objectif',
                          es: 'Objetivo',
                        ),
                        role.goal,
                      ),
                      _buildDossierSection(
                        context,
                        strings.tr(
                          de: 'Alibi',
                          en: 'Alibi',
                          fr: 'Alibi',
                          es: 'Coartada',
                        ),
                        role.alibi,
                      ),
                      _buildDossierSection(
                        context,
                        strings.tr(
                          de: 'Verdachtsmoment',
                          en: 'Suspicion',
                          fr: 'Soupcon',
                          es: 'Sospecha',
                        ),
                        role.suspicion,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.tr(
                          de: 'Versteckte Hinweise',
                          en: 'Hidden clues',
                          fr: 'Indices caches',
                          es: 'Pistas ocultas',
                        ),
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...role.hiddenClues.map(
                        (clue) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(Icons.circle, size: 8, color: AppPalette.gold),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Text(clue, style: textTheme.bodyLarge)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        strings.tr(
                          de: 'Kostuemempfehlung',
                          en: 'Costume recommendation',
                          fr: 'Suggestion de costume',
                          es: 'Sugerencia de vestuario',
                        ),
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.tr(
                          de: 'Neutral: ${role.outfit.neutral}',
                          en: 'Neutral: ${role.outfit.neutral}',
                          fr: 'Neutre : ${role.outfit.neutral}',
                          es: 'Neutral: ${role.outfit.neutral}',
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.tr(
                          de: 'Accessoires: ${role.outfit.accessories.join(', ')}',
                          en: 'Accessories: ${role.outfit.accessories.join(', ')}',
                          fr: 'Accessoires : ${role.outfit.accessories.join(', ')}',
                          es: 'Accesorios: ${role.outfit.accessories.join(', ')}',
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.tr(
                          de: 'Make-up: ${role.outfit.makeup}',
                          en: 'Makeup: ${role.outfit.makeup}',
                          fr: 'Maquillage : ${role.outfit.makeup}',
                          es: 'Maquillaje: ${role.outfit.makeup}',
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.tr(
                          de: 'Frisur: ${role.outfit.hairstyle}',
                          en: 'Hairstyle: ${role.outfit.hairstyle}',
                          fr: 'Coiffure : ${role.outfit.hairstyle}',
                          es: 'Peinado: ${role.outfit.hairstyle}',
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 48),
                      Text(
                        strings.tr(
                          de: 'Eigene Notizen',
                          en: 'Personal notes',
                          fr: 'Notes personnelles',
                          es: 'Notas personales',
                        ),
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        maxLines: 8,
                        onChanged: (_) => _saveNotes(),
                        decoration: InputDecoration(
                          hintText: strings.tr(
                            de: 'Mache dir Notizen ueber Verdaechtige, Luegen oder Alibis...',
                            en: 'Write down notes about suspects, lies or alibis...',
                            fr: 'Prends des notes sur les suspects, les mensonges ou les alibis...',
                            es: 'Toma notas sobre sospechosos, mentiras o coartadas...',
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDossierSection(BuildContext context, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppPalette.gold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

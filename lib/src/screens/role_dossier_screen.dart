import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final state = ref.watch(mysteryControllerProvider);
    final lobby = state.lobbies.where((l) => l.code == widget.code).firstOrNull;
    final mysteryCase = lobby != null
        ? ref.watch(mysteryCaseProvider(lobby.caseId))
        : null;

    if (lobby == null || mysteryCase == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rollenakte')),
        body: const Center(child: Text('Lobby oder Fall nicht gefunden.')),
      );
    }

    final role = mysteryCase.roles.where((r) => r.id == widget.roleId).firstOrNull;

    if (role == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rollenakte')),
        body: const Center(child: Text('Rolle nicht gefunden.')),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Streng geheim: ${role.name}'),
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
                      _buildDossierSection(context, 'Persönlichkeit', role.persona),
                      _buildDossierSection(context, 'Geheimnis', role.secret),
                      _buildDossierSection(context, 'Motiv', role.motive),
                      _buildDossierSection(context, 'Beziehungen', role.relationships),
                      _buildDossierSection(context, 'Ziel', role.goal),
                      _buildDossierSection(context, 'Alibi', role.alibi),
                      _buildDossierSection(context, 'Verdachtsmoment', role.suspicion),
                      
                      const SizedBox(height: 16),
                      Text('Versteckte Hinweise', style: textTheme.titleLarge),
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
                              Expanded(
                                child: Text(clue, style: textTheme.bodyLarge),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Kostümempfehlung', style: textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text('Neutral: ${role.outfit.neutral}', style: textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Accessoires: ${role.outfit.accessories.join(', ')}', style: textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Make-up: ${role.outfit.makeup}', style: textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Frisur: ${role.outfit.hairstyle}', style: textTheme.bodyLarge),
                      
                      const SizedBox(height: 48),
                      Text('Eigene Notizen', style: textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        maxLines: 8,
                        onChanged: (_) => _saveNotes(),
                        decoration: InputDecoration(
                          hintText: 'Mache dir Notizen über Verdächtige, Lügen oder Alibis...',
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
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppPalette.gold)),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

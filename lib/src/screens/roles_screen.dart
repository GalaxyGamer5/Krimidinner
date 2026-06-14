import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import '../widgets/mystery_shell.dart';

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archive = ref.watch(mysteryControllerProvider).roleArchive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Persönliches Rollenarchiv',
            subtitle:
                'Jede Rolle, die du im Verlauf einer Lobby zugewiesen bekommst, wird hier lokal festgehalten. So behältst du Ziel, Signatur und Fallkontext im Blick.',
            child: archive.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Noch keine Rolle gespeichert.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Erstelle eine Lobby oder tritt einem Raum bei, um sofort dein erstes Dossier zu archivieren.',
                      ),
                    ],
                  )
                : Column(
                    children: archive.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Colors.white.withOpacity(0.04),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                InfoPill(
                                    label: entry.caseTitle,
                                    icon: Icons.menu_book_rounded),
                                InfoPill(
                                    label: 'Lobby ${entry.lobbyCode}',
                                    icon: Icons.key_rounded),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              entry.characterName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(entry.signature),
                            const SizedBox(height: 12),
                            Text(
                              'Ziel: ${entry.goal}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Freigeschaltet für ${entry.playerName} am ${_formatDate(entry.unlockedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
  }
}

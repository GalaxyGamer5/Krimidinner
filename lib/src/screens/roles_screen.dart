import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../state/app_providers.dart';
import '../widgets/mystery_shell.dart';

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final archive = ref.watch(mysteryControllerProvider).roleArchive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: strings.rolesArchiveTitle,
            subtitle: strings.rolesArchiveSubtitle,
            child: archive.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.noRolesTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(strings.noRolesBody),
                    ],
                  )
                : Column(
                    children: archive.map((entry) {
                      final date = _formatDate(entry.unlockedAt);
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
                                  icon: Icons.menu_book_rounded,
                                ),
                                InfoPill(
                                  label: strings.lobbyLabel(entry.lobbyCode),
                                  icon: Icons.key_rounded,
                                ),
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
                              strings.goalLabel(entry.goal),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strings.unlockedFor(entry.playerName, date),
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

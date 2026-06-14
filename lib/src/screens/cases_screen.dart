import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mystery_shell.dart';

class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  MysteryCategory? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(mysteryCatalogProvider);
    final visibleCases = selectedCategory == null
        ? cases
        : cases.where((item) => item.category == selectedCategory).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Kuratiertes Krimi-Archiv',
            subtitle:
                'Wähl ein Szenario mit klarer Atmosphäre, passender Spielerzahl und sofort spielbaren Rollendossiers.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilterChip(
                      label: const Text('Alle'),
                      selected: selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => selectedCategory = null),
                    ),
                    ...MysteryCategory.values.map(
                      (category) => FilterChip(
                        label: Text(category.label),
                        selected: selectedCategory == category,
                        onSelected: (_) =>
                            setState(() => selectedCategory = category),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Aktüll verfügbar: ${visibleCases.length} spielbereite Fälle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1200
                  ? 3
                  : constraints.maxWidth >= 760
                      ? 2
                      : 1;
              return GridView.builder(
                itemCount: visibleCases.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: columns == 1 ? 1.12 : 0.94,
                ),
                itemBuilder: (context, index) {
                  final mysteryCase = visibleCases[index];
                  return _CaseCard(mysteryCase: mysteryCase);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.mysteryCase});

  final MysteryCase mysteryCase;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/cases/${mysteryCase.id}'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              mysteryCase.coverColors.first.withOpacity(0.92),
              mysteryCase.coverColors[1].withOpacity(0.86),
              mysteryCase.coverColors.last.withOpacity(0.78),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoPill(
              label: mysteryCase.category.label,
              icon: Icons.local_activity_rounded,
              accent: Colors.white,
            ),
            const Spacer(),
            Text(
              mysteryCase.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppPalette.parchment,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              mysteryCase.tagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.parchment.withOpacity(0.92),
                  ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetaBubble(
                  label:
                      '${mysteryCase.playerMin}-${mysteryCase.playerMax} Spieler',
                ),
                _MetaBubble(label: '${mysteryCase.durationMinutes} Min'),
                _MetaBubble(label: mysteryCase.difficulty.label),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              mysteryCase.highlights.first,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.parchment.withOpacity(0.9),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Details öffnen',
                  style: TextStyle(
                    color: AppPalette.parchment,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppPalette.parchment,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBubble extends StatelessWidget {
  const _MetaBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppPalette.parchment,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

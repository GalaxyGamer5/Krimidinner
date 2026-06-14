import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration:
                BoxDecoration(gradient: MysteryDecor.background(isDark)),
          ),
          Positioned(
            left: -30,
            top: 100,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 10),
              tween: Tween(begin: -20, end: 30),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(value, 0),
                  child: child,
                );
              },
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.gold.withOpacity(0.08),
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: 180,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 14),
              tween: Tween(begin: 40, end: -20),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                );
              },
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.wine.withOpacity(0.12),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.04),
                    Colors.transparent,
                    Colors.black.withOpacity(0.14),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: MysteryDecor.panel(context, opacity: 0.76),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 820;
                        return isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _buildNarrative(context, textTheme),
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(
                                    child: _buildAtmospherePanel(context),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildNarrative(context, textTheme),
                                  const SizedBox(height: 24),
                                  _buildAtmospherePanel(context),
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrative(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroBadge(label: 'Premium Multiplayer Mystery'),
        const SizedBox(height: 24),
        Text(
          'MYSTERY NIGHT',
          style: textTheme.displayMedium?.copyWith(
            letterSpacing: 3.6,
            height: 1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Das Geheimnis wartet.',
          style: textTheme.headlineSmall?.copyWith(
            color: AppPalette.gold,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Erstelle elegante Lobbys, teile QR-Codes, verteile geheime Rollen und fuehre deine Runde durch cineastische Krimi-Dinner-Abende auf Web, Android und iOS.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _FeatureChip(label: 'Nebel-Atmosphaere'),
            _FeatureChip(label: 'Rollen nur fuer dich sichtbar'),
            _FeatureChip(label: 'QR- und Link-Einladungen'),
            _FeatureChip(label: 'Phasen mit Countdown'),
          ],
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => context.go('/hub'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Spiel starten'),
        ),
      ],
    );
  }

  Widget _buildAtmospherePanel(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.midnight.withOpacity(0.86),
            AppPalette.noir.withOpacity(0.72),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.nightlight_round, color: AppPalette.gold),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Inszenierung beim Start',
                  style: TextStyle(
                    color: AppPalette.parchment,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Langsam ziehender Nebel, flackernde Laternen, regennasse Fensterscheiben und eine ruhige Kamera-Drift schaffen bereits auf dem Startscreen die richtige Stimmung.',
            style: textTheme.bodyMedium?.copyWith(color: AppPalette.parchment),
          ),
          const SizedBox(height: 18),
          const _AtmosphereLine(
              'Villa im Hintergrund, als geheimnisvolle Silhouette'),
          const _AtmosphereLine(
              'Elegante Serifentitel fuer cineastische Wirkung'),
          const _AtmosphereLine(
              'Atmosphaerische Audio- und Hinweis-Hooks fuer spaetere Assets'),
          const _AtmosphereLine(
              'Responsiv von Smartphone bis Desktop ausgelegt'),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.gold.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppPalette.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(label),
    );
  }
}

class _AtmosphereLine extends StatelessWidget {
  const _AtmosphereLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: AppPalette.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppPalette.parchment),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroBadge(label: strings.introBadge),
                        const SizedBox(height: 24),
                        Text(
                          strings.appName,
                          style: textTheme.displayMedium?.copyWith(
                            letterSpacing: 3.6,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          strings.introHeadline,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppPalette.gold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          strings.introDescription,
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.go('/hub'),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(strings.startGame),
                        ),
                      ],
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

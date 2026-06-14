import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class MysteryShell extends StatelessWidget {
  const MysteryShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  static const List<_Destination> _destinations = [
    _Destination(label: 'Salon', icon: Icons.home_rounded, path: '/hub'),
    _Destination(
        label: 'Faelle', icon: Icons.auto_stories_rounded, path: '/cases'),
    _Destination(label: 'Lobbys', icon: Icons.groups_rounded, path: '/lobbies'),
    _Destination(
        label: 'Rollen', icon: Icons.person_search_rounded, path: '/roles'),
    _Destination(label: 'Konto', icon: Icons.tune_rounded, path: '/account'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1080;
        final selectedIndex = _selectedIndex();
        final title = _pageTitle();

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          bottomNavigationBar: isWide
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: NavigationBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) {
                        context.go(_destinations[index].path);
                      },
                      destinations: _destinations
                          .map(
                            (item) => NavigationDestination(
                              icon: Icon(item.icon),
                              label: item.label,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
          body: Stack(
            children: [
              const MysteryBackdrop(),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 16,
                    isWide ? 24 : 14,
                    isWide ? 28 : 16,
                    0,
                  ),
                  child: Column(
                    children: [
                      _ShellHeader(title: title),
                      const SizedBox(height: 18),
                      Expanded(
                        child: isWide
                            ? Row(
                                children: [
                                  _RailPanel(
                                    destinations: _destinations,
                                    selectedIndex: selectedIndex,
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _ContentFrame(child: child),
                                  ),
                                ],
                              )
                            : _ContentFrame(child: child),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _selectedIndex() {
    if (location.startsWith('/cases')) {
      return 1;
    }
    if (location.startsWith('/lobbies')) {
      return 2;
    }
    if (location.startsWith('/roles')) {
      return 3;
    }
    if (location.startsWith('/account')) {
      return 4;
    }
    return 0;
  }

  String _pageTitle() {
    if (location.startsWith('/cases/')) {
      return 'Krimiakte';
    }
    if (location.startsWith('/cases')) {
      return 'Krimi-Auswahl';
    }
    if (location.startsWith('/lobbies/room/')) {
      return 'Live-Lobby';
    }
    if (location.startsWith('/lobbies')) {
      return 'Lobby-System';
    }
    if (location.startsWith('/roles')) {
      return 'Meine Rollen';
    }
    if (location.startsWith('/account')) {
      return 'Freunde, Erfolge und Einstellungen';
    }
    return 'MYSTERY NIGHT';
  }
}

class MysteryBackdrop extends StatelessWidget {
  const MysteryBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(gradient: MysteryDecor.background(isDark)),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            left: -40,
            child: _Orb(
              diameter: 260,
              color: AppPalette.gold.withOpacity(isDark ? 0.08 : 0.09),
            ),
          ),
          Positioned(
            top: 120,
            right: -30,
            child: _Orb(
              diameter: 220,
              color: AppPalette.wine.withOpacity(isDark ? 0.12 : 0.08),
            ),
          ),
          Positioned(
            bottom: -60,
            left: 120,
            child: _Orb(
              diameter: 260,
              color: AppPalette.midnight.withOpacity(isDark ? 0.18 : 0.1),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(isDark ? 0.015 : 0.08),
                    Colors.transparent,
                    Colors.black.withOpacity(isDark ? 0.08 : 0.02),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: MysteryDecor.panel(context, opacity: 0.74),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MYSTERY NIGHT',
                  style: textTheme.titleLarge?.copyWith(
                    letterSpacing: 1.8,
                    color: isDark ? AppPalette.gold : AppPalette.midnight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const InfoPill(
            icon: Icons.radio_button_checked_rounded,
            label: 'Atmosphaere aktiv',
          ),
        ],
      ),
    );
  }
}

class _RailPanel extends StatelessWidget {
  const _RailPanel({
    required this.destinations,
    required this.selectedIndex,
  });

  final List<_Destination> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      decoration: MysteryDecor.panel(context, opacity: 0.74),
      child: NavigationRail(
        labelType: NavigationRailLabelType.all,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          context.go(destinations[index].path);
        },
        destinations: destinations
            .map(
              (item) => NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ContentFrame extends StatelessWidget {
  const _ContentFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MysteryDecor.panel(context, opacity: 0.82),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: child,
      ),
    );
  }
}

class SectionPanel extends StatelessWidget {
  const SectionPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: padding,
      decoration: MysteryDecor.panel(context),
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
                    Text(title, style: textTheme.headlineSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle!, style: textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    this.icon,
    this.accent,
  });

  final String label;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseAccent = accent ?? AppPalette.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: baseAccent.withOpacity(isDark ? 0.14 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: baseAccent),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppPalette.parchment : AppPalette.midnight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.caption,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark
            ? Colors.white.withOpacity(0.035)
            : Colors.white.withOpacity(0.84),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : AppPalette.midnight.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppPalette.gold),
            const SizedBox(height: 14),
          ],
          Text(value, style: textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(label, style: textTheme.titleMedium),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(caption!, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class TwoColumnLayout extends StatelessWidget {
  const TwoColumnLayout({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final List<Widget> primary;
  final List<Widget> secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...primary.expand((item) => [item, const SizedBox(height: 16)]),
              ...secondary.expand((item) => [item, const SizedBox(height: 16)]),
            ]..removeLast(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  ...primary
                      .expand((item) => [item, const SizedBox(height: 16)]),
                ]..removeLast(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  ...secondary
                      .expand((item) => [item, const SizedBox(height: 16)]),
                ]..removeLast(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

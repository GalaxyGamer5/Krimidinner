import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'localization/app_strings.dart';
import 'models/mystery_models.dart';
import 'router/app_router.dart';
import 'state/app_providers.dart';
import 'theme/app_theme.dart';

class MysteryNightApp extends ConsumerWidget {
  const MysteryNightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final strings = ref.watch(appStringsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: Locale(settings.language.code),
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('fr'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AAGuardianApp(),
    ),
  );
}

class AAGuardianApp extends ConsumerWidget {
  const AAGuardianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'Adiss Road',

      // Current selected language
      locale: locale,

      // English + Amharic
      supportedLocales: const AppLocalizationsDelegate().supportedLocales,

      // Flutter + our custom localization
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      debugShowCheckedModeBanner: false,

      theme: appTheme.light,
      darkTheme: appTheme.dark,
      themeMode: ThemeMode.light,

      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
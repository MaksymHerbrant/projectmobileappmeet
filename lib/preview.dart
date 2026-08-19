// Стенд для перевірки оформлення.
//
// Не входить у застосунок: жодний файл із lib/ його не імпортує, у збірку він
// потрапляє тільки коли явно вказаний як точка входу:
//
//   flutter build web -t lib/preview.dart
//   відкрити  index.html#login  або  #registration
//
// Потрібен, бо більшість екранів лежить за реєстрацією, і побачити їх на
// різних розмірах екрана інакше можна лише пройшовши весь потік вручну.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'l10n/gen/app_localizations.dart';
import 'providers/app_state_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const _PreviewApp(),
    ),
  );
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final name = uri.fragment.split('?').first;
    final dark = uri.fragment.contains('dark');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('uk'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: switch (name.replaceAll('-dark', '')) {
        'login' => const LoginScreen(),
        'registration' => const RegistrationScreen(),
        _ => const LandingScreen(),
      },
    );
  }
}

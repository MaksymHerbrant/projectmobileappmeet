import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'l10n/gen/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/main_navigation_screen.dart';
// Зверни увагу: перевір, чи правильний шлях до екрану чату у твоїх папках!
import 'screens/conversation_screen.dart';
import 'config/app_config.dart';
import 'service/error_reporter.dart';

// 1. ГЛОБАЛЬНИЙ КЛЮЧ НАВІГАЦІЇ
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ФОНОВИЙ ОБРОБНИК (Має бути тут, на самому верху)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Фонове повідомлення: ${message.messageId}");
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(
            create: (_) => LocaleProvider()..syncLocaleToProfile()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(), // Ось тут викликається MyApp
    ),
  );
}

void main() async {
  // Без SENTRY_DSN застосунок стартує звичайним шляхом — інтеграція вмикається
  // лише тоді, коли ключ передали через --dart-define.
  if (AppConfig.sentryDsn.isEmpty) {
    await _bootstrap();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.environment = AppConfig.environment;
      // Трасування лише частини сесій: повне з'їдає квоту за дні.
      options.tracesSampleRate = 0.2;
      // У профілі є телефон і фото — жодних тіл запитів і PII у звітах.
      options.sendDefaultPii = false;
    },
    appRunner: _bootstrap,
  );
}

// 2. ОСЬ ТВІЙ MyApp (Він прямо тут!)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // 🔥 ДОДАЛИ КЛЮЧ СЮДИ
          title: 'Dating App',
          debugShowCheckedModeBanner: false,
          // null → мова телефона; MaterialApp сам зведе її до підтримуваної
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.mode,
          home: const AuthGate(),
          routes: {
            '/landing': (context) => const LandingScreen(),
            '/main': (context) => const MainNavigationScreen(),
          },
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Потік створюється один раз.
  ///
  /// Раніше він брався прямо в build(), і кожна перебудова давала новий
  /// об'єкт — StreamBuilder відписувався й підписувався знову, а Supabase
  /// на кожну підписку перевіряв сесію. Звідси черга «Refresh session»
  /// у журналі.
  late final Stream<AuthState> _authChanges =
      Supabase.instance.client.auth.onAuthStateChange;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationsAndListen();
    });

    // 🔥 ДОДАЛИ СЛУХАЧІВ ДЛЯ КЛІКІВ ПО ПУШАХ

    // А) Коли додаток згорнутий, але працює
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Б) Коли додаток був повністю вбитий
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationClick(message);
        });
      }
    });
  }

  // 🔥 ЛОГІКА НАВІГАЦІЇ ПРИ КЛІКУ
  void _handleNotificationClick(RemoteMessage message) {
    debugPrint("👉 КОРИСТУВАЧ НАТИСНУВ НА ПУШ: ${message.data}");

    final data = message.data;

    // Якщо прийшов пуш про чат
    if (data['type'] == 'chat') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            roomId: data['roomId'] ?? '',
            otherUserId: data['otherUserId'] ?? '',
            userName: data['userName'] ?? 'Чат',
            userPhoto: data['userPhoto'] ?? AppConfig.placeholderAvatarUrl,
            isOnline: false,
            isGroup: false,
          ),
        ),
      );
    }
    // Якщо прийшов пуш про лайк/матч
    else if (data['type'] == 'match' || data['type'] == 'like') {
      navigatorKey.currentState?.pushNamed('/main');
    }
  }

  /// Чи вже реєстрували токен у цьому запуску.
  bool _tokenRequested = false;

  /// Отримує токен пушів один раз за запуск.
  ///
  /// Помилка тут не має валити застосунок: на вебі сповіщення вимагають
  /// service worker, і в режимі розробки він часто не реєструється —
  /// це позначається на пушах, але не на решті застосунку.
  void _registerTokenOnce() {
    if (_tokenRequested) return;
    _tokenRequested = true;
    _resolveToken();
  }

  Future<void> _resolveToken() async {
    try {
      // На iOS токен FCM неможливо отримати, доки система не видала APNS-токен,
      // а це стається за кілька секунд після запуску. Без очікування getToken()
      // просто падає з apns-token-not-set, і пристрій лишається без пушів до
      // наступного запуску.
      if (!kIsWeb && Platform.isIOS) {
        for (var attempt = 0; attempt < 10; attempt++) {
          if (await FirebaseMessaging.instance.getAPNSToken() != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveTokenToSupabase(token);
    } catch (e) {
      debugPrint('Пуші недоступні: $e');
    }
  }

  Future<void> _setupNotificationsAndListen() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.instance.onTokenRefresh.listen(
        _saveTokenToSupabase,
        onError: (Object e) => debugPrint('Оновлення токена не вдалося: $e'),
      );
    } catch (e) {
      // Те саме: без пушів застосунок працює повністю.
      debugPrint('Налаштування пушів пропущено: $e');
    }
  }

  /// Токени живуть у user_devices, а не в профілі: профіль читає кожен
  /// авторизований користувач, і токен там був доступний усім.
  Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('user_devices').upsert({
        'profile_id': user.id,
        'fcm_token': token,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('🚀 FCM токен збережено');
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'saveTokenToSupabase');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authChanges,
      builder: (context, snapshot) {
        // Джерело правди — поточна сесія клієнта, а не остання подія потоку:
        // події бувають і без сесії (оновлення користувача, поновлення
        // токена), і на них екран стрибав би на вітання.
        final session = Supabase.instance.client.auth.currentSession;

        // Спінер лише поки сесія справді невідома. Якщо вона вже є в
        // пам'яті, чекати на першу подію потоку немає сенсу — саме це
        // затримувало вхід.
        if (session == null &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (session != null) {
          // Реєстрація токена — побічний ефект, і в build() їй не місце:
          // build викликається на кожну перебудову, тож токен запитувався
          // й перезаписувався знову і знову.
          _registerTokenOnce();
          return const MainNavigationScreen();
        }
        return const LandingScreen();
      },
    );
  }
}

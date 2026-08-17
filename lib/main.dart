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
import 'screens/landing_screen.dart'; 
import 'screens/main_navigation_screen.dart';
// Зверни увагу: перевір, чи правильний шлях до екрану чату у твоїх папках!
import 'screens/conversation_screen.dart';
import 'config/app_config.dart';

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
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
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
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // 🔥 ДОДАЛИ КЛЮЧ СЮДИ
          title: 'Dating App',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale, 
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF3E5F5)),
            useMaterial3: true,
          ),
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
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
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

  Future<void> _setupNotificationsAndListen() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(newToken);
    });
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('🚀 FCM Token saved: $token');
      } catch (e) {
        debugPrint('❌ Error saving token: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;
        if (session != null) {
          FirebaseMessaging.instance.getToken().then((token) {
            if (token != null) _saveTokenToSupabase(token);
          });
          return const MainNavigationScreen();
        }
        return const LandingScreen();
      },
    );
  }
}
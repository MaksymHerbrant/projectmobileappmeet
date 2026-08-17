/// Конфіг з --dart-define (CI/build). Для локального запуску без define використовується fallback.
/// Приклад: flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oiibnyhkbfkwchtnqtqw.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Jv8X1exKVYALxppe9FuFpg_N2DGM5hz',
  );
  static const String phonePrefix = String.fromEnvironment(
    'PHONE_PREFIX',
    defaultValue: '+380',
  );
  static const String placeholderAvatarUrl = String.fromEnvironment(
    'PLACEHOLDER_AVATAR_URL',
    defaultValue: 'https://ui-avatars.com/api/?name=User',
  );

  /// Порожній за замовчуванням — без DSN Sentry просто не вмикається,
  /// і застосунок працює як раніше. Для збірок:
  ///   flutter build apk --dart-define=SENTRY_DSN=https://...
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Окремі середовища в Sentry, щоб помилки з дебагу не змішувались із продом.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
}

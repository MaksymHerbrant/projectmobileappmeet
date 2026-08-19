import 'package:flutter/material.dart';

/// Семантичні кольори, яких немає в ColorScheme.
///
/// Успіх, попередження і статус «онлайн» не виводяться з акценту, але мусять
/// змінюватись разом із темою — на темному тлі ті самі відтінки нечитабельні.
@immutable
class AppSemantics extends ThemeExtension<AppSemantics> {
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color online;

  const AppSemantics({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.online,
  });

  static const light = AppSemantics(
    success: Color(0xFF1B6B3C),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF8A5B00),
    online: Color(0xFF1B8A4B),
  );

  static const dark = AppSemantics(
    success: Color(0xFF6EDBA0),
    onSuccess: Color(0xFF00391E),
    warning: Color(0xFFE2B159),
    online: Color(0xFF4CD98A),
  );

  @override
  AppSemantics copyWith({Color? success, Color? onSuccess, Color? warning, Color? online}) =>
      AppSemantics(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        warning: warning ?? this.warning,
        online: online ?? this.online,
      );

  @override
  AppSemantics lerp(ThemeExtension<AppSemantics>? other, double t) {
    if (other is! AppSemantics) return this;
    return AppSemantics(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      online: Color.lerp(online, other.online, t)!,
    );
  }
}

/// Оформлення застосунку в одному місці.
///
/// Гама «Графіт»: приглушена сталь. Обрана свідомо — у застосунку про людей
/// головний контент це фото, і нейтральний інтерфейс лишає їм більше простору.
class AppTheme {
  const AppTheme._();

  /// Насіннєвий колір. Уся решта відтінків виводиться з нього автоматично,
  /// тож зміна гами — це зміна цього рядка.
  static const Color seed = Color(0xFF475569);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Фон екранів. Ледь помітний градієнт замість заливки — так само, як було
  /// раніше, але виведений з теми, а не вписаний у кожен екран.
  static List<Color> backgroundGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const [Color(0xFF1A2029), Color(0xFF0E1116)]
        : const [Color(0xFFE9EEF6), Color(0xFFFDFDFF)];
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF111418) : const Color(0xFFF8F9FF),
    );

    return base.copyWith(
      extensions: [isDark ? AppSemantics.dark : AppSemantics.light],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1B2028) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        tileColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2A3038) : const Color(0xFF2E343C),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSecondaryContainer),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

/// Короткий доступ до кольорів у віджетах.
extension AppThemeX on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  AppSemantics get semantics => Theme.of(this).extension<AppSemantics>()!;
}

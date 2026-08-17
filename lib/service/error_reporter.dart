import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Помилка, яку варто показати користувачу текстом, а не проковтнути.
class AppFailure implements Exception {
  final String message;
  final bool isRateLimit;

  const AppFailure(this.message, {this.isRateLimit = false});

  @override
  String toString() => message;
}

/// Єдина точка обробки помилок.
///
/// Раніше майже кожен метод сервісу закінчувався `catch { return [] }`:
/// користувач бачив порожній екран замість причини, а в проді не лишалось
/// жодного сліду. Тепер помилка потрапляє в Sentry (якщо заданий DSN) і
/// перетворюється на текст, який можна показати.
class ErrorReporter {
  const ErrorReporter._();

  /// Надіслати помилку в Sentry. У дебагу — просто в консоль.
  static Future<void> report(
    Object error,
    StackTrace? stack, {
    String? context,
  }) async {
    if (kDebugMode) {
      debugPrint('❌ ${context ?? 'error'}: $error');
    }
    await Sentry.captureException(
      error,
      stackTrace: stack,
      withScope: (scope) {
        if (context != null) scope.setTag('operation', context);
      },
    );
  }

  /// Перетворює технічну помилку на повідомлення для користувача.
  ///
  /// Окремо розпізнає rate limit: сервер повертає SQLSTATE 53400, і людині
  /// треба сказати «зачекайте», а не «щось пішло не так».
  static AppFailure toFailure(Object error) {
    if (error is AppFailure) return error;

    if (error is PostgrestException) {
      if (error.code == '53400') {
        return const AppFailure(
          'Забагато дій поспіль. Спробуйте трохи пізніше.',
          isRateLimit: true,
        );
      }
      if (error.code == '42501' || error.code == 'PGRST301') {
        return const AppFailure('Немає доступу до цих даних.');
      }
      return const AppFailure('Не вдалося зберегти зміни. Спробуйте ще раз.');
    }

    if (error is AuthException) {
      return AppFailure(error.message);
    }

    if (error is StorageException) {
      return const AppFailure(
        'Не вдалося завантажити фото. Перевірте розмір і формат файлу.',
      );
    }

    return const AppFailure("Немає зв'язку з сервером. Перевірте інтернет.");
  }

  /// Зареєструвати помилку і одразу отримати текст для інтерфейсу.
  static Future<AppFailure> handle(
    Object error,
    StackTrace? stack, {
    String? context,
  }) async {
    await report(error, stack, context: context);
    return toFailure(error);
  }
}

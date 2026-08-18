import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/gen/app_localizations.dart';

/// Про що саме помилка.
///
/// Сервіси не мають доступу до контексту, тому не можуть перекладати текст.
/// Вони повертають код, а текст добирає інтерфейс — інакше повідомлення про
/// помилки назавжди залишились би однією мовою.
enum FailureKind {
  rateLimit,
  forbidden,
  save,
  storage,
  network,
  notAuthenticated,
  smsFailed,
  wrongCode,
  updatePassword,
  deleteAccount,
  unknown,
}

/// Помилка, яку варто показати користувачу.
class AppFailure implements Exception {
  final FailureKind kind;

  /// Технічні подробиці — для журналів, не для показу.
  final String? details;

  const AppFailure(this.kind, {this.details});

  bool get isRateLimit => kind == FailureKind.rateLimit;

  String localized(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (kind) {
      FailureKind.rateLimit => t.err_rate_limit,
      FailureKind.forbidden => t.err_forbidden,
      FailureKind.save => t.err_save,
      FailureKind.storage => t.err_storage,
      FailureKind.network => t.err_network,
      FailureKind.notAuthenticated => t.err_not_authed,
      FailureKind.smsFailed => t.err_sms_failed,
      FailureKind.wrongCode => t.err_wrong_code,
      FailureKind.updatePassword => t.err_update_password,
      FailureKind.deleteAccount => t.err_delete_account,
      FailureKind.unknown => t.err_unknown,
    };
  }

  @override
  String toString() => 'AppFailure(${kind.name}${details == null ? '' : ': $details'})';
}

/// Єдина точка обробки помилок.
class ErrorReporter {
  const ErrorReporter._();

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

  /// Технічна помилка → код, зрозумілий інтерфейсу.
  static AppFailure toFailure(Object error) {
    if (error is AppFailure) return error;

    if (error is PostgrestException) {
      // 53400 — наш ліміт частоти; людині треба сказати «зачекайте»,
      // а не «щось пішло не так».
      if (error.code == '53400') return const AppFailure(FailureKind.rateLimit);
      if (error.code == '42501' || error.code == 'PGRST301') {
        return const AppFailure(FailureKind.forbidden);
      }
      return AppFailure(FailureKind.save, details: error.message);
    }

    if (error is AuthException) {
      return AppFailure(FailureKind.unknown, details: error.message);
    }

    if (error is StorageException) {
      return AppFailure(FailureKind.storage, details: error.message);
    }

    return AppFailure(FailureKind.network, details: error.toString());
  }

  /// Текст помилки для показу, вже перекладений.
  static String message(BuildContext context, Object error) =>
      toFailure(error).localized(context);

  static Future<AppFailure> handle(
    Object error,
    StackTrace? stack, {
    String? context,
  }) async {
    await report(error, stack, context: context);
    return toFailure(error);
  }
}

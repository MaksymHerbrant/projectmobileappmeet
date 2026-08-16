import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Відправка пушів через Supabase Edge Function.
///
/// Клієнт передає лише receiver_id. Токен пристрою читає сама Edge Function
/// під service_role — чужі FCM-токени тепер недоступні з застосунку, і функція
/// перевіряє, що відправник має право писати отримувачу.
class NotificationService {
  final _supabase = Supabase.instance.client;
  static const String _functionName = 'send-push';
  static const Duration _invokeTimeout = Duration(seconds: 15);

  Future<void> sendPush({
    required String receiverId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await _supabase.functions
          .invoke(
            _functionName,
            body: {
              'receiver_id': receiverId,
              'title': title,
              'body': body,
              'data': data ?? {},
            },
          )
          .timeout(_invokeTimeout);
      if (kDebugMode) debugPrint('🚀 Пуш надіслано через Edge Function');
    } on TimeoutException {
      if (kDebugMode) debugPrint('❌ Помилка пуша: тайм-аут запиту');
    } on FunctionException catch (e) {
      if (kDebugMode) debugPrint('❌ Помилка пуша (Edge Function): ${e.details}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Помилка пуша');
    }
  }
}

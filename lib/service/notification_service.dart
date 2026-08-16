import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Відправка пушів через Supabase Edge Function.
/// Параметри: token, title, body, data — відповідають очікуваному тілу Edge Function.
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
      final userData = await _supabase
          .from('profiles')
          .select('fcm_token')
          .eq('id', receiverId)
          .maybeSingle();
      final String? deviceToken = userData?['fcm_token'] as String?;
      if (deviceToken == null || deviceToken.isEmpty) return;

      await _supabase.functions
          .invoke(
            _functionName,
            body: {
              'token': deviceToken,
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

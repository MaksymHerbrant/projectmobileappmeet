import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/app_config.dart';
import '../service/error_reporter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Нормалізує номер для пошуку в profiles (формат як у auth, напр. +380...)
  String _normalizePhone(String phone) {
    final clean = phone.trim().replaceAll(RegExp(r'^\+?380\s*'), '');
    return '${AppConfig.phonePrefix}$clean';
  }

  Future<void> signInWithPhone(String phone) async {
    try {
      final fullPhone = '${AppConfig.phonePrefix}${phone.trim()}';
      await _supabase.auth.signInWithOtp(phone: fullPhone);
    } on AuthException catch (e) {
      throw AppFailure(FailureKind.smsFailed, details: e.message);
    } catch (e) {
      throw AppFailure(FailureKind.smsFailed, details: e.toString());
    }
  }

  Future<AuthResponse> verifyOtp(String phone, String code) async {
    try {
      final fullPhone = '${AppConfig.phonePrefix}${phone.trim()}';
      final response = await _supabase.auth.verifyOTP(
        phone: fullPhone,
        token: code,
        type: OtpType.sms,
      );
      await updateFcmToken();
      return response;
    } on AuthException catch (e) {
      throw AppFailure(FailureKind.wrongCode, details: e.message);
    } catch (e) {
      throw AppFailure(FailureKind.wrongCode, details: e.toString());
    }
  }

  Future<void> signInWithPassword(String phone, String password) async {
    try {
      final fullPhone = '${AppConfig.phonePrefix}${phone.trim()}';
      await _supabase.auth.signInWithPassword(phone: fullPhone, password: password);
      await updateFcmToken();
    } on AuthException catch (e) {
      throw AppFailure(FailureKind.wrongCode, details: e.message);
    } catch (e) {
      throw const AppFailure(FailureKind.wrongCode);
    }
  }

  Future<bool> checkUserExists(String phone) async {
    try {
      final fullPhone = _normalizePhone(phone);
      // RPC, а не запит до таблиці: колонка phone більше не читається клієнтом,
      // і відповідь тут — рівно так/ні, без можливості перебирати користувачів.
      final exists = await _supabase.rpc(
        'phone_is_registered',
        params: {'p_phone': fullPhone},
      );
      return exists == true;
    } catch (e, st) {
      await ErrorReporter.report(e, st, context: 'checkUserExists');
      rethrow;
    }
  }

  // Завершення реєстрації: Встановлення пароля + Запис даних в базу
  Future<void> completeRegistration({
    required String name,
    required DateTime birthDate,
    required String password, 
  }) async {
    final user = currentUser;
    if (user == null) throw const AppFailure(FailureKind.notAuthenticated);

    try {
      // А) Встановлюємо пароль для користувача (щоб міг входити потім без смс)
      try {
        await _supabase.auth.updateUser(
          UserAttributes(password: password),
        );
      } on AuthApiException catch (e) {
        // Незавершена реєстрація, розпочата заново з тим самим номером і
        // паролем: пароль уже саме такий, міняти нічого — ідемо далі.
        if (e.code != 'same_password') rethrow;
      }

      // Б) Записуємо анкету в таблицю 'profiles'.
      //
      // Саме UPDATE, а не upsert: рядок уже створив тригер on_auth_user_created,
      // а upsert (INSERT ... ON CONFLICT) вимагає SELECT на таблицю — його в
      // authenticated свідомо немає після захисту колонок із телефонами.
      // Телефон теж не пишемо: тригер уже поклав його з auth.
      await _supabase.from('profiles').update({
        'full_name': name,
        'birth_date': birthDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      await updateFcmToken();
    } catch (e) {
      throw AppFailure(FailureKind.save, details: e.toString());
    }
  }
  Future<void> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (response.user == null) {
        throw const AppFailure(FailureKind.updatePassword);
      }
    } catch (e) {
      throw AppFailure(FailureKind.updatePassword, details: e.toString());
    }
  }
  // 👇 ОСЬ ЦЕЙ МЕТОД ТИ ПРОСИВ (Отримання даних профілю)
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // Свій профіль цілком (з телефоном) віддає тільки ця RPC — у таблиці
      // приватні колонки закриті для клієнта.
      final data = await _supabase.rpc('get_my_profile');
      return data == null ? null : Map<String, dynamic>.from(data as Map);
    } catch (e) {
      // Якщо профілю ще немає або помилка мережі
      return null;
    }
  }
  Future<void> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user');
      await _supabase.auth.signOut();
    } on PostgrestException catch (e) {
      throw AppFailure(FailureKind.deleteAccount, details: e.message);
    } catch (e) {
      throw AppFailure(FailureKind.deleteAccount, details: e.toString());
    }
  }

  Future<void> signOut() async {
    final user = currentUser;
    if (user != null) {
      try {
        // Знімаємо лише поточний пристрій — на інших девайсах пуші мають лишитись.
        final token = await FirebaseMessaging.instance.getToken();
        final query = _supabase.from('user_devices').delete().eq('profile_id', user.id);
        await (token != null ? query.eq('fcm_token', token) : query);
        if (kDebugMode) debugPrint('🧹 FCM токен видалено з бази перед виходом');
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Не вдалося видалити токен з бази: $e');
      }
    }
    await _supabase.auth.signOut();
  }

  Future<void> updateFcmToken() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _supabase.from('user_devices').upsert({
            'profile_id': user.id,
            'fcm_token': token,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
          if (kDebugMode) debugPrint('🚀 FCM токен оновлено');
        }
      }
    } catch (e, st) {
      // Пуші — не критичний шлях: без токена застосунок працює далі.
      ErrorReporter.report(e, st, context: 'updateFcmToken');
    }
  }
}
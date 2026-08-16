import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/app_config.dart';

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
      throw Exception('Помилка відправки SMS: ${e.message}');
    } catch (e) {
      throw Exception('Помилка відправки SMS: $e');
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
      throw Exception('Невірний код: ${e.message}');
    } catch (e) {
      throw Exception('Невірний код: $e');
    }
  }

  Future<void> signInWithPassword(String phone, String password) async {
    try {
      final fullPhone = '${AppConfig.phonePrefix}${phone.trim()}';
      await _supabase.auth.signInWithPassword(phone: fullPhone, password: password);
      await updateFcmToken();
    } on AuthException catch (e) {
      throw Exception('Невірний номер або пароль: ${e.message}');
    } catch (e) {
      throw Exception('Невірний номер або пароль');
    }
  }

  Future<bool> checkUserExists(String phone) async {
    try {
      final fullPhone = _normalizePhone(phone);
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('phone', fullPhone)
          .maybeSingle();
      return response != null;
    } catch (e) {
      if (kDebugMode) debugPrint('Помилка пошуку в БД');
      return false;
    }
  }

  // Завершення реєстрації: Встановлення пароля + Запис даних в базу
  Future<void> completeRegistration({
    required String name,
    required DateTime birthDate,
    required String password, 
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Користувач не авторизований');

    try {
      // А) Встановлюємо пароль для користувача (щоб міг входити потім без смс)
      await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      // Б) Записуємо анкету в таблицю 'profiles'
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'birth_date': birthDate.toIso8601String(),
        'phone': user.phone,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await updateFcmToken();
    } catch (e) {
      throw Exception('Помилка збереження даних: $e');
    }
  }
  Future<void> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (response.user == null) {
        throw Exception('Не вдалося оновити пароль');
      }
    } catch (e) {
      throw Exception('Помилка оновлення: ${e.toString()}');
    }
  }
  // 👇 ОСЬ ЦЕЙ МЕТОД ТИ ПРОСИВ (Отримання даних профілю)
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single(); // single() означає, що ми чекаємо 1 запис
      return data;
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
      throw Exception('Помилка видалення: ${e.message}');
    } catch (e) {
      throw Exception('Помилка видалення: $e');
    }
  }

  Future<void> signOut() async {
    final user = currentUser;
    if (user != null) {
      try {
        await _supabase.from('profiles').update({'fcm_token': null}).eq('id', user.id);
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
          await _supabase.from('profiles').update({'fcm_token': token}).eq('id', user.id);
          if (kDebugMode) debugPrint('🚀 FCM токен оновлено');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Помилка оновлення FCM токена');
    }
  }
}
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_reporter.dart';

/// Оновлення власної позиції.
///
/// Раніше координати записувались лише тоді, коли користувач вручну зберігав
/// профіль — тобто зазвичай один раз за весь час. Для продукту «друзі поруч»
/// це означало, що радіус рахувався від місця, де людина була колись.
class LocationService {
  final _supabase = Supabase.instance.client;

  /// Чи готовий користувач ділитись позицією. Не запитує дозвіл повторно,
  /// якщо його вже відхилили назавжди.
  Future<bool> hasPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Зчитує позицію і зберігає її. Викликається при відкритті застосунку.
  ///
  /// Повертає false, якщо дозволу немає — це не помилка, і застосунок має
  /// працювати далі: стрічка просто збереться без фільтра за відстанню.
  Future<bool> refreshMyLocation() async {
    try {
      if (!await hasPermission()) {
        // Без координат хоча б відмічаємо, що людина заходила: свіжість
        // активності бере участь у ранжуванні окремо від відстані.
        await _supabase.rpc('touch_last_active');
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 100,
        ),
      );

      await _supabase.rpc('update_my_location', params: {
        'p_lat': position.latitude,
        'p_long': position.longitude,
      });
      return true;
    } catch (e, st) {
      // Не критично: стрічка працює і без свіжих координат.
      ErrorReporter.report(e, st, context: 'refreshMyLocation');
      return false;
    }
  }
}

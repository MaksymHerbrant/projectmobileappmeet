import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';
import 'error_reporter.dart';

/// Чим саме закінчилась спроба оновити локацію.
///
/// Різні причини потребують різних дій від користувача: увімкнути геолокацію
/// в системі, дати дозвіл, або зайти в налаштування, якщо дозвіл відхилено
/// назавжди і система більше не питатиме.
enum LocationOutcome {
  updated,
  serviceDisabled,
  denied,
  deniedForever,
  failed,
}

extension LocationOutcomeMessage on LocationOutcome {
  /// Текст добирається за контекстом: сервіс не має доступу до перекладів.
  String localized(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      LocationOutcome.updated => t.loc_updated,
      LocationOutcome.serviceDisabled => t.loc_disabled,
      LocationOutcome.denied => t.loc_denied,
      LocationOutcome.deniedForever => t.loc_denied_forever,
      LocationOutcome.failed => t.loc_failed,
    };
  }

  bool get isSuccess => this == LocationOutcome.updated;

  /// Чи має сенс показувати кнопку «Відкрити налаштування».
  bool get needsSettings =>
      this == LocationOutcome.deniedForever ||
      this == LocationOutcome.serviceDisabled;
}

/// Оновлення власної позиції.
///
/// Координати пишуться через RPC `update_my_location`, а не прямо в таблицю:
/// вона заповнює і `geo` для просторового пошуку, і `location_point` для
/// сумісності, і відмічає активність — усе однією операцією.
class LocationService {
  final _supabase = Supabase.instance.client;

  Future<LocationOutcome> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationOutcome.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationOutcome.updated,
      LocationPermission.deniedForever => LocationOutcome.deniedForever,
      _ => LocationOutcome.denied,
    };
  }

  /// Чи можемо ми взагалі читати позицію — без запиту дозволу наново.
  Future<bool> hasPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Зчитує позицію і зберігає її.
  ///
  /// [silent] — виклик при відкритті застосунку: дозвіл не випрошується
  /// повторно, якщо його вже відхилили, щоб не дратувати системним діалогом
  /// на кожному запуску.
  Future<LocationOutcome> refreshMyLocation({bool silent = false}) async {
    try {
      final permission =
          silent ? (await hasPermission()
                      ? LocationOutcome.updated
                      : LocationOutcome.denied)
                 : await _ensurePermission();

      if (!permission.isSuccess) {
        // Навіть без координат відмічаємо, що людина заходила: свіжість
        // активності бере участь у ранжуванні окремо від відстані.
        await _supabase.rpc('touch_last_active');
        return permission;
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
      return LocationOutcome.updated;
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'refreshMyLocation');
      return LocationOutcome.failed;
    }
  }

  /// Останні збережені координати — щоб показати їх у профілі.
  Future<({double lat, double long})?> myCoordinates() async {
    try {
      final data = await _supabase.rpc('get_my_match_context');
      if (data == null) return null;
      final map = Map<String, dynamic>.from(data as Map);
      final lat = (map['lat'] as num?)?.toDouble();
      final long = (map['long'] as num?)?.toDouble();
      if (lat == null || long == null) return null;
      return (lat: lat, long: long);
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'myCoordinates');
      return null;
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

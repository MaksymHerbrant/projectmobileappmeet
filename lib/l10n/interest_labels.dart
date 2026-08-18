import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

/// Назви інтересів для показу.
///
/// У базі інтереси зберігаються українськими рядками — за ними працює підбір
/// (`interest_weights`, `interest_affinity`), тому самі значення чіпати не
/// можна: переклад збережених даних зламав би матчинг. Локалізується лише те,
/// що бачить користувач.
class InterestLabels {
  const InterestLabels._();

  static String of(BuildContext context, String canonical) {
    final t = AppLocalizations.of(context)!;
    return switch (canonical) {
      'IT' => t.interest_it,
      'Біг' => t.interest_running,
      'Велоспорт' => t.interest_cycling,
      'Вечірка' => t.interest_party,
      'Геймінг' => t.interest_gaming,
      'Гори' => t.interest_mountains,
      'Йога' => t.interest_yoga,
      'Кава' => t.interest_coffee,
      'Кулінарія' => t.interest_cooking,
      'Кіно' => t.interest_cinema,
      'Малювання' => t.interest_drawing,
      'Мистецтво' => t.interest_art,
      'Музика' => t.interest_music,
      'Музика Lo-Fi' => t.interest_lofi,
      'Настільні ігри' => t.interest_board_games,
      'Освіта' => t.interest_learning,
      'Плавання' => t.interest_swimming,
      'Подорожі' => t.interest_travel,
      'Походи' => t.interest_hiking,
      'Похід з наметом' => t.interest_camping,
      'Природа' => t.interest_nature,
      'Програмування' => t.interest_programming,
      'Спорт' => t.interest_sport,
      'Танці' => t.interest_dancing,
      'Фентезі книги' => t.interest_fantasy_books,
      'Фотографія' => t.interest_photography,
      'Фітнес' => t.interest_fitness,
      'Читання' => t.interest_reading,
      // Невідоме значення показуємо як є: краще українською, ніж порожньо.
      _ => canonical,
    };
  }
}

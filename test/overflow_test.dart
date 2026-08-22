// Перевіряє, що екрани витримують довгі імена й назви міст.
//
// Тестові профілі в базі мають імена на кшталт «А · Ті самі хобі, поруч» —
// саме на такому рядок у профілі й вилазив за екран на 213 пікселів.
import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:dating_app/models/user_profile.dart';
import 'package:dating_app/screens/user_profile_view_screen.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/providers/locale_provider.dart';

UserProfile _longUser() => UserProfile(
      id: 'test-id',
      name: 'А · Ті самі хобі, поруч, лайкнув, дуже довге ім\'я',
      age: 24,
      description: 'Опис, який теж буває довгим і має гарно обрізатись.',
      photos: const [],
      location: 'Львівська область, Пустомитівський район',
      hobbies: const ['Програмування', 'Фотографія', 'Похід з наметом'],
    );

void main() {
  testWidgets('профіль не переповнюється довгим іменем і містом',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: MaterialApp(
          locale: const Locale('uk'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: UserProfileViewScreen(user: _longUser()),
        ),
      ),
    );
    await tester.pump();

    // Будь-яке переповнення в Flutter — це виняток під час верстки.
    expect(tester.takeException(), isNull);
  });
}

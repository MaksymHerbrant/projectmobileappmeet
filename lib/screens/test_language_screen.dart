import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class TestLanguageScreen extends StatelessWidget {
  const TestLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).get('app_name')),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFF3E5F5), Colors.white],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Поточна мова: ${LanguageProvider.getLanguageName(languageProvider.currentLocale.languageCode)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Назва додатку: ${AppLocalizations.of(context).get('app_name')}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Кнопка "ОК": ${AppLocalizations.of(context).get('ok')}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Кнопка "Скасувати": ${AppLocalizations.of(context).get('cancel')}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Кнопка "Зберегти": ${AppLocalizations.of(context).get('save')}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Змінити мову:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...LanguageProvider.availableLanguages.map((language) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          onPressed: () async {
                            await languageProvider.changeLanguage(language);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: languageProvider.currentLocale.languageCode == 
                                LanguageProvider.getLanguageCode(language) 
                                ? Colors.blue 
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            language,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 
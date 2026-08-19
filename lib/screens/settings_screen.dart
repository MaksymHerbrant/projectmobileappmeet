import 'package:flutter/material.dart';

import '../theme/design_kit.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';
import '../service/auth_service.dart'; // Імпортуємо твій сервіс
import 'change_password_screen.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Екземпляр сервісу для виходу
  final _authService = AuthService();

  // Стан налаштувань (тимчасові локальні змінні)
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return DsScreen(
          top: DsTopBar(
            onBack: () => Navigator.of(context).pop(),
            title: AppLocalizations.of(context)!.settings,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLanguageSection(),
                const SizedBox(height: 18),
                _buildAppearanceSection(),
                const SizedBox(height: 18),
                _buildNotificationsSection(),
                const SizedBox(height: 18),
                _buildPrivacySection(),
                const SizedBox(height: 18),
                _buildAccountSection(), // Тут кнопка виходу
              ],
            ),
          ),
        );
      },
    );
  }

  /* --- ЗАКОМЕНТОВАНА СЕКЦІЯ МОВИ ---
  Widget _buildLanguageSection() {
    return _buildSectionCard(
      title: AppLocalizations.of(context)!.language,
      icon: Icons.language,
      child: Column(
        children: [
          _buildLanguageSelector(),
          const SizedBox(height: 16),
          _buildLanguagePreview(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLanguage = LocaleProvider.getLanguageName(localeProvider.locale.languageCode);
    final availableLanguages = LocaleProvider.availableLanguages;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguage,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          items: availableLanguages.map((language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(language, style: const TextStyle(fontSize: 16)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value != null) {
              final languageCode = LocaleProvider.getLanguageCode(value);
              await localeProvider.changeLanguageByCode(languageCode);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLanguagePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.preview, color: Theme.of(context).colorScheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.hello_how_are_you,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
  */

  // --- МОВА ---

  Widget _buildLanguageSection() {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<LocaleProvider>();

    return DsSection(
      title: t.language,
      rows: [
          _buildChoiceTile(
            label: t.language_system,
            // Показуємо, яку саме мову дав телефон, інакше «як у телефоні»
            // нічого не пояснює.
            trailing: LocaleProvider.getLanguageName(
                LocaleProvider.supportedLocales
                    .firstWhere(
                      (l) =>
                          l.languageCode ==
                          provider.effectiveLocale.languageCode,
                      orElse: () => const Locale('en', 'US'),
                    )
                    .languageCode),
            selected: provider.followSystem,
            onTap: provider.useSystemLanguage,
          ),
          ...LocaleProvider.languageCodes.map((code) {
            return _buildChoiceTile(
              label: LocaleProvider.getLanguageName(code),
              selected: !provider.followSystem &&
                  provider.effectiveLocale.languageCode == code,
              onTap: () => provider.changeLanguageByCode(code),
            );
          }),
      ],
    );
  }

  // --- ОФОРМЛЕННЯ ---

  Widget _buildAppearanceSection() {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<ThemeProvider>();

    final options = <(ThemeMode, String, IconData)>[
      (ThemeMode.system, t.theme_system, Icons.brightness_auto),
      (ThemeMode.light, t.theme_light, Icons.light_mode),
      (ThemeMode.dark, t.theme_dark, Icons.dark_mode),
    ];

    return DsSection(
      title: t.appearance,
      rows: [
        for (final (mode, label, icon) in options)
          _buildChoiceTile(
            label: label,
            leading: icon,
            selected: provider.mode == mode,
            onTap: () => provider.setMode(mode),
          ),
      ],
    );
  }

  Widget _buildChoiceTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? leading,
    String? trailing,
  }) {
    return DsRow(
      label: label,
      subtitle: trailing,
      icon: leading,
      selected: selected,
      onTap: onTap,
    );
  }

  // --- СЕКЦІЯ АКАУНТА (З ВИХОДОМ) ---
  Widget _buildAccountSection() {
    final t = AppLocalizations.of(context)!;
    return DsSection(
      title: AppLocalizations.of(context)!.account,
      rows: [
          _buildListTile(
            title: AppLocalizations.of(context)!.change_password,
            subtitle: AppLocalizations.of(context)!.st_update_password,
            icon: Icons.lock,
            onTap: () {
              // 👇 ДОДАНО ПЕРЕХІД НА ЕКРАН ЗМІНИ ПАРОЛЯ
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          // 🟢 КНОПКА ВИХОДУ
          _buildListTile(
            title: t.sign_out,
            subtitle: AppLocalizations.of(context)!.st_end_session,
            icon: Icons.logout,
            onTap: _showLogoutDialog,
            isDestructive: true,
          ),
          _buildListTile(
            title: AppLocalizations.of(context)!.delete_account,
            subtitle: AppLocalizations.of(context)!.st_delete_data,
            icon: Icons.delete_forever,
            onTap: _showDeleteAccountDialog, // 👇 ДОДАНО
            isDestructive: true,
          ),
      ],
    );
  }
// --- ЛОГІКА ВИДАЛЕННЯ АКАУНТА ---
  void _showDeleteAccountDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      // ВАЖЛИВО: перейменовуємо контекст діалогу на dialogContext
      builder: (dialogContext) => AlertDialog(
        title: Text(t.delete_account_title),
        content: Text(
          t.delete_account_confirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: Text(t.cancel)
          ),
          TextButton(
            onPressed: () async {
              // 1. ЗБЕРІГАЄМО необхідні інструменти головного екрана ДО асинхронних дій
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              // 2. Закриваємо діалог, використовуючи його власний контекст
              Navigator.pop(dialogContext); 
              
              try {
                await _authService.deleteAccount();
                if (mounted) {
                  // 3. Використовуємо збережений навігатор
                  navigator.pushNamedAndRemoveUntil('/landing', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  // 4. Використовуємо збережений месенджер (він не null, бо ми його зберегли)
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(t.delete_account_failed), 
                      backgroundColor: Theme.of(context).colorScheme.error
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(t.delete_forever),
          ),
        ],
      ),
    );
  }
  // --- ЛОГІКА ВИХОДУ ---
  void _showLogoutDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.logout_title),
        content: Text(t.logout_confirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          TextButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                // Повертаємось на LandingScreen і видаляємо всі екрани з черги
                Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(t.sign_out),
          ),
        ],
      ),
    );
  }

  // --- ДОПОМІЖНІ ВІДЖЕТИ (ШАБЛОНИ) ---

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return DsRow(
      label: title,
      subtitle: subtitle,
      icon: icon,
      onTap: onTap,
      destructive: isDestructive,
    );
  }

  // Інші секції
  Widget _buildNotificationsSection() => DsSection(
        title: AppLocalizations.of(context)!.notifications,
        rows: [
          DsRow(
            label: AppLocalizations.of(context)!.notification_settings,
            icon: Icons.notifications_outlined,
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
          ),
        ],
      );

  Widget _buildPrivacySection() => DsSection(
        title: AppLocalizations.of(context)!.privacy,
        rows: [
          DsRow(
            label: AppLocalizations.of(context)!.privacy_settings,
            icon: Icons.shield_outlined,
            trailing: Switch(
              value: _locationEnabled,
              onChanged: (v) => setState(() => _locationEnabled = v),
            ),
          ),
        ],
      );
}
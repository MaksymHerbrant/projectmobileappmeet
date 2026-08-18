import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
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
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFF3E5F5), Colors.white],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ЗАКОМЕНТОВАНО: Секція мови
                          // _buildLanguageSection(),
                          // const SizedBox(height: 24),
                          
                          _buildNotificationsSection(),
                          const SizedBox(height: 24),
                          
                          _buildPrivacySection(),
                          const SizedBox(height: 24),
                          
                          // ВИДАЛЕНО: Секція параметрів пошуку (_buildPreferencesSection)
                          
                          _buildAccountSection(), // Тут кнопка виходу
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context)!.settings,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.preview, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.hello_how_are_you,
              style: TextStyle(color: Colors.blue.shade700, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
  */

  // --- СЕКЦІЯ АКАУНТА (З ВИХОДОМ) ---
  Widget _buildAccountSection() {
    final t = AppLocalizations.of(context)!;
    return _buildSectionCard(
      title: AppLocalizations.of(context)!.account,
      icon: Icons.account_circle,
      child: Column(
        children: [
          _buildListTile(
            title: AppLocalizations.of(context)!.change_password,
            subtitle: "Оновити ваш пароль",
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
            subtitle: 'Завершити поточну сесію',
            icon: Icons.logout,
            onTap: _showLogoutDialog,
            isDestructive: true,
          ),
          _buildListTile(
            title: AppLocalizations.of(context)!.delete_account,
            subtitle: "Незворотно видалити дані",
            icon: Icons.delete_forever,
            onTap: _showDeleteAccountDialog, // 👇 ДОДАНО
            isDestructive: true,
          ),
          
        ],
      ),
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
                      backgroundColor: Colors.red
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.sign_out),
          ),
        ],
      ),
    );
  }

  // --- ДОПОМІЖНІ ВІДЖЕТИ (ШАБЛОНИ) ---

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: Colors.blue), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildListTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black87, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: isDestructive ? Colors.red.withOpacity(0.7) : Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Інші секції
  Widget _buildNotificationsSection() => _buildSectionCard(
      title: AppLocalizations.of(context)!.notifications,
      icon: Icons.notifications,
      child: Text(AppLocalizations.of(context)!.notification_settings));

  Widget _buildPrivacySection() => _buildSectionCard(
      title: AppLocalizations.of(context)!.privacy,
      icon: Icons.privacy_tip,
      child: Text(AppLocalizations.of(context)!.privacy_settings));
}
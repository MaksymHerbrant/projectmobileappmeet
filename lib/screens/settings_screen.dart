import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;
  double _maxDistance = 50.0;
  int _minAge = 18;
  int _maxAge = 35;

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
                      _buildLanguageSection(),
                      const SizedBox(height: 24),
                      _buildNotificationsSection(),
                      const SizedBox(height: 24),
                      _buildPrivacySection(),
                      const SizedBox(height: 24),
                      _buildPreferencesSection(),
                      const SizedBox(height: 24),
                      _buildAccountSection(),
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
              child: Row(
                children: [
                  Text(
                    language,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value != null) {
              final languageCode = LocaleProvider.getLanguageCode(value);
              await localeProvider.changeLanguageByCode(languageCode);
              _showLanguageChangedDialog();
            }
          },
        ),
      ),
    );
  }

  Widget _getLanguageFlag(String language) {
    String flag;
    switch (language) {
      case 'Українська':
        flag = '🇺🇦';
        break;
      case 'English':
        flag = '🇬🇧';
        break;
      case 'Polski':
        flag = '🇵🇱';
        break;
      case 'Português':
        flag = '🇵🇹';
        break;
      case 'Español':
        flag = '🇪🇸';
        break;
      default:
        flag = '🇺🇦';
    }
    return Text(flag, style: const TextStyle(fontSize: 20));
  }

  Widget _buildLanguagePreview() {
    final previewText = AppLocalizations.of(context)!.hello_how_are_you;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.preview, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              previewText,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSectionCard(
      title: AppLocalizations.of(context)!.notifications,
      icon: Icons.notifications,
      child: Column(
        children: [
          _buildSwitchTile(
            title: AppLocalizations.of(context)!.enable_notifications,
            subtitle: AppLocalizations.of(context)!.new_matches,
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 12),
            _buildNotificationTypes(),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return Column(
      children: [
        _buildCheckboxTile(
          title: AppLocalizations.of(context)!.new_matches,
          subtitle: AppLocalizations.of(context)!.messages_notifications,
          value: true,
          onChanged: (value) {},
        ),
        _buildCheckboxTile(
          title: AppLocalizations.of(context)!.messages_notifications,
          subtitle: AppLocalizations.of(context)!.messages_notifications,
          value: true,
          onChanged: (value) {},
        ),
        _buildCheckboxTile(
          title: AppLocalizations.of(context)!.events_nearby_notifications,
          subtitle: AppLocalizations.of(context)!.events_nearby_notifications,
          value: false,
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSectionCard(
      title: AppLocalizations.of(context)!.privacy,
      icon: Icons.privacy_tip,
      child: Column(
        children: [
          _buildSwitchTile(
            title: AppLocalizations.of(context)!.location_access,
            subtitle: AppLocalizations.of(context)!.location_access,
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: AppLocalizations.of(context)!.dark_mode,
            subtitle: AppLocalizations.of(context)!.dark_mode,
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSectionCard(
      title: AppLocalizations.of(context)!.search_preferences,
      icon: Icons.tune,
      child: Column(
        children: [
          _buildDistanceSlider(),
          const SizedBox(height: 20),
          _buildAgeRangeSlider(),
        ],
      ),
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.max_distance,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_maxDistance.round()} ${AppLocalizations.of(context)!.km_away.split(' ')[0]}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _maxDistance,
          min: 1.0,
          max: 100.0,
          divisions: 99,
          activeColor: Colors.blue,
          onChanged: (value) {
            setState(() {
              _maxDistance = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 ${AppLocalizations.of(context)!.km_away.split(' ')[0]}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('100 ${AppLocalizations.of(context)!.km_away.split(' ')[0]}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.age_range,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$_minAge - $_maxAge ${AppLocalizations.of(context)!.years_old}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
          min: 18.0,
          max: 60.0,
          divisions: 42,
          activeColor: Colors.blue,
          onChanged: (values) {
            setState(() {
              _minAge = values.start.round();
              _maxAge = values.end.round();
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('18 ${AppLocalizations.of(context)!.years_old}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('60 ${AppLocalizations.of(context)!.years_old}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSectionCard(
      title: AppLocalizations.of(context)!.account,
      icon: Icons.account_circle,
      child: Column(
        children: [
          _buildListTile(
            title: AppLocalizations.of(context)!.change_password,
            subtitle: AppLocalizations.of(context)!.change_password,
            icon: Icons.lock,
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          _buildListTile(
            title: AppLocalizations.of(context)!.email,
            subtitle: 'user@example.com',
            icon: Icons.email,
            onTap: () {
              _showChangeEmailDialog();
            },
          ),
          _buildListTile(
            title: AppLocalizations.of(context)!.delete_account,
            subtitle: AppLocalizations.of(context)!.delete_account,
            icon: Icons.delete_forever,
            onTap: () {
              _showDeleteAccountDialog();
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive ? Colors.red.shade300 : Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _showLanguageChangedDialog() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLanguage = LocaleProvider.getLanguageName(localeProvider.locale.languageCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.language_changed),
        content: Text(AppLocalizations.of(context)!.language_changed_message(currentLanguage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.change_password),
        content: Text(AppLocalizations.of(context)!.change_password),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.change_email),
        content: Text(AppLocalizations.of(context)!.change_email),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete_account),
        content: Text(AppLocalizations.of(context)!.delete_account_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteAccountConfirmation();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.account_deleted),
        content: Text(AppLocalizations.of(context)!.account_deleted_message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Повертаємось до профілю
            },
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
} 
import '../l10n/interest_labels.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
import 'package:provider/provider.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../providers/locale_provider.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';
import '../service/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PageController _photoController = PageController();
  final _authService = AuthService();
  
  int _currentPhotoIndex = 0;
  bool _isLoading = true;

  // 👇 Змінні більше не final/static, ми їх оновлюємо
  DateTime? userBirthDate;

  // 🟢 ЗМІНЕНО: Список фото тепер динамічний (посилання з бази), а не assets
  List<String> userPhotos = []; 

  // Обчислюємо вік автоматично
  int get userAge {
    if (userBirthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - userBirthDate!.year;
    if (today.month < userBirthDate!.month || 
        (today.month == userBirthDate!.month && today.day < userBirthDate!.day)) {
      age--;
    }
    return age;
  }
  
  String userName = '';
  String? userLocation; // null → підставляємо стандартне значення у build
  String? aboutMe; // null → показуємо «Завантаження…» у build
  
  // Хобі
  List<String> hobbies = [
    'Геймінг', 'Музика', 'Подорожі' // Це дефолтні, потім завантажаться з бази
  ];
  
  bool _showFullAboutMe = false;
  bool _showFullHobbies = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 👇 Функція завантаження даних
  Future<void> _loadUserData() async {
    try {
      final profile = await _authService.getCurrentProfile();
      
      if (mounted && profile != null) {
        setState(() {
          userName = profile['full_name'] ?? AppLocalizations.of(context)!.no_name;
          aboutMe = profile['bio'] ?? AppLocalizations.of(context)!.default_bio; 
          userLocation = profile['location'] ?? AppLocalizations.of(context)!.default_country;
          
          // Обробка дати
          if (profile['birth_date'] != null) {
            try {
              userBirthDate = DateTime.parse(profile['birth_date']); 
            } catch (e) {
              print('Помилка формату дати: $e');
            }
          }

          // 🟢 НОВЕ: Завантаження списку фото
          if (profile['photos'] != null) {
            // Конвертуємо JSON-масив у List<String>
            userPhotos = List<String>.from(profile['photos']);
          } else {
            userPhotos = [];
          }

          // Завантаження хобі
          if (profile['hobbies'] != null) {
            hobbies = List<String>.from(profile['hobbies']);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Єдине джерело назв інтересів. Раніше тут була власна мапа на кілька
  /// значень, тож більшість інтересів лишалась українською в будь-якій мові.
  List<String> _getLocalizedHobbies(List<String> hobbies, BuildContext context) {
    return hobbies.map((h) => InterestLabels.of(context, h)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        if (_isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: Ds.background(context),
            // Фото йде під статусний рядок, тому SafeArea тут немає: кнопки
            // згори самі відступають на висоту вирізу.
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildPhotoHeader(),
                  _buildSheet(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Шапка з фото за `design/Profile.dc.html`: 330px, ім'я внизу зліва,
  /// смужки гортання внизу справа, кнопки згори справа.
  Widget _buildPhotoHeader() {
    final t = AppLocalizations.of(context)!;
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (userPhotos.isEmpty)
            _buildNoPhotosPlaceholder()
          else
            PageView.builder(
              controller: _photoController,
              onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
              itemCount: userPhotos.length,
              itemBuilder: (context, index) => Image.network(
                userPhotos[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    DsPhotoBlock(radius: 0, fontSize: 76, initial: userName),
              ),
            ),

          // Затемнення тільки внизу — щоб білий підпис читався на будь-якому фото.
          if (userPhotos.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x8C000000)],
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            top: top + 8,
            right: 20,
            child: Row(
              children: [
                DsIconButton(
                  icon: Icons.edit_outlined,
                  onTap: _openEditProfile,
                  semanticLabel: t.edit_profile,
                ),
                const SizedBox(width: 10),
                DsIconButton(
                  icon: Icons.settings_outlined,
                  onTap: _openSettings,
                  semanticLabel: t.settings,
                ),
              ],
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userAge > 0 ? '$userName, $userAge' : userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          // Білий навмисно, а не з теми: підпис лежить на фото,
                          // де колір теми на світлій темі був майже чорним.
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          shadows: [Shadow(color: Color(0x80000000), blurRadius: 12, offset: Offset(0, 2))],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              userLocation ?? t.default_country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                shadows: [Shadow(color: Color(0x80000000), blurRadius: 12)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (userPhotos.length > 1)
                  Row(
                    children: [
                      for (var i = 0; i < userPhotos.length; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Container(
                          width: 22,
                          height: 3,
                          decoration: BoxDecoration(
                            color: i == _currentPhotoIndex ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Аркуш, що наїжджає на фото — рівно як у макеті: скруглення 22 і зсув -22.
  Widget _buildSheet() {
    final t = AppLocalizations.of(context)!;
    final about = (aboutMe ?? '').trim();
    final localizedHobbies = _getLocalizedHobbies(hobbies, context);

    return Transform.translate(
      offset: const Offset(0, -22),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.backgroundGradient(context).last,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.about_me.toUpperCase(), style: Ds.label(context)),
            const SizedBox(height: 8),
            if (about.isEmpty)
              // Порожній розділ має пропонувати дію, а не показувати прочерк.
              GestureDetector(
                onTap: _openEditProfile,
                child: Text(
                  t.profile_add_about,
                  style: Ds.sub(context).copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              )
            else ...[
              Text(
                _showFullAboutMe || about.length <= 160
                    ? about
                    : '${about.substring(0, 160)}…',
                style: Ds.sub(context).copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              if (about.length > 160) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _showFullAboutMe = !_showFullAboutMe),
                  child: Text(
                    _showFullAboutMe ? t.less : t.more,
                    style: Ds.tiny(context).copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            Text(t.hobbies.toUpperCase(), style: Ds.label(context)),
            const SizedBox(height: 10),
            if (localizedHobbies.isEmpty)
              GestureDetector(
                onTap: _openEditProfile,
                child: Text(
                  t.profile_add_interests,
                  style: Ds.sub(context).copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hobby in _showFullHobbies
                      ? localizedHobbies
                      : localizedHobbies.take(6))
                    DsChip(label: hobby, small: true),
                  if (localizedHobbies.length > 6)
                    DsChip(
                      label: _showFullHobbies ? t.less : t.more,
                      small: true,
                      selected: true,
                      onTap: () => setState(() => _showFullHobbies = !_showFullHobbies),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Заглушка, коли фото ще немає.
  Widget _buildNoPhotosPlaceholder() {
    return GestureDetector(
      onTap: _openEditProfile,
      child: DsPhotoBlock(
        radius: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.no_photos_tap_to_add,
              textAlign: TextAlign.center,
              style: Ds.sub(context),
            ),
          ],
        ),
      ),
    );
  }


  void _openEditProfile() async {
    final profileData = {
      'name': userName,
      'location': (userLocation ?? AppLocalizations.of(context)!.default_country),
      'birthDate': userBirthDate,
      '(aboutMe ?? AppLocalizations.of(context)!.loading_info)': (aboutMe ?? AppLocalizations.of(context)!.loading_info),
      'hobbies': hobbies,
      // 🟢 Передаємо поточні фото в редагування
      'photos': userPhotos, 
    };

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profileData: profileData),
      ),
    );

    if (result != null) {
      setState(() {
        userName = result['name'];
        userLocation = result['location'];
        if (result['birthDate'] != null) {
          userBirthDate = result['birthDate'] as DateTime; 
        }
        aboutMe = result['(aboutMe ?? AppLocalizations.of(context)!.loading_info)'];
        hobbies = List<String>.from(result['hobbies']);
        
        // 🟢 Оновлюємо список фото після редагування
        if (result['photos'] != null) {
          userPhotos = List<String>.from(result['photos']);
        }
      });
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
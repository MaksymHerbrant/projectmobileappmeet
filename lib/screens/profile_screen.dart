import '../l10n/interest_labels.dart';
import 'package:flutter/material.dart';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Container(
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildProfileCard(), // 🟢 Оновлена картка
                          const SizedBox(height: 24),
                          _buildAboutMeSection(),
                          const SizedBox(height: 24),
                          _buildHobbiesSection(),
                          const SizedBox(height: 100),
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
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.my_profile,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _openSettings,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 ЗМІНЕНО: Логіка вибору віджета (Фото або Кнопка)
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 400,
      child: Stack(
        children: [
          if (userPhotos.isEmpty)
             _buildNoPhotosPlaceholder() // Якщо пусто -> показуємо кнопку
          else
             _buildPhotosPageView(),     // Якщо є фото -> показуємо слайдер
        ],
      ),
    );
  }

  // 🟢 НОВЕ: Віджет "Немає фото" (Тупа кнопка)
  Widget _buildNoPhotosPlaceholder() {
    return GestureDetector(
      onTap: _openEditProfile, // Веде в редагування
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 50, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.no_photos_tap_to_add,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 НОВЕ: Слайдер фото (винесено в окремий метод)
  Widget _buildPhotosPageView() {
    return Stack(
      children: [
        PageView.builder(
          controller: _photoController,
          onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
          physics: const BouncingScrollPhysics(),
          itemCount: userPhotos.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(userPhotos[index]), // 🟢 Використовуємо інтернет-фото
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$userName $userAge',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (userLocation ?? AppLocalizations.of(context)!.default_country),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Індикатори фото
        if (userPhotos.length > 1)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                userPhotos.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _currentPhotoIndex == index ? 12 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPhotoIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAboutMeSection() {
    final displayText = _showFullAboutMe 
        ? (aboutMe ?? AppLocalizations.of(context)!.loading_info) 
        : (aboutMe ?? AppLocalizations.of(context)!.loading_info).length > 100 
            ? '${(aboutMe ?? AppLocalizations.of(context)!.loading_info).substring(0, 100)}...' 
            : (aboutMe ?? AppLocalizations.of(context)!.loading_info);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.about_me,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
                ),
              ),
              if ((aboutMe ?? AppLocalizations.of(context)!.loading_info).length > 100) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullAboutMe = !_showFullAboutMe;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showFullAboutMe 
                            ? AppLocalizations.of(context)!.less
                            : AppLocalizations.of(context)!.more,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showFullAboutMe ? Icons.keyboard_arrow_up : Icons.arrow_forward,
                          size: 16, color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHobbiesSection() {
    final localizedHobbies = _getLocalizedHobbies(hobbies, context);
    final displayHobbies = _showFullHobbies 
        ? localizedHobbies 
        : localizedHobbies.take(3).toList();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.hobbies,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayHobbies.map((hobby) => _buildHobbyTag(hobby)).toList(),
              ),
              if (localizedHobbies.length > 3) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullHobbies = !_showFullHobbies;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showFullHobbies 
                            ? AppLocalizations.of(context)!.less
                            : AppLocalizations.of(context)!.more,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showFullHobbies ? Icons.keyboard_arrow_up : Icons.arrow_forward,
                          size: 16, color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHobbyTag(String hobby) {
    String iconPath;
    switch (hobby) {
      case 'Геймінг': iconPath = 'assets/icons/joystick.png'; break;
      case 'Настільні ігри': iconPath = 'assets/icons/board-game.png'; break;
      case 'Музика Lo-Fi': iconPath = 'assets/icons/music.png'; break;
      case 'Похід з наметом': iconPath = 'assets/icons/tent.png'; break;
      case 'Фентезі книги': iconPath = 'assets/icons/book.png'; break;
      case 'Фотографія': iconPath = 'assets/icons/picture.png'; break;
      case 'Подорожі': iconPath = 'assets/icons/heart-2.png'; break;
      case 'Кулінарія': iconPath = 'assets/icons/heart-2.png'; break;
      case 'Спорт': iconPath = 'assets/icons/heart-2.png'; break;
      case 'Читання': iconPath = 'assets/icons/book.png'; break;
      case 'Музика': iconPath = 'assets/icons/music.png'; break;
      case 'Танці': iconPath = 'assets/icons/heart-2.png'; break;
      default: iconPath = 'assets/icons/heart-2.png';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 14, height: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              hobby,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
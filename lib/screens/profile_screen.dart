import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'edit_profile_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;

  // Список фото користувача
  final List<String> userPhotos = [
    'assets/images/portrait-man-laughing.jpg',
    'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
    'assets/images/pleased-smiling-man-with-beard-looking-camera.jpg',
    'assets/images/selfie-portrait-videocall.jpg',
  ];

  // Інформація про користувача
  String userName = 'Роман';
  int userAge = 19;
  String userLocation = 'м.Луцьк';
  String aboutMe = 'Привіт! Я Роман, мені 19 і я з Луцька. Люблю занурюватися в атмосферу пригод — будь то гра, книжка або справжній похід. Завжди шукаю нові виклики та цікаві знайомства. Обожнюю проводити час на природі, грати в настільні ігри з друзями та відкривати нові місця. Вважаю, що життя - це пригода, і кожен день приносить щось нове та захоплююче.';
  List<String> hobbies = [
    'Геймінг',
    'Настільні ігри',
    'Музика Lo-Fi',
    'Похід з наметом',
    'Фентезі книги',
    'Фотографія',
    'Подорожі',
    'Кулінарія',
    'Спорт',
    'Читання',
    'Музика',
    'Танці',
  ];
  
  bool _showFullAboutMe = false;
  bool _showFullHobbies = false;

  // Функція для локалізації хобі
  List<String> _getLocalizedHobbies(List<String> hobbies, BuildContext context) {
    Map<String, String> hobbyTranslations = {
      'Геймінг': AppLocalizations.of(context)!.gaming,
      'Настільні ігри': AppLocalizations.of(context)!.board_games,
      'Музика Lo-Fi': AppLocalizations.of(context)!.lofi_music,
      'Похід з наметом': AppLocalizations.of(context)!.camping,
      'Фентезі книги': AppLocalizations.of(context)!.fantasy_books,
      'Фотографія': AppLocalizations.of(context)!.photography,
      'Подорожі': AppLocalizations.of(context)!.travel,
      'Кулінарія': AppLocalizations.of(context)!.cooking,
      'Спорт': AppLocalizations.of(context)!.sport,
      'Читання': AppLocalizations.of(context)!.reading,
      'Музика': AppLocalizations.of(context)!.music,
      'Танці': AppLocalizations.of(context)!.dancing,
    };
    
    return hobbies.map((hobby) => hobbyTranslations[hobby] ?? hobby).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
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
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 24),
                      _buildAboutMeSection(),
                      const SizedBox(height: 24),
                      _buildHobbiesSection(),
                      const SizedBox(height: 100), // Місце для bottom navigation
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _openSettings,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 400,
      child: Stack(
        children: [
          // Фонові фото (наступне та попереднє)
          Row(
            children: [
              // Попереднє фото (зліва)
              if (_currentPhotoIndex > 0)
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: 0.5,
                    child: Transform.translate(
                      offset: const Offset(-20, 0),
                      child: Transform.rotate(
                        angle: -0.1,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: AssetImage(userPhotos[_currentPhotoIndex - 1]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Наступне фото (справа)
              if (_currentPhotoIndex < userPhotos.length - 1)
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: 0.5,
                    child: Transform.translate(
                      offset: const Offset(20, 0),
                      child: Transform.rotate(
                        angle: 0.1,
                        child: Container(
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: AssetImage(userPhotos[_currentPhotoIndex + 1]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Основне фото
          PageView.builder(
            controller: _photoController,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            pageSnapping: true,
            physics: const BouncingScrollPhysics(),
            itemCount: userPhotos.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(userPhotos[index]),
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
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userLocation,
                          style: const TextStyle(
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildAboutMeSection() {
    final displayText = _showFullAboutMe 
        ? aboutMe 
        : aboutMe.length > 100 
            ? '${aboutMe.substring(0, 100)}...' 
            : aboutMe;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.about_me,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
              if (aboutMe.length > 100) ...[
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
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showFullAboutMe 
                            ? AppLocalizations.of(context)!.less
                            : AppLocalizations.of(context)!.more,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showFullAboutMe ? Icons.keyboard_arrow_up : Icons.arrow_forward,
                          size: 16,
                          color: Colors.black87,
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
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
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showFullHobbies 
                            ? AppLocalizations.of(context)!.less
                            : AppLocalizations.of(context)!.more,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showFullHobbies ? Icons.keyboard_arrow_up : Icons.arrow_forward,
                          size: 16,
                          color: Colors.black87,
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
      case 'Геймінг':
        iconPath = 'assets/icons/joystick.png';
        break;
      case 'Настільні ігри':
        iconPath = 'assets/icons/board-game.png';
        break;
      case 'Музика Lo-Fi':
        iconPath = 'assets/icons/music.png';
        break;
      case 'Похід з наметом':
        iconPath = 'assets/icons/tent.png';
        break;
      case 'Фентезі книги':
        iconPath = 'assets/icons/book.png';
        break;
      case 'Фотографія':
        iconPath = 'assets/icons/picture.png';
        break;
      case 'Подорожі':
        iconPath = 'assets/icons/heart-2.png';
        break;
      case 'Кулінарія':
        iconPath = 'assets/icons/heart-2.png';
        break;
      case 'Спорт':
        iconPath = 'assets/icons/heart-2.png';
        break;
      case 'Читання':
        iconPath = 'assets/icons/book.png';
        break;
      case 'Музика':
        iconPath = 'assets/icons/music.png';
        break;
      case 'Танці':
        iconPath = 'assets/icons/heart-2.png';
        break;
      default:
        iconPath = 'assets/icons/heart-2.png';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 14,
            height: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              hobby,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
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
      'location': userLocation,
      'age': userAge,
      'aboutMe': aboutMe,
      'hobbies': hobbies,
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
        userAge = result['age'];
        aboutMe = result['aboutMe'];
        hobbies = List<String>.from(result['hobbies']);
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
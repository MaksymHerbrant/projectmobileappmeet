import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/user_profile.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'profile_detail_screen.dart';
import 'events_screen.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  int _selectedTab = 0; // 0 - Для вас, 1 - Заходи поблизу
  int _currentUserIndex = 0; // Індекс поточного користувача
  
  // Контролер для CardSwiper
  final CardSwiperController _cardSwiperController = CardSwiperController();
  
  // Контролери для каруселі фото кожного користувача
  final Map<String, PageController> _photoControllers = {};
  final Map<String, int> _currentPhotoIndex = {};

  /// Створює або повертає існуючий PageController для користувача
  PageController _createControllerForUser(String userId) {
    if (!_photoControllers.containsKey(userId)) {
      _photoControllers[userId] = PageController(initialPage: 0);
      _currentPhotoIndex[userId] = 0;
    }
    return _photoControllers[userId]!;
  }

  // Функція для локалізації хобі
  List<String> _getLocalizedHobbies(List<String> hobbies, BuildContext context) {
    Map<String, String> hobbyTranslations = {
      'Фентезі книги': AppLocalizations.of(context)!.fantasy_books,
      'Похід з наметом': AppLocalizations.of(context)!.camping,
      'Ранкова кава з видом на гори': AppLocalizations.of(context)!.morning_coffee,
      'Гра на гітарі': AppLocalizations.of(context)!.guitar,
      'Фотографія': AppLocalizations.of(context)!.photography,
      'Кулінарія': AppLocalizations.of(context)!.cooking,
      'Подорожі': AppLocalizations.of(context)!.travel,
      'Спорт': AppLocalizations.of(context)!.sport,
      'Читання': AppLocalizations.of(context)!.reading,
      'Йога': AppLocalizations.of(context)!.yoga,
      'Медитація': AppLocalizations.of(context)!.meditation,
      'Велоспорт': AppLocalizations.of(context)!.cycling,
      'Мистецтво': AppLocalizations.of(context)!.art,
      'Фітнес': AppLocalizations.of(context)!.fitness,
      'Гори': AppLocalizations.of(context)!.mountains,
      'Бокс': AppLocalizations.of(context)!.boxing,
      'Плавання': AppLocalizations.of(context)!.swimming,
      'Біг': AppLocalizations.of(context)!.running,
      'Здорове харчування': AppLocalizations.of(context)!.healthy_nutrition,
      'Мотивація': AppLocalizations.of(context)!.motivation,
    };
    
    return hobbies.map((hobby) => hobbyTranslations[hobby] ?? hobby).toList();
  }

  // Список користувачів
  final List<UserProfile> users = [
    UserProfile(
      id: '1',
      name: 'Роман',
      age: 19,
      description: 'Люблю пригоди, ігри, книги, походи, знаходити друзів, затишну компанію, дивитися на зірки, геймерські битви',
      photos: [
        'assets/images/portrait-man-laughing.jpg',
        'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
        'assets/images/pleased-smiling-man-with-beard-looking-camera.jpg',
      ],
      location: 'Луцьк',
      hobbies: ['Фентезі книги', 'Похід з наметом', 'Ранкова кава з видом на гори', 'Гра на гітарі', 'Фотографія', 'Кулінарія', 'Подорожі', 'Спорт'],
    ),
    UserProfile(
      id: '2',
      name: 'Анна',
      age: 22,
      description: 'Люблю подорожувати, фотографувати, читати книги та знайомитися з новими людьми',
      photos: [
        'assets/images/selfie-portrait-videocall.jpg',
        'assets/images/portrait-man-laughing.jpg',
        'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
      ],
      location: 'Київ',
      hobbies: ['Подорожі', 'Фотографія', 'Читання', 'Йога', 'Медитація', 'Велоспорт', 'Кулінарія', 'Мистецтво'],
    ),
    UserProfile(
      id: '3',
      name: 'Максим',
      age: 25,
      description: 'Спортсмен, люблю активний спосіб життя та нові виклики',
      photos: [
        'assets/images/pleased-smiling-man-with-beard-looking-camera.jpg',
        'assets/images/portrait-man-laughing.jpg',
        'assets/images/selfie-portrait-videocall.jpg',
      ],
      location: 'Львів',
      hobbies: ['Спорт', 'Фітнес', 'Гори', 'Бокс', 'Плавання', 'Біг', 'Здорове харчування', 'Мотивація'],
    ),
  ];

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
                  // Верхня панель
                  _buildTopBar(),
                  
                  // Основний контент з свайп-картками
                  Expanded(
                    child: _buildSwipeCards(),
                  ),
                  
                  // Нижня панель дій
                  _buildBottomActions(),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          // Пошукова панель
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search_people,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onChanged: (value) {
                // Тут буде логіка пошуку людей
                debugPrint('Пошук: $value');
              },
            ),
          ),
          
          // Кнопки "Для вас" та "Заходи поблизу"
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.for_you,
                          style: TextStyle(
                            color: _selectedTab == 0 ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EventsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.events_nearby,
                          style: TextStyle(
                            color: _selectedTab == 1 ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Головний контейнер для відображення анкет з CardSwiper
  Widget _buildSwipeCards() {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'Більше немає користувачів',
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    
    return CardSwiper(
      controller: _cardSwiperController,
      cardsCount: users.length,
      numberOfCardsDisplayed: users.length < 3 ? users.length : 3,
      onSwipe: _onSwipe,
      onEnd: _onEnd,
      cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
        return _buildUserCard(users[index]);
      },
      duration: const Duration(milliseconds: 300),
      threshold: 80, // Поріг для свайпу анкети
      allowedSwipeDirection: AllowedSwipeDirection.only(
        left: true,
        right: true,
        up: false,
        down: false,
      ), // Дозволяємо лише горизонтальні свайпи для анкет
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(10), // Зменшили відступ для більшої картки
      height: MediaQuery.of(context).size.height * 0.75, // Збільшили висоту картки
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Карусель фото з правильним обробником жестов
            Container(
              height: double.infinity,
              margin: const EdgeInsets.only(bottom: 0), // Зменшили відступ знизу для більшого фото
              child: PageView.builder(
                key: ValueKey('pageview_${user.id}'),
                controller: _createControllerForUser(user.id),
                physics: const PageScrollPhysics(), // Стандартне листання для фото
                itemCount: user.photos.length,
                itemBuilder: (context, photoIndex) {
                  return Image.asset(
                    user.photos[photoIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
                onPageChanged: (index) {
                  debugPrint('PageView onPageChanged: $index для користувача ${user.name}');
                  setState(() {
                    _currentPhotoIndex[user.id] = index;
                  });
                },
              ),
            ),
            
            // Градієнт поверх фото
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            
            // Індикатор фото (текстовий) - показуємо тільки якщо є більше одного фото
            if (user.photos.length > 1)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Текстовий індикатор (1/3, 2/3, 3/3)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(_currentPhotoIndex[user.id] ?? 0) + 1}/${user.photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Іконка інформації (зверху справа)
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileDetailScreen(profile: {
                        'name': user.name,
                        'age': user.age,
                        'description': user.description,
                        'photos': user.photos,
                        'location': user.location,
                        'hobbies': user.hobbies,
                        'aboutMe': user.description,
                        'distance': AppLocalizations.of(context)!.distance,
                      }),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            // Інформація про користувача
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.name}, ${user.age}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.location,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _getLocalizedHobbies(user.hobbies, context).take(5).map((hobby) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          hobby,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Стрілки для перемикання фото (показуємо тільки якщо є більше одного фото)
            if (user.photos.length > 1)
              Positioned(
                bottom: 15, // Підвищили позицію стрілок
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Центруємо стрілки
                  children: [
                    // Ліва стрілка
                    GestureDetector(
                      onTap: () {
                        final currentIndex = _currentPhotoIndex[user.id] ?? 0;
                        if (currentIndex > 0) {
                          _createControllerForUser(user.id).previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5), // Більш видимий фон
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: (_currentPhotoIndex[user.id] ?? 0) > 0 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.3),
                          size: 24,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20), // Відступ між стрілками
                    
                    // Права стрілка
                    GestureDetector(
                      onTap: () {
                        final currentIndex = _currentPhotoIndex[user.id] ?? 0;
                        if (currentIndex < user.photos.length - 1) {
                          _createControllerForUser(user.id).nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5), // Більш видимий фон
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: (_currentPhotoIndex[user.id] ?? 0) < user.photos.length - 1 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.3),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Обробка свайпу картки
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    debugPrint('Свайпнуто ${direction.name} з індексу $previousIndex на $currentIndex');
    
    if (direction == CardSwiperDirection.right) {
      // Лайк
      debugPrint('Лайк для ${users[previousIndex].name}');
      // Тут можна додати логіку для лайку (збереження в базу даних тощо)
    } else if (direction == CardSwiperDirection.left) {
      // Дизлайк
      debugPrint('Дизлайк для ${users[previousIndex].name}');
      // Тут можна додати логіку для дизлайку (збереження в базу даних тощо)
    }
    
    // Оновлюємо поточний індекс користувача
    if (currentIndex != null) {
      setState(() {
        _currentUserIndex = currentIndex;
      });
    }
    
    // Скидаємо фото до першої для наступного користувача
    if (currentIndex != null && currentIndex < users.length) {
      final nextUser = users[currentIndex];
      final controller = _photoControllers[nextUser.id];
      if (controller != null) {
        controller.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        // Скидаємо індекс фото
        _currentPhotoIndex[nextUser.id] = 0;
      }
    }
    
    return true;
  }

  /// Обробка закінчення карток
  void _onEnd() {
    debugPrint('Закінчилися картки');
    // Тут можна додати логіку для завантаження нових користувачів
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Кнопка ❌ (не подобається) - свайп вліво
          _buildActionButton(
            Icons.close,
            Colors.red,
            () {
              _cardSwiperController.swipeLeft();
            },
            size: 65,
          ),
          
          // Кнопка 💬 (повідомлення)
          _buildActionButton(
            Icons.chat_bubble_outline,
            Colors.white,
            () {
              if (_currentUserIndex < users.length) {
                debugPrint('Повідомлення для ${users[_currentUserIndex].name}');
                // Тут можна додати логіку для відкриття чату
              }
            },
            borderColor: Colors.grey.shade300,
            size: 55,
          ),
          
          // Кнопка ❤️ (подобається) - свайп вправо
          _buildActionButton(
            Icons.favorite,
            Colors.blue,
            () {
              _cardSwiperController.swipeRight();
            },
            size: 65,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color backgroundColor, VoidCallback onTap, {Color? borderColor, double size = 60}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: backgroundColor == Colors.white ? Colors.black : Colors.white,
          size: size * 0.45, // Пропорційний розмір іконки
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Очищаємо всі PageController'и для запобігання витоку пам'яті
    for (var controller in _photoControllers.values) {
      controller.dispose();
    }
    _photoControllers.clear();
    super.dispose();
  }
}
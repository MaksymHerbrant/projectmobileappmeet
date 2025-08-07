import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'event_detail_screen.dart';
import 'main_navigation_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final CardSwiperController controller = CardSwiperController();
  
  // Контролери для каруселі фото кожного заходу
  final Map<String, PageController> _photoControllers = {};
  final Map<String, int> _currentPhotoIndex = {};

  // Список заходів
  final List<Event> events = [
    Event(
      id: '1',
      title: 'Вечірка в клубі',
      location: 'Клуб "Парадокс"',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      photos: [
        'assets/images/club1.jpg',
        'assets/images/club2.jpeg',
        'assets/images/club3.jpg',
      ],
      tags: ['Музика', 'Танці', 'Вечірка'],
      description: 'Велика вечірка з найкращою музикою та атмосферою. Приходьте разом з друзями!',
      participantsCount: 45,
    ),
    Event(
      id: '2',
      title: 'Похід на Говерлу',
      location: 'Гора Говерла',
      dateTime: DateTime.now().add(const Duration(days: 5)),
      photos: [
        'assets/images/goverla1.jpg',
        'assets/images/goverla2.jpeg',
        'assets/images/hoverla4.jpg',
      ],
      tags: ['Природа', 'Похід', 'Гори'],
      description: 'Група походу на найвищу точку України. Не забудьте теплий одяг та гарний настрій!',
      participantsCount: 12,
    ),
    Event(
      id: '3',
      title: 'Воркшоп з програмування',
      location: 'IT Hub',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      photos: [
        'assets/images/workshop.jpg',
        'assets/images/workshop2.jpg',
        'assets/images/workshop3.jpeg',
      ],
      tags: ['Освіта', 'IT', 'Воркшоп'],
      description: 'Навчимося створювати веб-додатки з нуля. Підходить для початківців.',
      participantsCount: 25,
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

          // Нижнє меню навігації
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }



  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          // Кнопки "Для вас" та "Заходи поблизу"
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.for_you,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.events,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Кнопка фільтрів
          GestureDetector(
            onTap: _showFilters,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/icons/filter.png',
                width: 20,
                height: 20,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeCards() {
    return CardSwiper(
      controller: controller,
      cardsCount: events.length,
      numberOfCardsDisplayed: events.length < 3 ? events.length : 3,
      onSwipe: _onSwipe,
      onEnd: _onEnd,
      cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
        return _buildEventCard(events[index]);
      },
      duration: const Duration(milliseconds: 300),
      threshold: 80, // Збільшуємо поріг для меншої чутливості (максимум 100)
    );
  }

  Widget _buildEventCard(Event event) {
    // Створюємо контролер для цього заходу, якщо його ще немає
    if (!_photoControllers.containsKey(event.id)) {
      _photoControllers[event.id] = PageController();
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(20),
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
            // Карусель фото з обробкою свайпів
            SizedBox(
              height: double.infinity,
              child: PageView.builder(
                controller: _photoControllers[event.id],
                physics: const PageScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPhotoIndex[event.id] = index;
                  });
                },
                itemCount: event.photos.length,
                itemBuilder: (context, photoIndex) {
                  return Image.asset(
                    event.photos[photoIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
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
            
            // Індикатор фото (3 точки) - показуємо тільки якщо є більше одного фото
            if (event.photos.length > 1)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    event.photos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_currentPhotoIndex[event.id] ?? 0) == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
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
                      builder: (context) => EventDetailScreen(event: event),
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
            
            // Інформація про захід
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
                                event.title,
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
                                    event.location,
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
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.dateTime.day}.${event.dateTime.month}.${event.dateTime.year}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.people,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.participantsCount} ${AppLocalizations.of(context)!.participants}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: event.tags.take(5).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          tag,
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
          ],
        ),
      ),
    );
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
              controller.swipeLeft();
            },
            size: 65,
          ),
          
          // Кнопка 💬 (повідомлення)
          _buildActionButton(
            Icons.chat_bubble_outline,
            Colors.white,
            () {
              // Логіка для повідомлення
              debugPrint('Повідомлення для заходу');
            },
            borderColor: Colors.grey.shade300,
            size: 55,
          ),
          
          // Кнопка ❤️ (подобається) - свайп вправо
          _buildActionButton(
            Icons.favorite,
            Colors.blue,
            () {
              controller.swipeRight();
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

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    debugPrint('Свайпнуто ${direction.name} з індексу $previousIndex на $currentIndex');
    
    if (direction == CardSwiperDirection.right) {
      // Лайк
      debugPrint('Лайк для ${events[previousIndex].title}');
    } else if (direction == CardSwiperDirection.left) {
      // Дизлайк
      debugPrint('Дизлайк для ${events[previousIndex].title}');
    }
    
    // Скидаємо фото до першої для наступного заходу
    if (currentIndex != null && currentIndex < events.length) {
      final nextEvent = events[currentIndex];
      final controller = _photoControllers[nextEvent.id];
      if (controller != null) {
        controller.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        // Скидаємо індекс фото
        _currentPhotoIndex[nextEvent.id] = 0;
      }
    }
    
    return true;
  }

  void _onEnd() {
    debugPrint('Закінчилися картки');
    // Тут можна додати логіку для завантаження нових заходів
  }

  // Змінні для фільтрів
  String? _selectedDateFilter;
  String? _selectedDistanceFilter;
  final Set<String> _selectedTags = {};

  void _showFilters() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.event_filters,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7, // Обмежуємо висоту
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Фільтр по даті
                    _buildDateFilter(setState),
                    const SizedBox(height: 20),
                    
                    // Фільтр по відстані
                    _buildDistanceFilter(setState),
                    const SizedBox(height: 20),
                    
                    // Фільтр по тегах
                    _buildTagsFilter(setState),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _selectedDateFilter = null;
                  _selectedDistanceFilter = null;
                  _selectedTags.clear();
                  Navigator.of(context).pop();
                },
                child: Text(
                  AppLocalizations.of(context)!.clear_filters,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _applyFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.apply_filters),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateFilter(StateSetter setState) {
    final dateOptions = [
      AppLocalizations.of(context)!.today,
      AppLocalizations.of(context)!.tomorrow,
      AppLocalizations.of(context)!.this_week,
      AppLocalizations.of(context)!.this_month,
      AppLocalizations.of(context)!.next_month,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.filter_by_date,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: dateOptions.map((option) {
            final isSelected = _selectedDateFilter == option;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDateFilter = isSelected ? null : option;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDistanceFilter(StateSetter setState) {
    final distanceOptions = [
      AppLocalizations.of(context)!.within_1_km,
      AppLocalizations.of(context)!.within_5_km,
      AppLocalizations.of(context)!.within_10_km,
      AppLocalizations.of(context)!.within_25_km,
      AppLocalizations.of(context)!.within_50_km,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.filter_by_distance,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: distanceOptions.map((option) {
            final isSelected = _selectedDistanceFilter == option;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDistanceFilter = isSelected ? null : option;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsFilter(StateSetter setState) {
    final allTags = [
      AppLocalizations.of(context)!.music,
      AppLocalizations.of(context)!.dancing,
      AppLocalizations.of(context)!.sport,
      AppLocalizations.of(context)!.travel,
      AppLocalizations.of(context)!.cooking,
      AppLocalizations.of(context)!.reading,
      AppLocalizations.of(context)!.gaming,
      AppLocalizations.of(context)!.board_games,
      AppLocalizations.of(context)!.photography,
      AppLocalizations.of(context)!.art,
      AppLocalizations.of(context)!.fitness,
      AppLocalizations.of(context)!.yoga,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.filter_by_tags,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
                          Text(
                _selectedTags.isEmpty
                    ? AppLocalizations.of(context)!.no_tags_selected
                    : AppLocalizations.of(context)!.selected_tags(_selectedTags.length.toString()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _applyFilters() {
    // Тут буде логіка застосування фільтрів
    debugPrint('Застосовано фільтри:');
    debugPrint('Дата: $_selectedDateFilter');
    debugPrint('Відстань: $_selectedDistanceFilter');
    debugPrint('Теги: $_selectedTags');
    
    // Можна додати логіку фільтрації заходів тут
    // Наприклад, оновити список events на основі вибраних фільтрів
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      color: const Color(0xFFF3E5F5),
      padding: const EdgeInsets.only(top: 20, bottom: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Кнопка "Для вас" (головна стрічка) - активна в екрані заходів
          _buildBottomNavItem(
            icon: 'assets/icons/cards_8531803.png',
            index: 0,
            isActive: true,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainNavigationScreen(initialIndex: 0),
                ),
              );
            },
          ),
          
          // Кнопка "Чат"
          _buildBottomNavItem(
            icon: 'assets/icons/email_2099199.png',
            index: 1,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainNavigationScreen(initialIndex: 1),
                ),
              );
            },
          ),
          
          // Кнопка "Пари"
          _buildBottomNavItem(
            icon: 'assets/icons/heart-2.png',
            index: 2,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainNavigationScreen(initialIndex: 2),
                ),
              );
            },
          ),
          
          // Кнопка "Профіль"
          _buildBottomNavItem(
            icon: 'assets/icons/user_12289885.png',
            index: 3,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainNavigationScreen(initialIndex: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required String icon,
    required int index,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          icon,
          width: 32,
          height: 32,
          color: isActive ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
} 
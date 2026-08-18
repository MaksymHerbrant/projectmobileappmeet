import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/locale_provider.dart';
import '../service/matches_service.dart';
import 'event_detail_screen.dart';
import 'main_navigation_screen.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final CardSwiperController controller = CardSwiperController();
  final MatchesService _matchesService = MatchesService();

  /// Той самий радіус, що і в стрічці людей — користувач налаштовує його раз.
  int _radiusKm = 50;
  
  // Стан
  List<Event> events = [];
  bool _isLoading = true;
  bool _isFinished = false;
  // 🟢 Тимчасова змінна для зберігання повідомлення перед свайпом
  String? _pendingMessage; 

  final Map<String, PageController> _photoControllers = {};
  final Map<String, int> _currentPhotoIndex = {};

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getInt('feed_radius_km') ?? 50;
      if (mounted && saved != _radiusKm) {
        setState(() => _radiusKm = saved);
        _loadEvents();
      }
    });
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _isFinished = false; // 🟢 СКИДАЄМО СТАН AppLocalizations.of(context)!.ended_badge
    });
    
    try {
      final newEvents = await _matchesService.getEventFeed(radiusKm: _radiusKm);
      if (mounted) {
        setState(() {
          events = newEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Помилка завантаження подій: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Хелпер для фото (з фіксом помилки 404)
  ImageProvider _getImageProvider(List<String>? photos) {
    if (photos == null || photos.isEmpty) {
      return const NetworkImage('https://ui-avatars.com/api/?name=Event&background=random'); 
    }
    final String path = photos.first;
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    // Фікс для старих посилань або placeholder
    if (path.contains('placeholder')) {
       return const NetworkImage('https://ui-avatars.com/api/?name=Event&background=random');
    }
    return AssetImage(path);
  }

  ImageProvider _getSingleImageProvider(String? path) {
    if (path == null || path.isEmpty) {
      return const NetworkImage('https://ui-avatars.com/api/?name=Event&background=random');
    }
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    if (path.contains('placeholder')) {
       return const NetworkImage('https://ui-avatars.com/api/?name=Event&background=random');
    }
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          // resizeToAvoidBottomInset: false дозволяє клавіатурі відкриватися поверх, не ламаючи верстку
          resizeToAvoidBottomInset: false, 
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: AppTheme.backgroundGradient(context),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _isLoading 
                        ? const Center(child: CircularProgressIndicator()) 
                        : _buildSwipeCards(),
                  ),
                  // Ховаємо кнопки, якщо клавіатура відкрита (опціонально)
                  if (!_isLoading && events.isNotEmpty && MediaQuery.of(context).viewInsets.bottom == 0)
                    _buildBottomActions(),
                ],
              ),
            ),
          ),
          // Нижню навігацію можна приховати на цьому екрані або залишити
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  // ... _buildTopBar залишаємо без змін ...
  Widget _buildTopBar() {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(AppLocalizations.of(context)!.for_you, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, borderRadius: BorderRadius.circular(20)),
                  child: Text(AppLocalizations.of(context)!.events, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Кнопка фільтрів (поки заглушка)
           Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.filter_list, size: 20, color: Theme.of(context).colorScheme.onSurface),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeCards() {
    // 1. Якщо подій взагалі не прийшло з сервера
    if (events.isEmpty && !_isLoading) {
      return _buildNoMoreEventsState(); // Використаємо той самий віджет
    }

    // 2. 🟢 Якщо користувач прогортав усі картки
    if (_isFinished) {
      return _buildNoMoreEventsState();
    }

    // 3. Якщо все ок — показуємо свайпер
    return CardSwiper(
      controller: controller,
      cardsCount: events.length,
      numberOfCardsDisplayed: events.length < 3 ? events.length : 3,
      onSwipe: _onSwipe,
      onEnd: _onEnd,
      isLoop: false, // Важливо: не зациклювати
      cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
        return _buildEventCard(events[index]);
      },
      duration: const Duration(milliseconds: 300),
      threshold: 80,
      allowedSwipeDirection: const AllowedSwipeDirection.only(left: true, right: true, up: false, down: false),
    );
  }

  // 🟢 Гарний віджет для повідомлення "Все скінчилось"
  Widget _buildNoMoreEventsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
              ),
              child: Icon(Icons.sentiment_dissatisfied, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.events_finished_title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.events_finished_body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.refresh),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Або твій основний колір
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEventCard(Event event) {
    // Ініціалізація контролера, якщо ще немає
    if (!_photoControllers.containsKey(event.id)) {
      _photoControllers[event.id] = PageController();
      _currentPhotoIndex[event.id] = 0;
    }
    
    final pageController = _photoControllers[event.id]!;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Карусель фото (Свайп ВИМКНЕНО)
            SizedBox(
              height: double.infinity,
              child: PageView.builder(
                controller: pageController,
                // 🔴 ВАЖЛИВО: Вимикаємо свайп самого PageView, щоб не конфліктував з карткою
                physics: const NeverScrollableScrollPhysics(), 
                onPageChanged: (index) {
                  setState(() => _currentPhotoIndex[event.id] = index);
                },
                itemCount: event.photos.isEmpty ? 1 : event.photos.length,
                itemBuilder: (context, photoIndex) {
                  final photo = event.photos.isNotEmpty ? event.photos[photoIndex] : null;
                  return Image(
                    image: _getSingleImageProvider(photo), 
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).colorScheme.outlineVariant),
                  );
                },
              ),
            ),
            
            // 2. Градієнт
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // 🟢 3. ЗОНИ НАТИСКАННЯ (Для гортання фото)
            if (event.photos.length > 1)
              Row(
                children: [
                  // Ліва половина - НАЗАД
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent, // Пропускає свайпи картки, але ловить тапи
                      onTap: () {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 250), 
                          curve: Curves.easeInOut
                        );
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // Права половина - ВПЕРЕД
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 250), 
                          curve: Curves.easeInOut
                        );
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            
            // 4. Індикатори (Крапки зверху)
            if (event.photos.length > 1)
              Positioned(
                top: 10, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    event.photos.length,
                    (index) {
                       // Отримуємо поточний індекс безпечно
                       final currentIndex = _currentPhotoIndex[event.id] ?? 0;
                       return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: currentIndex == index ? 24 : 6, // Активна риска довша
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: currentIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            // 5. Інфо іконка
            Positioned(
              top: 20, right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                ),
              ),
            ),
            
            // 6. Інформація про захід (Текст знизу)
            Positioned(
              bottom: 0, left: 0, right: 0,
              // `IgnorePointer` дозволяє тапати "крізь" текст, щоб перемикати фото,
              // або можна прибрати його, якщо хочеш, щоб текст не був клікабельним для фото.
              child: IgnorePointer( 
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(event.location, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ... інші віджети (дата, учасники, теги)
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
                          const SizedBox(width: 4),
                          Text('${event.dateTime.day}.${event.dateTime.month}.${event.dateTime.year}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                          const SizedBox(width: 16),
                          Icon(Icons.people, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context)!.participants_count(event.participantsCount), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        children: event.tags.take(3).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                          child: Text(tag, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 ГОЛОВНА ЛОГІКА СВАЙПІВ
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex >= events.length) return false;
    
    final swipedEvent = events[previousIndex];
    
    if (direction == CardSwiperDirection.right) {
      debugPrint('Лайк події: ${swipedEvent.title}');
      
      // 🟢 Передаємо повідомлення (якщо воно є)
      _matchesService.recordEventSwipe(swipedEvent.id, true, message: _pendingMessage);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pendingMessage != null ? AppLocalizations.of(context)!.request_sent_msg : AppLocalizations.of(context)!.request_sent), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (direction == CardSwiperDirection.left) {
      debugPrint('Пропуск події: ${swipedEvent.title}');
      _matchesService.recordEventSwipe(swipedEvent.id, false);
    }
    
    // Очищаємо повідомлення після свайпу
    _pendingMessage = null;
    
    if (currentIndex != null && currentIndex < events.length) {
       _currentPhotoIndex[events[currentIndex].id] = 0;
       _photoControllers[events[currentIndex].id]?.jumpToPage(0);
    }
    
    return true;
  }

  void _onEnd() {
    debugPrint('Події закінчилися');
    setState(() {
      _isFinished = true; // 🟢 ТЕПЕР МИ ЗНАЄМО, ЩО КАРТКИ СКІНЧИЛИСЬ
    });
  }

  Widget _buildBottomActions() {
      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.close, Colors.red, () => controller.swipe(CardSwiperDirection.left), size: 65),
          
          // 🟢 Кнопка ПОВІДОМЛЕННЯ
          _buildActionButton(
            Icons.chat_bubble_outline,
            Colors.white,
            _showMessageDialog, // 👈 Викликаємо діалог
            borderColor: Theme.of(context).colorScheme.outlineVariant,
            size: 55,
          ),
          
         _buildActionButton(Icons.favorite ,Colors.blue, () => controller.swipe(CardSwiperDirection.right), size: 65),
        ],
      ),
    );
  }

  // 🟢 Діалог для введення повідомлення
  void _showMessageDialog() {
    // Якщо немає подій, не показуємо діалог
    if (events.isEmpty) return;

    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.send_message),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.join_message_hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // 1. Зберігаємо текст у тимчасову змінну
              setState(() {
                _pendingMessage = textController.text.trim();
              });
              
              // 2. Закриваємо діалог
              Navigator.pop(context);
              
              // 3. Робимо свайп вправо (Лайк). Це викличе _onSwipe, де ми використаємо _pendingMessage
              controller.swipe(CardSwiperDirection.right);
            },
            child: Text(AppLocalizations.of(context)!.send),
          ),
        ],
      ),
    );
  }

   Widget _buildActionButton(IconData icon, Color backgroundColor, VoidCallback onTap, {Color? borderColor, double size = 60}) {
     return GestureDetector(onTap: onTap, child: Container(
       width: size, height: size, 
       decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle, border: borderColor != null ? Border.all(color: borderColor) : null),
       child: Icon(icon, color: backgroundColor == Colors.white ? Colors.black : Colors.white),
     ));
   }
   
   // ... (BottomNavigationBar без змін) ...
    Widget _buildBottomNavigationBar() {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.only(top: 20, bottom: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(icon: 'assets/icons/cards_8531803.png', index: 0, isActive: true, onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialIndex: 0)))),
          _buildBottomNavItem(icon: 'assets/icons/email_2099199.png', index: 1, onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialIndex: 1)))),
          _buildBottomNavItem(icon: 'assets/icons/heart-2.png', index: 2, onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialIndex: 2)))),
          _buildBottomNavItem(icon: 'assets/icons/user_12289885.png', index: 3, onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialIndex: 3)))),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({required String icon, required int index, required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.3) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Image.asset(icon, width: 28, height: 28, color: isActive ? Colors.black : Colors.grey,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.circle, color: isActive ? Colors.black : Colors.grey),
        ),
      ),
    );
  }
}
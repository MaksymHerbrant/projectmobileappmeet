import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // Для ефекту блюру
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 1. Імпорт для швидкості
import '../models/user_profile.dart';
import '../providers/locale_provider.dart';
import '../service/matches_service.dart';
import '../service/error_reporter.dart';
import '../service/location_service.dart';
import 'profile_detail_screen.dart';
import 'events_screen.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  final MatchesService _matchesService = MatchesService();
  final LocationService _locationService = LocationService();
  final CardSwiperController _cardSwiperController = CardSwiperController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Стан
  int _selectedTab = 0; 
  bool _isLoading = true;
  bool _isFinished = false;
  bool _isSearchActive = false;

  /// Радіус пошуку в кілометрах. Зберігається між сеансами.
  int _radiusKm = 50;
  bool _hasLocation = true;
  
  List<UserProfile> users = [];
  Timer? _debounce; 

  final Map<String, PageController> _photoControllers = {};
  final Map<String, int> _currentPhotoIndex = {};

  @override
  void initState() {
    super.initState();
    _restoreRadiusAndLoad();
    
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchActive = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cardSwiperController.dispose();
    for (var controller in _photoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- ЗАВАНТАЖЕННЯ ДАНИХ ---

  Future<void> _restoreRadiusAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _radiusKm = prefs.getInt('feed_radius_km') ?? 50;

    // Позиція оновлюється при кожному відкритті, інакше радіус рахувався б
    // від місця, де людина була востаннє при редагуванні профілю.
    // silent: не випрошуємо дозвіл системним діалогом на кожному запуску —
    // це робить явна кнопка в профілі.
    final outcome = await _locationService.refreshMyLocation(silent: true);
    _hasLocation = outcome.isSuccess;
    if (!mounted) return;
    await _loadUsers();
  }

  Future<void> _setRadius(int km) async {
    setState(() => _radiusKm = km);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('feed_radius_km', km);
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _isFinished = false;
    });

    try {
      final newUsers = await _matchesService.getFeed(radiusKm: _radiusKm);
      if (mounted) {
        setState(() {
          users = newUsers;
          _isLoading = false;
        });
        
        // 🔥 2. Одразу починаємо вантажити фото перших користувачів
        if (users.isNotEmpty) _preloadImages(context, users[0]);
        if (users.length > 1) _preloadImages(context, users[1]);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorReporter.toFailure(e).message)),
        );
      }
    }
  }
  
  // 🔥 3. ФУНКЦІЯ ДЛЯ ШВИДКОГО ЗАВАНТАЖЕННЯ (Pre-cache)
  void _preloadImages(BuildContext context, UserProfile user) {
    for (var photoUrl in user.photos) {
      if (photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
        precacheImage(CachedNetworkImageProvider(photoUrl), context);
      }
    }
  }

  // --- ПОШУК ---

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) return; 

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final searchResults = await _matchesService.searchUsersByName(query);
        if (mounted) {
          setState(() {
            users = searchResults;
          });
        }
      } catch (e) {
        debugPrint("Помилка пошуку: $e");
      }
    });
  }

  // --- ЛОГІКА СВАЙПІВ ---

  void _onEnd() {
    setState(() => _isFinished = true);
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex >= users.length) return false;
    final swipedUser = users[previousIndex];
    
    if (direction == CardSwiperDirection.right) {
      _submitSwipe(swipedUser.id, true);
    } else if (direction == CardSwiperDirection.left) {
      _submitSwipe(swipedUser.id, false);
    }

    return true;
  }

  /// Свайп навмисно не блокує анімацію картки — але помилку показати треба,
  /// інакше при вичерпаному ліміті свайпи мовчки перестають зберігатись.
  Future<void> _submitSwipe(String userId, bool isLike) async {
    try {
      await _matchesService.recordSwipe(userId, isLike);
    } catch (e) {
      if (!mounted) return;
      final failure = ErrorReporter.toFailure(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

  // --- ХЕЛПЕРИ UI ---

  PageController _createControllerForUser(String userId) {
    if (!_photoControllers.containsKey(userId)) {
      _photoControllers[userId] = PageController(initialPage: 0);
      _currentPhotoIndex[userId] = 0;
    }
    return _photoControllers[userId]!;
  }

  // --- ГОЛОВНИЙ BUILD ---

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false, 
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
                  if (!_isSearchActive) _buildRadiusControl(),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildBody(), 
                        if (_isSearchActive)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                _searchController.clear();
                                if (users.isEmpty) _loadUsers();
                              },
                              child: ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(color: Colors.black.withOpacity(0.1)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLoading && !_isFinished && users.isNotEmpty && !_isSearchActive && MediaQuery.of(context).viewInsets.bottom == 0)
                    _buildBottomActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- ВІДЖЕТИ ---

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return _buildEmptyState();
    if (_isFinished) return _buildFinishedState();

    return CardSwiper(
      controller: _cardSwiperController,
      cardsCount: users.length,
      // 🔥 Оптимізація: малюємо тільки 2 картки
      numberOfCardsDisplayed: users.length < 2 ? users.length : 2,
      onSwipe: _onSwipe,
      onEnd: _onEnd,
      isLoop: false,
      cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
        // 🔥 4. ЗАПУСКАЄМО ЗАВАНТАЖЕННЯ НАСТУПНОГО КОРИСТУВАЧА
        // Поки ми дивимось на index, ми вже качаємо index + 1
        if (index + 1 < users.length) {
          _preloadImages(context, users[index + 1]);
        }
        
        return _buildUserCard(users[index]);
      },
      duration: const Duration(milliseconds: 300),
      threshold: 80,
      allowedSwipeDirection: const AllowedSwipeDirection.only(left: true, right: true, up: false, down: false),
    );
  }

  Widget _buildTopBar() {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search_people, 
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                        _loadUsers();
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onChanged: _onSearchChanged, 
            ),
          ),
          
          if (!_isSearchActive)
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.black : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(AppLocalizations.of(context)!.for_you, style: TextStyle(color: _selectedTab == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EventsScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.black : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(AppLocalizations.of(context)!.events_nearby, style: TextStyle(color: _selectedTab == 1 ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 16)),
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

  static const List<int> _radiusSteps = [5, 10, 25, 50, 100, 200];

  int _nextRadius(int current) {
    for (final step in _radiusSteps) {
      if (step > current) return step;
    }
    return _radiusSteps.last;
  }

  /// Керування радіусом. Без нього «друзі поруч» — просто список усіх, кого
  /// повернув сервер.
  Widget _buildRadiusControl() {
    final t = AppLocalizations.of(context)!;
    if (!_hasLocation) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            t.radius_km(_radiusKm),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: _radiusSteps.indexOf(_radiusKm).toDouble().clamp(0, (_radiusSteps.length - 1).toDouble()),
                min: 0,
                max: (_radiusSteps.length - 1).toDouble(),
                divisions: _radiusSteps.length - 1,
                activeColor: Colors.black87,
                inactiveColor: Colors.black12,
                onChanged: (v) => setState(() => _radiusKm = _radiusSteps[v.round()]),
                onChangeEnd: (v) => _setRadius(_radiusSteps[v.round()]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
              child: const Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(t.feed_empty_title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Text(
              _hasLocation
                  ? t.feed_empty_radius(_radiusKm)
                  : t.feed_empty_no_location,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Порожній стан має пропонувати дію, а не просто повідомляти факт.
            if (_hasLocation && _radiusKm < 200)
              ElevatedButton.icon(
                onPressed: () => _setRadius(_nextRadius(_radiusKm)),
                icon: const Icon(Icons.travel_explore),
                label: Text(t.search_within_km(_nextRadius(_radiusKm))),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              )
            else
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: Text(t.refresh),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedState() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
              child: const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 24),
            Text(t.feed_finished_title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: Text(t.search_again),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final controller = _createControllerForUser(user.id);

    return Container(
      // 🔥 1. ВАЖЛИВО: Робимо картку непрозорою, щоб не бачити наступну
      decoration: BoxDecoration(
        color: Colors.white, // Білий фон перекриває картку знизу
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Карусель фото
            Positioned.fill(
              // 🔥 2. Додаємо білий фон під фото, щоб при завантаженні не було "дірки"
              child: Container(
                color: Colors.white, 
                child: PageView.builder(
                  controller: controller,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: user.photos.isEmpty ? 1 : user.photos.length,
                  itemBuilder: (context, photoIndex) {
                    final photo = user.photos.isNotEmpty ? user.photos[photoIndex] : null;

                    if (photo != null && photo.startsWith('http')) {
                      return CachedNetworkImage(
                        imageUrl: photo,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        // 🔥 3. Замість прозорості показуємо сірий блок
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200], 
                          child: const Center(
                            child: SizedBox(
                              width: 30, height: 30, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)
                            )
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
                        // 🔥 4. Вимикаємо плавну появу (fade-in), бо вона створює прозорість на 0.5с
                        fadeInDuration: Duration.zero, 
                        fadeOutDuration: Duration.zero,
                      );
                    }

                    // Для локальних фото
                    return Image(
                      image: _getSingleImageProvider(photo),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      // Те саме для звичайних фото - білий фон при помилці
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                    );
                  },
                  onPageChanged: (index) {
                    setState(() => _currentPhotoIndex[user.id] = index);
                  },
                ),
              ),
            ),

            // 2. Градієнт (Тінь знизу)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent, 
                      Colors.black.withOpacity(0.3), 
                      Colors.black.withOpacity(0.9)
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Тап-зони (Для перемикання фото)
            if (user.photos.length > 1)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent, // Пропускає натискання
                      onTap: () {
                        controller.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                        if ((_currentPhotoIndex[user.id] ?? 0) > 0) {
                          setState(() => _currentPhotoIndex[user.id] = (_currentPhotoIndex[user.id] ?? 0) - 1);
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        controller.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                        if ((_currentPhotoIndex[user.id] ?? 0) < user.photos.length - 1) {
                          setState(() => _currentPhotoIndex[user.id] = (_currentPhotoIndex[user.id] ?? 0) + 1);
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),

            // 4. Індикатори (Крапки зверху)
            if (user.photos.length > 1)
              Positioned(
                top: 20, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(user.photos.length, (index) {
                    bool isActive = (_currentPhotoIndex[user.id] ?? 0) == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 24 : 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),

            // 5. Кнопка Інфо (i)
            Positioned(
              top: 20, right: 20,
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
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                ),
              ),
            ),

            // 6. Текстова інформація (Ім'я, вік, місто)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.name}, ${user.age}', 
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            user.location.isNotEmpty ? user.location : 'Ukraine', 
                            style: const TextStyle(color: Colors.white70, fontSize: 16)
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.description, 
                        style: const TextStyle(color: Colors.white, fontSize: 14), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        children: user.hobbies.take(3).map((hobby) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2), 
                            borderRadius: BorderRadius.circular(15)
                          ),
                          child: Text(hobby, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
  // --- ХЕЛПЕР (Для старих ImageProvider) ---
  ImageProvider _getSingleImageProvider(String? path) {
    if (path == null || path.isEmpty) return const NetworkImage('https://ui-avatars.com/api/?name=User&background=random');
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.contains('placeholder')) return const NetworkImage('https://ui-avatars.com/api/?name=User&background=random');
    return AssetImage(path);
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Замість controller.swipeLeft()
          _buildActionButton(Icons.close, Colors.red, () => _cardSwiperController.swipe(CardSwiperDirection.left), size: 65),

          // Замість controller.swipeRight()
          _buildActionButton(Icons.favorite, Colors.blue, () => _cardSwiperController.swipe(CardSwiperDirection.right), size: 65),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(IconData icon, Color backgroundColor, VoidCallback onTap, {Color? borderColor, double size = 60}) {
     return GestureDetector(onTap: onTap, child: Container(
       width: size, height: size, 
       decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle, border: borderColor != null ? Border.all(color: borderColor) : null),
       child: Icon(icon, color: Colors.white),
     ));
  }
}
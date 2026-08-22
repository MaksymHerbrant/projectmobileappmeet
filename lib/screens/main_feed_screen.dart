import '../theme/design_kit.dart';
import '../l10n/interest_labels.dart';
import '../providers/app_state_provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // Для ефекту блюру
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'map_screen.dart';
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
          _preloaded.clear();
        });

        // 🔥 2. Одразу починаємо вантажити фото перших користувачів
        if (users.isNotEmpty) _preloadImages(context, users[0]);
        if (users.length > 1) _preloadImages(context, users[1]);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorReporter.message(context, e))),
        );
      }
    }
  }

  /// Профілі, фото яких уже ставили в чергу завантаження.
  ///
  /// Без цього набору попереднє завантаження запускалося повторно для того
  /// самого профілю щоразу, коли перемальовувалась картка.
  final Set<String> _preloaded = {};

  /// Попереднє завантаження фото наступної картки.
  ///
  /// На вебі не виконується взагалі. Браузер і так кешує відповіді, тож
  /// виграшу немає, а декілька одночасних декодувань через CanvasKit
  /// вивалюються в `Aborted()` — після чого рушій працює з пошкодженою
  /// пам'яттю і застосунок перестає реагувати на дотики.
  void _preloadImages(BuildContext context, UserProfile user) {
    if (kIsWeb) return;
    if (!_preloaded.add(user.id)) return;

    for (final photoUrl in user.photos) {
      if (photoUrl.isEmpty || !photoUrl.startsWith('http')) continue;
      precacheImage(
        CachedNetworkImageProvider(photoUrl),
        context,
        onError: (error, stack) {
          // Недоступне фото — не подія: картка покаже заглушку з ініціалом.
          debugPrint('Фото не завантажилось: $photoUrl');
        },
      );
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

  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex >= users.length) return false;
    final swipedUser = users[previousIndex];

    if (direction == CardSwiperDirection.right) {
      _submitSwipe(swipedUser.id, true);
    } else if (direction == CardSwiperDirection.left) {
      _submitSwipe(swipedUser.id, false);
    }

    // Черга завантаження просувається саме тут: колода зрушила рівно на одну
    // картку, тож наступну можна почати вантажити заздалегідь.
    if (currentIndex != null && currentIndex + 1 < users.length) {
      _preloadImages(context, users[currentIndex + 1]);
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
        SnackBar(content: Text(failure.localized(context))),
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
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: Ds.background(context),
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
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                      color: Colors.black.withOpacity(0.1)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLoading &&
                      !_isFinished &&
                      users.isNotEmpty &&
                      !_isSearchActive &&
                      MediaQuery.of(context).viewInsets.bottom == 0)
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
      // cardBuilder викликається щокадру під час перетягування, тож нічого,
      // крім побудови картки, тут бути не може.
      cardBuilder: (context, index, horizontalThresholdPercentage,
              verticalThresholdPercentage) =>
          _buildUserCard(users[index]),
      duration: const Duration(milliseconds: 300),
      threshold: 80,
      allowedSwipeDirection: const AllowedSwipeDirection.only(
          left: true, right: true, up: false, down: false),
    );
  }

  Widget _buildTopBar() {
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DsSearchField(
                  hint: t.search_people,
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              if (_searchController.text.isNotEmpty)
                DsIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    _loadUsers();
                  },
                )
              else
                // Кнопка карти з макета: та сама позиція, але залита
                // основним кольором — це головна дія поруч із пошуком.
                _MapButton(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MapScreen(radiusKm: _radiusKm),
                    ),
                  ),
                ),
            ],
          ),
          if (!_isSearchActive) ...[
            const SizedBox(height: 12),
            DsSegmented(
              items: [t.for_you, t.events_nearby],
              index: _selectedTab,
              onChanged: (i) {
                if (i == 0) {
                  setState(() => _selectedTab = 0);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const EventsScreen()),
                  );
                }
              },
            ),
          ],
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

  /// Просить дозвіл на геолокацію явно — на відміну від тихої спроби при
  /// запуску, тут системний діалог доречний, бо людина сама натиснула.
  Future<void> _enableLocation() async {
    final outcome = await _locationService.refreshMyLocation();
    if (!mounted) return;

    if (outcome.isSuccess) {
      setState(() => _hasLocation = true);
      await _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.feed_location_denied)),
      );
    }
  }

  /// Керування радіусом. Без нього «друзі поруч» — просто список усіх, кого
  /// повернув сервер.
  ///
  /// Коли позиції немає, повзунок безглуздий — але порожнє місце на його
  /// боці теж нічого не пояснює. Тому там стоїть рядок із дією: саме
  /// геолокація перетворює цей екран на «хто поруч».
  Widget _buildRadiusControl() {
    final t = AppLocalizations.of(context)!;

    if (!_hasLocation) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: GestureDetector(
          onTap: _enableLocation,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(Icons.location_off_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t.feed_enable_location, style: Ds.tiny(context)),
              ),
              const SizedBox(width: 10),
              DsChip(
                label: t.feed_enable_location_action,
                small: true,
                selected: true,
                onTap: _enableLocation,
              ),
            ],
          ),
        ),
      );
    }

    // Крок нерівномірний навмисно: між 5 і 10 км різниця відчутна, між 100 і
    // 105 — ні, тож повзунок ходить по заздалегідь обраних значеннях.
    final index =
        _radiusSteps.indexOf(_radiusKm).clamp(0, _radiusSteps.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: DsRadiusSlider(
        km: index,
        min: 0,
        max: _radiusSteps.length - 1,
        format: (i) => t.radius_km(_radiusSteps[i]),
        onChanged: (i) {
          final km = _radiusSteps[i];
          if (km == _radiusKm) return;
          setState(() => _radiusKm = km);
          _setRadius(km);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context)!;
    final canWiden = _hasLocation && _radiusKm < 200;

    return DsEmptyState(
      icon: Icons.location_searching_rounded,
      title: _hasLocation
          ? t.feed_empty_radius_title(_radiusKm)
          : t.feed_empty_title,
      body: _hasLocation ? t.feed_empty_widen_hint : t.feed_empty_no_location,
      actionLabel:
          canWiden ? t.search_within_km(_nextRadius(_radiusKm)) : t.refresh,
      onAction:
          canWiden ? () => _setRadius(_nextRadius(_radiusKm)) : _loadUsers,
      footer: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const EventsScreen()),
        ),
        child: Text.rich(
          TextSpan(
            style: Ds.tiny(context),
            children: [
              TextSpan(text: '${t.or_word} '),
              TextSpan(
                text: t.feed_empty_events_link,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedState() {
    final t = AppLocalizations.of(context)!;

    return DsEmptyState(
      icon: Icons.check_rounded,
      title: t.feed_finished_title,
      body: t.feed_finished_body,
      actionLabel: t.search_again,
      onAction: _loadUsers,
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final controller = _createControllerForUser(user.id);
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final photoIndex = _currentPhotoIndex[user.id] ?? 0;

    return Container(
      decoration: BoxDecoration(
        // Непрозорий фон обов'язковий: під карткою лежить наступна.
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Ds.rCard),
        boxShadow: Ds.shadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Ds.rCard),
        child: Column(
          children: [
            Expanded(child: _cardPhoto(user, controller, photoIndex, t)),
            _cardInfo(user, t, scheme),
          ],
        ),
      ),
    );
  }

  /// Верхня половина картки: фото, відстань і смужки гортання.
  Widget _cardPhoto(
    UserProfile user,
    PageController controller,
    int photoIndex,
    AppLocalizations t,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DsPhotoBlock(
          radius: 0,
          fontSize: 64,
          initial: user.name.isEmpty ? null : user.name,
          child: user.photos.isEmpty
              ? null
              : PageView.builder(
                  controller: controller,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: user.photos.length,
                  itemBuilder: (context, i) => _photo(user.photos[i]),
                  onPageChanged: (i) =>
                      setState(() => _currentPhotoIndex[user.id] = i),
                ),
        ),

        // Тап-зони для гортання фото.
        if (user.photos.length > 1)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _stepPhoto(user, controller, -1),
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _stepPhoto(user, controller, 1),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),

        if (user.distanceKm != null)
          Positioned(
            top: 14,
            left: 14,
            child: DsPill(
              icon: Icons.place_outlined,
              label: t.dist_km_short(_formatKm(user.distanceKm!)),
            ),
          ),

        // Смужки замість крапок — видно, скільки фото лишилось.
        if (user.photos.length > 1)
          Positioned(
            top: 14,
            right: 14,
            child: Row(
              children: [
                for (var i = 0; i < user.photos.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Container(
                    width: 26,
                    height: 3,
                    decoration: BoxDecoration(
                      color: i == photoIndex ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// Нижня половина: ім'я, збіг, опис, інтереси.
  ///
  /// Раніше цей текст лежав просто на фото під темним градієнтом і брав колір
  /// із теми — на світлій темі виходив майже чорний текст на майже чорному
  /// тлі. Тепер він на власній поверхні, тож читається завжди.
  Widget _cardInfo(UserProfile user, AppLocalizations t, ColorScheme scheme) {
    final mine = context.read<AppStateProvider>().currentUserProfile?.hobbies ??
        const <String>[];

    return Container(
      width: double.infinity,
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${user.name}, ${user.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Ds.h2(context),
                ),
              ),
              const SizedBox(width: 10),
              if (user.likesMe)
                DsChip(
                    label: t.likes_you,
                    small: true,
                    selected: true,
                    icon: Icons.favorite_rounded)
              else if (user.affinity != null && user.affinity! > 0)
                DsChip(
                  label: t.match_percent((user.affinity! * 100).round()),
                  small: true,
                  selected: true,
                  onTap: () => _openProfile(user),
                ),
            ],
          ),
          if (user.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              user.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Ds.sub(context).copyWith(color: scheme.onSurface),
            ),
          ],
          if (user.hobbies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Спільні інтереси підсвічені — саме вони пояснюють, чому ця
                // картка тут.
                for (final hobby in user.hobbies.take(4))
                  DsChip(
                    label: InterestLabels.of(context, hobby),
                    small: true,
                    selected: mine.contains(hobby),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _stepPhoto(UserProfile user, PageController controller, int delta) {
    final next = (_currentPhotoIndex[user.id] ?? 0) + delta;
    if (next < 0 || next >= user.photos.length) return;
    controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    setState(() => _currentPhotoIndex[user.id] = next);
  }

  Widget _photo(String photo) {
    if (photo.startsWith('http')) {
      // На вебі — звичайний Image.network: він вантажить фото через власний
      // механізм браузера, який уміє віддати зображення в CanvasKit без
      // проміжного декодування байтів. cached_network_image на вебі йде
      // іншим шляхом і саме там народжується EncodingError.
      // На телефоні кеш навпаки цінний — там лишається він.
      if (kIsWeb) {
        return Image.network(
          photo,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : const SizedBox.shrink(),
        );
      }

      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Плавна поява робить картку напівпрозорою на пів секунди, і крізь неї
        // видно наступну — тому вимкнена.
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) => const SizedBox.shrink(),
      );
    }
    return Image(
      image: _getSingleImageProvider(photo),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          const DsPhotoBlock(radius: 0),
    );
  }

  /// «0,9 км» — з комою, як заведено в українській, і без зайвого нуля.
  String _formatKm(double km) {
    final s = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return s.replaceAll('.', ',');
  }

  void _openProfile(UserProfile user) {
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
  }

  // --- ХЕЛПЕР (Для старих ImageProvider) ---
  ImageProvider _getSingleImageProvider(String? path) {
    if (path == null || path.isEmpty)
      return const NetworkImage(
          'https://ui-avatars.com/api/?name=User&format=png&background=random');
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.contains('placeholder'))
      return const NetworkImage(
          'https://ui-avatars.com/api/?name=User&format=png&background=random');
    return AssetImage(path);
  }

  Widget _buildBottomActions() {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionButton(
            icon: Icons.close_rounded,
            size: 60,
            background: scheme.surface,
            foreground: scheme.onSurfaceVariant,
            onTap: () => _cardSwiperController.swipe(CardSwiperDirection.left),
          ),
          const SizedBox(width: 26),
          _actionButton(
            icon: Icons.favorite_rounded,
            size: 68,
            background: scheme.primary,
            foreground: scheme.onPrimary,
            onTap: () => _cardSwiperController.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required double size,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: Ds.shadow(context),
        ),
        child: Icon(icon, size: 22, color: foreground),
      ),
    );
  }
}

/// Кнопка карти в шапці стрічки — `.iconbtn` із заливкою `--pri`.
class _MapButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MapButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(Ds.rTile),
      child: InkWell(
        borderRadius: BorderRadius.circular(Ds.rTile),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.map_outlined, size: 20, color: scheme.onPrimary),
        ),
      ),
    );
  }
}

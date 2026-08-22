import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
import '../l10n/interest_labels.dart';
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
      _isFinished =
          false; // 🟢 СКИДАЄМО СТАН AppLocalizations.of(context)!.ended_badge
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

  ImageProvider _getSingleImageProvider(String? path) {
    if (path == null || path.isEmpty) {
      return const NetworkImage(
          'https://ui-avatars.com/api/?name=Event&format=png&background=random');
    }
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    if (path.contains('placeholder')) {
      return const NetworkImage(
          'https://ui-avatars.com/api/?name=Event&format=png&background=random');
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
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: Ds.background(context),
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
                  if (!_isLoading &&
                      events.isNotEmpty &&
                      MediaQuery.of(context).viewInsets.bottom == 0)
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

  Widget _buildTopBar() {
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Column(
        children: [
          DsSearchField(hint: t.search_events),
          const SizedBox(height: 12),
          DsSegmented(
            items: [t.for_you, t.events],
            index: 1,
            // Стрічка людей лежить під цим екраном у стеку — повертаємось на
            // неї, а не відкриваємо другу копію.
            onChanged: (i) {
              if (i == 0) Navigator.of(context).pop();
            },
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
      cardBuilder: (context, index, horizontalThresholdPercentage,
          verticalThresholdPercentage) {
        return _buildEventCard(events[index]);
      },
      duration: const Duration(milliseconds: 300),
      threshold: 80,
      allowedSwipeDirection: const AllowedSwipeDirection.only(
          left: true, right: true, up: false, down: false),
    );
  }

  Widget _buildNoMoreEventsState() {
    final t = AppLocalizations.of(context)!;

    return DsEmptyState(
      icon: Icons.event_available_outlined,
      title: t.events_finished_title,
      body: t.events_finished_body,
      actionLabel: t.refresh,
      onAction: _loadEvents,
    );
  }

  Widget _buildEventCard(Event event) {
    // Ініціалізація контролера, якщо ще немає
    if (!_photoControllers.containsKey(event.id)) {
      _photoControllers[event.id] = PageController();
      _currentPhotoIndex[event.id] = 0;
    }

    final pageController = _photoControllers[event.id]!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Ds.rCard),
        boxShadow: Ds.shadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Ds.rCard),
        child: Column(
          children: [
            Expanded(child: _eventPhoto(event, pageController)),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => EventDetailScreen(event: event)),
              ),
              child: _eventInfo(event, scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventPhoto(Event event, PageController pageController) {
    final t = AppLocalizations.of(context)!;
    final current = _currentPhotoIndex[event.id] ?? 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        DsPhotoBlock(radius: 0, fontSize: 40, initial: event.title),
        if (event.photos.isNotEmpty)
          PageView.builder(
            controller: pageController,
            // Свайп самого PageView вимкнено, щоб не конфліктував з карткою.
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) =>
                setState(() => _currentPhotoIndex[event.id] = index),
            itemCount: event.photos.length,
            itemBuilder: (context, i) => Image(
              image: _getSingleImageProvider(event.photos[i]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        if (event.photos.length > 1)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        Positioned(
          top: 12,
          left: 12,
          child:
              DsPill(icon: Icons.schedule_rounded, label: _whenLabel(event, t)),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            children: [
              if (event.distanceKm != null)
                DsPill(label: t.dist_km_short(_formatKm(event.distanceKm!))),
              if (event.photos.length > 1) ...[
                const SizedBox(width: 8),
                for (var i = 0; i < event.photos.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Container(
                    width: 26,
                    height: 3,
                    decoration: BoxDecoration(
                      color: i == current ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _eventInfo(Event event, ColorScheme scheme) {
    final t = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Ds.h2(context).copyWith(fontSize: 17),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.place_outlined,
                  size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Ds.tiny(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(t.participants_count(event.participantsCount),
                  style: Ds.tiny(context)),
              const Spacer(),
              if (event.tags.isNotEmpty)
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    children: [
                      for (final tag in event.tags.take(2))
                        DsChip(
                            label: InterestLabels.of(context, tag),
                            small: true),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// «сьогодні, 18:30» — дата в макеті подана як людський орієнтир, а не
  /// як повний штамп часу.
  String _whenLabel(Event event, AppLocalizations t) {
    final now = DateTime.now();
    final d = event.dateTime;
    final time = '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    final days = DateTime(d.year, d.month, d.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    return switch (days) {
      0 => '${t.today.toLowerCase()}, $time',
      1 => '${t.tomorrow.toLowerCase()}, $time',
      _ => '${d.day}.${d.month.toString().padLeft(2, '0')}, $time',
    };
  }

  String _formatKm(double km) {
    final s = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return s.replaceAll('.', ',');
  }

  // 🟢 ГОЛОВНА ЛОГІКА СВАЙПІВ
  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex >= events.length) return false;

    final swipedEvent = events[previousIndex];

    if (direction == CardSwiperDirection.right) {
      debugPrint('Лайк події: ${swipedEvent.title}');

      // 🟢 Передаємо повідомлення (якщо воно є)
      _matchesService.recordEventSwipe(swipedEvent.id, true,
          message: _pendingMessage);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pendingMessage != null
              ? AppLocalizations.of(context)!.request_sent_msg
              : AppLocalizations.of(context)!.request_sent),
          backgroundColor: Theme.of(context).extension<AppSemantics>()!.success,
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
            onTap: () => controller.swipe(CardSwiperDirection.left),
          ),
          const SizedBox(width: 20),
          // Приєднатись із повідомленням — окрема дія, бо заявка з текстом
          // приймається помітно частіше за мовчазну.
          _actionButton(
            icon: Icons.chat_bubble_outline_rounded,
            size: 52,
            background: scheme.surface,
            foreground: scheme.onSurfaceVariant,
            onTap: _showMessageDialog,
          ),
          const SizedBox(width: 20),
          _actionButton(
            icon: Icons.favorite_rounded,
            size: 68,
            background: scheme.primary,
            foreground: scheme.onPrimary,
            onTap: () => controller.swipe(CardSwiperDirection.right),
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

  Widget _buildBottomNavigationBar() {
    final t = AppLocalizations.of(context)!;

    return DsNavBar(
      index: 0,
      onChanged: (i) => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => MainNavigationScreen(initialIndex: i)),
      ),
      items: [
        DsNavItem(icon: Icons.style_outlined, label: t.nav_feed),
        DsNavItem(icon: Icons.mail_outline_rounded, label: t.nav_chats),
        DsNavItem(icon: Icons.favorite_border_rounded, label: t.nav_matches),
        DsNavItem(icon: Icons.person_outline_rounded, label: t.nav_profile),
      ],
    );
  }
}

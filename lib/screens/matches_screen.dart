import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
import '../l10n/interest_labels.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';

// Імпорти моделей та сервісів
import '../models/user_profile.dart';
import '../models/event.dart';
import '../providers/app_state_provider.dart'; // ВАЖЛИВО: Імпорт провайдера

// Імпорти екранів
import 'event_requests_screen.dart';
import 'user_profile_view_screen.dart';
import 'create_event_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0; // 0 - Запити, 1 - Мої події, 2 - Запрошення
  int _invitationsFilter = 0; // 0 - Очікувані, 1 - Прийняті

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });

    // 🔥 ВАЖЛИВО: Завантажуємо дані через провайдер при старті
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🟢 Хелпер для картинок (Network vs Asset)
  ImageProvider _getImageProvider(List<String>? photos) {
    if (photos == null || photos.isEmpty) {
      return const NetworkImage(
          'https://ui-avatars.com/api/?name=User&format=png&background=random');
    }

    final String path = photos.first;

    if (path.startsWith('http')) {
      return NetworkImage(path);
    }

    // Для демо-даних (assets/...)
    if (path.contains('placeholder')) {
      return const NetworkImage(
          'https://ui-avatars.com/api/?name=User&format=png&background=random');
    }

    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // 🔥 Використовуємо дані з провайдера
    final appState = context.watch<AppStateProvider>();

    // Якщо йде завантаження І немає даних - показуємо спіннер
    if (appState.isLoading &&
        appState.incomingRequests.isEmpty &&
        appState.myEvents.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: Ds.background(context),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: Ds.background(context),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(t),
              _buildTabBar(t),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Вкладка 1: Лайки (беремо з провайдера)
                    _buildLikedMeTab(appState.incomingRequests, t),

                    // Вкладка 2: Мої події (беремо з провайдера)
                    _buildMyEventsTab(appState.myEvents, t),

                    // Вкладка 3: Запрошення (беремо з провайдера)
                    _buildEventInvitationsTab(appState.myEventApplications, t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations t) {
    String title = t.requests;
    if (_selectedTab == 1) title = t.my_events;
    if (_selectedTab == 2) title = t.event_invitations;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Ds.h1(context).copyWith(fontSize: 24)),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DsSegmented(
        items: [t.requests, t.my_events, t.seg_invites],
        index: _selectedTab,
        onChanged: (i) => _tabController.animateTo(i),
      ),
    );
  }

  // --- Вкладка 1: Вхідні лайки (Requests) ---

  Widget _buildLikedMeTab(
      List<Map<String, dynamic>> requests, AppLocalizations t) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<AppStateProvider>().loadAllData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            _buildEmptyState(
              icon: Icons.favorite_border,
              title: t.no_new_requests,
              subtitle: t.no_new_requests_subtitle,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<AppStateProvider>().refreshIncomingRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final item = requests[index];
          return _buildUserCardWithMessage(
            item['user'] as UserProfile,
            item['message'] as String?,
            item['hasMessage'] as bool,
            item['like_id'] as String?,
            t,
          );
        },
      ),
    );
  }

  /// Картка запиту за `design/Requests.dc.html`: рядок з аватаром і
  /// інтересами, повідомлення на тихій підкладці, дві кнопки по 44.
  Widget _buildUserCardWithMessage(
    UserProfile user,
    String? message,
    bool hasMessage,
    String? likeId,
    AppLocalizations t,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final interests = user.hobbies
        .take(2)
        .map((h) => InterestLabels.of(context, h))
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserProfileViewScreen(user: user),
                ),
              ),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  DsAvatar(
                    initial: user.name,
                    photoUrl: user.photos.isEmpty ? null : user.photos.first,
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.age > 0
                              ? '${user.name}, ${user.age}'
                              : user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        if (interests.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            interests,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Ds.tiny(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (user.distanceKm != null) ...[
                    const SizedBox(width: 8),
                    DsChip(
                      label: t.dist_km_short(user.distanceKm!
                          .toStringAsFixed(1)
                          .replaceAll('.', ',')),
                      small: true,
                      icon: Icons.place_outlined,
                    ),
                  ],
                ],
              ),
            ),
            if (hasMessage && message != null && message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: Ds.tiny(context)
                      .copyWith(color: scheme.onSecondaryContainer),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallButton(
                    label: t.reject,
                    ghost: true,
                    onTap: () => _handleReject(likeId, t),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallButton(
                    label: t.like_user,
                    onTap: () => _handleLike(user, likeId, t),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Кнопка на 44 — у картках вона нижча за екранну (52), як у макеті.
  Widget _smallButton({
    required String label,
    required VoidCallback onTap,
    bool ghost = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: ghost ? Colors.transparent : scheme.primary,
      borderRadius: BorderRadius.circular(Ds.rField),
      child: InkWell(
        borderRadius: BorderRadius.circular(Ds.rField),
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Ds.rField),
            border: ghost
                ? Border.all(color: scheme.outlineVariant, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: ghost ? scheme.primary : scheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // --- Вкладка 2: Мої події (My Events) ---

  Widget _buildMyEventsTab(List<Event> events, AppLocalizations t) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: DsButton(
            label: t.create_event,
            icon: Icons.add_rounded,
            onPressed: _navigateToCreateEvent,
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? _buildEmptyState(
                  icon: Icons.event,
                  title: t.no_created_events,
                  subtitle: t.no_created_events_subtitle)
              : RefreshIndicator(
                  onRefresh: () =>
                      context.read<AppStateProvider>().refreshMyEvents(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: events.length,
                    itemBuilder: (context, index) =>
                        _buildEventCard(events[index], t),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event, AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Ds.rCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DsPhotoBlock(
                      radius: 0,
                      fontSize: 40,
                      initial: event.title,
                      child: event.photos.isEmpty
                          ? null
                          : Image(
                              image: _getImageProvider(event.photos),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: DsPill(
                        icon: Icons.schedule_rounded,
                        label:
                            '${event.dateTime.day}.${event.dateTime.month.toString().padLeft(2, '0')}.${event.dateTime.year}',
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: DsPill(
                        icon: Icons.people_outline_rounded,
                        label: '${event.participantsCount}',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
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
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Ds.sub(context),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _smallButton(
                      label: t.view_requests,
                      onTap: () => _handleViewRequests(event),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Вкладка 3: Запрошення (Invitations) ---

  Widget _buildEventInvitationsTab(
      List<Map<String, dynamic>> invitations, AppLocalizations t) {
    // Фільтруємо на клієнті (оскільки дані вже завантажені в провайдер)
    final filteredList = invitations.where((item) {
      final isAccepted =
          item['status'] == 'accepted'; // Перевір поле статусу в моделі
      return _invitationsFilter == 1 ? isAccepted : !isAccepted;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: DsSegmented(
            items: [
              AppLocalizations.of(context)!.m_pending,
              AppLocalizations.of(context)!.m_accepted,
            ],
            index: _invitationsFilter,
            onChanged: (i) => setState(() => _invitationsFilter = i),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<AppStateProvider>().loadAllData(),
            child: filteredList.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
                      _buildEmptyState(
                        icon: _invitationsFilter == 0
                            ? Icons.schedule
                            : Icons.check_circle,
                        title: _invitationsFilter == 0
                            ? AppLocalizations.of(context)!.m_no_pending
                            : AppLocalizations.of(context)!.m_no_accepted,
                        subtitle: AppLocalizations.of(context)!.m_requests_here,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) => _buildInvitationCard(
                      filteredList[index],
                      t,
                      isAccepted: _invitationsFilter == 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Рядок заявки за `design/MyEvents.dc.html`: фото 52 зі скругленням 13,
  /// назва й дата, статус — плашкою праворуч.
  ///
  /// Раніше статус малювався зеленим текстом на зеленій заливці й був
  /// нечитабельним; плашка бере кольори з `AppSemantics`, де пара
  /// success/onSuccess підібрана під обидві теми.
  Widget _buildInvitationCard(
    Map<String, dynamic> invitation,
    AppLocalizations t, {
    bool isAccepted = false,
  }) {
    final event = invitation['event'] as Event;
    final semantics = Theme.of(context).extension<AppSemantics>()!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DsCard(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        onTap: null,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: 52,
                height: 52,
                child: DsPhotoBlock(
                  radius: 0,
                  fontSize: 19,
                  initial: event.title,
                  child: event.photos.isEmpty
                      ? null
                      : Image(
                          image: _getImageProvider(event.photos),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${event.dateTime.day}.${event.dateTime.month.toString().padLeft(2, '0')} · '
                    '${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                    style: Ds.tiny(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? semantics.success
                        : scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isAccepted ? t.m_accepted_chip : t.m_pending_chip,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAccepted
                          ? semantics.onSuccess
                          : scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                if (isAccepted) ...[
                  const SizedBox(height: 4),
                  Text(t.m_chat_open,
                      style: Ds.tiny(context).copyWith(fontSize: 10.5)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Загальні віджети ---

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return DsEmptyState(icon: icon, title: title, body: subtitle);
  }

  // --- Дії та навігація ---

  // 🔥 МЕТОД ДЛЯ КНОПКИ "ПРИЙНЯТИ"
  Future<void> _handleLike(
      UserProfile user, String? likeId, AppLocalizations t) async {
    if (likeId == null) return;

    try {
      // Використовуємо ПРОВАЙДЕР для прийняття лайка
      await context.read<AppStateProvider>().acceptLike(likeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.match_chat_created(user.name)),
            backgroundColor:
                Theme.of(context).extension<AppSemantics>()!.success,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.ok,
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Помилка при прийнятті: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.chat_create_failed),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    }
  }

  // 🔥 МЕТОД ДЛЯ КНОПКИ "ВІДХИЛИТИ"
  Future<void> _handleReject(String? likeId, AppLocalizations t) async {
    if (likeId == null) return;
    try {
      await context.read<AppStateProvider>().rejectLike(likeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.user_rejected), backgroundColor: Colors.grey));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
          backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  void _navigateToCreateEvent() async {
    final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CreateEventScreen()));
    if (result != null) {
      if (mounted) context.read<AppStateProvider>().loadAllData();
    }
  }

  void _handleViewRequests(Event event) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EventRequestsScreen(event: event)));
  }
}

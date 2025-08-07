import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user_profile.dart';
import '../models/event.dart';
import 'event_requests_screen.dart';
import 'user_profile_view_screen.dart';
import 'create_event_screen.dart';
import 'accepted_event_detail_screen.dart';

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

  // Запити із можливим повідомленням
  final List<Map<String, dynamic>> _likedMeWithMessages = [
    {
      'user': UserProfile(
        id: '3',
        name: 'Олена',
        age: 23,
        description: 'Люблю кав\'ярні та нові знайомства',
        photos: ['assets/images/uifaces-popular-image.jpg'],
        location: 'Харків',
        hobbies: ['Кава', 'Книги', 'Подорожі'],
      ),
      'message': 'Привіт! Дуже подобається твій профіль. Можливо, зустрінемось на каву? ☕',
      'hasMessage': true,
    },
    {
      'user': UserProfile(
        id: '4',
        name: 'Ірина',
        age: 27,
        description: 'Шукаю компанію для концертів',
        photos: ['assets/images/uifaces-popular-image-2.jpg'],
        location: 'Одеса',
        hobbies: ['Музика', 'Концерти', 'Танці'],
      ),
      'message': null,
      'hasMessage': false,
    },
  ];

  // Мої події (мок)
  final List<Event> _myEvents = [
    Event(
      id: '1',
      title: 'Похід у Карпати',
      location: 'Говерла',
      dateTime: DateTime.now().add(const Duration(days: 7)),
      photos: ['assets/images/pexels-rpnickson-2609463.jpg'],
      tags: ['Походи', 'Гори', 'Природа'],
      description: 'Відвідуємо найвищу точку України',
      participantsCount: 8,
    ),
    Event(
      id: '2',
      title: 'Вечірка в кав\'ярні',
      location: 'Київ, центр',
      dateTime: DateTime.now().add(const Duration(days: 3)),
      photos: ['assets/images/pexels-rdne-4920848.jpg'],
      tags: ['Кава', 'Спілкування', 'Вечірка'],
      description: 'Зустріч для знайомств за кавою',
      participantsCount: 12,
    ),
  ];

  // Запрошення на події (мок)
  final List<Map<String, dynamic>> _eventInvitations = [
    {
      'event': Event(
        id: '3',
        title: 'Вечірка в клубі',
        location: 'Клуб "Парадокс"',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        photos: ['assets/images/club1.jpg'],
        tags: ['Музика', 'Танці', 'Вечірка'],
        description: 'Велика вечірка з найкращою музикою та атмосферою.',
        participantsCount: 45,
      ),
      'inviter': UserProfile(
        id: '6',
        name: 'Роман',
        age: 19,
        description: 'Люблю пригоди та нові знайомства',
        photos: ['assets/images/portrait-man-laughing.jpg'],
        location: 'Луцьк',
        hobbies: ['Геймінг', 'Музика', 'Походи'],
      ),
      'message': 'Привіт! Запрошую на вечірку. Буде весело!',
    },
  ];

  // Прийняті запрошення (мок)
  final List<Map<String, dynamic>> _acceptedInvitations = [
    {
      'event': Event(
        id: '6',
        title: 'Караоке вечір',
        location: 'Караоке клуб "Зірка"',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        photos: ['assets/images/club2.jpeg'],
        tags: ['Музика', 'Караоке', 'Вечірка'],
        description: 'Вечір караоке з друзями. Співаємо найкращі хіти!',
        participantsCount: 8,
        isPrivate: false, // Публічна подія
      ),
      'inviter': UserProfile(
        id: '9',
        name: 'Олена',
        age: 23,
        description: 'Люблю музику та спілкування',
        photos: ['assets/images/uifaces-popular-image-3.jpg'],
        location: 'Київ',
        hobbies: ['Музика', 'Спів', 'Вечірки'],
      ),
      'message': 'Зустрінемось на караоке!',
      'acceptedAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'event': Event(
        id: '7',
        title: 'Приватна вечірка в пентхаусі',
        location: 'Район Печерськ',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        photos: ['assets/images/club3.jpg'],
        tags: ['Вечірка', 'VIP', 'Музика', 'Танці'],
        description: 'Ексклюзивна приватна вечірка в пентхаусі з панорамним видом на місто. Дрес-код: smart casual. Буде DJ, бар та фуршет.',
        participantsCount: 15,
        isPrivate: true, // Приватна подія
        privateLocation: 'вул. Липська, 15А, 25-й поверх, пентхаус',
        meetingPoint: 'Біля головного входу в ЖК "Мetropolitan", консьєрж проведе до ліфта',
        additionalInfo: 'Код домофону: 2580. Дрес-код: smart casual (джинси не підходять). Принесіть документи для пропуску. Алкоголь та закуски на місці. Паркування безкоштовне в підземному гаражі.',
      ),
      'inviter': UserProfile(
        id: '10',
        name: 'Дмитро',
        age: 29,
        description: 'Підприємець, люблю вечірки та нові знайомства',
        photos: ['assets/images/pleased-smiling-man-with-beard-looking-camera.jpg'],
        location: 'Київ',
        hobbies: ['Бізнес', 'Вечірки', 'Подорожі'],
      ),
      'message': 'Привіт! Запрошую на ексклюзивну вечірку в моєму пентхаусі. Буде неймовірна атмосфера, гарна музика та цікаві люди. Приходь, точно сподобається! 🍾✨',
      'acceptedAt': DateTime.now().subtract(const Duration(hours: 6)),
    },
  ];

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
        return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      body: SafeArea(
          child: Column(
            children: [
            _buildTopBar(t),
            _buildTabBar(t),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                  _buildLikedMeTab(t),
                  _buildMyEventsTab(t),
                  _buildEventInvitationsTab(t),
                  ],
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        t.requests,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _TabChip(
              isActive: _selectedTab == 0,
              label: t.requests,
              onTap: () => _tabController.animateTo(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TabChip(
              isActive: _selectedTab == 1,
              label: t.my_events,
              onTap: () => _tabController.animateTo(1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TabChip(
              isActive: _selectedTab == 2,
              label: t.event_invitations,
              onTap: () => _tabController.animateTo(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikedMeTab(AppLocalizations t) {
    if (_likedMeWithMessages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: t.no_new_requests,
        subtitle: t.no_new_requests_subtitle,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _likedMeWithMessages.length,
      itemBuilder: (context, index) {
        final item = _likedMeWithMessages[index];
        return _buildUserCardWithMessage(
          item['user'] as UserProfile,
          item['message'] as String?,
          item['hasMessage'] as bool,
          t,
        );
      },
    );
  }

  Widget _buildUserCardWithMessage(
    UserProfile user,
    String? message,
    bool hasMessage,
    AppLocalizations t,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото та загальна інформація
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: AssetImage(user.photos.first),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showUserMenu(context, user, t),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Row(
                          children: [
                            Text(
                              '${user.name}, ${user.age}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                        const Icon(Icons.location_on, size: 16, color: Colors.white70),
                            Text(
                              user.location,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
          
          // Хобі
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.common_interests,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: user.hobbies.take(3).map((hobby) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E6FE9).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E5BE9).withOpacity(0.3)),
                      ),
                      child: Text(
                        hobby,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E65E9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Повідомлення
          if (hasMessage && message != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4C78AF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4C78AF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.message, size: 16, color: Color(0xFF4C78AF)),
                      const SizedBox(width: 6),
                      Text(
                        t.message,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4C78AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Дії
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.close,
                    label: t.reject,
                    color: const Color(0xFF7E7E7E),
                    onTap: () => _handleReject(user, t),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    icon: Icons.favorite,
                    label: t.like_user,
                    color: const Color(0xFFF05473),
                    onTap: () => _handleLike(user, t),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.event,
                    label: t.invite_to_event,
                    color: Colors.purple,
                    onTap: () => _showEventInvitationDialog(user, t),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyEventsTab(AppLocalizations t) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(20),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToCreateEvent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              t.create_event,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        Expanded(
          child: _myEvents.isEmpty
              ? _buildEmptyState(
                  icon: Icons.event,
                  title: t.no_created_events,
                  subtitle: t.no_created_events_subtitle,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _myEvents.length,
                  itemBuilder: (context, index) => _buildEventCard(_myEvents[index], t),
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event, AppLocalizations t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(image: AssetImage(event.photos.first), fit: BoxFit.cover),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showEventInfoDialog(event, t),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                  padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        event.title,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.white70),
                            Text(event.location, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 16),
                            const Icon(Icons.people, size: 16, color: Colors.white70),
                            Text('${event.participantsCount}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${event.dateTime.day}.${event.dateTime.month}.${event.dateTime.year}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: event.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E6FE9).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E5BE9).withOpacity(0.3)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E65E9), fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
                              child: ElevatedButton(
                  onPressed: () => _handleViewRequests(event),
                  style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C78AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(t.view_requests, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInvitationsTab(AppLocalizations t) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _TabChip(
                  isActive: _invitationsFilter == 0,
                  label: 'Очікувані',
                  onTap: () => setState(() => _invitationsFilter = 0),
                  activeColor: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TabChip(
                  isActive: _invitationsFilter == 1,
                  label: 'Прийняті',
                  onTap: () => setState(() => _invitationsFilter = 1),
                  activeColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
        Expanded(
          child: _invitationsFilter == 0 
              ? _buildPendingInvitationsList(t)
              : _buildAcceptedInvitationsList(t),
        ),
      ],
    );
  }

  Widget _buildPendingInvitationsList(AppLocalizations t) {
    if (_eventInvitations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'Немає очікуваних запрошень',
        subtitle: 'Коли ви отримаєте запрошення на подію, воно з\'явиться тут',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _eventInvitations.length,
      itemBuilder: (context, index) => _buildInvitationCard(
        _eventInvitations[index],
        t,
        isAccepted: false,
      ),
    );
  }

  Widget _buildAcceptedInvitationsList(AppLocalizations t) {
    if (_acceptedInvitations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'Немає прийнятих запрошень',
        subtitle: 'Прийняті запрошення на події з\'являться тут',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _acceptedInvitations.length,
      itemBuilder: (context, index) => _buildInvitationCard(
        _acceptedInvitations[index],
        t,
        isAccepted: true,
      ),
    );
  }

  Widget _buildInvitationCard(
    Map<String, dynamic> invitation,
    AppLocalizations t, {
    bool isAccepted = false,
  }) {
    final event = invitation['event'] as Event;
    final inviter = invitation['inviter'] as UserProfile;
    final message = invitation['message'] as String? ?? '';
    final acceptedAt = invitation['acceptedAt'] as DateTime?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(image: AssetImage(event.photos.first), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(event.location, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundImage: AssetImage(inviter.photos.first)),
              const SizedBox(width: 8),
              Text('${inviter.name} запрошує', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          if (message.isNotEmpty) ...[
          const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
            ),
          ],
          const SizedBox(height: 12),
          if (isAccepted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Запрошення прийнято', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                        if (acceptedAt != null)
                          Text('Прийнято ${_formatDate(acceptedAt)}', style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showAcceptedEventDetails(invitation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Деталі'),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAcceptInvitation(invitation, t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    child: Text(t.accept_invitation),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDeclineInvitation(invitation, t),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    child: Text(t.decline_invitation),
                    ),
                  ),
              ],
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, size: 48, color: const Color(0xFFE91E63)),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // Actions and helpers
  void _handleLike(UserProfile user, AppLocalizations t) {
    setState(() {
      _likedMeWithMessages.removeWhere((item) => item['user'].id == user.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.like_sent), backgroundColor: const Color(0xFF4CAF50)),
    );
  }

  void _handleReject(UserProfile user, AppLocalizations t) {
    setState(() {
      _likedMeWithMessages.removeWhere((item) => item['user'].id == user.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.user_rejected), backgroundColor: Colors.red),
    );
  }

  void _showUserMenu(BuildContext context, UserProfile user, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF4C78AF)),
                title: Text(t.view_profile),
                onTap: () {
                  Navigator.pop(context);
                  _handleViewProfile(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text(t.block_user, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _likedMeWithMessages.removeWhere((item) => item['user'].id == user.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user.name} заблоковано'), backgroundColor: Colors.red),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleViewProfile(UserProfile user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => UserProfileViewScreen(user: user)),
    );
  }

  void _showEventInvitationDialog(UserProfile user, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.send_event_invitation),
          content: Column(
            mainAxisSize: MainAxisSize.min,
                        children: [
              Text('Виберіть подію для запрошення ${user.name}:'),
              const SizedBox(height: 16),
              ..._myEvents.map((event) => ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(image: AssetImage(event.photos.first), fit: BoxFit.cover),
                      ),
                    ),
                    title: Text(event.title),
                    subtitle: Text(event.location),
                    onTap: () {
                      Navigator.of(context).pop();
                      _sendEventInvitation(user, event);
                    },
                  )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
          ],
        );
      },
    );
  }

  void _sendEventInvitation(UserProfile user, Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Запрошення на "${event.title}" надіслано користувачу ${user.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToCreateEvent() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    );
    
    if (result != null && result is Event) {
      setState(() {
        _myEvents.add(result);
      });
    }
  }

  void _handleViewRequests(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EventRequestsScreen(event: event)),
    );
  }

  void _showEventInfoDialog(Event event, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event.title),
          content: Text(event.description),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.ok)),
          ],
        );
      },
    );
  }

  void _handleAcceptInvitation(Map<String, dynamic> invitation, AppLocalizations t) {
    setState(() {
      _eventInvitations.remove(invitation);
      _acceptedInvitations.add({...invitation, 'acceptedAt': DateTime.now()});
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.invitation_accepted), backgroundColor: Colors.green),
    );
  }

  void _handleDeclineInvitation(Map<String, dynamic> invitation, AppLocalizations t) {
    setState(() {
      _eventInvitations.remove(invitation);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.invitation_declined), backgroundColor: Colors.red),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'сьогодні';
    if (diff == 1) return 'вчора';
    if (diff < 7) return '$diff днів тому';
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showAcceptedEventDetails(Map<String, dynamic> invitation) {
    final event = invitation['event'] as Event;
    final inviter = invitation['inviter'] as UserProfile;
    final message = invitation['message'] as String?;
    final acceptedAt = invitation['acceptedAt'] as DateTime;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AcceptedEventDetailScreen(
          event: event,
          organizer: inviter,
          acceptedAt: acceptedAt,
          invitationMessage: message,
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final bool isActive;
  final String label;
  final VoidCallback onTap;
  final Color? activeColor;

  const _TabChip({
    Key? key,
    required this.isActive,
    required this.label,
    required this.onTap,
    this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = activeColor ?? Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
                                   decoration: BoxDecoration(
          color: isActive ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isActive ? selectedColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
                                               style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
                                                 fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
          color: color,
                            borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
                          ),
                          child: Column(
                            children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
                                  Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

 

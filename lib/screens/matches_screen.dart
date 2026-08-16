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
import 'accepted_event_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
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
      return const NetworkImage('https://ui-avatars.com/api/?name=User&background=random');
    }
    
    final String path = photos.first;
    
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    
    // Для демо-даних (assets/...)
    if (path.contains('placeholder')) {
       return const NetworkImage('https://ui-avatars.com/api/?name=User&background=random');
    }

    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // 🔥 Використовуємо дані з провайдера
    final appState = context.watch<AppStateProvider>();

    // Якщо йде завантаження І немає даних - показуємо спіннер
    if (appState.isLoading && appState.incomingRequests.isEmpty && appState.myEvents.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3E5F5),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
    );
  }

  Widget _buildTopBar(AppLocalizations t) {
    String title = t.requests;
    if (_selectedTab == 1) title = t.my_events;
    if (_selectedTab == 2) title = t.event_invitations;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
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

  // --- Вкладка 1: Вхідні лайки (Requests) ---

  Widget _buildLikedMeTab(List<Map<String, dynamic>> requests, AppLocalizations t) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<AppStateProvider>().loadAllData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
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
      onRefresh: () => context.read<AppStateProvider>().refreshIncomingRequests(),
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

  Widget _buildUserCardWithMessage(
    UserProfile user,
    String? message,
    bool hasMessage,
    String? likeId,
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
          // Фото
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: _getImageProvider(user.photos),
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
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('${user.name}, ${user.age}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on, size: 16, color: Colors.white70),
                        Text(user.location, style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
            child: Wrap(
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
                  child: Text(hobby, style: const TextStyle(fontSize: 12, color: Color(0xFF1E65E9), fontWeight: FontWeight.w600)),
                );
              }).toList(),
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
                      Text(t.message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4C78AF))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Кнопки дій
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Кнопка ВІДХИЛИТИ
                Expanded(
                  child: _ActionButton(
                    icon: Icons.close, 
                    label: t.reject, 
                    color: const Color(0xFF7E7E7E), 
                    onTap: () => _handleReject(likeId, t)
                  )
                ),
                const SizedBox(width: 10),
                // Кнопка ПРИЙНЯТИ (Створення чату)
                Expanded(
                  flex: 2, 
                  child: _ActionButton(
                    icon: Icons.favorite, 
                    label: t.like_user, 
                    color: const Color(0xFFF05473), 
                    onTap: () => _handleLike(user, likeId, t)
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Вкладка 2: Мої події (My Events) ---

  Widget _buildMyEventsTab(List<Event> events, AppLocalizations t) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(20),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToCreateEvent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(t.create_event, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? _buildEmptyState(icon: Icons.event, title: t.no_created_events, subtitle: t.no_created_events_subtitle)
              : RefreshIndicator(
                  onRefresh: () => context.read<AppStateProvider>().refreshMyEvents(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: events.length,
                    itemBuilder: (context, index) => _buildEventCard(events[index], t),
                  ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(image: _getImageProvider(event.photos), fit: BoxFit.cover),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12, right: 12,
                  child: GestureDetector(
                    onTap: () => _showEventInfoDialog(event, t),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.info, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)])),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    Text('${event.dateTime.day}.${event.dateTime.month}.${event.dateTime.year}', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleViewRequests(event),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C78AF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(t.view_requests, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Вкладка 3: Запрошення (Invitations) ---

  Widget _buildEventInvitationsTab(List<Map<String, dynamic>> invitations, AppLocalizations t) {
    // Фільтруємо на клієнті (оскільки дані вже завантажені в провайдер)
    final filteredList = invitations.where((item) {
      final isAccepted = item['status'] == 'accepted'; // Перевір поле статусу в моделі
      return _invitationsFilter == 1 ? isAccepted : !isAccepted;
    }).toList();

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
          child: RefreshIndicator(
            onRefresh: () => context.read<AppStateProvider>().loadAllData(),
            child: filteredList.isEmpty 
              ? ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    _buildEmptyState(
                      icon: _invitationsFilter == 0 ? Icons.schedule : Icons.check_circle,
                      title: _invitationsFilter == 0 ? 'Немає очікуваних запитів' : 'Немає прийнятих запрошень',
                      subtitle: 'Ваші заявки з\'являться тут',
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

  Widget _buildInvitationCard(
    Map<String, dynamic> invitation,
    AppLocalizations t, {
    bool isAccepted = false,
  }) {
    final event = invitation['event'] as Event;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
                  image: DecorationImage(image: _getImageProvider(event.photos), fit: BoxFit.cover),
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
          
          if (isAccepted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text('Заявку схвалено!', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.green),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text('Очікує підтвердження', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Загальні віджети ---

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
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

  // --- Дії та навігація ---

  // 🔥 МЕТОД ДЛЯ КНОПКИ "ПРИЙНЯТИ"
  Future<void> _handleLike(UserProfile user, String? likeId, AppLocalizations t) async {
    if (likeId == null) return;
    
    try {
      // Використовуємо ПРОВАЙДЕР для прийняття лайка
      await context.read<AppStateProvider>().acceptLike(likeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Метч! Чат з ${user.name} створено!"), 
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ок',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Помилка при прийнятті: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Помилка створення чату"), backgroundColor: Colors.red)
        );
      }
    }
  }

  // 🔥 МЕТОД ДЛЯ КНОПКИ "ВІДХИЛИТИ"
  Future<void> _handleReject(String? likeId, AppLocalizations t) async {
    if (likeId == null) return;
    try {
      await context.read<AppStateProvider>().rejectLike(likeId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.user_rejected), backgroundColor: Colors.grey)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Помилка"), backgroundColor: Colors.red)
      );
    }
  }

  void _showUserMenu(BuildContext context, UserProfile user, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserProfileViewScreen(user: user)));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCreateEvent() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateEventScreen()));
    if (result != null) {
      if (mounted) context.read<AppStateProvider>().loadAllData();
    }
  }

  void _handleViewRequests(Event event) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventRequestsScreen(event: event)));
  }

  void _showEventInfoDialog(Event event, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Text(event.description),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.ok))],
      ),
    );
  }
}

// Допоміжні класи віджетів (UI без змін)

class _TabChip extends StatelessWidget {
  final bool isActive;
  final String label;
  final VoidCallback onTap;
  final Color? activeColor;

  const _TabChip({Key? key, required this.isActive, required this.label, required this.onTap, this.activeColor}) : super(key: key);

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
          style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 14),
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

  const _ActionButton({Key? key, required this.icon, required this.label, required this.color, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
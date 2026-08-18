import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/user_profile.dart';
import '../service/matches_service.dart'; // 👇 Імпорт сервісу
import 'package:dating_app/l10n/gen/app_localizations.dart';

class EventLikesScreen extends StatefulWidget {
  const EventLikesScreen({Key? key}) : super(key: key);

  @override
  State<EventLikesScreen> createState() => _EventLikesScreenState();
}

class _EventLikesScreenState extends State<EventLikesScreen> {
  // 🟢 Сервіс
  final _matchesService = MatchesService();
  
  bool _isLoading = true;
  
  // Список моїх подій
  List<Event> _myEvents = [];
  
  // Мапа: ID події -> Список людей, які її лайкнули
  Map<String, List<UserProfile>> _eventLikes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 🟢 Завантаження реальних даних з Supabase
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Отримуємо список лайків (структура: {eventId: [users...]})
      final likesMap = await _matchesService.getEventLikes();
      
      // 2. Отримуємо список самих подій
      final events = await _matchesService.getMyEvents();
      
      if (mounted) {
        setState(() {
          _myEvents = events;
          _eventLikes = likesMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Помилка завантаження лайків подій: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 👇 Хелпер для фото (захист від помилок 404)
  ImageProvider _getImageProvider(List<String>? photos) {
    if (photos == null || photos.isEmpty) {
      return const NetworkImage('https://ui-avatars.com/api/?name=User&background=random');
    }
    
    final String path = photos.first;
    
    // Якщо це лінк на інтернет
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    
    // Якщо це старий placeholder, який викликав помилку
    if (path.contains('placeholder')) {
       return const NetworkImage('https://ui-avatars.com/api/?name=User&background=random');
    }

    // Локальний асет
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    : _myEvents.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _myEvents.length,
                              itemBuilder: (context, index) {
                                return _buildEventCard(_myEvents[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.el_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    // Отримуємо список людей, які лайкнули ЦЮ конкретну подію
    final likes = _eventLikes[event.id] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок події (Кольорова шапка)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.likes_count(likes.length),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Список користувачів або повідомлення "Немає лайків"
          if (likes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.el_who_wants,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Генеруємо картки користувачів
                  ...likes.map((user) => _buildUserCard(user, event.id)),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 48,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.el_no_likes,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user, String eventId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Аватарка
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              image: DecorationImage(
                image: _getImageProvider(user.photos),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Інформація про користувача
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.name}, ${user.age}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.location,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Кнопки дій (Прийняти / Відхилити)
          // Поки що вони просто візуальні або видаляють зі списку локально
          Column(
            children: [
              _buildActionButton(
                icon: Icons.check,
                color: const Color(0xFF4CAF50),
                onTap: () => _handleAccept(user, eventId),
                label: AppLocalizations.of(context)!.accept,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                onTap: () => _handleReject(user, eventId),
                label: AppLocalizations.of(context)!.decline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.event,
                size: 48,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.el_no_events,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.el_create_hint,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Навігація до створення події
                await Navigator.pushNamed(context, '/create-event');
                _loadData(); // Оновити після повернення
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.create_event,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Дії (Тимчасова локальна логіка) ---
  
  void _handleAccept(UserProfile user, String eventId) {
    setState(() {
      // Видаляємо користувача зі списку "нових лайків", ніби ми його обробили
      final likes = _eventLikes[eventId] ?? [];
      likes.remove(user);
      _eventLikes[eventId] = likes;
    });
    
    // Тут можна додати логіку запису в базу (наприклад, зміна статусу на 'approved')
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.user_accepted(user.name)),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _handleReject(UserProfile user, String eventId) {
    setState(() {
      final likes = _eventLikes[eventId] ?? [];
      likes.remove(user);
      _eventLikes[eventId] = likes;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.user_declined(user.name)),
        backgroundColor: Colors.red,
      ),
    );
  }
}
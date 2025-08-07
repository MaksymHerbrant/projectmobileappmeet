import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/event.dart';
import '../models/user_profile.dart';

class EventLikesScreen extends StatefulWidget {
  const EventLikesScreen({Key? key}) : super(key: key);

  @override
  State<EventLikesScreen> createState() => _EventLikesScreenState();
}

class _EventLikesScreenState extends State<EventLikesScreen> {
  // Мокові дані для демонстрації
  final List<Event> _myEvents = [
    Event(
      id: '1',
      title: 'Риболовля на Дніпрі',
      location: 'Київ',
      dateTime: DateTime.now().add(const Duration(days: 3)),
      photos: ['https://example.com/fishing.jpg'],
      tags: ['Риболовля', 'Природа', 'Активний відпочинок'],
      description: 'Риболовля на Дніпрі з ранку до вечора',
      participantsCount: 3,
    ),
    Event(
      id: '2',
      title: 'Вечірка в кав\'ярні',
      location: 'Львів',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      photos: ['https://example.com/cafe.jpg'],
      tags: ['Кава', 'Спілкування', 'Вечірка'],
      description: 'Вечірка в стильній кав\'ярні з живою музикою',
      participantsCount: 8,
    ),
    Event(
      id: '3',
      title: 'Концерт рок-музики',
      location: 'Харків',
      dateTime: DateTime.now().add(const Duration(days: 5)),
      photos: ['https://example.com/concert.jpg'],
      tags: ['Музика', 'Концерт', 'Рок'],
      description: 'Концерт українських рок-гуртів',
      participantsCount: 15,
    ),
  ];

  final Map<String, List<UserProfile>> _eventLikes = {
    '1': [
      UserProfile(
        id: 'user1',
        name: 'Анна',
        age: 25,
        description: 'Люблю риболовлю та активний відпочинок',
        photos: ['https://example.com/photo1.jpg'],
        location: 'Київ',
        hobbies: ['Риболовля', 'Походи', 'Музика'],
      ),
      UserProfile(
        id: 'user2',
        name: 'Марія',
        age: 28,
        description: 'Шукаю компанію для походів у гори',
        photos: ['https://example.com/photo2.jpg'],
        location: 'Львів',
        hobbies: ['Походи', 'Фотографія', 'Книги'],
      ),
    ],
    '2': [
      UserProfile(
        id: 'user3',
        name: 'Олена',
        age: 23,
        description: 'Люблю кав\'ярні та нові знайомства',
        photos: ['https://example.com/photo3.jpg'],
        location: 'Харків',
        hobbies: ['Кава', 'Книги', 'Подорожі'],
      ),
    ],
    '3': [
      UserProfile(
        id: 'user4',
        name: 'Ірина',
        age: 27,
        description: 'Шукаю компанію для концертів',
        photos: ['https://example.com/photo4.jpg'],
        location: 'Одеса',
        hobbies: ['Музика', 'Концерти', 'Танці'],
      ),
    ],
  };

  final Map<String, String> _userMessages = {
    'user1': 'Дуже хочу приєднатися до риболовлі!',
    'user3': 'Чудова ідея для вечірки!',
  };

  @override
  Widget build(BuildContext context) {
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
              _buildTopBar(),
              Expanded(
                child: _myEvents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _myEvents.length,
                        itemBuilder: (context, index) {
                          return _buildEventCard(_myEvents[index]);
                        },
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
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Лайки до моїх подій',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final likes = _eventLikes[event.id] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Заголовок події
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: const LinearGradient(
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.dateTime.day}.${event.dateTime.month}.${event.dateTime.year}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${likes.length} лайків',
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

          // Список користувачів
          if (likes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Користувачі, які лайкнули:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    'Поки що немає лайків',
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
    final hasMessage = _userMessages.containsKey(user.id);
    
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
                image: NetworkImage(user.photos.first),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // Fallback до placeholder
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Інформація про користувача
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${user.name}, ${user.age}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (hasMessage) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Є повідомлення',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.location,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                ),
                if (hasMessage) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _userMessages[user.id]!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4CAF50),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Кнопки дій
          Column(
            children: [
              _buildActionButton(
                icon: Icons.check,
                color: const Color(0xFF4CAF50),
                onTap: () => _handleAccept(user, eventId),
                label: 'Прийняти',
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                onTap: () => _handleReject(user, eventId),
                label: 'Відхилити',
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
              style: const TextStyle(
                color: Colors.white,
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
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.event,
                size: 48,
                color: const Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'У вас поки що немає подій',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Створіть подію, щоб почати отримувати лайки',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Навігація до створення події
                Navigator.pushNamed(context, '/create-event');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Створити подію',
                style: TextStyle(
                  color: Colors.white,
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

  void _handleAccept(UserProfile user, String eventId) {
    // Логіка прийняття користувача
    setState(() {
      final likes = _eventLikes[eventId] ?? [];
      likes.remove(user);
      _eventLikes[eventId] = likes;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} додано до події'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _handleReject(UserProfile user, String eventId) {
    // Логіка відхилення користувача
    setState(() {
      final likes = _eventLikes[eventId] ?? [];
      likes.remove(user);
      _eventLikes[eventId] = likes;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} відхилено'),
        backgroundColor: Colors.red,
      ),
    );
  }
} 
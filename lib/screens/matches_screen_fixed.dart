import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'event_requests_screen.dart';
import 'user_profile_view_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  int _selectedTab = 0; // 0 - Запити, 1 - Мої події, 2 - Запрошення на події
  int _invitationsFilter = 0; // 0 - Очікувані, 1 - Прийняті

  // Розширена модель для запитів з повідомленнями
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
      'message': 'Привіт! Дуже подобається твій профіль. Можливо, зможемо зустрітися за кавою? ☕',
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

  // Мокові дані для подій
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

  // Мокові дані для запрошень на події (очікувані)
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
        location: 'Київ',
        hobbies: ['Музика', 'Танці', 'Вечірки'],
      ),
      'isAccepted': false,
    },
    {
      'event': Event(
        id: '4',
        title: 'Похід у гори',
        location: 'Карпати',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        photos: ['assets/images/pexels-rpnickson-2609463.jpg'],
        tags: ['Походи', 'Гори', 'Природа'],
        description: 'Відвідуємо найкращі маршрути Карпат.',
        participantsCount: 12,
      ),
      'inviter': UserProfile(
        id: '7',
        name: 'Марія',
        age: 25,
        description: 'Люблю природу та активний відпочинок',
        photos: ['assets/images/pleased-smiling-man-with-beard-looking-camera.jpg'],
        location: 'Львів',
        hobbies: ['Походи', 'Природа', 'Фотографія'],
      ),
      'isAccepted': false,
    },
  ];

  // Мокові дані для прийнятих запрошень
  final List<Map<String, dynamic>> _acceptedInvitations = [
    {
      'event': Event(
        id: '7',
        title: 'Пікнік в парку',
        location: 'Парк Шевченка',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        photos: ['assets/images/pexels-rdne-4920848.jpg'],
        tags: ['Природа', 'Пікнік', 'Відпочинок'],
        description: 'Пікнік з іграми та спілкуванням на свіжому повітрі.',
        participantsCount: 15,
        isPrivate: true,
        privateLocation: 'Парк Шевченка, алея біля фонтану, лавка №15',
        meetingPoint: 'Біля головного входу в парк, біля пам\'ятника Шевченку',
        additionalInfo: 'Принесіть щось смачне для спільного столу. Код доступу до парку: 1234. Дрескод: casual.',
      ),
      'inviter': UserProfile(
        id: '8',
        name: 'Анна',
        age: 24,
        description: 'Люблю природу та спілкування',
        photos: ['assets/images/selfie-portrait-videocall.jpg'],
        location: 'Київ',
        hobbies: ['Природа', 'Пікніки', 'Ігри'],
      ),
      'isAccepted': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Матчі'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildMyEventsTab(),
                _buildEventInvitationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.purple,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        tabs: const [
          Tab(text: 'Запити'),
          Tab(text: 'Мої події'),
          Tab(text: 'Запрошення'),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_likedMeWithMessages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Немає нових запитів',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Коли хтось поставить лайк вашому профілю,\nвін з\'явиться тут',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedMeWithMessages.length,
      itemBuilder: (context, index) {
        final request = _likedMeWithMessages[index];
        final user = request['user'] as UserProfile;
        final message = request['message'] as String?;
        final hasMessage = request['hasMessage'] as bool;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(user.photos.first),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${user.age} років • ${user.location}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: user.hobbies.map((hobby) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hobby,
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (hasMessage && message != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.message, color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleReject(user),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Відхилити'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLike(user),
                        icon: const Icon(Icons.favorite, size: 18),
                        label: const Text('Лайк'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleInviteToEvent(user),
                        icon: const Icon(Icons.event, size: 18),
                        label: const Text('Запросити'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

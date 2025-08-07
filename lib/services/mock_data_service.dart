import '../models/user_profile.dart';
import '../models/event.dart';
import '../models/message.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Користувачі для свайпера
  List<UserProfile> getUsers() {
    return [
      UserProfile(
        id: '1',
        name: 'Роман',
        age: 19,
        description: 'Люблю пригоди, ігри, книги, походи, знаходити друзів, затишну компанію, дивитися на зірки, геймерські битви',
        photos: [
          'assets/images/portrait-man-laughing.jpg',
          'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
          'assets/images/pleased-smiling-man-with-beard-looking-camera.jpg',
        ],
        location: 'Луцьк',
        hobbies: ['Фентезі книги', 'Похід з наметом', 'Ранкова кава з видом на гори', 'Гра на гітарі', 'Фотографія', 'Кулінарія', 'Подорожі', 'Спорт'],
      ),
      UserProfile(
        id: '2',
        name: 'Анна',
        age: 22,
        description: 'Люблю подорожувати, фотографувати, читати книги та знайомитися з новими людьми',
        photos: [
          'assets/images/selfie-portrait-videocall.jpg',
          'assets/images/portrait-man-laughing.jpg',
          'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
        ],
        location: 'Київ',
        hobbies: ['Подорожі', 'Фотографія', 'Читання', 'Йога', 'Медитація', 'Велоспорт', 'Кулінарія', 'Мистецтво'],
      ),
      UserProfile(
        id: '3',
        name: 'Максим',
        age: 25,
        description: 'Спортсмен, люблю активний спосіб життя та нові виклики',
        photos: [
          'assets/images/pleased-smiling-man-with-beard-looking-camera.jpg',
          'assets/images/portrait-man-laughing.jpg',
          'assets/images/selfie-portrait-videocall.jpg',
        ],
        location: 'Львів',
        hobbies: ['Спорт', 'Фітнес', 'Гори', 'Бокс', 'Плавання', 'Біг', 'Здорове харчування', 'Мотивація'],
      ),
      UserProfile(
        id: '4',
        name: 'Олена',
        age: 23,
        description: 'Люблю кав\'ярні та нові знайомства',
        photos: ['assets/images/uifaces-popular-image.jpg'],
        location: 'Харків',
        hobbies: ['Кава', 'Книги', 'Подорожі'],
      ),
      UserProfile(
        id: '5',
        name: 'Ірина',
        age: 27,
        description: 'Шукаю компанію для концертів',
        photos: ['assets/images/uifaces-popular-image-2.jpg'],
        location: 'Одеса',
        hobbies: ['Музика', 'Концерти', 'Танці'],
      ),
    ];
  }

  // Події
  List<Event> getEvents() {
    return [
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
      Event(
        id: '3',
        title: 'Вечірка в клубі',
        location: 'Клуб "Парадокс"',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        photos: ['assets/images/club1.jpg'],
        tags: ['Музика', 'Танці', 'Вечірка'],
        description: 'Велика вечірка з найкращою музикою та атмосферою.',
        participantsCount: 45,
      ),
    ];
  }

  // Матчі з повідомленнями
  List<Map<String, dynamic>> getMatchesWithMessages() {
    return [
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
        'matchedAt': DateTime.now().subtract(const Duration(hours: 2)),
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
        'matchedAt': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];
  }

  // Чатові розмови
  List<ChatConversation> getConversations() {
    return [
      ChatConversation(
        id: '1',
        userId: '2',
        userName: 'Роман',
        userPhoto: 'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
        lastMessage: 'Пише..',
        lastMessageTime: DateTime.now(),
        unreadCount: 5,
        isOnline: true,
        isTyping: true,
      ),
      ChatConversation(
        id: '2',
        userId: '5',
        userName: 'Максим',
        userPhoto: 'assets/images/portrait-man-laughing.jpg',
        lastMessage: 'Ти: Привіт, як справи?',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 0,
        isOnline: false,
      ),
      ChatConversation(
        id: '3',
        userId: '3',
        userName: 'Яна',
        userPhoto: 'assets/images/selfie-portrait-videocall.jpg',
        lastMessage: 'Коли зустрінемося?',
        lastMessageTime: DateTime.now(),
        unreadCount: 3,
        isOnline: true,
      ),
    ];
  }

  // Повідомлення для чату
  List<Message> getMessages(String conversationId) {
    final messages = [
      Message(
        id: '1',
        senderId: conversationId,
        receiverId: 'current_user',
        content: 'Привіт! Як справи?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: true,
      ),
      Message(
        id: '2',
        senderId: 'current_user',
        receiverId: conversationId,
        content: 'Привіт! Все добре, дякую! А у тебе?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        isRead: true,
      ),
      Message(
        id: '3',
        senderId: conversationId,
        receiverId: 'current_user',
        content: 'Теж добре! Можливо, зустрінемось на каву? ☕',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
    ];
    return messages;
  }

  // Активні контакти (stories)
  List<ActiveContact> getActiveContacts() {
    return [
      ActiveContact(
        id: '1',
        name: 'Ти',
        photo: 'assets/images/portrait-man-laughing.jpg',
        isOnline: true,
      ),
      ActiveContact(
        id: '2',
        name: 'Роман',
        photo: 'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
        hasNewStory: true,
        isOnline: true,
      ),
      ActiveContact(
        id: '3',
        name: 'Яна',
        photo: 'assets/images/selfie-portrait-videocall.jpg',
        isOnline: false,
      ),
    ];
  }
}

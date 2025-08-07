import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import '../models/message.dart';
import '../services/mock_data_service.dart';

class AppStateProvider extends ChangeNotifier {
  final MockDataService _mockDataService = MockDataService();
  
  // Поточний користувач
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  
  // Список користувачів для свайпера
  List<UserProfile> _users = [];
  List<UserProfile> get users => _users;
  
  // Матчі
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> get matches => _matches;
  
  // Події
  List<Event> _events = [];
  List<Event> get events => _events;
  
  // Чатові розмови
  List<ChatConversation> _conversations = [];
  List<ChatConversation> get conversations => _conversations;
  
  // Активні контакти
  List<ActiveContact> _activeContacts = [];
  List<ActiveContact> get activeContacts => _activeContacts;
  
  // Лайки та дизлайки
  Set<String> _likedUsers = {};
  Set<String> _dislikedUsers = {};
  
  // Ініціалізація
  AppStateProvider() {
    _initializeData();
  }
  
  void _initializeData() {
    _users = _mockDataService.getUsers();
    _matches = _mockDataService.getMatchesWithMessages();
    _events = _mockDataService.getEvents();
    _conversations = _mockDataService.getConversations();
    _activeContacts = _mockDataService.getActiveContacts();
    
    // Встановлюємо поточного користувача (мок)
    _currentUser = UserProfile(
      id: 'current_user',
      name: 'Ти',
      age: 25,
      description: 'Люблю подорожі, музику та нові знайомства',
      photos: ['assets/images/portrait-man-laughing.jpg'],
      location: 'Київ',
      hobbies: ['Подорожі', 'Музика', 'Спорт', 'Книги'],
    );
  }
  
  // Лайк користувача
  void likeUser(String userId) {
    if (!_likedUsers.contains(userId) && !_dislikedUsers.contains(userId)) {
      _likedUsers.add(userId);
      
      // Перевіряємо чи є взаємний лайк (матч)
      final likedUser = _users.firstWhere((user) => user.id == userId);
      if (_checkForMatch(likedUser)) {
        _createMatch(likedUser);
      }
      
      notifyListeners();
    }
  }
  
  // Дизлайк користувача
  void dislikeUser(String userId) {
    if (!_likedUsers.contains(userId) && !_dislikedUsers.contains(userId)) {
      _dislikedUsers.add(userId);
      notifyListeners();
    }
  }
  
  // Перевірка на матч
  bool _checkForMatch(UserProfile likedUser) {
    // В реальному додатку тут була б логіка перевірки взаємного лайку
    // Для мок-даних просто повертаємо true з ймовірністю 30%
    return DateTime.now().millisecondsSinceEpoch % 3 == 0;
  }
  
  // Створення матчу
  void _createMatch(UserProfile matchedUser) {
    final match = {
      'user': matchedUser,
      'message': 'Ви понравилися один одному! 💕',
      'hasMessage': true,
      'matchedAt': DateTime.now(),
    };
    
    _matches.insert(0, match);
    
    // Створюємо чатову розмову
    final conversation = ChatConversation(
      id: 'match_${matchedUser.id}',
      userId: matchedUser.id,
      userName: matchedUser.name,
      userPhoto: matchedUser.photos.first,
      lastMessage: 'Ви понравилися один одному! 💕',
      lastMessageTime: DateTime.now(),
      unreadCount: 1,
      isOnline: true,
    );
    
    _conversations.insert(0, conversation);
  }
  
  // Отримання повідомлень для розмови
  List<Message> getMessagesForConversation(String conversationId) {
    return _mockDataService.getMessages(conversationId);
  }
  
  // Відправка повідомлення
  void sendMessage(String conversationId, String content) {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_user',
      receiverId: conversationId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    );
    
    // Оновлюємо останнє повідомлення в розмові
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = ChatConversation(
        id: _conversations[conversationIndex].id,
        userId: _conversations[conversationIndex].userId,
        userName: _conversations[conversationIndex].userName,
        userPhoto: _conversations[conversationIndex].userPhoto,
        lastMessage: 'Ти: $content',
        lastMessageTime: DateTime.now(),
        unreadCount: _conversations[conversationIndex].unreadCount,
        isOnline: _conversations[conversationIndex].isOnline,
        isTyping: _conversations[conversationIndex].isTyping,
      );
    }
    
    notifyListeners();
  }
  
  // Створення події
  void createEvent(Event event) {
    _events.add(event);
    notifyListeners();
  }
  
  // Приєднання до події
  void joinEvent(String eventId) {
    // В реальному додатку тут була б логіка приєднання до події
    notifyListeners();
  }
  
  // Очищення даних
  void clearData() {
    _users.clear();
    _matches.clear();
    _events.clear();
    _conversations.clear();
    _activeContacts.clear();
    _likedUsers.clear();
    _dislikedUsers.clear();
    notifyListeners();
  }
}

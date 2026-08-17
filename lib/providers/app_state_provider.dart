import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import '../service/matches_service.dart';
import '../service/chat_service.dart';

class AppStateProvider extends ChangeNotifier {
  // Сервіси
  
  final MatchesService _matchesService = MatchesService();
  final ChatService _chatService = ChatService(); // Переконайтеся, що цей сервіс існує
  final _supabase = Supabase.instance.client;

  // --- СТАН (Дані) ---
  
  UserProfile? _currentUserProfile;
  List<Map<String, dynamic>> _incomingRequests = []; // Вхідні лайки
  List<Event> _myEvents = []; // Мої події
  List<Map<String, dynamic>> _myEventApplications = []; // Мої заявки на події
  int _unreadMessageCount = 0; // Лічильник непрочитаних
  
  bool _isLoading = false;
  String? _errorMessage;

  // --- ГЕТТЕРИ (Щоб читати дані з UI) ---

  UserProfile? get currentUserProfile => _currentUserProfile;
  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  List<Event> get myEvents => _myEvents;
  List<Map<String, dynamic>> get myEventApplications => _myEventApplications;
  int get unreadMessageCount => _unreadMessageCount;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- ОСНОВНІ ДІЇ ---

  // 1. Головний метод: Завантажити ВСЕ (викликається при старті)
  Future<void> loadAllData() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      // Виконуємо запити паралельно для швидкості
      await Future.wait([
        _fetchUserProfile(userId),
        refreshIncomingRequests(),
        refreshMyEvents(),
        _countUnreadMessages(),
      ]);

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("❌ AppStateProvider Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  // 2. Оновити тільки вхідні лайки (наприклад, після свайпу)
  Future<void> refreshIncomingRequests() async {
    try {
      final requests = await _matchesService.getIncomingRequests();
      _incomingRequests = requests;
      notifyListeners(); // Повідомляємо UI про зміни
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    }
  }

  // 3. Оновити мої події
  Future<void> refreshMyEvents() async {
    try {
      final events = await _matchesService.getMyEvents();
      _myEvents = events;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching events: $e");
    }
  }

  // 4. Прийняти лайк (Оптимістичне оновлення UI)
  Future<void> acceptLike(String likeId) async {
    // 1. Миттєво прибираємо зі списку на екрані (щоб користувач не чекав)
    _incomingRequests.removeWhere((item) => item['like_id'] == likeId);
    notifyListeners();

    try {
      // 2. Робимо запит на сервер
      await _matchesService.acceptLike(likeId);
      // Якщо успіх - нічого не робимо, бо ми вже оновили UI
    } catch (e) {
      // Якщо помилка - повертаємо назад (відкочуємо зміни) і показуємо помилку
      _errorMessage = "Не вдалося прийняти лайк";
      await refreshIncomingRequests(); // Перезавантажуємо список чесно
      notifyListeners();
    }
  }

  // 5. Відхилити лайк
  Future<void> rejectLike(String likeId) async {
    _incomingRequests.removeWhere((item) => item['like_id'] == likeId);
    notifyListeners();

    try {
      await _matchesService.rejectLike(likeId);
    } catch (e) {
      await refreshIncomingRequests();
    }
  }

  // --- ВНУТРІШНІ МЕТОДИ ---

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select(kPublicProfileFields)
          .eq('id', userId)
          .single();
      _currentUserProfile = UserProfile.fromMap(data);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> _countUnreadMessages() async {
    // Тут логіка підрахунку непрочитаних. 
    // Якщо у ChatService є метод getUnreadCount(), використай його.
    // Поки ставимо заглушку або простий запит
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Приклад запиту:
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('is_read', false)
          .neq('sender_id', userId) // Повідомлення не від мене
          .count();
      
      _unreadMessageCount = response.count;
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // Метод для очищення стану при виході (Logout)
  void clearState() {
    _currentUserProfile = null;
    _incomingRequests = [];
    _myEvents = [];
    _unreadMessageCount = 0;
    notifyListeners();
  }
}
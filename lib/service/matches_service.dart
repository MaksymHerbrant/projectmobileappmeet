import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import '../service/chat_service.dart';
import '../service/notification_service.dart';
import '../service/error_reporter.dart';

class VectorUtils {
  static const List<String> allInterests = [
    'Музика', 'Танці', 'Спорт', 'Подорожі', 'Освіта', 'Вечірка',
    'Кава', 'Кіно', 'Мистецтво', 'Походи', 'Гори', 'Природа',
    'IT', 'Програмування', 'Геймінг', 'Фотографія', 'Кулінарія',
    'Йога', 'Фітнес', 'Біг' 
  ];

  static List<double> tagsToVector(List<String> userTags) {
    List<double> vector = List.filled(384, 0.0); 
    for (int i = 0; i < allInterests.length; i++) {
      if (userTags.contains(allInterests[i])) {
        if (i < 384) vector[i] = 1.0; 
      }
    }
    return vector;
  }
}

/// Колонки профілю, які дозволено бачити іншим користувачам.
///
/// Голий `.select()` більше не працює: `phone`, `email` і `fcm_token` відкликані
/// на рівні прав доступу, тому `select *` впаде з permission denied. Свій
/// власний профіль читається через RPC `get_my_profile`.
const String kPublicProfileFields =
    'id, full_name, birth_date, age, bio, photos, location, hobbies';

class MatchesService {
  final _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // ------------------------------------------
  // КОРИСТУВАЧІ (MATCHING)
  // ------------------------------------------

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<UserProfile>> getPotentialMatches() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final interactions = await _supabase
          .from('likes')
          .select('receiver_id')
          .eq('sender_id', userId);

      final List<String> ignoredIds = (interactions as List)
          .map((e) => e['receiver_id'].toString())
          .toList();
      ignoredIds.add(userId);

      var query = _supabase.from('profiles').select(kPublicProfileFields);
      if (ignoredIds.isNotEmpty) {
        query = query.not('id', 'in', ignoredIds);
      }
      final response = await query.limit(20);

      return List<Map<String, dynamic>>.from(response)
          .map((data) => UserProfile.fromMap(data))
          .toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getPotentialMatches');
      return [];
    }
  }

  /// Стрічка людей у заданому радіусі.
  ///
  /// Ранжування рахує сервер: спорідненість інтересів із поправкою на їх
  /// рідкість, реальна відстань у метрах, свіжість активності та взаємність.
  /// Радіус — справжній фільтр по просторовому індексу, а не сортування
  /// постфактум.
  Future<List<UserProfile>> getFeed({
    int radiusKm = 50,
    int limit = 20,
    int offset = 0,
  }) async {
    if (_userId == null) return [];
    try {
      final response = await _supabase.rpc('get_feed', params: {
        'p_radius_km': radiusKm,
        'p_limit': limit,
        'p_offset': offset,
      });
      return List<Map<String, dynamic>>.from(response as List)
          .map(UserProfile.fromMap)
          .toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getFeed');
      rethrow;
    }
  }

  /// Свайп цілком виконується однією транзакцією на сервері: запис лайка,
  /// перевірка взаємності, створення чату. Раніше це були чотири окремі
  /// запити, і два одночасні свайпи назустріч давали подвійний метч і два чати.
  ///
  /// Повертає true, якщо метч стався.
  Future<bool> recordSwipe(String receiverId, bool isLike) async {
    if (_userId == null) return false;

    try {
      final result = await _supabase.rpc('record_swipe', params: {
        'p_receiver': receiverId,
        'p_is_like': isLike,
      });

      final matched = (result is Map && result['matched'] == true);

      if (isLike) {
        await _notificationService.sendPush(
          receiverId: receiverId,
          title: matched ? "Це взаємно! 🔥" : "Новий інтерес! 👋",
          body: matched
              ? "У тебе новий метч, мерщій зазирни в чати!"
              : "Хтось хоче з тобою закентуватись. Можливо, це твій новий бро?",
        );
      }
      return matched;
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'recordSwipe');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final response = await _supabase
          .from('likes')
          .select('*, sender:profiles!sender_id($kPublicProfileFields)')
          .eq('receiver_id', userId)
          .eq('is_like', true)
          .eq('is_accepted', false);

      return List<Map<String, dynamic>>.from(response).map((item) {
        final profileData = item['sender'];
        final user = UserProfile.fromMap(profileData);
        return {
          'user': user,
          'message': item['message'],
          'hasMessage': item['message'] != null && item['message'].toString().isNotEmpty,
          'like_id': item['id'],
        };
      }).toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getIncomingRequests');
      return [];
    }
  }

  Future<List<UserProfile>> searchUsersByName(String query) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final response = await _supabase
          .from('profiles')
          .select(kPublicProfileFields)
          .ilike('full_name', '%$query%')
          .neq('id', userId)
          .limit(20);

      return List<Map<String, dynamic>>.from(response)
          .map((data) => UserProfile.fromMap(data))
          .toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'searchUsersByName');
      return [];
    }
  }

  // ------------------------------------------
  // ПОДІЇ (EVENTS)
  // ------------------------------------------

  Future<List<Event>> getPotentialEvents() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final interactions = await _supabase
          .from('event_likes')
          .select('event_id')
          .eq('user_id', userId);

      final List<String> ignoredIds = (interactions as List)
          .map((e) => e['event_id'].toString())
          .toList();

      var query = _supabase.from('events').select();
      if (ignoredIds.isNotEmpty) {
        query = query.not('id', 'in', ignoredIds);
      }
      final response = await query.neq('creator_id', userId).limit(20);

      return List<Map<String, dynamic>>.from(response)
          .map((data) => Event.fromMap(data))
          .toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getPotentialEvents');
      return [];
    }
  }

  /// Стрічка подій. Додатково враховує, наскільки скоро подія і скільки людей
  /// уже приєдналось.
  Future<List<Event>> getEventFeed({
    int radiusKm = 50,
    int limit = 20,
    int offset = 0,
  }) async {
    if (_userId == null) return [];
    try {
      final response = await _supabase.rpc('get_event_feed', params: {
        'p_radius_km': radiusKm,
        'p_limit': limit,
        'p_offset': offset,
      });
      return List<Map<String, dynamic>>.from(response as List)
          .map(Event.fromMap)
          .toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getEventFeed');
      rethrow;
    }
  }

  Future<void> recordEventSwipe(String eventId, bool isLike, {String? message}) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase.from('event_likes').upsert({
        'user_id': userId,
        'event_id': eventId,
        'is_like': isLike,
      });
      if (isLike) {
        await _supabase.from('event_participants').upsert({
          'event_id': eventId,
          'user_id': userId,
          'status': 'pending',
          'message': message,
        });
      }
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'recordEventSwipe');
      rethrow;
    }
  }

  Future<void> createEvent(Event event) async {
    final userId = _userId;
    if (userId == null) throw Exception('Користувач не авторизований');
    final vector = VectorUtils.tagsToVector(event.tags);
    try {
      // Подія і її груповий чат створюються однією транзакцією на сервері.
      // Окремі виклики тут не працювали: клієнт не може прочитати щойно
      // створену кімнату, бо ще не є її учасником.
      await _supabase.rpc('create_event_with_chat', params: {
        'p_title': event.title,
        'p_description': event.description,
        'p_location': event.location,
        'p_event_date': event.dateTime.toUtc().toIso8601String(),
        'p_photos': event.photos,
        'p_tags': event.tags,
        'p_participants_count': event.participantsCount,
        'p_is_private': event.isPrivate,
        'p_private_location': event.privateLocation,
        'p_meeting_point': event.meetingPoint,
        'p_additional_info': event.additionalInfo,
        'p_embedding': vector.toString(),
      });
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'createEvent');
      rethrow;
    }
  }

  Future<List<Event>> getMyEvents() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('creator_id', userId)
          .order('event_date', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map((e) => Event.fromMap(e))
          .toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getMyEvents');
      return [];
    }
  }

  /// Один запит замість N+1: отримуємо всі лайки до моїх подій з join на profiles.
  Future<Map<String, List<UserProfile>>> getEventLikes() async {
    final userId = _userId;
    if (userId == null) return {};
    try {
      final myEvents = await getMyEvents();
      if (myEvents.isEmpty) return {};

      final eventIds = myEvents.map((e) => e.id).toList();
      final response = await _supabase
          .from('event_likes')
          .select('event_id, profiles($kPublicProfileFields)')
          .inFilter('event_id', eventIds)
          .eq('is_like', true);

      final Map<String, List<UserProfile>> result = {};
      for (final row in List<Map<String, dynamic>>.from(response)) {
        final eventId = row['event_id'] as String?;
        final profileData = row['profiles'];
        if (eventId == null || profileData == null) continue;
        result.putIfAbsent(eventId, () => []).add(UserProfile.fromMap(profileData));
      }
      return result;
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getEventLikes');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getRequestsForEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('event_participants')
          .select('*, user:profiles!user_id($kPublicProfileFields)')
          .eq('event_id', eventId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response).map((item) {
        return {
          'user': UserProfile.fromMap(item['user']),
          'message': item['message'],
          'hasMessage': item['message'] != null && item['message'].toString().isNotEmpty,
          'request_id': item['id'],
        };
      }).toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getRequestsForEvent');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEventInvitations(String status) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final response = await _supabase
          .from('event_participants')
          .select('''
            *,
            event:events(*),
            inviter:profiles!inviter_id($kPublicProfileFields)
          ''')
          .eq('user_id', userId)
          .eq('status', status);

      return List<Map<String, dynamic>>.from(response).map((item) {
        return {
          'event': Event.fromMap(item['event']),
          'inviter': item['inviter'] != null
              ? UserProfile.fromMap(item['inviter'])
              : UserProfile(id: 'del', name: 'Видалено', age: 0, description: '', photos: [], location: '', hobbies: []),
          'message': item['message'],
          'invitation_id': item['id'],
          'acceptedAt': item['created_at'] != null ? DateTime.parse(item['created_at']) : null,
        };
      }).toList();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'getEventInvitations');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMyEventApplications(String status) async {
    return getEventInvitations(status);
  }

  // ------------------------------------------
  // ДІЇ (ACTIONS)
  // ------------------------------------------

  /// Прийняти запит — це те саме, що лайкнути у відповідь, тому виконується
  /// тією ж атомарною транзакцією.
  Future<void> acceptLike(String likeId) async {
    if (_userId == null) return;
    try {
      final likeData = await _supabase
          .from('likes')
          .select('sender_id')
          .eq('id', likeId)
          .single();
      final String otherUserId = likeData['sender_id'];

      await _supabase.rpc('accept_like', params: {'p_like_id': likeId});

      await _notificationService.sendPush(
        receiverId: otherUserId,
        title: "Твій запит прийнято! 🎉",
        body: "Тепер ви друзі. Почніть спілкування зараз!",
      );
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'acceptLike');
      rethrow;
    }
  }

  Future<void> rejectLike(String likeId) async {
    try {
      await _supabase.from('likes').delete().eq('id', likeId);
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'rejectLike');
      rethrow;
    }
  }

  // 🟢 ВИПРАВЛЕНО: Додає у чат лише по конкретному requestId
  Future<void> respondToEventRequest(String requestId, String newStatus) async {
    await _supabase.from('event_participants').update({'status': newStatus}).eq('id', requestId);

    if (newStatus == 'accepted') {
      try {
        final requestData = await _supabase
            .from('event_participants')
            .select('user_id, event_id')
            .eq('id', requestId)
            .single();

        await ChatService().addUserToEventChat(
          requestData['event_id'], 
          requestData['user_id']
        );
      } catch (e) {
        if (kDebugMode) debugPrint('respondToEventRequest: addUserToEventChat failed');
      }
    }
  }

  Future<void> updateInvitationStatus(String invitationId, String status) async {
    try {
      await _supabase.from('event_participants').update({'status': status}).eq('id', invitationId);
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'updateInvitationStatus');
      rethrow;
    }
  }
}
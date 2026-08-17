import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import '../service/chat_service.dart';
import '../service/notification_service.dart';

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
    } catch (e) {
      if (kDebugMode) debugPrint('getPotentialMatches: $e');
      return [];
    }
  }

  Future<List<UserProfile>> getSmartMatches() async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      // Свої embedding і координати — через RPC: у таблиці ці колонки закриті,
      // щоб ніхто не міг вивантажити точні позиції всіх користувачів.
      final ctx = await _supabase.rpc('get_my_match_context');
      final currentUserData = ctx == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(ctx as Map);

      if (currentUserData['embedding'] == null) {
          return await getPotentialMatches();
      }

      final interactions = await _supabase.from('likes').select('receiver_id').eq('sender_id', userId);
      final ignoredIds = (interactions as List).map((e) => e['receiver_id']).toList();

      final double userLat = (currentUserData['lat'] as num?)?.toDouble() ?? 0;
      final double userLong = (currentUserData['long'] as num?)?.toDouble() ?? 0;
      
      final String embeddingStr = currentUserData['embedding']; 

      final response = await _supabase.rpc(
        'get_smart_recommendations',
        params: {
          'query_embedding': embeddingStr,
          'user_lat': userLat,
          'user_long': userLong,
          'match_threshold': 0.0, 
          'match_count': 20,
          'ignored_ids': ignoredIds,
        },
      );

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        return await getPotentialMatches();
      }

      return data.map((d) => UserProfile.fromMap(d)).toList();
      
    } catch (e) {
      if (kDebugMode) debugPrint('getSmartMatches: $e');
      return await getPotentialMatches();
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
    } catch (e) {
      if (kDebugMode) debugPrint('recordSwipe: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('getIncomingRequests: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('searchUsersByName: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('getPotentialEvents: $e');
      return [];
    }
  }

  Future<List<Event>> getSmartEvents() async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      final ctx = await _supabase.rpc('get_my_match_context');
      final currentUserData = ctx == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(ctx as Map);

      if (currentUserData['embedding'] == null) {
        return await getPotentialEvents();
      }

      final String userEmbeddingStr = currentUserData['embedding'];
      
      final double userLat = (currentUserData['lat'] as num?)?.toDouble() ?? 0;
      final double userLong = (currentUserData['long'] as num?)?.toDouble() ?? 0;

      final interactions = await _supabase
          .from('event_likes')
          .select('event_id')
          .eq('user_id', userId);
      
      final ignoredIds = (interactions as List).map((e) => e['event_id'].toString()).toList();

      final response = await _supabase.rpc(
        'get_smart_event_recommendations',
        params: {
          'query_embedding': userEmbeddingStr,
          'user_lat': userLat,
          'user_long': userLong,
          'match_threshold': 0.0,
          'match_count': 20,
          'ignored_ids': ignoredIds,
        },
      );
      
      final List<dynamic> data = response as List<dynamic>;
      
      if (data.isEmpty) {
        return await getPotentialEvents();
      }

      return data.map((d) => Event.fromMap(d)).toList();

    } catch (e) {
      if (kDebugMode) debugPrint('getSmartEvents: $e');
      return await getPotentialEvents();
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
    } catch (e) {
      if (kDebugMode) debugPrint('recordEventSwipe: $e');
      rethrow;
    }
  }

  Future<void> createEvent(Event event) async {
    final userId = _userId;
    if (userId == null) throw Exception('Користувач не авторизований');
    final vector = VectorUtils.tagsToVector(event.tags);
    try {
      final response = await _supabase.from('events').insert({
        'creator_id': userId,
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'event_date': event.dateTime.toIso8601String(),
        'photos': event.photos,
        'tags': event.tags,
        'participants_count': event.participantsCount,
        'is_private': event.isPrivate,
        'private_location': event.privateLocation,
        'meeting_point': event.meetingPoint,
        'additional_info': event.additionalInfo,
        'embedding': vector.toString(),
      }).select('id').single();

      final String newEventId = response['id'];
      final String? groupPhoto = event.photos.isNotEmpty ? event.photos.first : null;
      await ChatService().createEventGroupChat(newEventId, event.title, groupPhoto);
    } catch (e) {
      if (kDebugMode) debugPrint('createEvent: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('getMyEvents: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('getEventLikes: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('getRequestsForEvent: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('getEventInvitations: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('acceptLike: $e');
      rethrow;
    }
  }

  Future<void> rejectLike(String likeId) async {
    try {
      await _supabase.from('likes').delete().eq('id', likeId);
    } catch (e) {
      if (kDebugMode) debugPrint('rejectLike: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('updateInvitationStatus: $e');
      rethrow;
    }
  }
}
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

      var query = _supabase.from('profiles').select();
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
      final currentUserData = await _supabase
          .from('profiles')
          .select('embedding, location_point')
          .eq('id', userId)
          .single();

      if (currentUserData['embedding'] == null) {
          return await getPotentialMatches();
      }

      final interactions = await _supabase.from('likes').select('receiver_id').eq('sender_id', userId);
      final ignoredIds = (interactions as List).map((e) => e['receiver_id']).toList();

      double userLat = 0;
      double userLong = 0;
      final pointStr = currentUserData['location_point'] as String?;
      
      if (pointStr != null) {
         final coords = pointStr.replaceAll(RegExp(r'[()]'), '').split(',');
         if (coords.length >= 2) {
           userLat = double.tryParse(coords[0]) ?? 0;
           userLong = double.tryParse(coords[1]) ?? 0;
         }
      }
      
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

  Future<void> recordSwipe(String receiverId, bool isLike) async {
    final userId = _userId;
    if (userId == null) return;

    if (!isLike) {
       await _supabase.from('likes').insert({
        'sender_id': userId, 'receiver_id': receiverId, 'is_like': false, 'is_accepted': false,
      });
      return;
    }

    try {
      final incomingLike = await _supabase
          .from('likes')
          .select().eq('sender_id', receiverId).eq('receiver_id', userId).eq('is_like', true).maybeSingle();

      if (incomingLike != null) {
        await _supabase.from('likes').update({'is_accepted': true}).eq('id', incomingLike['id']);
        await _supabase.from('likes').insert({
          'sender_id': userId, 'receiver_id': receiverId, 'is_like': true, 'is_accepted': true,
        });

        final ChatService chatService = ChatService();
        await chatService.createPrivateChat(receiverId);
        
        await _notificationService.sendPush(
          receiverId: receiverId,
          title: "Це взаємно! 🔥",
          body: "У тебе новий метч, мерщій зазирни в чати!",
        );

      } else {
        await _supabase.from('likes').insert({
          'sender_id': userId, 'receiver_id': receiverId, 'is_like': true, 'is_accepted': false,
        });
        
        await _notificationService.sendPush(
          receiverId: receiverId, 
          title: "Новий інтерес! 👋", 
          body: "Хтось хоче з тобою закентуватись. Можливо, це твій новий бро?"
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('recordSwipe: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final response = await _supabase
          .from('likes')
          .select('*, sender:profiles!sender_id(*)')
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
          .select()
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
      final currentUserData = await _supabase
          .from('profiles')
          .select('embedding, location_point')
          .eq('id', userId)
          .single();

      if (currentUserData['embedding'] == null) {
        return await getPotentialEvents();
      }

      final String userEmbeddingStr = currentUserData['embedding'];
      
      double userLat = 0;
      double userLong = 0;
      final pointStr = currentUserData['location_point'] as String?;
      if (pointStr != null) {
         final coords = pointStr.replaceAll(RegExp(r'[()]'), '').split(',');
         if (coords.length >= 2) {
           userLat = double.tryParse(coords[0]) ?? 0;
           userLong = double.tryParse(coords[1]) ?? 0;
         }
      }

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
          .select('event_id, profiles(*)')
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
          .select('*, user:profiles!user_id(*)')
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
            inviter:profiles!inviter_id(*)
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

  Future<void> acceptLike(String likeId) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final likeData = await _supabase.from('likes').select('sender_id').eq('id', likeId).single();
      final String otherUserId = likeData['sender_id'];

      await _notificationService.sendPush(
        receiverId: otherUserId,
        title: "Твій запит прийнято! 🎉",
        body: "Тепер ви друзі. Почніть спілкування зараз!",
      );

      await _supabase.from('likes').update({'is_accepted': true}).eq('id', likeId);
      await _supabase.from('likes').upsert({
        'sender_id': userId,
        'receiver_id': otherUserId,
        'is_like': true,
        'is_accepted': true,
      });

      await ChatService().createPrivateChat(otherUserId);
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
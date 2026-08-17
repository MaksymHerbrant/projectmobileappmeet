import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../service/notification_service.dart';
import '../service/error_reporter.dart';

class ChatService {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;
  final NotificationService _notificationService = NotificationService();

  /// Список чатів. Realtime-підписка на `rooms` тепер лише сигнал «щось
  /// змінилось» — сам список збирає одна RPC замість чотирьох запитів на
  /// кожну кімнату. Завдяки RLS підписка віддає тільки мої кімнати.
  Stream<List<Map<String, dynamic>>> getMyChatsStream() {
    return _supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => fetchMyChats());
  }

  Future<List<Map<String, dynamic>>> fetchMyChats() async {
    try {
      final response = await _supabase.rpc('get_my_chats');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'fetchMyChats');
      rethrow;
    }
  }
  void subscribeToPresence(String userId, Function(Set<String>) onUpdate) {
    final Set<String> onlineIds = {};

    _presenceChannel = _supabase.channel(
      'online-users',
      opts: const RealtimeChannelConfig(self: true),
    );

    _presenceChannel!
        .onPresenceJoin((payload) {
          try {
            for (final presence in payload.newPresences) {
              final presenceData = presence.payload;
              if (presenceData != null && presenceData['user_id'] != null) {
                onlineIds.add(presenceData['user_id'].toString());
              }
            }
            onUpdate(onlineIds);
          } catch (e) {
            debugPrint('Join Error: $e');
          }
        })
        .onPresenceLeave((payload) {
          try {
            for (final presence in payload.leftPresences) {
              final presenceData = presence.payload;
              if (presenceData != null && presenceData['user_id'] != null) {
                onlineIds.remove(presenceData['user_id'].toString());
              }
            }
            onUpdate(onlineIds);
          } catch (e) {
            debugPrint('Leave Error: $e');
          }
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _presenceChannel!.track({'user_id': userId});
          }
        });
  }

  void unsubscribeFromPresence() {
    if (_presenceChannel != null) {
      _supabase.removeChannel(_presenceChannel!);
      _presenceChannel = null;
    }
  }

  Future<String> createPrivateChat(String otherUserId) async {
    final myId = _supabase.auth.currentUser!.id;
    try {
      final existingRoomId = await _supabase.rpc('find_existing_chat', params: {
        'user1': myId, 'user2': otherUserId
      });
      if (existingRoomId != null) return existingRoomId.toString();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'findExistingChat');
    }

    final roomResponse = await _supabase.from('rooms').insert({
      'type': 'private',
      'last_message': 'Новий матч! Привітайся 👋',
      'last_message_time': DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    final roomId = roomResponse['id'];

    await _supabase.from('room_participants').insert([
      {'room_id': roomId, 'profile_id': myId},
      {'room_id': roomId, 'profile_id': otherUserId}
    ]);

    return roomId.toString();
  }

  Future<void> sendMessage(String roomId, String content) async {
    try {
      final myId = _supabase.auth.currentUser!.id;
      final nowIso = DateTime.now().toUtc().toIso8601String(); 
      
      await _supabase.from('messages').insert({
        'room_id': roomId,
        'sender_id': myId,
        'content': content,
        'is_read': false,
      });

      // 🟢 ОНОВЛЕНО: Зберігаємо ID того, хто написав повідомлення
      await _supabase.from('rooms').update({
        'last_message': content,
        'last_message_time': nowIso, 
        'last_message_sender_id': myId, 
      }).eq('id', roomId);

      final participants = await _supabase
          .from('room_participants')
          .select('profile_id')
          .eq('room_id', roomId)
          .neq('profile_id', myId);

      if (participants.isNotEmpty) {
        final receiverId = participants.first['profile_id'];

        final myProfile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', myId)
            .maybeSingle();

        final String senderName = myProfile?['full_name'] ?? "Нове повідомлення";

        await _notificationService.sendPush(
          receiverId: receiverId,
          title: senderName,
          body: content,
        );
      }
    } catch (e, st) {
      // Повідомлення, яке не дійшло, не можна ховати: далі його показує UI.
      await ErrorReporter.report(e, st, context: 'sendMessage');
      throw ErrorReporter.toFailure(e);
    }
  }

  Future<void> createEventGroupChat(String eventId, String eventName, String? photoUrl) async {
    final myId = _supabase.auth.currentUser!.id;

    try {
      final roomData = await _supabase.from('rooms').insert({
        'is_group': true,
        'name': eventName,
        'avatar_url': photoUrl,
        'event_id': eventId,
        'last_message': 'Груповий чат створено 🥳', 
        'last_message_time': DateTime.now().toUtc().toIso8601String(),
      }).select('id').single();

      final roomId = roomData['id'];

      await _supabase.from('room_participants').insert({
        'room_id': roomId,
        'profile_id': myId,
      });
      
    } catch (e, st) {
      await ErrorReporter.report(e, st, context: 'createEventGroupChat');
      rethrow;
    }
  }

  Future<void> addUserToEventChat(String eventId, String userId) async {
    try {
      final room = await _supabase.from('rooms').select('id').eq('event_id', eventId).maybeSingle();
      if (room == null) return;

      final roomId = room['id'];

      final existing = await _supabase.from('room_participants')
          .select()
          .eq('room_id', roomId)
          .eq('profile_id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('room_participants').insert({
          'room_id': roomId,
          'profile_id': userId,
        });
      }
    } catch (e, st) {
      await ErrorReporter.report(e, st, context: 'addUserToEventChat');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String roomId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('room_id', roomId)
          .neq('sender_id', myId)
          .eq('is_read', false);
    } catch (e, st) {
      // Некритично: прочитаність оновиться при наступному відкритті чату.
      ErrorReporter.report(e, st, context: 'markMessagesAsRead');
    }
  }

  Future<void> createEventGroup(String eventName, String eventPhoto) async {
     final myId = _supabase.auth.currentUser!.id;
     final roomResponse = await _supabase.from('rooms').insert({
      'type': 'group',
      'name': eventName,
      'photo': eventPhoto,
      'last_message': 'Групу створено',
      'last_message_time': DateTime.now().toUtc().toIso8601String(),
    }).select().single();
    
    await _supabase.from('room_participants').insert({
      'room_id': roomResponse['id'], 
      'profile_id': myId
    });
  }
}
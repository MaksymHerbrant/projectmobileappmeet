import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../service/notification_service.dart';

class ChatService {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;
  final NotificationService _notificationService = NotificationService();

  Stream<List<Map<String, dynamic>>> getMyChatsStream() {
    final userId = _supabase.auth.currentUser!.id;

    return _supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .asyncMap((data) async {
      final List<Map<String, dynamic>> rooms = List<Map<String, dynamic>>.from(data as List);
      final List<Map<String, dynamic>> enrichedRooms = [];

      for (var room in rooms) {
        final roomId = room['id'];

        try {
          // 🛑 1. ГОЛОВНЕ ВИПРАВЛЕННЯ: Чи є Я в цьому чаті?
          final amIParticipant = await _supabase
              .from('room_participants')
              .select('room_id') // ✅ Замінили на room_id
              .eq('room_id', roomId)
              .eq('profile_id', userId)
              .maybeSingle();

          // Якщо мене немає в цій групі/чаті - просто ігноруємо її! (Чужі події сюди більше не потраплять)
          if (amIParticipant == null) {
            continue; 
          }

          // 2. Отримуємо ІНШИХ учасників (не мене)
          final List<dynamic> participants = await _supabase
              .from('room_participants')
              .select('profile_id, profiles(full_name, photos)')
              .eq('room_id', roomId)
              .neq('profile_id', userId);

          final Map<String, dynamic>? participantData = 
              participants.isNotEmpty ? participants.first as Map<String, dynamic> : null;
          
          final unreadList = await _supabase
              .from('messages')
              .select('id')
              .eq('room_id', roomId)
              .eq('is_read', false)
              .neq('sender_id', userId);
          
          final int unreadCount = unreadList.length;

          // ГРУПОВИЙ ЧАТ
          if (room['is_group'] == true || room['type'] == 'group') { 
            String displayMessage = room['last_message'] ?? 'Чат створено';
            
            if (room['last_message_sender_id'] != null) {
              final senderProfile = await _supabase
                  .from('profiles')
                  .select('full_name')
                  .eq('id', room['last_message_sender_id'])
                  .maybeSingle();
              if (senderProfile != null) {
                displayMessage = "${senderProfile['full_name']}: $displayMessage";
              }
            }

            enrichedRooms.add({
              'room_id': roomId,
              'type': 'group',
              'name': room['name'] ?? 'Група події',
              'last_message': displayMessage,
              'last_message_time': room['last_message_time']?.toString() ?? DateTime.now().toIso8601String(),
              'photo': room['avatar_url'] ?? room['photo'], 
              'unread_count': unreadCount,
            });
          } 
          // ПРИВАТНИЙ ЧАТ
          else if (participantData != null) {
            final profile = participantData['profiles'] as Map<String, dynamic>?;
            List<String> photos = [];
            
            if (profile != null && profile['photos'] != null) {
              photos = List<String>.from(profile['photos'] as List);
            }

            enrichedRooms.add({
              'room_id': roomId,
              'type': 'private',
              'last_message': room['last_message'],
              'last_message_time': room['last_message_time']?.toString(),
              'other_user_id': participantData['profile_id'],
              'other_user_name': profile != null ? (profile['full_name'] ?? 'Невідомий') : 'Невідомий',
              'other_user_photo': photos.isNotEmpty ? photos.first : null,
              'unread_count': unreadCount,
            });
          }
        } catch (e) {
          debugPrint("⚠️ Помилка обробки кімнати $roomId: $e");
          continue;
        }
      }
      return enrichedRooms;
    });
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
    } catch (e) {
      debugPrint("RPC error: $e");
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
    } catch (e) {
      debugPrint("❌ ПОМИЛКА В sendMessage: $e"); 
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
      
    } catch (e) {
      debugPrint("❌ Помилка створення групового чату: $e");
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
    } catch (e) {
      debugPrint("❌ Помилка додавання в груповий чат: $e");
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
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
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
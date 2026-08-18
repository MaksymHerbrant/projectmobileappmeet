import '../theme/app_theme.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/chat_service.dart';
import '../service/error_reporter.dart';

class ConversationScreen extends StatefulWidget {
  final String roomId;
  final String userName;
  final String userPhoto;
  final bool isOnline;
  final bool isGroup;
  final String otherUserId;

  const ConversationScreen({
    super.key,
    required this.roomId,
    required this.userName, // Тут має приходити ім'я з ChatScreen
    required this.userPhoto,
    this.isOnline = false,
    this.isGroup = false,
    required this.otherUserId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // 1. Створюємо змінну для стріму
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    ChatService().markMessagesAsRead(widget.roomId);
    
    // 2. Ініціалізуємо стрім один раз
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at', ascending: true);

    // 3. ✨ МАГІЯ: Слухаємо стрім у фоні і перевіряємо нові повідомлення
    _messagesStream.listen((messages) {
      if (!mounted) return;
      final myId = _supabase.auth.currentUser!.id;
      
      // Перевіряємо, чи є НЕпрочитані повідомлення ВІД співрозмовника
      final hasUnreadFromOther = messages.any((msg) => 
          msg['sender_id'] != myId && msg['is_read'] == false);

      if (hasUnreadFromOther) {
        _markMessagesAsRead();
      }
    });

    // Первинний виклик про всяк випадок
    _markMessagesAsRead();
  }
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 👇 НОВА ФУНКЦІЯ
  Future<void> _markMessagesAsRead() async {
    final myId = _supabase.auth.currentUser!.id;

    try {
      // 1. Позначаємо як прочитані
      await _supabase.from('messages')
          .update({'is_read': true})
          .eq('room_id', widget.roomId)
          .neq('sender_id', myId)
          .eq('is_read', false);
      
      // 2. 🔥 ГОЛОВНИЙ ТРЮК: Оновлюємо кімнату, щоб список чатів "прокинувся"
      // Ми просто оновлюємо updated_at або перезаписуємо last_message_time тим самим значенням
      // Це змусить Stream у ChatService перезапуститися і перерахувати unread_count (який стане 0)
      
      /* Варіант А: Якщо у вас є колонка updated_at (рекомендовано)
         await _supabase.from('rooms').update({
           'updated_at': DateTime.now().toIso8601String()
         }).eq('id', widget.roomId);
      */

      // Варіант Б (Хак): Якщо немає updated_at, беремо поточний last_message
      // (Це безпечно, бо текст не змінюється, але Supabase побачить подію UPDATE)
      final roomData = await _supabase.from('rooms').select('last_message').eq('id', widget.roomId).single();
      await _supabase.from('rooms').update({
         'last_message': roomData['last_message'] 
      }).eq('id', widget.roomId);

      debugPrint("✅ Прочитано і оновлено");
    } catch (e) {
      debugPrint("❌ Помилка: $e");
    }
  }
  // 🔥 ГОЛОВНИЙ МЕТОД ВІДПРАВКИ
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Тимчасово прибираємо клавіатуру, щоб екран не стрибав (опціонально)
    // FocusScope.of(context).unfocus(); 

    try {
      debugPrint("📤 Викликаємо ChatService для відправки...");
      
      // ВИКЛИКАЄМО НАШ СЕРВІС!
      // Він сам збереже повідомлення, оновить кімнату і ВІДПРАВИТЬ ПУШ!
      await ChatService().sendMessage(widget.roomId, text);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorReporter.toFailure(e).message)),
        );
        // Текст не втрачається — повертаємо його в поле, щоб не набирати знову.
        _messageController.text = text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      appBar: _buildAppBar(), // Винесли в окремий метод
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: AppTheme.backgroundGradient(context),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 🔥 STREAM BUILDER (Слухає базу в реальному часі)
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _messagesStream, // Використовуємо нашу змінну! // Старі зверху, нові знизу
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Помилка: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!;
                    
                    // Автоскрол до низу при нових повідомленнях
                    if (messages.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context)!.write_first_message,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == _supabase.auth.currentUser!.id;
                        return _buildMessageBubble(msg, isMe);
                      },
                    );
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(widget.userPhoto),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName, // Ім'я береться з параметрів
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!widget.isGroup)
                  Text(
                    widget.isOnline ? 'Онлайн' : 'Офлайн',
                    style: TextStyle(
                      color: widget.isOnline ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final content = message['content'] ?? '';
    final time = DateTime.parse(message['created_at']).toLocal();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFF3E5F5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(time),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    (message['is_read'] ?? false) ? Icons.done_all : Icons.done,
                    size: 14,
                    color: (message['is_read'] ?? false) ? Colors.blue : Colors.grey,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white, // Білий фон тепер заллє весь низ екрану
      child: SafeArea( // Захищаємо контент від налізання на Home Indicator
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.message_hint,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: const CircleAvatar( // Прибрав const з Color і додав сюди
                  backgroundColor: Color(0xFFF3E5F5),
                  child: Icon(Icons.send, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
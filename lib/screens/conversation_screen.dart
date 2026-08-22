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

  /// Підписку треба тримати, щоб скасувати її при виході: інакше слухач
  /// живе далі й продовжує позначати повідомлення прочитаними вже після
  /// того, як екран закрито.
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  /// Повідомлення тримаємо в стані, а не малюємо через StreamBuilder.
  ///
  /// Кожне прослуховування supabase-стріму піднімає власний канал реального
  /// часу й робить власне повне завантаження. Слухач у initState разом зі
  /// StreamBuilder у build давали два канали на одну кімнату: подвійний
  /// трафік і подвійна обробка кожної події.
  List<Map<String, dynamic>>? _messages;
  Object? _messagesError;

  /// Скільки останніх повідомлень тримаємо на екрані.
  static const int _pageSize = 60;

  /// Повідомлення, які вже позначено прочитаними в цьому відкритті.
  ///
  /// Це і є запобіжник від зациклення: слухач стріму сам змінює таблицю,
  /// на яку підписаний, тож без нього кожна відповідь сервера знову
  /// запускала оновлення — і застосунок захлинався запитами.
  final Set<String> _markedRead = {};

  @override
  void initState() {
    super.initState();
    // Перший знімок стріму приходить одразу після підписки, і саме він
    // запускає позначення прочитаним — окремий виклик тут зайвий.

    // 2. Ініціалізуємо стрім один раз
    // Останні _pageSize повідомлень, а не вся історія: стрім тримає всі
    // отримані рядки в пам'яті й переобробляє їх на кожну подію, тож у
    // довгому листуванні відкриття чату дорожчало б із кожним днем.
    // Порядок спадний, бо ліміт має відрізати старе; на екрані список
    // розвертається назад.
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at', ascending: false)
        .limit(_pageSize);

    // 3. Нові повідомлення від співрозмовника одразу позначаємо прочитаними.
    _messagesSub = _messagesStream.listen(
      (messages) {
        if (!mounted) return;
        // Стрім віддає найновіші першими — на екрані потрібен зворотний порядок.
        final ordered = messages.reversed.toList(growable: false);
        setState(() {
          _messages = ordered;
          _messagesError = null;
        });
        _markMessagesAsRead(ordered);
      },
      onError: (Object e) {
        if (mounted) setState(() => _messagesError = e);
      },
    );
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Позначає прочитаними тільки ті повідомлення, які ще не позначали.
  ///
  /// Раніше метод оновлював усі непрочитані щоразу, коли стрім щось віддавав,
  /// і додатково переписував `rooms.last_message` тим самим значенням, щоб
  /// «розбудити» список чатів. Обидві дії змінюють таблиці, на які підписані
  /// стріми, тож відповідь сервера запускала наступний виток — і так по колу.
  Future<void> _markMessagesAsRead(List<Map<String, dynamic>> messages) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    final pending = messages
        .where((m) => m['sender_id'] != myId && m['is_read'] == false)
        .map((m) => m['id'].toString())
        .where(_markedRead.add)
        .toList();

    // Нічого нового — і будити список чатів немає підстав.
    if (pending.isEmpty) return;

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true}).inFilter('id', pending);

      // Список чатів слухає зміни кімнат, тож лічильник непрочитаних
      // оновлюється лише після справжньої зміни — не на кожну подію стріму.
      final room = await _supabase
          .from('rooms')
          .select('last_message')
          .eq('id', widget.roomId)
          .single();
      await _supabase.from('rooms').update(
          {'last_message': room['last_message']}).eq('id', widget.roomId);
    } catch (e) {
      // Позначку знімаємо, щоб наступна спроба була можливою.
      _markedRead.removeAll(pending);
      debugPrint('Не вдалося позначити прочитаним: $e');
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
          SnackBar(content: Text(ErrorReporter.message(context, e))),
        );
        // Текст не втрачається — повертаємо його в поле, щоб не набирати знову.
        _messageController.text = text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

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
              Expanded(child: _buildMessageList()),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface),
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
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!widget.isGroup)
                  Text(
                    widget.isOnline
                        ? AppLocalizations.of(context)!.online
                        : AppLocalizations.of(context)!.offline,
                    style: TextStyle(
                      color: widget.isOnline
                          ? Theme.of(context).extension<AppSemantics>()!.success
                          : Colors.grey,
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

  Widget _buildMessageList() {
    if (_messagesError != null) {
      return Center(
          child: Text(ErrorReporter.message(context, _messagesError!)));
    }

    final messages = _messages;
    if (messages == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.write_first_message,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Автоскрол до низу при нових повідомленнях.
    //
    // Якщо людина сама піднялася вгору читати старе листування, смикати її
    // вниз не можна — тому зсуваємось лише коли вона й так біля кінця.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final distanceToBottom = pos.maxScrollExtent - pos.pixels;
      if (distanceToBottom < 4) return;

      if (distanceToBottom > 600) {
        // Здалеку анімація нічого не показує — тільки гальмує.
        _scrollController.jumpTo(pos.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          pos.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final myId = _supabase.auth.currentUser?.id;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildMessageBubble(msg, msg['sender_id'] == myId);
      },
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
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft:
                isMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(time),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    (message['is_read'] ?? false) ? Icons.done_all : Icons.done,
                    size: 14,
                    color: (message['is_read'] ?? false)
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
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
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        // Захищаємо контент від налізання на Home Indicator
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
                    fillColor: Theme.of(context).colorScheme.outlineVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.send,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

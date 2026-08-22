import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/locale_provider.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'conversation_screen.dart';
import '../service/chat_service.dart';
import '../service/error_reporter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  Set<String> _onlineUsers = {};
  final Map<String, bool> _typingUsers = {};
  Timer? _refreshTimer; // Додано таймер для автоматичного оновлення часу

  @override
  void initState() {
    super.initState();
    _initRealtime();
    // Таймер оновлює екран щохвилини, щоб час "Зараз" змінювався на цифри
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _initRealtime() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId != null) {
      _chatService.subscribeToPresence(myId, (ids) {
        if (mounted) setState(() => _onlineUsers = ids);
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Відключаємо таймер
    _chatService.unsubscribeFromPresence();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(Map<String, dynamic> chat,
      {required bool isOnline}) async {
    final roomId = chat['room_id'].toString();
    final isGroup = chat['type'] == 'group';

    final name = isGroup
        ? chat['name']
        : (chat['other_user_name'] ?? AppLocalizations.of(context)!.ch_user);

    // 👇 РОЗУМНЕ ВИЗНАЧЕННЯ ФОТО (Універсальне для обох типів)
    String photoUrl;
    if (isGroup) {
      // Якщо група - беремо фото групи
      photoUrl = chat['photo'] ??
          'https://ui-avatars.com/api/?name=Group&format=png&background=random';
    } else {
      // Якщо приватний - беремо фото співрозмовника
      photoUrl = chat['other_user_photo'] ??
          'https://ui-avatars.com/api/?name=User&format=png&background=random';
    }
    final navigator = Navigator.of(context);

    try {
      // Позначення прочитаним більше не тримає перехід: екран розмови робить
      // це сам, щойно отримує список. Раніше тап по чату чекав на мережевий
      // запит, і на повільному зв'язку виглядав як зависання.
      unawaited(_chatService.markMessagesAsRead(roomId));

      await navigator.push(
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            roomId: roomId,
            userName: name,
            userPhoto: photoUrl,
            isOnline: isOnline,
            isGroup: isGroup,
            otherUserId: chat['other_user_id']?.toString() ?? '',
          ),
        ),
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error opening chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: Ds.background(context),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildSearchBar(),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _chatService.getMyChatsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          final failure =
                              ErrorReporter.toFailure(snapshot.error!);
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  failure.localized(context),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => setState(() {}),
                                  child: Text(
                                      AppLocalizations.of(context)!.try_again),
                                ),
                              ],
                            ),
                          );
                        }

                        final conversations = snapshot.data ?? [];
                        final filtered = conversations.where((chat) {
                          final name = chat['type'] == 'group'
                              ? chat['name']
                              : chat['other_user_name'] ??
                                  AppLocalizations.of(context)!.ch_user;
                          return name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase());
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                              child: Text(AppLocalizations.of(context)!
                                      .no_chats_yet ??
                                  AppLocalizations.of(context)!.no_chats_yet));
                        }

                        return Column(
                          children: [
                            _buildActiveContacts(filtered),
                            _buildMessagesHeader(),
                            Expanded(child: _buildConversationsList(filtered)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveContacts(List<Map<String, dynamic>> chats) {
    final onlineFriends = chats.where((c) {
      return c['type'] == 'private' &&
          _onlineUsers.contains(c['other_user_id']);
    }).toList();

    if (onlineFriends.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(
            AppLocalizations.of(context)!.online_now.toUpperCase(),
            style: Ds.label(context),
          ),
        ),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: onlineFriends.length,
            itemBuilder: (context, index) {
              final friend = onlineFriends[index];
              final name = friend['other_user_name'] ?? '';
              final photo = friend['other_user_photo'] as String?;

              return GestureDetector(
                onTap: () => _openChat(friend, isOnline: true),
                child: Container(
                  width: 64,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          DsAvatar(initial: name, photoUrl: photo, size: 56),
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .extension<AppSemantics>()!
                                    .online,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: scheme.surface, width: 2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Ds.tiny(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConversationsList(List<Map<String, dynamic>> conversations) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      itemCount: conversations.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: scheme.outlineVariant),
      itemBuilder: (context, index) => _chatRow(conversations[index], scheme),
    );
  }

  /// Один рядок списку за `design/Chats.dc.html`.
  ///
  /// Груповий чат має квадратний аватар зі скругленням, приватний — круглий.
  /// Це єдина ознака, за якою вони розрізняються з першого погляду.
  Widget _chatRow(Map<String, dynamic> chat, ColorScheme scheme) {
    final t = AppLocalizations.of(context)!;
    final isGroup = chat['type'] == 'group';

    final name = isGroup
        ? (chat['name'] ?? t.ch_unknown)
        : (chat['other_user_name'] ?? t.ch_unknown);
    final photo =
        (isGroup ? chat['photo'] : chat['other_user_photo']) as String?;

    final lastMsg = chat['last_message'] ?? '';
    final unread = (chat['unread_count'] ?? 0) as int;
    final roomId = chat['room_id'];
    final isOnline = !isGroup && _onlineUsers.contains(chat['other_user_id']);
    final isTyping = _typingUsers[roomId] == true;

    // Сервер віддає час у UTC; якщо він опиняється в майбутньому, зсув уже
    // застосовано двічі — знімаємо його.
    DateTime? parsedTime;
    if (chat['last_message_time'] != null) {
      try {
        parsedTime = DateTime.parse(chat['last_message_time'].toString().trim())
            .toLocal();
        final now = DateTime.now();
        if (parsedTime.isAfter(now.add(const Duration(minutes: 1)))) {
          parsedTime = parsedTime.subtract(now.timeZoneOffset);
        }
      } catch (e) {
        debugPrint('Time parsing error: $e');
      }
    }

    return InkWell(
      onTap: () => _openChat(chat, isOnline: isOnline),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isGroup ? 16 : 26),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: photo != null && photo.isNotEmpty
                          ? Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => DsPhotoBlock(
                                  initial: name, fontSize: 19, radius: 0),
                            )
                          : DsPhotoBlock(
                              initial: name, fontSize: 19, radius: 0),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .extension<AppSemantics>()!
                              .online,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ds.body(context),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isTyping ? t.typing_now : lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ds.tiny(context).copyWith(
                      color:
                          isTyping ? scheme.primary : scheme.onSurfaceVariant,
                      fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                      fontWeight:
                          unread > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  parsedTime != null ? _formatTime(parsedTime) : '',
                  style: Ds.tiny(context),
                ),
                if (unread > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unread',
                      style: TextStyle(
                        // Раніше тут стояв onSurface: на світлій темі це майже
                        // чорний текст на синьому кружку.
                        color: scheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.chats,
            style: Ds.h1(context).copyWith(fontSize: 24),
          ),
          const Spacer(),
          Material(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(Ds.rTile),
            child: InkWell(
              borderRadius: BorderRadius.circular(Ds.rTile),
              onTap: _showGroupOptionsDialog,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DsSearchField(
        hint: AppLocalizations.of(context)!.search_contacts,
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildMessagesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      child: Text(
        AppLocalizations.of(context)!.messages.toUpperCase(),
        style: Ds.label(context),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    // Якщо менше 60 сек
    if (difference.inSeconds.abs() < 60) {
      return AppLocalizations.of(context)?.now ??
          AppLocalizations.of(context)!.ch_now;
    }

    // Сьогодні
    if ((now.year == time.year &&
            now.month == time.month &&
            now.day == time.day) ||
        time.isAfter(now)) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }

    // Вчора
    final yesterday = now.subtract(const Duration(days: 1));
    if (time.year == yesterday.year &&
        time.month == yesterday.month &&
        time.day == yesterday.day) {
      return AppLocalizations.of(context)!.ch_yesterday;
    }

    // Інші дні
    return "${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}";
  }

  void _showGroupOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              AppLocalizations.of(context)!.create_group ?? 'Create Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  leading: const Icon(Icons.group_add),
                  title: Text(AppLocalizations.of(context)!.private_group ??
                      'Private Group'),
                  onTap: () => Navigator.of(context).pop()),
              ListTile(
                  leading: const Icon(Icons.public),
                  title: Text(AppLocalizations.of(context)!.public_group ??
                      'Public Group'),
                  onTap: () => Navigator.of(context).pop()),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel ?? 'Cancel'))
          ],
        );
      },
    );
  }
}

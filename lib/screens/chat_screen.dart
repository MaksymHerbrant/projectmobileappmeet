import '../theme/app_theme.dart';
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

  Future<void> _openChat(Map<String, dynamic> chat, {required bool isOnline}) async {
    final roomId = chat['room_id'].toString();
    final isGroup = chat['type'] == 'group';

    final name = isGroup ? chat['name'] : (chat['other_user_name'] ?? 'Користувач');

    // 👇 РОЗУМНЕ ВИЗНАЧЕННЯ ФОТО (Універсальне для обох типів)
    String photoUrl;
    if (isGroup) {
      // Якщо група - беремо фото групи
      photoUrl = chat['photo'] ?? 'https://ui-avatars.com/api/?name=Group&format=png&background=random';
    } else {
      // Якщо приватний - беремо фото співрозмовника
      photoUrl = chat['other_user_photo'] ?? 'https://ui-avatars.com/api/?name=User&format=png&background=random';
    }
    final navigator = Navigator.of(context);

    try {
      await _chatService.markMessagesAsRead(roomId);
      if (!mounted) return;

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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: AppTheme.backgroundGradient(context),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildSearchBar(),
                  
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _chatService.getMyChatsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          final failure =
                              ErrorReporter.toFailure(snapshot.error!);
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  failure.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => setState(() {}),
                                  child: Text(AppLocalizations.of(context)!.try_again),
                                ),
                              ],
                            ),
                          );
                        }

                        final conversations = snapshot.data ?? [];
                        final filtered = conversations.where((chat) {
                          final name = chat['type'] == 'group' ? chat['name'] : chat['other_user_name'] ?? 'Користувач';
                          return name.toLowerCase().contains(_searchQuery.toLowerCase());
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(child: Text(AppLocalizations.of(context)!.no_chats_yet ?? 'Чатів ще немає'));
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
      return c['type'] == 'private' && _onlineUsers.contains(c['other_user_id']);
    }).toList();

    if (onlineFriends.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: onlineFriends.length,
        itemBuilder: (context, index) {
          final friend = onlineFriends[index];
          final photo = friend['other_user_photo'] ?? 'https://ui-avatars.com/api/?name=${friend['other_user_name'] ?? 'User'}&format=png';
          final name = friend['other_user_name'] ?? 'User';

          return GestureDetector(
            onTap: () => _openChat(friend, isOnline: true),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 2)),
                        child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.network(photo, fit: BoxFit.cover)),
                      ),
                      Positioned(right: 0, bottom: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationsList(List<Map<String, dynamic>> conversations) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final chat = conversations[index];
        final isGroup = chat['type'] == 'group';
        
        // 👇 УНІВЕРСАЛЬНЕ ВИЗНАЧЕННЯ ІМЕНІ ТА ФОТО ПРЯМО ТУТ
        final name = isGroup ? chat['name'] : (chat['other_user_name'] ?? 'Невідомий');
        
        // Вибираємо правильне джерело фото і правильну PNG-заглушку
        String photo;
        if (isGroup) {
          // Для груп беремо поле 'photo' (з avatar_url у ChatService)
          photo = chat['photo'] ?? 'https://ui-avatars.com/api/?name=${name}&format=png&background=random';
        } else {
          // Для приватних чатів беремо фото співрозмовника
          photo = chat['other_user_photo'] ?? 'https://ui-avatars.com/api/?name=${name}&format=png&background=random';
        }

        final lastMsg = chat['last_message'] ?? '';
        
        // ЄДИНЕ ОГОЛОШЕННЯ ЧАСУ, гарантує правильний парсинг
        // ЄДИНЕ ОГОЛОШЕННЯ ЧАСУ з автоматичною корекцією часових поясів
        DateTime? parsedTime;
        if (chat['last_message_time'] != null) {
          try {
            String timeStr = chat['last_message_time'].toString().trim();
            parsedTime = DateTime.parse(timeStr).toLocal();
            
            // РОЗУМНА КОРЕКЦІЯ: 
            // Якщо час повідомлення більший за поточний час (полетів у майбутнє на 2 години),
            // ми просто віднімаємо локальний зсув (ваші +2 години).
            final now = DateTime.now();
            if (parsedTime.isAfter(now.add(const Duration(minutes: 1)))) {
              parsedTime = parsedTime.subtract(now.timeZoneOffset);
            }
            
          } catch (e) {
            debugPrint("Time parsing error: $e");
          }
        }
        
        final unread = chat['unread_count'] ?? 0;
        final roomId = chat['room_id'];
        final isOnline = !isGroup && _onlineUsers.contains(chat['other_user_id']);
        final isTyping = _typingUsers[roomId] == true;
        
        return GestureDetector(
          onTap: () => _openChat(chat, isOnline: isOnline),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isOnline ? Colors.green : Colors.grey.shade300, width: 2)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.network(photo, fit: BoxFit.cover)),
                    ),
                    if (isOnline) Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black))),
                          Text(
                            parsedTime != null ? _formatTime(parsedTime) : '', // ТЕПЕР ПРАЦЮЄ КОРЕКТНО
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isTyping ? '${AppLocalizations.of(context)!.typing ?? "Друкує"}...' : lastMsg,
                              style: TextStyle(fontSize: 14, color: isTyping ? Colors.blue : Colors.grey.shade600, fontStyle: isTyping ? FontStyle.italic : FontStyle.normal, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.all(Radius.circular(10))),
                              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppLocalizations.of(context)!.chats, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
          GestureDetector(
            onTap: _showGroupOptionsDialog,
            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.add, color: Colors.white, size: 24)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(25)),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(hintText: AppLocalizations.of(context)!.search_contacts, border: InputBorder.none, icon: const Icon(Icons.search, color: Colors.grey)),
      ),
    );
  }
  
  Widget _buildMessagesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(children: [Text(AppLocalizations.of(context)!.messages, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    // Якщо менше 60 сек
    if (difference.inSeconds.abs() < 60) {
      return AppLocalizations.of(context)?.now ?? 'Зараз';
    }
    
    // Сьогодні
    if ((now.year == time.year && now.month == time.month && now.day == time.day) || time.isAfter(now)) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
    
    // Вчора
    final yesterday = now.subtract(const Duration(days: 1));
    if (time.year == yesterday.year && time.month == yesterday.month && time.day == yesterday.day) {
      return "Вчора";
    }

    // Інші дні
    return "${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}";
  }

  void _showGroupOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.create_group ?? 'Create Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.group_add), title: Text(AppLocalizations.of(context)!.private_group ?? 'Private Group'), onTap: () => Navigator.of(context).pop()),
              ListTile(leading: const Icon(Icons.public), title: Text(AppLocalizations.of(context)!.public_group ?? 'Public Group'), onTap: () => Navigator.of(context).pop()),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel ?? 'Cancel'))],
        );
      },
    );
  }
}
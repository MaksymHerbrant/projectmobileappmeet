import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'conversation_screen.dart';
import 'profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Активні контакти (stories)
  final List<ActiveContact> activeContacts = [
    ActiveContact(
      id: '1',
      name: 'Ти',
      photo: 'assets/images/portrait-man-laughing.jpg',
      isOnline: true,
    ),
    ActiveContact(
      id: '2',
      name: 'Роман',
      photo: 'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
      hasNewStory: true,
      isOnline: true,
    ),
    ActiveContact(
      id: '3',
      name: 'Яна',
      photo: 'assets/images/selfie-portrait-videocall.jpg',
      isOnline: false,
    ),
    ActiveContact(
      id: '4',
      name: 'Андрій',
      photo: 'assets/images/pleased-smiling-man-with-beard-looking-camera.jpg',
      isOnline: true,
    ),
  ];

  // Список чатів
  final List<ChatConversation> conversations = [
    ChatConversation(
      id: '1',
      userId: '2',
      userName: 'Роман',
      userPhoto: 'assets/images/close-up-portrait-curly-handsome-european-male.jpg',
      lastMessage: 'Пише..',
      lastMessageTime: DateTime.now(),
      unreadCount: 5,
      isOnline: true,
      isTyping: true,
    ),
    ChatConversation(
      id: '2',
      userId: '5',
      userName: 'Максим',
      userPhoto: 'assets/images/portrait-man-laughing.jpg',
      lastMessage: 'Ти: Привіт, як справи?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 0,
      isOnline: false,
    ),
    ChatConversation(
      id: '3',
      userId: '3',
      userName: 'Яна',
      userPhoto: 'assets/images/selfie-portrait-videocall.jpg',
      lastMessage: 'Коли зустрінемося?',
      lastMessageTime: DateTime.now(),
      unreadCount: 3,
      isOnline: true,
    ),
    ChatConversation(
      id: '4',
      userId: '4',
      userName: 'Андрій',
      userPhoto: 'assets/images/pleased-smiling-man-with-beard-looking-camera.jpg',
      lastMessage: 'Йдеш сьогодні в кафе?',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
      isOnline: true,
    ),
  ];

  List<ChatConversation> get filteredConversations {
    if (_searchQuery.isEmpty) {
      return conversations;
    }
    return conversations.where((conversation) {
      return conversation.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             conversation.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFF3E5F5), Colors.white],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Верхня панель з заголовком та фільтром
                  _buildTopBar(),
                  
                  // Пошук
                  _buildSearchBar(),
                  
                  // Активні контакти (stories)
                  _buildActiveContacts(),
                  
                  // Заголовок повідомлень
                  _buildMessagesHeader(),
                  
                  // Список повідомлень
                  Expanded(
                    child: _buildConversationsList(),
                  ),
                ],
              ),
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
        children: [
          // Заголовок
          Text(
            AppLocalizations.of(context)!.chats,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const Spacer(),
          
          // Кнопка коментаря
          GestureDetector(
            onTap: () {
              _showGroupOptionsDialog();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.comment,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Кнопка фільтра
          GestureDetector(
            onTap: () {
              // Логіка фільтрації
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/icons/filter.png',
                width: 20,
                height: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/search.png',
            width: 20,
            height: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search_contacts,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContacts() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: activeContacts.length,
        itemBuilder: (context, index) {
          final contact = activeContacts[index];
          return Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: contact.isOnline ? Colors.green : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          contact.photo,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (contact.hasNewStory)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.messages,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        return GestureDetector(
          onTap: () {
                         Navigator.of(context).push(
               MaterialPageRoute(
                 builder: (context) => ConversationScreen(
                   userName: conversation.userName,
                   userPhoto: conversation.userPhoto,
                   isOnline: conversation.isOnline,
                 ),
               ),
             );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Аватар
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: conversation.isOnline ? Colors.green : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          conversation.userPhoto,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (conversation.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Інформація про чат
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(conversation.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.isTyping 
                                ? AppLocalizations.of(context)!.typing
                                : conversation.lastMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: conversation.isTyping 
                                  ? Colors.blue 
                                  : Colors.grey.shade600,
                                fontStyle: conversation.isTyping 
                                  ? FontStyle.italic 
                                  : FontStyle.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return DateFormat('dd.MM').format(time);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}г';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}хв';
    } else {
      return 'зараз';
    }
  }

  void _showGroupOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.create_group),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.group_add),
                title: Text(AppLocalizations.of(context)!.private_group),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCreateGroupDialog(true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(AppLocalizations.of(context)!.public_group),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCreateGroupDialog(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: Text(AppLocalizations.of(context)!.join_group),
                onTap: () {
                  Navigator.of(context).pop();
                  _showJoinGroupDialog();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showCreateGroupDialog(bool isPrivate) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isPrivate 
            ? AppLocalizations.of(context)!.private_group
            : AppLocalizations.of(context)!.public_group),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.group_name,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.group_description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessDialog(
                  'Група "${nameController.text}" створена успішно!',
                );
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  void _showJoinGroupDialog() {
    final mockGroups = [
      {
        'name': 'Київські вечірки',
        'members': 45,
        'description': 'Організація вечірок у Києві',
      },
      {
        'name': 'Походи в Карпати',
        'members': 23,
        'description': 'Група для організації походів',
      },
      {
        'name': 'Фотографія',
        'members': 67,
        'description': 'Спільнота фотографів',
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.join_group),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: mockGroups.map((group) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${group['members']} ${AppLocalizations.of(context)!.group_members} • ${group['description']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showSuccessDialog(
                                '${AppLocalizations.of(context)!.group_joined} "${group['name']}"!',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3E5F5),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.join,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.success),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }


} 
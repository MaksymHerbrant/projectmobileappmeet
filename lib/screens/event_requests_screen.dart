import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'user_profile_view_screen.dart';

class EventRequestsScreen extends StatefulWidget {
  final Event event;
  
  const EventRequestsScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventRequestsScreen> createState() => _EventRequestsScreenState();
}

class _EventRequestsScreenState extends State<EventRequestsScreen> {
  
  // Мокові дані для запитів на подію
  final List<Map<String, dynamic>> _eventRequests = [
    {
      'user': UserProfile(
        id: '1',
        name: 'Марія',
        age: 24,
        description: 'Люблю активний відпочинок та нові знайомства',
        photos: ['assets/images/uifaces-popular-image-3.jpg'],
        location: 'Київ',
        hobbies: ['Походи', 'Фотографія', 'Спорт'],
      ),
      'message': 'Дуже хочу приєднатися до походу! Маю досвід в горах.',
      'hasMessage': true,
    },
    {
      'user': UserProfile(
        id: '2',
        name: 'Андрій',
        age: 26,
        description: 'Шукаю компанію для активного відпочинку',
        photos: ['assets/images/uifaces-popular-image-7.jpg'],
        location: 'Львів',
        hobbies: ['Гори', 'Походи', 'Природа'],
      ),
      'message': null,
      'hasMessage': false,
    },
    {
      'user': UserProfile(
        id: '3',
        name: 'Катерина',
        age: 23,
        description: 'Люблю подорожувати та знайомитися з новими людьми',
        photos: ['assets/images/uifaces-popular-image-5.jpg'],
        location: 'Харків',
        hobbies: ['Подорожі', 'Фотографія', 'Книги'],
      ),
      'message': 'Привіт! Це буде мій перший похід, але дуже хочу спробувати!',
      'hasMessage': true,
    },
  ];



  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
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
              _buildTopBar(),
              Expanded(
                child: _buildRequestsList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.event_requests,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_eventRequests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _eventRequests.length,
      itemBuilder: (context, index) {
        final item = _eventRequests[index];
        return _buildUserCardWithMessage(
          item['user'], 
          item['message'], 
          item['hasMessage']
        );
      },
    );
  }

  Widget _buildUserCardWithMessage(UserProfile user, String? message, bool hasMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Фото та основна інформація
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: AssetImage(user.photos.first),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                // Іконка інформації в правому верхньому куті
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showUserMenu(context, user),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/icons/info.png',
                        width: 18,
                        height: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Інформація внизу фото
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${user.name}, ${user.age}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                            Text(
                              user.location,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Інтереси
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.common_interests,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: user.hobbies.take(3).map((hobby) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 30, 111, 233).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color.fromARGB(255, 30, 91, 233).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        hobby,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 30, 101, 233),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Повідомлення (якщо є)
          if (hasMessage && message != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 76, 120, 175).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 76, 120, 175).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.message,
                        size: 16,
                        color: const Color.fromARGB(255, 76, 120, 175),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.message,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 76, 120, 175),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Кнопки дій
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.close,
                    color: const Color.fromARGB(255, 126, 126, 126),
                    onTap: () => _handleReject(user),
                    label: AppLocalizations.of(context)!.reject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    icon: Icons.check,
                    color: const Color.fromARGB(255, 76, 175, 80),
                    onTap: () => _handleAccept(user),
                    label: AppLocalizations.of(context)!.accept,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.people,
                size: 48,
                color: const Color.fromARGB(255, 76, 120, 175),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.no_event_requests,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.no_event_requests_subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleAccept(UserProfile user) {
    setState(() {
      _eventRequests.removeWhere((item) => item['user'].id == user.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} прийнято до події!'),
        backgroundColor: const Color.fromARGB(255, 76, 175, 80),
      ),
    );
  }

  void _handleReject(UserProfile user) {
    setState(() {
      _eventRequests.removeWhere((item) => item['user'].id == user.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} відхилено'),
        backgroundColor: const Color.fromARGB(255, 126, 126, 126),
      ),
    );
  }

  void _showUserMenu(BuildContext context, UserProfile user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person, color: Color.fromARGB(255, 76, 120, 175)),
                title: Text(
                  AppLocalizations.of(context)!.view_profile,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleViewProfile(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text(
                  AppLocalizations.of(context)!.block_user,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleBlockUser(user);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _handleViewProfile(UserProfile user) {
    // Навігація до профілю користувача
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(user: user),
      ),
    );
  }

  void _handleBlockUser(UserProfile user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLocalizations.of(context)!.block_user_title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.block_user_message(user.name),
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _eventRequests.removeWhere((item) => item['user'].id == user.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.name} заблоковано'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.block,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


} 
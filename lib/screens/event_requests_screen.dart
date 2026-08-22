import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import '../service/matches_service.dart'; // 👇 Імпорт сервісу
import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'chat_screen.dart'; // Якщо плануєш перехід в чат
import 'user_profile_view_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventRequestsScreen extends StatefulWidget {
  final Event event;

  const EventRequestsScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventRequestsScreen> createState() => _EventRequestsScreenState();
}

class _EventRequestsScreenState extends State<EventRequestsScreen> {
  final _matchesService = MatchesService(); // 👇
  bool _isLoading = true;
  List<Map<String, dynamic>> _eventRequests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      // 1. Завантажуємо заявки з бази
      final requests =
          await _matchesService.getRequestsForEvent(widget.event.id);

      // 2. Отримуємо дані поточного користувача (ТЕБЕ), щоб було з чим порівнювати
      final myId = Supabase.instance.client.auth.currentUser!.id;
      final myProfileData = await Supabase.instance.client
          .from('profiles')
          .select('hobbies, location')
          .eq('id', myId)
          .single();

      final List<String> myHobbies =
          List<String>.from(myProfileData['hobbies'] ?? []);
      final String myLocation = myProfileData['location'] ?? '';

      // 3. ✨ АЛГОРИТМ КОРИСНОЇ СХОЖОСТІ
      for (var request in requests) {
        final user = request['user'] as UserProfile;
        int matchScore = 0;

        // А) Спільна локація (+20 балів)
        if (user.location == myLocation) {
          matchScore += 20;
        }

        // Б) Спільні інтереси (+10 балів за кожен збіг)
        final commonHobbiesCount =
            user.hobbies.where((hobby) => myHobbies.contains(hobby)).length;
        matchScore += (commonHobbiesCount * 10);

        // В) Наявність повідомлення (+5 балів, бо людина проявила ініціативу)
        if (request['hasMessage'] == true) {
          matchScore += 5;
        }

        // Зберігаємо бал у мапу запиту
        request['match_score'] = matchScore;
      }

      // 4. Сортуємо список: від найбільшого балу до найменшого
      requests.sort((a, b) =>
          (b['match_score'] as int).compareTo(a['match_score'] as int));

      if (mounted) {
        setState(() {
          _eventRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Помилка завантаження заявок: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Хелпер для фото
  ImageProvider _getImageProvider(List<String>? photos) {
    if (photos == null || photos.isEmpty)
      return const NetworkImage(
          'https://ui-avatars.com/api/?name=User&format=png&background=random');
    final path = photos.first;
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.contains('placeholder'))
      return const NetworkImage(
          'https://ui-avatars.com/api/?name=User&format=png&background=random');
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildRequestsList(),
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
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.event_requests,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                Text(
                  widget.event.title,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
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
          item['user'] as UserProfile,
          item['message'] as String?,
          item['hasMessage'] as bool,
          item['request_id'] as String, // ID заявки для прийняття/відхилення
        );
      },
    );
  }

  Widget _buildUserCardWithMessage(
      UserProfile user, String? message, bool hasMessage, String requestId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Фото та основна інформація
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: _getImageProvider(user.photos), // 🟢 Фікс картинок
                fit: BoxFit.cover,
                onError: (e, s) => debugPrint('Фото не завантажилось'),
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6)
                      ],
                    ),
                  ),
                ),
                // Іконка інформації
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showUserMenu(context, user, requestId),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child:
                          const Icon(Icons.info, color: Colors.white, size: 18),
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
                            Text('${user.name}, ${user.age}',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Icon(Icons.location_on,
                                color: Colors.white.withOpacity(0.8), size: 16),
                            Text(user.location,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14)),
                          ],
                        ),
                        if (user.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(user.description,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Інтереси
          if (user.hobbies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.common_interests,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: user.hobbies.take(3).map((hobby) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 30, 111, 233)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color.fromARGB(255, 30, 91, 233)
                                  .withOpacity(0.3),
                              width: 1),
                        ),
                        child: Text(hobby,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 30, 101, 233),
                                fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Повідомлення (якщо є)
          if (hasMessage && message != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 76, 120, 175).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color.fromARGB(255, 76, 120, 175)
                        .withOpacity(0.3),
                    width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.message,
                          size: 16, color: Color.fromARGB(255, 76, 120, 175)),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.message,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 76, 120, 175))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(message,
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),
          ],

          // Кнопки дій
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.close,
                    color: const Color.fromARGB(255, 126, 126, 126),
                    onTap: () => _handleReject(requestId, user.name),
                    label: AppLocalizations.of(context)!.reject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    icon: Icons.check,
                    color: const Color.fromARGB(255, 76, 175, 80),
                    onTap: () => _handleAccept(requestId, user.name),
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

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap,
      required String label}) {
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
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
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
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.people,
                  size: 48, color: Color.fromARGB(255, 76, 120, 175)),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.no_event_requests,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.no_event_requests_subtitle,
              style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 Обробка Прийняття
  Future<void> _handleAccept(String requestId, String userName) async {
    try {
      await _matchesService.respondToEventRequest(requestId, 'accepted');
      setState(() {
        _eventRequests.removeWhere((item) => item['request_id'] == requestId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.user_accepted(userName)),
              backgroundColor:
                  Theme.of(context).extension<AppSemantics>()!.success),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
          backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  // 🟢 Обробка Відхилення
  Future<void> _handleReject(String requestId, String userName) async {
    try {
      await _matchesService.respondToEventRequest(requestId, 'declined');
      setState(() {
        _eventRequests.removeWhere((item) => item['request_id'] == requestId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.user_declined(userName)),
              backgroundColor: Colors.grey),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
          backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  void _showUserMenu(BuildContext context, UserProfile user, String requestId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person,
                    color: Color.fromARGB(255, 76, 120, 175)),
                title: Text(AppLocalizations.of(context)!.view_profile,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _handleViewProfile(user);
                },
              ),
              ListTile(
                leading: Icon(Icons.block,
                    color: Theme.of(context).colorScheme.error),
                title: Text(AppLocalizations.of(context)!.block_user,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _handleReject(requestId,
                      user.name); // Блокування поки працює як відхилення
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
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(user: user)));
  }
}

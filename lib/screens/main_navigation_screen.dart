import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

import '../theme/design_kit.dart';
import 'chat_screen.dart';
import 'main_feed_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';

/// Каркас застосунку: чотири розділи й нижня навігація з `design/Feed.dc.html`.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex = widget.initialIndex;

  /// Вкладки, які людина вже відкривала.
  ///
  /// IndexedStack будує всіх своїх дітей одразу, тож при вході стартували
  /// разом: геолокація і стрічка, підписка на чати з опитуванням присутності,
  /// завантаження заявок і профіль. Через це вхід і тягнувся. Тепер вкладка
  /// створюється при першому відкритті — а далі IndexedStack тримає її
  /// живою, тож стан між перемиканнями не втрачається.
  late final Set<int> _visited = {widget.initialIndex};

  Widget _tab(int index) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    return switch (index) {
      0 => const MainFeedScreen(),
      1 => const ChatScreen(),
      2 => const MatchesScreen(),
      _ => const ProfileScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [for (var i = 0; i < 4; i++) _tab(i)],
      ),
      bottomNavigationBar: DsNavBar(
        index: _currentIndex,
        onChanged: (i) => setState(() {
          _visited.add(i);
          _currentIndex = i;
        }),
        items: [
          DsNavItem(icon: Icons.style_outlined, label: t.nav_feed),
          DsNavItem(icon: Icons.mail_outline_rounded, label: t.nav_chats),
          DsNavItem(icon: Icons.favorite_border_rounded, label: t.nav_matches),
          DsNavItem(icon: Icons.person_outline_rounded, label: t.nav_profile),
        ],
      ),
    );
  }
}

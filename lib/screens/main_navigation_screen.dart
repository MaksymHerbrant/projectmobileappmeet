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

  static const List<Widget> _screens = [
    MainFeedScreen(),
    ChatScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      // IndexedStack сам тримає всі чотири екрани живими, тож перемальовувати
      // його через AnimatedSwitcher означало б скидати стан при кожному
      // перемиканні — саме те, чого IndexedStack і уникає.
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: DsNavBar(
        index: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
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

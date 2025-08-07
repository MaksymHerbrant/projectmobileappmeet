import 'package:flutter/material.dart';
import 'main_feed_screen.dart';
import 'chat_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigationScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const MainFeedScreen(),
    const ChatScreen(),
    const MatchesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
        child: IndexedStack(
          key: ValueKey(_currentIndex),
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFF3E5F5),
        padding: const EdgeInsets.only(top: 20, bottom: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/icons/cards_8531803.png',
                  width: 32,
                  height: 32,
                  color: _currentIndex == 0 ? Colors.black : Colors.grey,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/icons/email_2099199.png',
                  width: 32,
                  height: 32,
                  color: _currentIndex == 1 ? Colors.black : Colors.grey,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/icons/heart-2.png',
                  width: 32,
                  height: 32,
                  color: _currentIndex == 2 ? Colors.black : Colors.grey,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/icons/user_12289885.png',
                  width: 32,
                  height: 32,
                  color: _currentIndex == 3 ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
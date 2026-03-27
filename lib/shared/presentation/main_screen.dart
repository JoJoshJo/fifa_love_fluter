import 'package:flutter/material.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/worldcup/presentation/worldcup_screen.dart';
import '../../features/me/presentation/me_screen.dart';
import '../widgets/bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DiscoverScreen(),
          ChatScreen(),
          WorldCupScreen(),
          MeScreen(),
        ],
      ),
      bottomNavigationBar: FifaBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            FocusScope.of(context).unfocus();
          });
        },
      ),
    );
  }
}

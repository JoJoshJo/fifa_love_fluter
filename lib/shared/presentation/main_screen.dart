import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/worldcup/presentation/worldcup_screen.dart';
import '../../features/me/presentation/me_screen.dart';
import '../widgets/bottom_nav.dart';
import '../providers/navigation_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Listen for tab changes from other screens (e.g. Discover → Chat)
    ref.listenManual(currentTabProvider, (prev, next) {
      if (mounted && next != _currentIndex) {
        setState(() => _currentIndex = next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Also react to currentTabProvider changes during build
    final tabFromProvider = ref.watch(currentTabProvider);
    if (tabFromProvider != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = tabFromProvider);
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            // Keep provider in sync
            ref.read(currentTabProvider.notifier).state = index;
            FocusScope.of(context).unfocus();
          });
        },
      ),
    );
  }
}

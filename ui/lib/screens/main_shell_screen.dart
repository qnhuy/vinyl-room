import 'package:flutter/material.dart';
import '../widgets/mini_player.dart';
import 'app_routes.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';
import 'search_screen.dart';

/// Khung chính của ứng dụng chứa các tab điều hướng và thanh phát nhạc thu nhỏ (Mini Player).
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          SearchScreen(),
          RankingScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(
            onTap: () => Navigator.pushNamed(context, AppRoutes.nowPlaying),
          ),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Tìm kiếm',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                selectedIcon: Icon(Icons.leaderboard),
                label: 'Xếp hạng',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Cá nhân',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Alias tương thích
typedef MainShell = MainShellScreen;

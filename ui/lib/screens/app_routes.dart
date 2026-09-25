import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/session.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_song_form_screen.dart';
import 'admin/admin_songs_screen.dart';
import 'admin/admin_users_screen.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';
import 'now_playing_screen.dart';
import 'playlist_detail_screen.dart';
import 'profile_screen.dart';
import 'public_playlists_screen.dart';
import 'ranking_screen.dart';
import 'register_screen.dart';
import 'search_screen.dart';

/// Quản lý danh sách URL và điều hướng các Screen tương ứng với URL trong toàn ứng dụng.
class AppRoutes {
  static const String shell = '/';
  static const String home = '/home';
  static const String search = '/search';
  static const String ranking = '/ranking';
  static const String profile = '/profile';
  static const String nowPlaying = '/now-playing';
  static const String playlistDetail = '/playlist-detail';
  static const String publicPlaylists = '/public-playlists';
  static const String login = '/login';
  static const String register = '/register';

  // Routes Quản trị viên (Admin)
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminSongs = '/admin/songs';
  static const String adminSongForm = '/admin/songs/form';
  static const String adminUsers = '/admin/users';

  /// Khởi tạo Route tương ứng với URL (name)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case shell:
      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainShellScreen(),
        );
      case search:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SearchScreen(),
        );
      case ranking:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RankingScreen(),
        );
      case profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileScreen(),
        );
      case nowPlaying:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NowPlayingScreen(),
        );
      case playlistDetail:
        final playlist = settings.arguments as Playlist?;
        if (playlist == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(
              body: Center(child: Text('Không tìm thấy playlist')),
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PlaylistDetailScreen(playlist: playlist),
        );
      case publicPlaylists:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PublicPlaylistsScreen(),
        );
      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );

      // --- Các routes Admin ---
      case admin:
      case adminDashboard:
        if (!Session.isAdmin) {
          return _forbiddenRoute(settings);
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminDashboardScreen(),
        );
      case adminSongs:
        if (!Session.isAdmin) {
          return _forbiddenRoute(settings);
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminSongsScreen(),
        );
      case adminSongForm:
        if (!Session.isAdmin) {
          return _forbiddenRoute(settings);
        }
        final song = settings.arguments as Song?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AdminSongFormScreen(song: song),
        );
      case adminUsers:
        if (!Session.isAdmin) {
          return _forbiddenRoute(settings);
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminUsersScreen(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('404 - Không tìm thấy')),
            body: Center(
              child: Text('Không tồn tại màn hình cho URL: ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Route<dynamic> _forbiddenRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Truy cập bị từ chối')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_bad, size: 64, color: Colors.redAccent),
                SizedBox(height: 16),
                Text(
                  '403 Forbidden',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Bạn không có quyền Quản trị viên để truy cập trang này!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

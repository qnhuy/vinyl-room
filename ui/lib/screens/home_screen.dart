import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../presenters/home_presenter.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import '../widgets/playlist_card.dart';
import '../widgets/section_header.dart';
import '../widgets/song_card.dart';
import 'app_routes.dart';

/// Màn hình Trang chủ hiển thị danh sách bài hát nghe gần đây, đang nghe nhiều và playlist.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> implements HomeView {
  late final HomePresenter _presenter;
  List<Song> _recent = [];
  List<Song> _topSongs = [];
  List<Playlist> _playlists = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _presenter = HomePresenter(this);
    MusicService.changeNotifier.addListener(_onDataChanged);
    _presenter.loadHomeData();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _presenter.loadHomeData();
  }

  // --- Triển khai các phương thức của HomeView ---
  @override
  void showLoading() {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
  }

  @override
  void hideLoading() {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void showHomeData({
    required List<Song> topSongs,
    required List<Song> recent,
    required List<Playlist> playlists,
  }) {
    if (mounted) {
      setState(() {
        _topSongs = topSongs;
        _recent = recent;
        _playlists = playlists;
      });
    }
  }

  @override
  void showError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
      });
    }
  }

  @override
  void showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guest = !Session.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(guest ? 'Vinyl Room (Khách)' : 'Vinyl Room'),
        actions: [
          if (guest)
            TextButton(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.login);
                if (mounted) _presenter.loadHomeData();
              },
              child: const Text('Đăng nhập'),
            ),
          IconButton(
            onPressed: () => _presenter.loadHomeData(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: () => _presenter.loadHomeData(),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (!guest) ...[
                        const SectionHeader(title: 'Nghe gần đây'),
                        if (_recent.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text('Chưa có lịch sử nghe'),
                          )
                        else
                          _buildHorizontalSongs(_recent),
                      ],
                      const SectionHeader(title: 'Đang nghe nhiều'),
                      if (_topSongs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Chưa có dữ liệu'),
                        )
                      else
                        _buildHorizontalSongs(_topSongs),
                      const SectionHeader(title: 'Playlist của tôi'),
                      if (guest)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextButton(
                            onPressed: () async {
                              await Navigator.pushNamed(
                                  context, AppRoutes.login);
                              if (mounted) _presenter.loadHomeData();
                            },
                            child: const Text('Đăng nhập để xem playlist'),
                          ),
                        )
                      else if (_playlists.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text('Chưa có playlist. Tạo ở tab Cá nhân.'),
                        )
                      else
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _playlists.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) {
                              final p = _playlists[i];
                              return PlaylistCard(
                                playlist: p,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.playlistDetail,
                                    arguments: p,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHorizontalSongs(List<Song> list) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = list[i];
          return SongCard(
            song: s,
            onTap: () => _presenter.playSong(s, list),
          );
        },
      ),
    );
  }
}

// Alias tương thích
typedef HomePage = HomeScreen;

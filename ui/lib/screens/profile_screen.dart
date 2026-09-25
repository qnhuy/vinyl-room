import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../presenters/profile_presenter.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import 'app_routes.dart';

/// Trang cá nhân hiển thị thông tin người dùng, bài hát yêu thích và danh sách playlist.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> implements ProfileView {
  late final ProfilePresenter _presenter;
  List<Song> _liked = [];
  List<Playlist> _playlists = [];
  List<Playlist> _favPlaylists = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _presenter = ProfilePresenter(this);
    MusicService.changeNotifier.addListener(_onDataChanged);
    _presenter.loadProfileData();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _presenter.loadProfileData();
  }

  @override
  void showLoading() {
    if (mounted) setState(() => _loading = true);
  }

  @override
  void hideLoading() {
    if (mounted) setState(() => _loading = false);
  }

  @override
  void showProfileData({
    required List<Song> liked,
    required List<Playlist> playlists,
    required List<Playlist> favPlaylists,
  }) {
    if (mounted) {
      setState(() {
        _liked = liked;
        _playlists = playlists;
        _favPlaylists = favPlaylists;
      });
    }
  }

  @override
  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _newPlaylist() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo Playlist mới'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nhập tên playlist...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await _presenter.createPlaylist(ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = Session.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.publicPlaylists);
              if (mounted) _presenter.loadProfileData();
            },
            icon: const Icon(Icons.explore),
            tooltip: 'Khám phá playlist công khai',
          ),
          IconButton(
            onPressed: () => AuthProvider.instance.toggleTheme(),
            icon: Icon(
              Session.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Đổi giao diện sáng/tối',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!loggedIn) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.account_circle,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'Bạn chưa đăng nhập',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              'Đăng nhập để quản lý bài hát yêu thích và playlist.'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () async {
                              await Navigator.pushNamed(
                                  context, AppRoutes.login);
                              if (mounted) _presenter.loadProfileData();
                            },
                            child: const Text('Đăng nhập / Đăng ký'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            child: Icon(Icons.person, size: 36),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Session.user!.username,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Session.user!.email ?? 'Chưa có email',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              await PlayerProvider.instance.stop();
                              await AuthProvider.instance.logout();
                              if (mounted) _presenter.loadProfileData();
                            },
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (Session.isAdmin) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: const Color(0xFFE8A35A).withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                            color: Color(0xFFE8A35A), width: 1.5),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8A35A),
                          child: Icon(Icons.admin_panel_settings,
                              color: Colors.black),
                        ),
                        title: const Text(
                          'Khu vực Quản trị Admin',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: const Text(
                            'Quản lý kho nhạc, người dùng & xem báo cáo thống kê'),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Color(0xFFE8A35A)),
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.adminDashboard),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bài hát yêu thích (${_liked.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_liked.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Chưa có bài hát yêu thích nào.'),
                      ),
                    )
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _liked.length > 5 ? 5 : _liked.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = _liked[i];
                          return ListTile(
                            leading: const Icon(Icons.favorite,
                                color: Colors.redAccent),
                            title: Text(s.title),
                            subtitle: Text(s.artist),
                            onTap: () =>
                                PlayerProvider.instance.playSong(s, _liked),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Playlist của tôi (${_playlists.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _newPlaylist,
                        icon: const Icon(Icons.add_circle, color: Colors.amber),
                        tooltip: 'Tạo playlist mới',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_playlists.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Chưa có playlist nào.'),
                            TextButton.icon(
                              onPressed: _newPlaylist,
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo ngay'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._playlists.map((p) {
                      final isShared = p.isShared;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading:
                              const Icon(Icons.queue_music, color: Colors.amber),
                          title: Text(p.name),
                          subtitle: Text(
                              '${p.songCount} bài · ${isShared ? "Công khai" : "Riêng tư"}'),
                          trailing: Icon(
                            isShared ? Icons.public : Icons.lock,
                            size: 18,
                            color: isShared ? Colors.green : Colors.grey,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.playlistDetail,
                              arguments: p,
                            );
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Playlist đã lưu (${_favPlaylists.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Navigator.pushNamed(
                              context, AppRoutes.publicPlaylists);
                          if (mounted) _presenter.loadProfileData();
                        },
                        child: const Text('Khám phá'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_favPlaylists.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Chưa lưu playlist công khai nào của người khác.'),
                      ),
                    )
                  else
                    ..._favPlaylists.map((p) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.bookmark,
                              color: Colors.blueAccent),
                          title: Text(p.name),
                          subtitle: Text(
                              'Tác giả: ${p.ownerName ?? 'Không rõ'} · ${p.songCount} bài'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.playlistDetail,
                              arguments: p,
                            );
                          },
                        ),
                      );
                    }),
                ],
              ],
            ),
    );
  }
}

// Alias tương thích
typedef ProfilePage = ProfileScreen;

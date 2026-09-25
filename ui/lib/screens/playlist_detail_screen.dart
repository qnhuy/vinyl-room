import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../presenters/playlist_detail_presenter.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import '../widgets/mini_player.dart';
import 'app_routes.dart';

/// Màn hình chi tiết Playlist hiển thị danh sách bài hát bên trong và các tùy chọn chia sẻ/yêu thích.
class PlaylistDetailScreen extends StatefulWidget {
  final dynamic playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen>
    implements PlaylistDetailView {
  late final PlaylistDetailPresenter _presenter;
  late Playlist _pl;
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _presenter = PlaylistDetailPresenter(this);
    if (widget.playlist is Playlist) {
      _pl = widget.playlist as Playlist;
    } else if (widget.playlist is Map<String, dynamic>) {
      _pl = Playlist.fromMap(widget.playlist as Map<String, dynamic>);
    } else {
      _pl = Playlist(id: 0, userId: 0, playlistName: 'Playlist');
    }

    MusicService.changeNotifier.addListener(_onDataChanged);
    if (_pl.id > 0) {
      _presenter.loadPlaylistSongs(_pl.id);
    }
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted && _pl.id > 0) {
      _presenter.loadPlaylistSongs(_pl.id);
    }
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
  void showSongs(List<Song> songs) {
    if (mounted) setState(() => _songs = songs);
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

  bool get _isOwner => Session.userId == _pl.userId;

  Future<void> _toggleShare() async {
    final nextShared = !_pl.isShared;

    try {
      await _presenter.toggleShare(_pl.id, nextShared);
      setState(() {
        _pl = _pl.copyWith(isShared: nextShared);
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            nextShared ? Icons.public : Icons.lock,
            size: 48,
            color: nextShared ? Colors.greenAccent : Colors.orangeAccent,
          ),
          title: Text(
            nextShared ? 'Đã công khai Playlist' : 'Đã đặt chế độ Riêng tư',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            nextShared
                ? 'Playlist "${_pl.name}" hiện đã ở chế độ Công khai (Public). Mọi người đều có thể tìm thấy và nghe playlist này!'
                : 'Playlist "${_pl.name}" hiện đã chuyển sang chế độ Riêng tư (Private). Chỉ mình bạn có thể xem playlist này!',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final nextFav = !_pl.isFavorite;
    await _presenter.toggleFavorite(_pl.id, nextFav);
    setState(() {
      _pl = _pl.copyWith(isFavorite: nextFav);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isShared = _pl.isShared;
    final isFavorite = _pl.isFavorite;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pl.name),
        actions: [
          if (_isOwner)
            IconButton(
              icon: Icon(
                isShared ? Icons.public : Icons.lock,
                color: isShared ? Colors.greenAccent : Colors.orangeAccent,
              ),
              tooltip: isShared
                  ? 'Đang Công khai (Bấm để đổi Riêng tư)'
                  : 'Đang Riêng tư (Bấm để đổi Công khai)',
              onPressed: _toggleShare,
            )
          else
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : null,
              ),
              tooltip: isFavorite ? 'Bỏ lưu' : 'Lưu playlist',
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pl.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tác giả: ${_pl.ownerName ?? 'Tôi'} · ${_songs.length} bài hát',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isShared ? Icons.public : Icons.lock,
                            size: 14,
                            color: isShared
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isShared
                                ? 'Công khai (Public)'
                                : 'Riêng tư (Private)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isShared
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                      if (_songs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _presenter.playSong(_songs.first, _songs),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Phát tất cả'),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: _songs.isEmpty
                      ? const Center(
                          child: Text('Playlist chưa có bài hát nào'),
                        )
                      : ListView.builder(
                          itemCount: _songs.length,
                          itemBuilder: (_, i) {
                            final s = _songs[i];
                            return ListTile(
                              leading: const Icon(Icons.music_note),
                              title: Text(s.title),
                              subtitle: Text(s.artist),
                              trailing: IconButton(
                                icon: Icon(
                                  s.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: s.isFavorite ? Colors.redAccent : null,
                                ),
                                onPressed: () async {
                                  await _presenter.toggleSongFavorite(
                                    s.musicId!,
                                    !s.isFavorite,
                                  );
                                  if (_pl.id > 0) {
                                    _presenter.loadPlaylistSongs(_pl.id);
                                  }
                                },
                              ),
                              onTap: () => _presenter.playSong(s, _songs),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: MiniPlayer(
        onTap: () => Navigator.pushNamed(context, AppRoutes.nowPlaying),
      ),
    );
  }
}

// Alias tương thích
typedef PlaylistDetailPage = PlaylistDetailScreen;

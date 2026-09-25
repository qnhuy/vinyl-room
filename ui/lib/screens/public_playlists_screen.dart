import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/music_service.dart';
import 'app_routes.dart';

/// Màn hình khám phá các playlist công khai từ những người dùng khác.
class PublicPlaylistsScreen extends StatefulWidget {
  const PublicPlaylistsScreen({super.key});

  @override
  State<PublicPlaylistsScreen> createState() => _PublicPlaylistsScreenState();
}

class _PublicPlaylistsScreenState extends State<PublicPlaylistsScreen> {
  List<Playlist> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    MusicService.changeNotifier.addListener(_onDataChanged);
    _load();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _playlists = await MusicService.instance.getPublicPlaylists();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khám phá Playlist công khai')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? const Center(child: Text('Chưa có playlist công khai nào'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _playlists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = _playlists[i];

                    return Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(child: Icon(Icons.queue_music)),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tạo bởi: ${p.ownerName ?? 'Không rõ'} · ${p.songCount} bài hát',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            p.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: p.isFavorite ? Colors.redAccent : null,
                          ),
                          tooltip:
                              p.isFavorite ? 'Bỏ lưu' : 'Lưu vào yêu thích',
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await MusicService.instance
                                  .togglePlaylistFavorite(p.id, !p.isFavorite);
                              _load();
                            } catch (e) {
                              if (mounted) {
                                messenger
                                    .showSnackBar(SnackBar(content: Text('$e')));
                              }
                            }
                          },
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
                  },
                ),
    );
  }
}

// Alias tương thích
typedef PublicPlaylistsPage = PublicPlaylistsScreen;

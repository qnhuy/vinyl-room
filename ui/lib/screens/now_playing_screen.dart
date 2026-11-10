import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import 'app_routes.dart';

/// Màn hình phát nhạc toàn màn hình (Now Playing).
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final player = PlayerProvider.instance;

  @override
  void initState() {
    super.initState();
    MusicService.changeNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    final song = player.current;
    if (song?.musicId == null) return;

    if (!Session.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    final next = !song!.isFavorite;
    try {
      await MusicService.instance.toggleFavorite(song.musicId!, next);
      player.updateCurrentFavorite(next);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addToPlaylist() async {
    final song = player.current;
    if (song?.musicId == null) return;

    if (!Session.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    final playlists = await MusicService.instance.getPlaylists();
    if (!mounted) return;

    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có playlist. Hãy tạo ở tab Cá nhân.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Playlist>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Thêm vào playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...playlists.map((p) {
                return ListTile(
                  leading: const Icon(Icons.queue_music, color: Colors.amber),
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, p),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    try {
      await MusicService.instance.addToPlaylist(selected.id, song!.musicId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm vào playlist ${selected.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _cover(Song song) {
    final url = song.coverImageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF282828),
      child: const Center(
        child: Icon(Icons.album, size: 100, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = player.current;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E0D),
      body: SafeArea(
        child: song == null
            ? const Center(
                child: Text(
                  'Chưa chọn bài hát',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 32,
                          ),
                          tooltip: 'Thu nhỏ',
                        ),
                        const Expanded(
                          child: Text(
                            'ĐANG PHÁT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (!AuthProvider.instance.isPremium) {
                              Navigator.pushNamed(context, AppRoutes.premiumPayment);
                              return;
                            }
                            player.toggleSmartFlow();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 2),
                                content: Text(
                                  player.isSmartFlow
                                      ? '✨ Đã BẬT AI Smart Flow: Tự động nối tiếp bài hát cùng tâm trạng'
                                      : 'Đã TẮT AI Smart Flow',
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.auto_awesome,
                            color: player.isSmartFlow
                                ? const Color(0xFFE8A35A)
                                : Colors.white38,
                          ),
                          tooltip: AuthProvider.instance.isPremium
                              ? 'AI Smart Flow (Nối mood thông minh)'
                              : 'AI Smart Flow (Yêu cầu Vinyl Premium 19k)',
                        ),
                        IconButton(
                          onPressed: _addToPlaylist,
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          tooltip: 'Tùy chọn',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _cover(song),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              if (player.currentAiReason != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8A35A)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE8A35A)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_awesome,
                                          size: 13,
                                          color: Color(0xFFE8A35A)),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'AI: ${player.currentAiReason}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFE8A35A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            song.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: song.isFavorite
                                ? const Color(0xFFE8A35A)
                                : Colors.white,
                          ),
                          tooltip: 'Yêu thích',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<Duration?>(
                    stream: player.durationStream,
                    builder: (context, durSnap) {
                      final total = durSnap.data ?? Duration.zero;
                      final maxMs = total.inMilliseconds > 0
                          ? total.inMilliseconds.toDouble()
                          : 1.0;

                      return StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (context, posSnap) {
                          final pos = posSnap.data ?? Duration.zero;
                          final value = pos.inMilliseconds
                              .clamp(0, maxMs.toInt())
                              .toDouble();

                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFFE8A35A),
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  trackHeight: 3,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: value,
                                  max: maxMs,
                                  onChanged: (v) {
                                    player.seek(
                                      Duration(milliseconds: v.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _format(pos),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _format(total),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? player.playing;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () async {
                                await player.toggleRepeat();
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.repeat,
                                color: player.repeat
                                    ? const Color(0xFFE8A35A)
                                    : Colors.white70,
                              ),
                              tooltip: 'Lặp lại',
                            ),
                            IconButton(
                              iconSize: 40,
                              onPressed: () async {
                                await player.previous();
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                              ),
                              tooltip: 'Bài trước',
                            ),
                            Material(
                              color: const Color(0xFFE8A35A),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () async {
                                  await player.togglePlay();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    playing ? Icons.pause : Icons.play_arrow,
                                    size: 40,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              iconSize: 40,
                              onPressed: () async {
                                await player.next();
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                              ),
                              tooltip: 'Bài tiếp theo',
                            ),
                            IconButton(
                              onPressed: _addToPlaylist,
                              icon: const Icon(
                                Icons.playlist_add,
                                color: Colors.white70,
                              ),
                              tooltip: 'Thêm vào playlist',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<double>(
                    stream: player.volumeStream,
                    builder: (context, snapshot) {
                      final vol = snapshot.data ?? player.volume;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                vol == 0
                                    ? Icons.volume_off
                                    : vol < 0.5
                                        ? Icons.volume_down
                                        : Icons.volume_up,
                                color: Colors.white70,
                                size: 20,
                              ),
                              onPressed: () {
                                player.setVolume(vol > 0 ? 0.0 : 1.0);
                              },
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFFE8A35A),
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: vol.clamp(0.0, 1.0),
                                  onChanged: (v) => player.setVolume(v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(vol * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}

// Alias tương thích
typedef NowPlayingPage = NowPlayingScreen;
